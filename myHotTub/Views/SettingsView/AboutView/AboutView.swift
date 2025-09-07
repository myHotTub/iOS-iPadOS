
import SwiftUI

struct AboutView: View {
	@Environment(ContentManager.self) var contentManager

	let appBuild: String   = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "Unknown"
	let appName: String    = Bundle.main.infoDictionary?["CFBundleDisplayName"] as? String ?? "Unknown"
	let appVersion: String = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "Unknown"

	var body: some View {
		NavigationStack {
			List {
				//MARK: Hero Section
				Section {
					VStack(spacing: 20) {
						Image(systemName: "figure.water.fitness")
							.font(.system(size: 80, weight: .light))
							.foregroundStyle(.blue)
							.symbolRenderingMode(.hierarchical)
						
						Text(appName)
							.font(.largeTitle)
							.fontWeight(.medium)
							.fontDesign(.rounded)
						
						Text("Take control of your Lay-Z-Spa Hot Tub from your \(UIDevice.current.model). Requires an ESP8266 module installation. Special thanks to visualapproach for the foundational work. \n[Learn more...](https://github.com/visualapproach/WiFi-remote-for-Bestway-Lay-Z-SPA)")
							.font(.subheadline)
							.foregroundStyle(.secondary)
							.multilineTextAlignment(.center)
							.fixedSize(horizontal: false, vertical: true)
					}
					.frame(maxWidth: .infinity)
				}
				.listRowBackground(Color.clear)
				.listRowSeparator(.hidden)
				
				//MARK: App Information Section
				Section("App Information") {
					LabeledContent("App Version", value: "\(appVersion) (\(appBuild))")
				}
				
				//MARK: ESP8266 Module Information Section
				Section("ESP8266 Module Information") {
					LabeledContent("Firmware Version", value: contentManager.other.fw ?? "Unknown")
				}
			}
			.navigationTitle("About")
			.navigationBarTitleDisplayMode(.inline)
			.listStyle(.insetGrouped)
		}
	}
}

#Preview {
	let contentManager = ContentManager()
	
	AboutView()
		.environment(contentManager)
}
