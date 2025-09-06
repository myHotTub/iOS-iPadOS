
import Foundation
import Observation

struct ScheduleData: Codable {
	let len: Int
	let cmd: [Int]?
	let value: [Int]?
	let xtime: [Int]?
	let interval: [Int]?
	let txt: [String]?

	enum CodingKeys: String, CodingKey {
		case len = "LEN"
		case cmd = "CMD"
		case value = "VALUE"
		case xtime = "XTIME"
		case interval = "INTERVAL"
		case txt = "TXT"
	}
}

struct SpaCommand {
	let cmd: Int
	let value: Float
	let xtime: Int
	let interval: Int
	let txt: String

	// MARK: - Spa Command Types
	static func setTargetTemp(_ temp: Int, at time: Date, interval: TimeInterval, txt: String = "") -> SpaCommand {
		return SpaCommand(
			cmd: 0,
			value: Float(temp),
			xtime: Int(time.timeIntervalSince1970),
			interval: Int(interval),
			txt: txt
		)
	}

	static func setHeater(_ enabled: Bool, at time: Date, interval: TimeInterval, txt: String = "") -> SpaCommand {
		return SpaCommand(
			cmd: 3,
			value: enabled ? 1 : 0,
			xtime: Int(time.timeIntervalSince1970),
			interval: Int(interval),
			txt: txt
		)
	}

	static func setFilterPump(_ enabled: Bool, at time: Date, interval: TimeInterval, txt: String = "") -> SpaCommand {
		return SpaCommand(
			cmd: 4,
			value: enabled ? 1 : 0,
			xtime: Int(time.timeIntervalSince1970),
			interval: Int(interval),
			txt: txt
		)
	}
}

// MARK: - Schedule Models
struct DailySchedule: Identifiable {
	let id = UUID()
	let order: Int
	let startTime: Date
	let endTime: Date
	let heaterEnabled: Bool
	let targetTemperature: Int?
	let filterEnabled: Bool
	let isGapSchedule: Bool
	
	var txtIdentifier: String {
		if isGapSchedule {
			return "gap_\(order)_\(Int(startTime.timeIntervalSince1970))"
		} else {
			let startTimestamp = Int(startTime.timeIntervalSince1970)
			let endTimestamp = Int(endTime.timeIntervalSince1970)
			return "schedule_\(order)_\(startTimestamp)_\(endTimestamp)"
		}
	}
	
	var timeRange: String {
		let formatter = DateFormatter()
		formatter.timeStyle = .short
		return "\(formatter.string(from: startTime)) - \(formatter.string(from: endTime))"
	}
}

struct LegacyScheduleItem {
	let index: Int
	let command: Int
	let value: Int
	let xtime: Int
	let interval: Int
	let suggestedStartTime: Date
}

enum ScheduleConflict {
	case overlap(with: DailySchedule, conflictRange: String)
	case none
}

@Observable
@MainActor
class ScheduleManager {
	private(set) var data: ScheduleData?
	private(set) var isLoading = false
	private(set) var errorMessage: String?
	private(set) var isSaving = false
	private(set) var legacySchedules: [LegacyScheduleItem] = []
	private(set) var scheduleBaseDate: Date?
	
	// User preferences
	var defaultFilterEnabled: Bool = false // Placeholder for user setting
	
	// Legacy Schedule Deletion
	var isDeletingLegacy: Bool     = false
	var deletionProgress: Int      = 0
	
	#if DEBUG_BUILD
	private let baseUrl = "http://layzspa-test.local"
	#else
	private let baseUrl = "http://layzspa.local"
	#endif
	
	// API Endpoints
	private var getCommandsUrl: URL { URL(string: "\(baseUrl)/getcommands/")! }
	private var addCommandUrl: URL { URL(string: "\(baseUrl)/addcommand/")! }
	private var editCommandUrl: URL { URL(string: "\(baseUrl)/editcommand/")! }
	private var deleteCommandUrl: URL { URL(string: "\(baseUrl)/delcommand/")! }

