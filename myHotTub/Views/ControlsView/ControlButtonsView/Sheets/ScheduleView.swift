import SwiftUI

struct ScheduleView: View {
	@Environment(\.dismiss) private var dismiss
	
	@State private var scheduleManager    = ScheduleManager()
	@State private var showingAddSchedule = false
	@State private var showingClearAlert  = false
	@State private var selectedSchedule: DailySchedule?
	
	private var hasLegacySchedules: Bool {
		!scheduleManager.legacySchedules.isEmpty
	}
	
	private var currentSchedules: [DailySchedule] {
		scheduleManager.parseExistingSchedules().sorted { $0.startTime < $1.startTime }
	}
	
	// Filter schedules for display (exclude gap schedules if there are non-gap schedules)
	private var displayedSchedules: [DailySchedule] {
		let nonGapSchedules = currentSchedules.filter { !$0.isGapSchedule }
		if nonGapSchedules.isEmpty {
			// Show all schedules including gaps if no regular schedules exist
			return currentSchedules
		} else {
			// Show all schedules (gaps will be displayed alongside regular ones)
			return currentSchedules
		}
	}
	
	var body: some View {
		NavigationView {
			VStack(spacing: 0) {
				// MARK: Legacy Warning Banner
				if hasLegacySchedules {
					LegacyWarningBanner(
						legacyCount: scheduleManager.legacySchedules.count,
						onClear: { showingClearAlert = true }
					)
					
					if scheduleManager.isDeletingLegacy {
						VStack(spacing: 8) {
							ProgressView("Deleting \(scheduleManager.deletionProgress) of \(scheduleManager.legacySchedules.count + scheduleManager.deletionProgress)...")
								.progressViewStyle(.linear)
							Text("Please wait while legacy schedules are removed.")
								.font(.caption)
								.foregroundColor(.secondary)
						}
					}
				}
				
				// MARK: Main Content
				// MARK: Loading Schedules View
				if scheduleManager.isLoading {
					Spacer()
					ProgressView("Loading schedules...")
						.padding()
					Spacer()
				// MARK: Error Loading Schedules View
				} else if let errorMessage = scheduleManager.errorMessage, scheduleManager.data == nil {
					Spacer()
					VStack(spacing: 16) {
						Image(systemName: "exclamationmark.triangle")
							.foregroundColor(.orange)
							.font(.largeTitle)
						
						Text("Error")
							.font(.headline)
						
						Text(errorMessage)
							.foregroundColor(.secondary)
							.multilineTextAlignment(.center)
							.padding(.horizontal)
						
						Button("Refresh") {
							scheduleManager.refresh()
						}
						.buttonStyle(.borderedProminent)
					}
					.padding()
					Spacer()
				// MARK: Add Schedules View
				} else if displayedSchedules.isEmpty && !hasLegacySchedules {
					Spacer()
					VStack(spacing: 16) {
						Image(systemName: "calendar.badge.plus")
							.foregroundColor(.blue)
							.font(.largeTitle)
						
						Text("No schedules yet.")
							.font(.headline)
						
						Text("Add a schedule to keep your Hot Tub warm and ready when you are.")
							.foregroundColor(.secondary)
							.multilineTextAlignment(.center)
							.padding(.horizontal)
						
						Button("Add Schedule") {
							showingAddSchedule = true
						}
						.buttonStyle(.borderedProminent)
					}
					.padding()
					Spacer()
				// MARK: Schedules View
				} else {
					ScrollView {
						LazyVStack(spacing: 8) {
							if !displayedSchedules.isEmpty {
								ForEach(displayedSchedules) { schedule in
									DailyScheduleCard(
										schedule: schedule,
										onDelete: { deleteSchedule(schedule) },
										onTap: { selectedSchedule = schedule }
									)
								}
								.padding(.horizontal)
							}
						}
						.animation(.default, value: displayedSchedules.count)
					}
				}
			}
			.navigationTitle("Schedule")
			.toolbar {
				ToolbarItem(placement: .cancellationAction) {
					Button {
						dismiss()
					} label: {
						Image(systemName: "xmark")
							.fontWeight(.medium)
							.foregroundColor(.blue)
					}
				}
				
				ToolbarItemGroup(placement: .primaryAction) {
					Button {
						scheduleManager.refresh()
					} label: {
						Image(systemName: "arrow.clockwise")
							.fontWeight(.medium)
					}
					
					if !hasLegacySchedules {
						Button {
							showingAddSchedule = true
						} label: {
							Image(systemName: "plus")
								.fontWeight(.medium)
						}
					}
				}
			}
			.disabled(scheduleManager.isLoading)
		}
		.sheet(isPresented: $showingAddSchedule) {
			AddScheduleView(scheduleManager: scheduleManager)
		}
		.sheet(item: $selectedSchedule) { schedule in
			DetailedScheduleView(scheduleManager: scheduleManager, schedule: schedule)
		}
		.alert("Clear Legacy Schedules", isPresented: $showingClearAlert) {
			Button("Cancel", role: .cancel) { }
			Button("Clear All", role: .destructive) {
				Task {
					await scheduleManager.deleteLegacySchedules()
				}
			}
		} message: {
			Text("This will delete all legacy schedules. Schedules created by myHotTub will remain intact. This action cannot be undone.")
		}
		.task {
			await scheduleManager.fetchData()
		}
	}
	
