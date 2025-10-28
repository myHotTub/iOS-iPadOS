
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
