
import SwiftUI

struct SettingsView: View {
	@Environment(ContentManager.self) var contentManager
	
	@State private var showRestartAlert: Bool = false
	
    var body: some View {
		NavigationStack {
			List {
				Section(header: Text("App Settings")) {
					NavigationLink(destination: AboutView()) {
						Text("About")
					}
					NavigationLink(destination: AppearanceView()) {
						Text("Appearance")
					}
				}
				
//				Removed until the logic for reconnecting is more robust.
//				HStack {
//					Button("Restart ESP8266 Module", role: .destructive) {
//						showRestartAlert.toggle()
//						
//					}
//					.alert(isPresented: $showRestartAlert) {
//						Alert(
//							title: Text("Restart ESP8266 Module"),
//							message: Text("This will restart the ESP8266 Module. It may take a while for the ESP8266 module to reboot and reconnect to your Wi-Fi network."),
//							primaryButton: .destructive(Text("Restart")) {
//								contentManager.sendCommand(webSocketTask: contentManager.webSocketTask, cmd: "restartEsp")
//							},
//							secondaryButton: .cancel()
//						)
//					}
//					.buttonStyle(.automatic)
//				}
			}
			.navigationTitle("Settings")
		}
    }
}

#Preview {
	let contentManager = ContentManager()
	
    SettingsView()
		.environment(contentManager)
}