	func fetchData() async {
		isLoading = true
		errorMessage = nil

		do {
			var request = URLRequest(url: getCommandsUrl)
			request.httpMethod = "POST"
			
			let (rawData, response) = try await URLSession.shared.data(for: request)
			guard let httpResponse = response as? HTTPURLResponse,
				  httpResponse.statusCode == 200 else {
				errorMessage = "Invalid response from server"
				isLoading = false
				return
			}

			guard !rawData.isEmpty else {
				errorMessage = "No data received"
				isLoading = false
				return
			}

			let decoder = JSONDecoder()
			let scheduleData = try decoder.decode(ScheduleData.self, from: rawData)

			if scheduleData.len == 0 {
				self.data = scheduleData
				self.legacySchedules = []
				errorMessage = "No schedules found."
			} else {
				self.data = scheduleData
				self.legacySchedules = identifyLegacySchedules(from: scheduleData)
				errorMessage = nil
			}

		} catch let decodingError as DecodingError {
			errorMessage = "Unexpected data format: \(decodingError.localizedDescription)"
		} catch {
			errorMessage = "Network error: \(error.localizedDescription)"
		}

		isLoading = false
	}
	
	private func getOrSetBaseDate(for newSchedule: DailySchedule? = nil) -> Date {
		let calendar = Calendar.current
		
		// If we already have a base date, use it
		if let existingBaseDate = scheduleBaseDate {
			return existingBaseDate
		}
		
		// If no base date exists, determine it from existing schedules or set a new one
		let existingSchedules = parseExistingSchedules().filter { !$0.isGapSchedule }
		
		if let firstExisting = existingSchedules.first {
			// Use the date from the first existing schedule
			let baseDate = calendar.startOfDay(for: firstExisting.startTime)
			scheduleBaseDate = baseDate
			return baseDate
		} else if let newSchedule = newSchedule {
			// Use yesterday relative to the new schedule being added
			let baseDate = calendar.startOfDay(for: calendar.date(byAdding: .day, value: -1, to: newSchedule.startTime) ?? newSchedule.startTime)
			scheduleBaseDate = baseDate
			return baseDate
		} else {
			// Fallback to yesterday
			let baseDate = calendar.startOfDay(for: calendar.date(byAdding: .day, value: -1, to: Date()) ?? Date())
			scheduleBaseDate = baseDate
			return baseDate
		}
	}

	// MARK: - Schedule Management
//	func addSchedule(_ schedule: DailySchedule) async -> Bool {
//		// Check for conflicts first (only with non-gap schedules)
//		let conflict = checkForConflicts(schedule)
//		if case .overlap = conflict {
//			return false // Conflict detected, don't proceed
//		}
//		
//		// Delete all existing schedules and regenerate everything
//		let success = await clearAllSchedulesAndRegenerate(addingSchedule: schedule)
//		return success
//	}
	func addSchedule(_ schedule: DailySchedule) async -> Bool {
		// Validate schedule doesn't cross midnight inappropriately
		let calendar = Calendar.current
		
		// Extract time components
		let startComponents = calendar.dateComponents([.hour, .minute], from: schedule.startTime)
		let endComponents = calendar.dateComponents([.hour, .minute], from: schedule.endTime)
		
		let startMinutes = (startComponents.hour ?? 0) * 60 + (startComponents.minute ?? 0)
		let endMinutes = (endComponents.hour ?? 0) * 60 + (endComponents.minute ?? 0)
		
		// Special case: if end time is 00:00, treat it as end of day (1440 minutes)
		let adjustedEndMinutes = endMinutes == 0 ? 1440 : endMinutes
		
		// Validate that start time is before end time within the same day
		if startMinutes >= adjustedEndMinutes {
			errorMessage = "Schedule start time must be before end time."
			return false
		}
		
		// Check for conflicts first (only with non-gap schedules)
		let conflict = checkForConflicts(schedule)
		if case .overlap = conflict {
			return false // Conflict detected, don't proceed
		}
		
		// Delete all existing schedules and regenerate everything
		let success = await clearAllSchedulesAndRegenerate(addingSchedule: schedule)
		return success
	}
	
	func checkForConflicts(_ newSchedule: DailySchedule) -> ScheduleConflict {
		let existingSchedules = parseExistingSchedules().filter { !$0.isGapSchedule }
		
		for existing in existingSchedules {
			if schedulesOverlap(newSchedule, existing) {
				return .overlap(with: existing, conflictRange: existing.timeRange)
			}
		}
		
		return .none
	}
	
