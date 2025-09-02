
import SwiftUI

struct AddScheduleView: View {
	@Environment(\.dismiss) private var dismiss
	@Bindable var scheduleManager: ScheduleManager
	
	@State private var startTime: Date
	@State private var endTime: Date
	@State private var heaterEnabled = false
	@State private var targetTemperature = 38
	@State private var filterEnabled = false
	@State private var showingSuccessAlert = false
	@State private var conflictError: String?

	
	init(scheduleManager: ScheduleManager) {
		self.scheduleManager = scheduleManager
		
		// Initialise with smart default times
		let defaultStartTime = scheduleManager.getNextAvailableStartTime()
		let defaultEndTime = Calendar.current.date(byAdding: .hour, value: 1, to: defaultStartTime) ?? defaultStartTime
		
		_startTime = State(initialValue: defaultStartTime)
		_endTime = State(initialValue: defaultEndTime)
	}
	
	private var isValidSchedule: Bool {
		startTime < endTime
	}
	
	private var hasAnyItemEnabled: Bool {
		heaterEnabled || filterEnabled
	}

	
	var body: some View {
		NavigationView {
			Form {
				Section("Times") {
					DatePicker("Start", selection: $startTime, displayedComponents: [.hourAndMinute])
						.onChange(of: startTime) { _, newValue in
							// Auto-adjust end time if needed
							if newValue >= endTime {
								endTime = Calendar.current.date(byAdding: .hour, value: 1, to: newValue) ?? endTime
							}
							checkForConflicts()
						}
					
					DatePicker("End", selection: $endTime, displayedComponents: [.hourAndMinute])
						.onChange(of: endTime) { _, _ in
							checkForConflicts()
						}
					
					if !isValidSchedule {
						Label("End time must be after start time", systemImage: "exclamationmark.triangle")
							.foregroundColor(.orange)
							.font(.caption)
					}
				}
				
				Section("Schedule Items") {
					Toggle("Heater", isOn: $heaterEnabled)
						.onChange(of: heaterEnabled) { _, newValue in
							if !newValue {
								// If heater is disabled, user can control filter
								// Keep current filter state
							} else {
								// If heater is enabled, filter is auto-controlled by hardware
								// Hide filter toggle since it's automatic
							}
							checkForConflicts()
						}
					
					if heaterEnabled {
						HStack {
							Text("Target Temperature")
							Spacer()
							Stepper("\(targetTemperature)°C", value: $targetTemperature, in: 20...40)
						}
						
						HStack {
							Text("Filter")
							Spacer()
							Text("Auto ON")
								.foregroundColor(.secondary)
								.italic()
						}
					} else {
						Toggle("Filter", isOn: $filterEnabled)
							.onChange(of: filterEnabled) { _, _ in
								checkForConflicts()
							}
					}
					
					if !hasAnyItemEnabled {
						Label("Select at least one item to schedule", systemImage: "info.circle")
							.foregroundColor(.blue)
							.font(.caption)
					}
				}
				
				if let conflictError = conflictError {
					Section("Schedule Conflict") {
						Label(conflictError, systemImage: "exclamationmark.triangle.fill")
							.foregroundColor(.red)
							.font(.callout)
					}
				}
				
				Section("Preview") {
					VStack(alignment: .leading, spacing: 8) {
						HStack {
							Text("Active Period:")
							Spacer()
							Text(timeRangePreview)
								.fontWeight(.medium)
								.foregroundColor(.blue)
						}
						
						VStack(alignment: .leading, spacing: 4) {
							HStack {
								Text("Items:")
								Spacer()
								Text(itemsPreview)
									.foregroundColor(.secondary)
							}
						}
					}
				}
			}
			.navigationTitle("Add Schedule")
			.navigationBarTitleDisplayMode(.inline)
			.toolbar {
				ToolbarItem(placement: .cancellationAction) {
					Button("Cancel") {
						dismiss()
					}
				}
				
				ToolbarItem(placement: .confirmationAction) {
					Button("Add") {
						addSchedule()
					}
					.disabled(scheduleManager.isSaving || !isValidSchedule || !hasAnyItemEnabled || conflictError != nil)
				}
			}
		}
		.alert("Schedule Added", isPresented: $showingSuccessAlert) {
			Button("OK") {
				dismiss()
			}
		} message: {
			Text("Your schedule has been added successfully.")
		}
		.onAppear {
			checkForConflicts()
		}
	}
	
	private var timeRangePreview: String {
		let formatter = DateFormatter()
		formatter.timeStyle = .short
		return "\(formatter.string(from: startTime)) - \(formatter.string(from: endTime))"
	}
	
	private var itemsPreview: String {
		var items: [String] = []
		
		if heaterEnabled {
			items.append("Heater ON")
			items.append("Filter ON (auto)")
			items.append("Target: \(targetTemperature)°C")
		} else if filterEnabled {
			items.append("Filter ON")
		}
		
		if items.isEmpty {
			return "None selected"
		}
		
		return items.joined(separator: ", ")
	}
	
	private func checkForConflicts() {
		guard isValidSchedule && hasAnyItemEnabled else {
			conflictError = nil
			return
		}
		
		// Create temporary schedule to check conflicts
		let tempSchedule = DailySchedule(
			order: 0, // Temporary order
			startTime: startTime,
			endTime: endTime,
			heaterEnabled: heaterEnabled,
			targetTemperature: heaterEnabled ? targetTemperature : nil,
			filterEnabled: heaterEnabled ? false : filterEnabled, // Filter auto-enabled with heater
			isGapSchedule: false
		)
		
		let conflict = scheduleManager.checkForConflicts(tempSchedule)
		
		switch conflict {
		case .overlap(let conflictingSchedule, let conflictRange):
			conflictError = "Overlaps with Schedule \(conflictingSchedule.order + 1) (\(conflictRange))"
		case .none:
			conflictError = nil
		}
	}
	
	private func addSchedule() {
		Task {
			// Get current non-gap schedules to determine order
			let existingSchedules = scheduleManager.parseExistingSchedules().filter { !$0.isGapSchedule }
			let newOrder = existingSchedules.count
			
			let schedule = DailySchedule(
				order: newOrder,
				startTime: startTime,
				endTime: endTime,
				heaterEnabled: heaterEnabled,
				targetTemperature: heaterEnabled ? targetTemperature : nil,
				filterEnabled: heaterEnabled ? false : filterEnabled, // Filter controlled by hardware when heater on
				isGapSchedule: false
			)
			
			let success = await scheduleManager.addSchedule(schedule)
			
			if success {
				await scheduleManager.fetchData() // Refresh to show new schedule
				showingSuccessAlert = true
			}
		}
	}
}


#Preview {
	AddScheduleView(scheduleManager: ScheduleManager())
}
