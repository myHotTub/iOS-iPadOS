
import SwiftUI

struct BubbleControlButton: View {
	@Environment(ContentManager.self) var contentManager
	
	var bubblesState: (icon: String, description: String, color: Color, toggle: Bool) {
		guard contentManager.connectionMonitor.isConnected else {
			return ("lightswitch.off", "---", .gray, false)
		}
		
		switch (contentManager.states.air) {
		case (0): return ("lightswitch.off", "Off", .gray, true)
		case (1): return ("lightswitch.on", "On", .green, false)
		default: return ("lightswitch.off", "---", .gray, false)
		}
	}
	
    var body: some View {
		Button {
			contentManager.sendCommand(webSocketTask: contentManager.webSocketTask, cmd: "toggleBubbles", value: bubblesState.toggle)
		} label: {
			RoundedRectangle(cornerRadius: 15)
				.aspectRatio(2.1, contentMode: .fit)
				.foregroundStyle(bubblesState.color)
			
			.overlay(alignment: .leading) {
				HStack {
					Image(systemName: bubblesState.icon)
						.font(.custom("System", size: 30, relativeTo: .largeTitle))
						.foregroundStyle(Color.white)
						.padding(.leading, 20)
					
					VStack(alignment: .leading) {
						Text("Bubbles")
							.font(.custom("System", size: 15, relativeTo: .title))
							.fontWeight(.heavy)
							.foregroundStyle(Color.white)
						
						Text("\(bubblesState.description)")
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
	
    BubbleControlButton()
		.environment(contentManager)
}