	func getNextAvailableStartTime() -> Date {
		let existingSchedules = parseExistingSchedules().filter { !$0.isGapSchedule }.sorted { $0.startTime < $1.startTime }
		
		// Start of day
		let calendar = Calendar.current
		let today = Date()
		var startOfDay = calendar.startOfDay(for: today)
		
		// Find the first gap
		for schedule in existingSchedules {
			let dayStart = calendar.startOfDay(for: schedule.startTime)
			let scheduleStartTime = calendar.dateComponents([.hour, .minute], from: schedule.startTime)
			let scheduleEndTime = calendar.dateComponents([.hour, .minute], from: schedule.endTime)
			
			let scheduleStart = calendar.date(byAdding: .hour, value: scheduleStartTime.hour ?? 0, to:
				calendar.date(byAdding: .minute, value: scheduleStartTime.minute ?? 0, to: dayStart)!)!
			let scheduleEnd = calendar.date(byAdding: .hour, value: scheduleEndTime.hour ?? 0, to:
				calendar.date(byAdding: .minute, value: scheduleEndTime.minute ?? 0, to: dayStart)!)!
			
			// If current start time doesn't conflict with this schedule, use it
			if startOfDay < scheduleStart {
				return startOfDay
			}
			
			// Move start time to end of this schedule
			startOfDay = scheduleEnd
		}
		
		return startOfDay
	}
	
	func parseExistingSchedules() -> [DailySchedule] {
		guard let data = data, data.len > 0,
			  let txtArray = data.txt,
			  let xtimeArray = data.xtime else {
			return []
		}
		
		var scheduleGroups: [String: [Int]] = [:]
		
		// Group indices by txt identifier (include both schedule_ and gap_ prefixes)
		for (index, txt) in txtArray.enumerated() {
			if txt.hasPrefix("schedule_") || txt.hasPrefix("gap_") {
				if scheduleGroups[txt] == nil {
					scheduleGroups[txt] = []
				}
				scheduleGroups[txt]?.append(index)
			}
		}
		
		var schedules: [DailySchedule] = []
		
		for (txtId, indices) in scheduleGroups {
			if txtId.hasPrefix("schedule_") {
				if let schedule = parseScheduleFromTxt(txtId, indices: indices, data: data) {
					schedules.append(schedule)
				}
			} else if txtId.hasPrefix("gap_") {
				if let gapSchedule = parseGapScheduleFromTxt(txtId, indices: indices, data: data) {
					schedules.append(gapSchedule)
				}
			}
		}
		
		return schedules
	}

	private func parseScheduleFromTxt(_ txtId: String, indices: [Int], data: ScheduleData) -> DailySchedule? {
		let components = txtId.split(separator: "_")
		guard components.count >= 4,
			  let order = Int(components[1]),
			  let startTimestamp = Int(components[2]),
			  let endTimestamp = Int(components[3]),
			  let cmdArray = data.cmd,
			  let valueArray = data.value,
			  let xtimeArray = data.xtime
		else { return nil }

		let startTime = Date(timeIntervalSince1970: TimeInterval(startTimestamp))
		let endTime = Date(timeIntervalSince1970: TimeInterval(endTimestamp))

		var heaterEnabled = false
		var targetTemperature: Int?
		var filterEnabled = false

		// Get all commands for this specific schedule
		let scheduleIndices = indices.filter { idx in
			guard idx < data.len,
				  let txtArray = data.txt,
				  idx < txtArray.count else { return false }
			return txtArray[idx] == txtId
		}

		// Look at START commands to determine what gets enabled
		let startCommands = scheduleIndices.filter { idx in
			let xtime = xtimeArray[idx]
			return xtime == startTimestamp
		}

		// Process start commands to see what gets turned ON
		for idx in startCommands {
			let cmd = cmdArray[idx]
			let value = valueArray[idx]

			switch cmd {
			case 3: // Heater command
				if value == 1 {
					heaterEnabled = true
				}
			case 0: // Target temperature command
				if value > 0 {
					targetTemperature = value
				}
			case 4: // Filter command
				if value == 1 {
					filterEnabled = true
				}
			default:
				break
			}
		}
		
		// If no start commands found (shouldn't happen), look at all commands for this schedule
		// and infer the state from what gets turned ON vs OFF
		if startCommands.isEmpty {
			var hasHeaterOn = false
			var hasFilterOn = false
			var foundTargetTemp: Int?
			
			for idx in scheduleIndices {
				let cmd = cmdArray[idx]
				let value = valueArray[idx]
				
				switch cmd {
				case 3: // Heater
					if value == 1 { hasHeaterOn = true }
				case 0: // Target temp
					if value > 0 { foundTargetTemp = value }
				case 4: // Filter
					if value == 1 { hasFilterOn = true }
				default:
					break
				}
			}
			
			heaterEnabled = hasHeaterOn
			targetTemperature = foundTargetTemp
			filterEnabled = hasFilterOn
		}
		
		return DailySchedule(
			order: order,
			startTime: startTime,
			endTime: endTime,
			heaterEnabled: heaterEnabled,
			targetTemperature: targetTemperature,
			filterEnabled: filterEnabled,
			isGapSchedule: false
		)
	}

