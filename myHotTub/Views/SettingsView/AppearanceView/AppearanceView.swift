
import SwiftUI

struct AppearanceView: View {
	@AppStorage("appearanceMode") private var appearanceMode: AppearanceMode = .system
	
	@Environment(ContentManager.self) var contentManager
	
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
					Picker("Appearance", selection: $appearanceMode) {
						ForEach (AppearanceMode.allCases) { mode in
							Text(mode.rawValue).tag(mode)
						}
					}
					.pickerStyle(.menu)
					
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
