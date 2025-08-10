
import SwiftUI

struct PowerButton: View {
	@Environment(ContentManager.self) var contentManager
	
	var pumpState: (icon: String, description: String, color: Color, toggle: Bool) {
		guard contentManager.connectionMonitor.isConnected else {
			return ("lightswitch.off", "---", .gray, false)
		}
		
		switch (contentManager.states.flt) {
		case (0): return ("power.circle.fill", "Off", .red, true)
		case (1): return ("power.circle.fill", "On", .green, false)
		default: return ("power.circle.fill", "---", .yellow, false)
		}
	}
	
    var body: some View {
		Button {
			contentManager.sendCommand(webSocketTask: contentManager.webSocketTask, cmd: "togglePump", value: pumpState.toggle)
		} label: {
			Image(systemName: pumpState.icon)
				.foregroundStyle(pumpState.color)
		}
    }
}

#Preview {
	let contentManager = ContentManager()
	
    PowerButton()
		.environment(contentManager)
}