	private func parseGapScheduleFromTxt(_ txtId: String, indices: [Int], data: ScheduleData) -> DailySchedule? {
		let components = txtId.split(separator: "_")
		guard components.count >= 3,
			  let order = Int(components[1]),
			  let startTimestamp = Int(components[2]),
			  let xtimeArray = data.xtime,
			  let cmdArray = data.cmd,
			  let valueArray = data.value
		else { return nil }

		let startTime = Date(timeIntervalSince1970: TimeInterval(startTimestamp))
		
		// Find the next schedule or end of day to determine end time
		let allScheduleTimes = parseAllScheduleTimes()
		let endTime = findGapEndTime(startTime: startTime, allTimes: allScheduleTimes)
		
		// Gap schedules should always show "All OFF"
		return DailySchedule(
			order: order,
			startTime: startTime,
			endTime: endTime,
			heaterEnabled: false,
			targetTemperature: nil,
			filterEnabled: false,
			isGapSchedule: true
		)
	}
	
	private func parseAllScheduleTimes() -> [Date] {
		guard let data = data, data.len > 0,
			  let txtArray = data.txt,
			  let xtimeArray = data.xtime else {
			return []
		}
		
		var times: [Date] = []
		
		for (index, txt) in txtArray.enumerated() {
			if txt.hasPrefix("schedule_") {
				let components = txt.split(separator: "_")
				if components.count >= 4,
				   let startTimestamp = Int(components[2]),
				   let endTimestamp = Int(components[3]) {
					times.append(Date(timeIntervalSince1970: TimeInterval(startTimestamp)))
					times.append(Date(timeIntervalSince1970: TimeInterval(endTimestamp)))
				}
			}
		}
		
		return times.sorted()
	}
	
	private func findGapEndTime(startTime: Date, allTimes: [Date]) -> Date {
		let calendar = Calendar.current
		let baseDate = calendar.startOfDay(for: startTime)
		let endOfDay = calendar.date(byAdding: .day, value: 1, to: baseDate) ?? startTime
		
		// Find the next schedule time after startTime
		for time in allTimes {
			let timeInSameDay = calendar.date(bySettingHour: calendar.component(.hour, from: time),
											 minute: calendar.component(.minute, from: time),
											 second: 0, of: baseDate) ?? time
			if timeInSameDay > startTime {
				return timeInSameDay
			}
		}
		
		return endOfDay
	}
	
	private func schedulesOverlap(_ schedule1: DailySchedule, _ schedule2: DailySchedule) -> Bool {
		let calendar = Calendar.current
		
		// Extract time components for comparison
		let start1 = calendar.dateComponents([.hour, .minute], from: schedule1.startTime)
		let end1 = calendar.dateComponents([.hour, .minute], from: schedule1.endTime)
		let start2 = calendar.dateComponents([.hour, .minute], from: schedule2.startTime)
		let end2 = calendar.dateComponents([.hour, .minute], from: schedule2.endTime)
		
		let start1Minutes = (start1.hour ?? 0) * 60 + (start1.minute ?? 0)
		let end1Minutes = (end1.hour ?? 0) * 60 + (end1.minute ?? 0)
		let start2Minutes = (start2.hour ?? 0) * 60 + (start2.minute ?? 0)
		let end2Minutes = (end2.hour ?? 0) * 60 + (end2.minute ?? 0)
		
		// Check for overlap (start time can equal end time, but not overlap)
		return start1Minutes < end2Minutes && start2Minutes < end1Minutes
	}
	
