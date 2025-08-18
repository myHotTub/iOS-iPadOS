
import SwiftUI

@main
struct myHotTubApp: App {
	let contentManager    = ContentManager()
	let connectionManager = ConnectionManager()
	
    var body: some Scene {
        WindowGroup {
            ContentView()
				.environment(contentManager)
				.environment(connectionManager)
        }
    }
}
