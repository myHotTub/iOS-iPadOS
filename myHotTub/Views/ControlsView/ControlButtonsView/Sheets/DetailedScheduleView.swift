import SwiftUI

struct DetailedScheduleView: View {
	@Environment(\.dismiss) private var dismiss
	@Bindable var scheduleManager: ScheduleManager
	
	let schedule: DailySchedule
	
	@State private var startTime: Date
	@State private var endTime: Date
	@State private var heaterEnabled: Bool
	@State private var targetTemperature: Int
	@State private var filterEnabled: Bool
	@State private var showingSuccessAlert = false
	@State private var showingDeleteAlert = false
	@State private var conflictError: String?
	
	init(scheduleManager: ScheduleManager, schedule: DailySchedule) {
		self.scheduleManager = scheduleManager
		self.schedule = schedule
		
		// Initialize state with current schedule values
		_startTime = State(initialValue: schedule.startTime)
		_endTime = State(initialValue: schedule.endTime)
		_heaterEnabled = State(initialValue: schedule.heaterEnabled)
		_targetTemperature = State(initialValue: schedule.targetTemperature ?? 38)
		_filterEnabled = State(initialValue: schedule.filterEnabled)
	}
	
	private var isValidSchedule: Bool {
		startTime < endTime
	}
	
	private var hasAnyItemEnabled: Bool {
		heaterEnabled || filterEnabled
	}
	
	private var hasChanges: Bool {
		startTime != schedule.startTime ||
		endTime != schedule.endTime ||
		heaterEnabled != schedule.heaterEnabled ||
		targetTemperature != (schedule.targetTemperature ?? 38) ||
		filterEnabled != schedule.filterEnabled
	}

	var body: some View {
		NavigationView {
			VStack(spacing: 0) {
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
				
				// Delete button pinned to bottom
				VStack(spacing: 0) {
					Divider()
					
					Button("Delete Schedule") {
						showingDeleteAlert = true
					}
					.foregroundColor(.red)
					.fontWeight(.medium)
					.frame(maxWidth: .infinity)
					.padding(.vertical, 16)
					.background(Color(.systemGroupedBackground))
				}
			}
			.navigationTitle("Edit Schedule")
			.navigationBarTitleDisplayMode(.inline)
			.toolbar {
				ToolbarItem(placement: .cancellationAction) {
					Button("Cancel") {
						dismiss()
					}
				}
				
				ToolbarItem(placement: .confirmationAction) {
					Button("Save") {
						saveSchedule()
					}
					.disabled(scheduleManager.isSaving || !isValidSchedule || !hasAnyItemEnabled || conflictError != nil || !hasChanges)
				}
			}
		}
		.alert("Schedule Saved", isPresented: $showingSuccessAlert) {
			Button("OK") {
				dismiss()
			}
		} message: {
			Text("Your schedule has been updated successfully.")
		}
		.alert("Delete Schedule", isPresented: $showingDeleteAlert) {
			Button("Cancel", role: .cancel) { }
			Button("Delete", role: .destructive) {
				deleteSchedule()
			}
		} message: {
			Text("Are you sure you want to delete this schedule? This action cannot be undone.")
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
			order: schedule.order,
			startTime: startTime,
			endTime: endTime,
			heaterEnabled: heaterEnabled,
			targetTemperature: heaterEnabled ? targetTemperature : nil,
			filterEnabled: heaterEnabled ? false : filterEnabled,
			isGapSchedule: false
		)
		
		// Check conflicts against all schedules except the current one
		let otherSchedules = scheduleManager.parseExistingSchedules().filter { $0.order != schedule.order }
		let conflict = scheduleManager.checkForConflicts(tempSchedule)
		
		switch conflict {
		case .overlap(let conflictingSchedule, let conflictRange):
			// Only show conflict if it's with a different schedule
			if conflictingSchedule.order != schedule.order {
				conflictError = "Overlaps with Schedule \(conflictingSchedule.order + 1) (\(conflictRange))"
			} else {
				conflictError = nil
			}
		case .none:
			conflictError = nil
		}
	}
	
//	private func saveSchedule() {
//		Task {
//			// First delete the existing schedule
//			let deleteSuccess = await scheduleManager.deleteSchedule(schedule)
//			
//			if deleteSuccess {
//				// Then add the updated schedule
//				let updatedSchedule = DailySchedule(
//					order: schedule.order,
//					startTime: startTime,
//					endTime: endTime,
//					heaterEnabled: heaterEnabled,
//					targetTemperature: heaterEnabled ? targetTemperature : nil,
//					filterEnabled: heaterEnabled ? false : filterEnabled,
//					isGapSchedule: false
//				)
//				
//				let addSuccess = await scheduleManager.addSchedule(updatedSchedule)
//				
//				if addSuccess {
//					await scheduleManager.fetchData() // Refresh schedules
//					showingSuccessAlert = true
//				}
//			}
//		}
//	}
	private func saveSchedule() {
		Task {
			// First delete the existing schedule (whether gap or regular)
			let deleteSuccess = await scheduleManager.deleteSchedule(schedule)
			
			if deleteSuccess {
				// Then add the updated schedule as a regular (non-gap) schedule
				let updatedSchedule = DailySchedule(
					order: schedule.order,
					startTime: startTime,
					endTime: endTime,
					heaterEnabled: heaterEnabled,
					targetTemperature: heaterEnabled ? targetTemperature : nil,
					filterEnabled: heaterEnabled ? false : filterEnabled,
					isGapSchedule: false // Always create as regular schedule
				)
				
				let addSuccess = await scheduleManager.addSchedule(updatedSchedule)
				
				if addSuccess {
					await scheduleManager.fetchData() // Refresh schedules
					showingSuccessAlert = true
				}
			}
		}
	}
	
	private func deleteSchedule() {
		Task {
			let success = await scheduleManager.deleteSchedule(schedule)
			if success {
				dismiss()
			}
		}
	}
}

#Preview {
	let scheduleManager = ScheduleManager()
	let sampleSchedule = DailySchedule(
		order: 0,
		startTime: Calendar.current.date(bySettingHour: 18, minute: 0, second: 0, of: Date()) ?? Date(),
		endTime: Calendar.current.date(bySettingHour: 22, minute: 0, second: 0, of: Date()) ?? Date(),
		heaterEnabled: true,
		targetTemperature: 38,
		filterEnabled: false,
		isGapSchedule: false
	)
	
	DetailedScheduleView(scheduleManager: scheduleManager, schedule: sampleSchedule)
}