	private func clearAllSchedulesAndRegenerate(addingSchedule newSchedule: DailySchedule? = nil) async -> Bool {
		// Get existing non-gap schedules
		var existingSchedules = parseExistingSchedules().filter { !$0.isGapSchedule }
		
		// Add new schedule if provided
		if let newSchedule = newSchedule {
			existingSchedules.append(newSchedule)
		}
		
		// Clear the queue first
		let clearSuccess = await clearQueue()
		if !clearSuccess {
			return false
		}
		
		// Generate all commands with proper ordering
		let allCommands = generateAllCommands(for: existingSchedules)
		
		// Add all commands
		for command in allCommands {
			let success = await addSingleCommand(command)
			if !success {
				return false
			}
		}
		
		return true
	}
	
	private func generateAllCommands(for schedules: [DailySchedule]) -> [SpaCommand] {
		var commands: [SpaCommand] = []
		let interval: TimeInterval = 86400 // Daily
		
		// Find the earliest date among all schedules to use as base date
		let baseDate = findBaseDate(for: schedules)
		
		// Normalize and sort schedules by start time, then assign proper order numbers
		let normalizedAndSorted = schedules
			.map { normalizeScheduleToBaseDate($0, baseDate: baseDate) }
			.sorted { $0.startTime < $1.startTime }
			.enumerated()
			.map { index, schedule in
				DailySchedule(
					order: index, // Assign chronological order
					startTime: schedule.startTime,
					endTime: schedule.endTime,
					heaterEnabled: schedule.heaterEnabled,
					targetTemperature: schedule.targetTemperature,
					filterEnabled: schedule.filterEnabled,
					isGapSchedule: false
				)
			}
		
		// Generate commands for all schedules
		for schedule in normalizedAndSorted {
			let scheduleCommands = generateScheduleCommands(schedule, interval: interval)
			commands.append(contentsOf: scheduleCommands)
		}
		
		// Generate gap-filling commands with proper numbering
		let gapCommands = generateGapFillingCommands(for: normalizedAndSorted, interval: interval)
		commands.append(contentsOf: gapCommands)
		
		return commands
	}
	
//	private func findBaseDate(for schedules: [DailySchedule]) -> Date {
//		guard !schedules.isEmpty else {
//			return Calendar.current.startOfDay(for: Date())
//		}
//		
//		// Find the earliest start time among all schedules
//		let earliestStartTime = schedules.min { $0.startTime < $1.startTime }?.startTime ?? Date()
//		
//		// Return the start of that day as our base date
//		return Calendar.current.startOfDay(for: earliestStartTime)
//	}
	private func findBaseDate(for schedules: [DailySchedule]) -> Date {
		return getOrSetBaseDate()
	}
	
//	private func normalizeScheduleToBaseDate(_ schedule: DailySchedule, baseDate: Date) -> DailySchedule {
//		let calendar = Calendar.current
//		
//		// Extract time components from original schedule
//		let startComponents = calendar.dateComponents([.hour, .minute], from: schedule.startTime)
//		let endComponents = calendar.dateComponents([.hour, .minute], from: schedule.endTime)
//		
//		// Create new dates using the base date
//		let normalizedStartTime = calendar.date(byAdding: .hour, value: startComponents.hour ?? 0, to:
//			calendar.date(byAdding: .minute, value: startComponents.minute ?? 0, to: baseDate)!) ?? schedule.startTime
//		
//		var normalizedEndTime = calendar.date(byAdding: .hour, value: endComponents.hour ?? 0, to:
//			calendar.date(byAdding: .minute, value: endComponents.minute ?? 0, to: baseDate)!) ?? schedule.endTime
//		
//		// Handle end time being on the next day (e.g., 23:30 to 00:30)
//		if normalizedEndTime <= normalizedStartTime {
//			normalizedEndTime = calendar.date(byAdding: .day, value: 1, to: normalizedEndTime) ?? normalizedEndTime
//		}
//		
//		return DailySchedule(
//			order: schedule.order,
//			startTime: normalizedStartTime,
//			endTime: normalizedEndTime,
//			heaterEnabled: schedule.heaterEnabled,
//			targetTemperature: schedule.targetTemperature,
//			filterEnabled: schedule.filterEnabled,
//			isGapSchedule: schedule.isGapSchedule
//		)
//	}
	private func normalizeScheduleToBaseDate(_ schedule: DailySchedule, baseDate: Date) -> DailySchedule {
		let calendar = Calendar.current
		
		// Extract time components from original schedule
		let startComponents = calendar.dateComponents([.hour, .minute], from: schedule.startTime)
		let endComponents = calendar.dateComponents([.hour, .minute], from: schedule.endTime)
		
		// Create new dates using the base date
		let normalizedStartTime = calendar.date(byAdding: .hour, value: startComponents.hour ?? 0, to:
			calendar.date(byAdding: .minute, value: startComponents.minute ?? 0, to: baseDate)!) ?? schedule.startTime
		
		var normalizedEndTime: Date
		
		// Special handling for 00:00 end time - treat as end of the same day
		if (endComponents.hour ?? 0) == 0 && (endComponents.minute ?? 0) == 0 {
			// End time is 00:00, so set it to the start of the next day (end of current day)
			normalizedEndTime = calendar.date(byAdding: .day, value: 1, to: baseDate) ?? schedule.endTime
		} else {
			normalizedEndTime = calendar.date(byAdding: .hour, value: endComponents.hour ?? 0, to:
				calendar.date(byAdding: .minute, value: endComponents.minute ?? 0, to: baseDate)!) ?? schedule.endTime
		}
		
		return DailySchedule(
			order: schedule.order,
			startTime: normalizedStartTime,
			endTime: normalizedEndTime,
			heaterEnabled: schedule.heaterEnabled,
			targetTemperature: schedule.targetTemperature,
			filterEnabled: schedule.filterEnabled,
			isGapSchedule: schedule.isGapSchedule
		)
	}
	
//	private func generateScheduleCommands(_ schedule: DailySchedule, interval: TimeInterval) -> [SpaCommand] {
//		var commands: [SpaCommand] = []
//		
//		// Start time commands - all commands at the same timestamp should have the same XTIME
//		if schedule.heaterEnabled {
//			commands.append(.setHeater(true, at: schedule.startTime, interval: interval, txt: schedule.txtIdentifier))
//			if let temp = schedule.targetTemperature {
//				commands.append(.setTargetTemp(temp, at: schedule.startTime, interval: interval, txt: schedule.txtIdentifier))
//			}
//		}
//		
//		// Handle filter independently of heater
//		if schedule.filterEnabled {
//			commands.append(.setFilterPump(true, at: schedule.startTime, interval: interval, txt: schedule.txtIdentifier))
//		}
//		
//		// End time commands - all commands at the same timestamp should have the same XTIME
//		commands.append(.setHeater(false, at: schedule.endTime, interval: interval, txt: schedule.txtIdentifier))
//		if schedule.filterEnabled {
//			commands.append(.setFilterPump(false, at: schedule.endTime, interval: interval, txt: schedule.txtIdentifier))
//		}
//		
//		return commands
//	}
	private func generateScheduleCommands(_ schedule: DailySchedule, interval: TimeInterval) -> [SpaCommand] {
		var commands: [SpaCommand] = []
		
		// Generate commands based on what this schedule should enable/disable
		
		// Heater commands
		if schedule.heaterEnabled {
			commands.append(.setHeater(true, at: schedule.startTime, interval: interval, txt: schedule.txtIdentifier))
			if let temp = schedule.targetTemperature {
				commands.append(.setTargetTemp(temp, at: schedule.startTime, interval: interval, txt: schedule.txtIdentifier))
			}
			// Filter is automatically enabled when heater is enabled
			commands.append(.setFilterPump(true, at: schedule.startTime, interval: interval, txt: schedule.txtIdentifier))
		} else {
			// Heater is disabled for this schedule - explicitly turn it off
			commands.append(.setHeater(false, at: schedule.startTime, interval: interval, txt: schedule.txtIdentifier))
			
			// Handle filter independently when heater is off
			if schedule.filterEnabled {
				commands.append(.setFilterPump(true, at: schedule.startTime, interval: interval, txt: schedule.txtIdentifier))
			} else {
				commands.append(.setFilterPump(false, at: schedule.startTime, interval: interval, txt: schedule.txtIdentifier))
			}
		}
		
		return commands
	}
	
