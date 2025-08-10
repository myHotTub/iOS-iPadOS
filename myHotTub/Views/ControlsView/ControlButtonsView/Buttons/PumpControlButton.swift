
import SwiftUI

struct PumpControlButton: View {
	@Environment(ContentManager.self) var contentManager
	
	var pumpState: (icon: String, description: String, color: Color, toggle: Bool) {
		guard contentManager.connectionMonitor.isConnected else {
			return ("lightswitch.off", "---", .gray, false)
		}
		
		switch (contentManager.states.flt) {
		case (0): return ("lightswitch.off", "Off", .gray, true)
		case (1): return ("lightswitch.on", "On", .blue, false)
		default: return ("lightswitch.off", "---", .gray, false)
		}
	}
	
    var body: some View {
		Button {
			contentManager.sendCommand(webSocketTask: contentManager.webSocketTask, cmd: "togglePump", value: pumpState.toggle)
		} label: {
			RoundedRectangle(cornerRadius: 15)
				.aspectRatio(2.1, contentMode: .fit)
				.foregroundStyle(pumpState.color)
			
			.overlay(alignment: .leading) {
				HStack {
					Image(systemName: pumpState.icon)
						.font(.custom("System", size: 30, relativeTo: .largeTitle))
						.foregroundStyle(Color.white)
						.padding(.leading, 20)
					
					VStack(alignment: .leading) {
						Text("Pump")
							.font(.custom("System", size: 15, relativeTo: .title))
							.fontWeight(.heavy)
							.foregroundStyle(Color.white)
						
						Text("\(pumpState.description)")
							.font(.custom("System", size: 15, relativeTo: .footnote))
							.foregroundStyle(Color.white)
					}
				}
			}
		}
		.buttonStyle(.plain)
		.contentShape(Rectangle())
		.clipShape(RoundedRectangle(cornerRadius: 15))
    }
}

#Preview {
	let contentManager = ContentManager()
	
    PumpControlButton()
		.environment(contentManager)
}