	private func deleteSchedule(_ schedule: DailySchedule) {
		Task {
			let success = await scheduleManager.deleteSchedule(schedule)
			if success {
				await scheduleManager.fetchData()
			}
		}
	}
}

// MARK: Legacy Warning Banner
struct LegacyWarningBanner: View {
	@State private var scheduleManager = ScheduleManager()
	
	let legacyCount: Int
	let onClear: () -> Void
	
	var body: some View {
		VStack(spacing: 12) {
			HStack {
				Image(systemName: "exclamationmark.triangle.fill")
					.foregroundColor(.orange)
					.padding(.trailing, 10)
				
				VStack(alignment: .leading, spacing: 4) {
					Text("Legacy Schedules Detected")
						.fontWeight(.semibold)
					
					Text("\(legacyCount) legacy schedule\(legacyCount == 1 ? "" : "s") created outside of myHotTub \(legacyCount == 1 ? "was" : "were") found. \(legacyCount == 1 ? "This schedule" : "These schedules") must be removed before you can create schedules using myHotTub.")
						.font(.caption)
						.foregroundColor(.secondary)
				}
				Spacer()
			}
			
			VStack(spacing: 12) {
				Button("Clear All Legacy Schedules") {
					onClear()
				}
				.buttonStyle(.bordered)
				.controlSize(.small)
				.foregroundColor(.red)
				.disabled(scheduleManager.isDeletingLegacy)
			}
		}
		.padding()
		.background(Color.orange.opacity(0.1))
		.overlay(
			Rectangle()
				.fill(Color.orange.opacity(0.3))
				.frame(height: 1),
			alignment: .bottom
		)
	}
}

// MARK: Daily Schedule Card
struct DailyScheduleCard: View {
	let schedule: DailySchedule
	let onDelete: () -> Void
	let onTap: () -> Void
	
	private var timeFormatter: DateFormatter {
		let formatter = DateFormatter()
		formatter.timeStyle = .short
		return formatter
	}
	
	private var cardBackground: Color {
		if schedule.isGapSchedule {
			return Color.gray.opacity(0.15)
		} else if schedule.heaterEnabled {
			return Color.orange.opacity(0.2)
		} else if schedule.filterEnabled {
			return Color.blue.opacity(0.2)
		} else {
			return Color.gray.opacity(0.2)
		}
	}
		
	@ViewBuilder
	private var actionIndicator: some View {
		let labelFont = Font.caption
		let badgeHeight: CGFloat = 22
		
		if schedule.isGapSchedule {
			HStack(spacing: 4) {
				Text("All OFF")
			}
			.font(labelFont)
			.fontWeight(.medium)
			.foregroundColor(.white)
			.frame(height: badgeHeight)
			.padding(.horizontal, 6)
			.background(Color.gray)
			.cornerRadius(4)
			
		} else if schedule.heaterEnabled {
			HStack(spacing: 6) {
				HStack(spacing: 4) {
					Image(systemName: "flame.fill")
					Text("Heat On")
				}
				.font(labelFont)
				.fontWeight(.medium)
				.foregroundColor(.white)
				.frame(height: badgeHeight)
				.padding(.horizontal, 6)
				.background(Color.orange)
				.cornerRadius(4)
				
				if let temp = schedule.targetTemperature {
					Text("\(temp)°C")
						.font(labelFont)
						.fontWeight(.medium)
						.foregroundColor(.white)
						.frame(height: badgeHeight)
						.padding(.horizontal, 6)
						.background(Color.orange)
						.cornerRadius(4)
						.monospacedDigit()
				}
			}
			
		} else if schedule.filterEnabled {
			HStack(spacing: 4) {
				Image(systemName: "drop.fill")
				Text("Filter On")
			}
			.font(labelFont)
			.fontWeight(.medium)
			.foregroundColor(.white)
			.frame(height: badgeHeight)
			.padding(.horizontal, 6)
			.background(Color.blue)
			.cornerRadius(4)
			
		} else {
			HStack(spacing: 4) {
				Text("OFF")
			}
			.font(labelFont)
			.fontWeight(.medium)
			.foregroundColor(.white)
			.frame(height: badgeHeight)
			.padding(.horizontal, 6)
			.background(Color.gray)
			.cornerRadius(4)
		}
	}

	var body: some View {
		Button(action: onTap) {
			HStack(alignment: .center) {
				VStack(alignment: .leading, spacing: 6) {
					HStack(spacing: 8) {
						Text("\(timeFormatter.string(from: schedule.startTime)) - \(timeFormatter.string(from: schedule.endTime))")
							.font(.headline)
							.fontWeight(.semibold)
					}
					
					HStack(alignment: .center) {
						actionIndicator
						Spacer(minLength: 0)
					}
				}
				
				Spacer()
				
				Image(systemName: "chevron.right")
					.foregroundColor(.secondary)
					.font(.system(size: 14, weight: .medium))
			}
			.padding(14)
			.background(cardBackground)
			.cornerRadius(12)
			.shadow(color: .black.opacity(0.05), radius: 2, x: 0, y: 1)
		}
		.buttonStyle(.plain)
		.contextMenu {
			// Only allow deletion of non-gap schedules
			if !schedule.isGapSchedule {
				Button("Delete Schedule", role: .destructive) {
					onDelete()
				}
			}
		}
		.onAppear{
			print("Schedule: \(schedule)")
		}
	}
}

#Preview {
	ScheduleView()
}