	private func generateGapFillingCommands(for schedules: [DailySchedule], interval: TimeInterval) -> [SpaCommand] {
		var commands: [SpaCommand] = []
		let calendar = Calendar.current
		
		// Use the same base date as the schedules
		let baseDate = schedules.first.map { calendar.startOfDay(for: $0.startTime) } ?? calendar.startOfDay(for: Date())
		
		// Create time periods that need default OFF state
		var gapPeriods: [(start: Date, end: Date)] = []
		var gapOrderCounter = schedules.count // Start gap numbering after schedule numbers
		
		if schedules.isEmpty {
			// Full day default
			let startOfDay = baseDate
			let endOfDay = calendar.date(byAdding: .day, value: 1, to: baseDate)!
			gapPeriods.append((start: startOfDay, end: endOfDay))
		} else {
			let sortedSchedules = schedules.sorted { $0.startTime < $1.startTime }
			
			// Before first schedule
			let firstScheduleStart = sortedSchedules[0].startTime
			if firstScheduleStart > baseDate {
				gapPeriods.append((start: baseDate, end: firstScheduleStart))
			}
			
			// Between schedules
			for i in 0..<(sortedSchedules.count - 1) {
				let currentEnd = sortedSchedules[i].endTime
				let nextStart = sortedSchedules[i + 1].startTime
				
				if currentEnd < nextStart {
					gapPeriods.append((start: currentEnd, end: nextStart))
				}
			}
			
			// After last schedule
			let lastScheduleEnd = sortedSchedules.last!.endTime
			let endOfDay = calendar.date(byAdding: .day, value: 1, to: baseDate)!
			if lastScheduleEnd < endOfDay {
				gapPeriods.append((start: lastScheduleEnd, end: endOfDay))
			}
		}
		
		// Create default OFF commands for gap periods with proper sequential numbering
		for period in gapPeriods {
			let gapTxt = "gap_\(gapOrderCounter)_\(Int(period.start.timeIntervalSince1970))"
			
			// All gap commands at the same time should have identical XTIME
			commands.append(.setHeater(false, at: period.start, interval: interval, txt: gapTxt))
			commands.append(.setFilterPump(false, at: period.start, interval: interval, txt: gapTxt))
			
			gapOrderCounter += 1
		}
		
		return commands
	}
	
