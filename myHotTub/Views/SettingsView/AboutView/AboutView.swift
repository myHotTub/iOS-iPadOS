
import SwiftUI

struct AboutView: View {
	@Environment(ContentManager.self) var contentManager
	
	let appName: String    = (Bundle.main.infoDictionary?["CFBundleDisplayName"] as? String)!
	let appVersion: String = (Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String)!
	
    var body: some View {
		NavigationStack {
			List {
				Section {
					VStack(alignment: .center) {
						Image(systemName: "figure.water.fitness")
							.font(.system(size: 70))
							.frame(maxWidth: .infinity, alignment: .center)
							.padding(.top, 2)
							.padding(.bottom, 1)
						
						Text("\(appName)")
							.font(.title)
							.fontWeight(.bold)
							.padding(.bottom, 1)
							.frame(maxWidth: .infinity, alignment: .center)
						
						Text("Manage your Lay-Z-Spa Hot Tub installed with an ESP8266 from your \(UIDevice.current.model). This project was made possible due to the work by visualapproach. [Learn more...](https://github.com/visualapproach/WiFi-remote-for-Bestway-Lay-Z-SPA)")
							.multilineTextAlignment(.center)
							.frame(maxWidth: .infinity, alignment: .center)
					}
				}
				
				Section(header: Text("Application Information")) {
					HStack {
						Text("App Version")
						Spacer()
						Text("\(appVersion)")
					}
				}
				
				Section(header: Text("ESP8266 Module Information")) {
					HStack {
						Text("Firmware Version")
						Spacer()
						Text("\(contentManager.other.fw ?? "Unknown")")
					}
				}
			}
			.navigationTitle("About")
			.navigationBarTitleDisplayMode(.inline)
		}
    }
}

#Preview {
	let contentManager = ContentManager()
	
    AboutView()
		.environment(contentManager)
}
