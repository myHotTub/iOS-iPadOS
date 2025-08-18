
import SwiftUI

struct ConnectionUnavailableView: View {
	@Environment(ContentManager.self) var contentManager
	
	@State var connectionAttempt: Int
	
	var body: some View {
		GroupBox {
			HStack{
				Image(systemName: "wifi.exclamationmark")
									
				VStack(alignment: .leading) {
					Text("Unable to connect the the ESP8266 Module!")
					Text("Please confirm that the module is connected to your Wi-Fi network. Retry attempt number \(connectionAttempt).")
				}
				.font(.footnote)
			}
			.padding(.vertical, 8)
			.background(Color(.systemGray6))
			.cornerRadius(15)
		}
	}
}

#Preview {
	let contentManager = ContentManager()
	
	ConnectionUnavailableView(connectionAttempt: contentManager.connectionMonitor.connectionAttempt)
		.environment(contentManager)
}