	private func identifyLegacySchedules(from data: ScheduleData) -> [LegacyScheduleItem] {
		guard data.len > 0,
			  let txtArray = data.txt,
			  let cmdArray = data.cmd,
			  let valueArray = data.value,
			  let xtimeArray = data.xtime,
			  let intervalArray = data.interval else {
			return []
		}
		
		var legacyItems: [LegacyScheduleItem] = []
		
		for index in 0..<data.len {
			let txt = txtArray.indices.contains(index) ? txtArray[index] : ""
			
			// Check if this is a legacy schedule (doesn't match new format)
			// Exclude both new schedule format AND gap-filling commands
			if !txt.hasPrefix("schedule_") && !txt.hasPrefix("gap_") {
				let suggestedStartTime = Date(timeIntervalSince1970: TimeInterval(xtimeArray[index]))
				
				let legacyItem = LegacyScheduleItem(
					index: index,
					command: cmdArray[index],
					value: valueArray[index],
					xtime: xtimeArray[index],
					interval: intervalArray[index],
					suggestedStartTime: suggestedStartTime
				)
				
				legacyItems.append(legacyItem)
			}
		}
		
		return legacyItems
	}

	// MARK: - Delete Single Schedule
	func deleteSchedule(_ schedule: DailySchedule) async -> Bool {
		// Get existing non-gap schedules excluding the one to delete
		let remainingSchedules = parseExistingSchedules()
			.filter { !$0.isGapSchedule && $0.txtIdentifier != schedule.txtIdentifier }
		
		// Clear the queue and regenerate with remaining schedules
		let clearSuccess = await clearQueue()
		if !clearSuccess {
			return false
		}
		
		// If no remaining schedules, just clear and we're done
		if remainingSchedules.isEmpty {
			await fetchData() // Refresh to show empty state
			return true
		}
		
		// Generate all commands for remaining schedules
		let allCommands = generateAllCommands(for: remainingSchedules)
		
		// Add all commands
		for command in allCommands {
			let success = await addSingleCommand(command)
			if !success {
				return false
			}
		}
		
		await fetchData() // Refresh schedules
		return true
	}

