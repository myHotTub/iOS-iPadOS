
import SwiftUI

struct AppearanceView: View {
	@AppStorage("onboardingComplete") private var onboardingComplete: Bool = false
	@AppStorage("onboardingCurrentPage") private var savedCurrentPage: Int = 1

	@Environment(ContentManager.self) var contentManager
	
	@State private var showRestartOnboardingAlert: Bool = false
	
	var availableUnits: [String] = ["Fahrenheit", "Celsius"]
	
	var selectedUnit: String {
		guard contentManager.connectionMonitor.isConnected else {
			return ""
		}
		
		switch contentManager.states.unt {
		case 0: return "Fahrenheit"
		case 1: return "Celsius"
		default: return "Fahrenheit"
		}
	}
	
	var body: some View {
		NavigationStack {
			List {
				Section {
					Picker("Temperature Unit", selection: Binding(
						get: { contentManager.states.unt ?? 0 },
						set: { newValue in
							contentManager.sendCommand(
								webSocketTask: contentManager.webSocketTask,
								cmd: "toggleUnit",
								value: newValue
							)
						}
					)) {
						ForEach(0..<availableUnits.count, id: \.self) { index in
							Text(availableUnits[index]).tag(index)
						}
					}
					.pickerStyle(.menu)
				}
				Section {
					HStack {
						Button("Restart Onboarding", role: .destructive) {
							showRestartOnboardingAlert = true
						}
						.alert("Restart Onboarding?",
							   isPresented: $showRestartOnboardingAlert) {
							Button("Yes", role: .destructive) {
								savedCurrentPage = 0
								
								onboardingComplete = false
							}
							Button("Cancel", role: .cancel) { }
						} message: {
							Text("This will restart the onboarding process. Some settings may be lost.")
						}
					}
				}
			}
			.navigationTitle("Appearance")
			.navigationBarTitleDisplayMode(.inline)
		}
	}
}

#Preview {
	let contentManager = ContentManager()
	
	AppearanceView()
		.environment(contentManager)
}
