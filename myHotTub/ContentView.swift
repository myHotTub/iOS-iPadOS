
import SwiftUI

struct ContentView: View {
	@Environment(ContentManager.self) var contentManager
	
    var body: some View {
		TabView {
			ControlsView()
				.tabItem {Label("Controls", systemImage: "switch.2")}
			SettingsView()
				.tabItem {Label("Settings", systemImage: "gear")}
		}
		.onAppear {
			contentManager.establishConnection()
		}
		.dynamicTypeSize(...DynamicTypeSize.xLarge)
	}
}


#Preview {
	let contentManager = ContentManager()
	
    ContentView()
		.environment(contentManager)
}
