
import SwiftUI

struct SettingsView: View {
    var body: some View {
		NavigationStack {
			List {
				Section(header: Text("App Settings")) {
					NavigationLink(destination: AboutView()) {
						Text("About")
					}
				}
				Section(header: Text("Appearance")) {
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
    SettingsView()
}