	// MARK: - Legacy Command Operations
	private func addSingleCommand(_ command: SpaCommand) async -> Bool {
		do {
			var request = URLRequest(url: addCommandUrl)
			request.httpMethod = "POST"
			request.setValue("application/json", forHTTPHeaderField: "Content-Type")

			let json: [String: Any] = [
				"CMD": command.cmd,
				"VALUE": command.value,
				"XTIME": command.xtime,
				"INTERVAL": command.interval,
				"TXT": command.txt
			]

			request.httpBody = try JSONSerialization.data(withJSONObject: json)

			let (_, response) = try await URLSession.shared.data(for: request)
			
			guard let httpResponse = response as? HTTPURLResponse,
				  httpResponse.statusCode == 200 else {
				errorMessage = "Failed to add command"
				return false
			}

			return true

		} catch {
			errorMessage = "Failed to add command: \(error.localizedDescription)"
			return false
		}
	}

	// MARK: - Delete Command
	func deleteCommand(at index: Int) async -> Bool {
		isSaving = true
		errorMessage = nil

		do {
			var request = URLRequest(url: deleteCommandUrl)
			request.httpMethod = "POST"
			request.setValue("application/json", forHTTPHeaderField: "Content-Type")

			let json: [String: Any] = ["IDX": index]
			request.httpBody = try JSONSerialization.data(withJSONObject: json)

			let (_, response) = try await URLSession.shared.data(for: request)
			
			guard let httpResponse = response as? HTTPURLResponse,
				  httpResponse.statusCode == 200 else {
				errorMessage = "Failed to delete command"
				isSaving = false
				return false
			}

			await fetchData()
			isSaving = false
			return true

		} catch {
			errorMessage = "Failed to delete command: \(error.localizedDescription)"
			isSaving = false
			return false
		}
	}
	
	// MARK: - Delete Legacy Schedules
	func deleteLegacySchedules() async {
		isDeletingLegacy = true
		deletionProgress = 0
		
		while !legacySchedules.isEmpty {
			let currentLegacy = legacySchedules.first!
			
			let success = await deleteCommand(at: currentLegacy.index)
			if success {
				deletionProgress += 1
				await fetchData() // Refresh to get updated indices
			} else {
				errorMessage = "Failed to delete legacy schedule at index \(currentLegacy.index)"
				break
			}
		}
		isDeletingLegacy = false
	}

	// MARK: - Clear Queue
//	func clearQueue() async -> Bool {
//		let resetCommand = SpaCommand(
//			cmd: 5, // reset command queue command
//			value: 1,
//			xtime: 0,
//			interval: 0,
//			txt: ""
//		)
//		let success = await addSingleCommand(resetCommand)
//		return success
//	}
	func clearQueue() async -> Bool {
		let resetCommand = SpaCommand(
			cmd: 5,
			value: 1,
			xtime: 0,
			interval: 0,
			txt: ""
		)
		let success = await addSingleCommand(resetCommand)
		
		// Reset base date when clearing queue
		if success {
			scheduleBaseDate = nil
		}
		
		return success
	}
	
	func resetScheduleBaseDate() {
		scheduleBaseDate = nil
	}

	func refresh() {
		Task {
			await fetchData()
		}
	}

	func clearData() {
		data = nil
		errorMessage = nil
		legacySchedules = []
	}
}
