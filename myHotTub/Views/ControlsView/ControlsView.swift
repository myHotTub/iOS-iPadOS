
import SwiftUI
import WhatsNewKit

struct ControlsView: View {
	@Environment(ContentManager.self) var contentManager
	
	var body: some View {
		NavigationStack {
			if !contentManager.connectionMonitor.isConnected && contentManager.connectionMonitor.connectionAttempt >= 3 {
//				ConnectionUnavailableView(connectionAttempt: contentManager.connectionMonitor.connectionAttempt)
				VStack(spacing: 20) {
							Image(systemName: "wifi.exclamationmark")
								.font(.system(size: 48))
								.foregroundColor(.red)
							
							Text("Connection Unavailable")
								.font(.title2)
								.fontWeight(.semibold)
							
							Text("We couldn’t connect to your ESP8266 module. Please check your Wi-Fi setup and ensure the module is powered on.")
								.font(.body)
								.foregroundColor(.secondary)
								.multilineTextAlignment(.center)
								.padding(.horizontal)
							
							Text("Retry attempt: \(contentManager.connectionMonitor.connectionAttempt)")
								.font(.footnote)
								.foregroundColor(.gray)
							
							Button("Retry") {
								contentManager.refreshConnection()
							}
							.buttonStyle(.borderedProminent)
						}
						.frame(maxWidth: .infinity, maxHeight: .infinity)
						.background(Color(.systemBackground))
						.navigationTitle("Connection Error")
						.navigationBarTitleDisplayMode(.inline)
				
			} else {
				GeometryReader { geometry in
					List {
						ControlButtonsView(availableSize: geometry.size)
						ReadyInList()
						SanitationView()
					}
					.navigationTitle("Controls")
					.navigationBarTitleDisplayMode(.automatic)
					.toolbar {
						ToolbarItem(placement: .topBarLeading) {
							SignalStrengthButton()
						}
					}
					.refreshable {
						contentManager.refreshConnection()
						try? await Task.sleep(for: .seconds(0.5))
					}
				}
			}

		}
		.whatsNewSheet()
	}
}

#Preview {
	let contentManager = ContentManager()
	
    ControlsView()
		.environment(contentManager)
}
