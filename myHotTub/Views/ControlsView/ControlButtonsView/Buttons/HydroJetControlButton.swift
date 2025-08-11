
import SwiftUI

struct HydroJetControlButton: View {
	@Environment(ContentManager.self) var contentManager
	
	var hydroJetsState: (icon: String, description: String, color: Color, toggle: Bool) {
		guard contentManager.connectionMonitor.isConnected else {
			return ("lightswitch.off", "---", .gray, false)
		}
		
		switch (contentManager.states.hjt) {
		case (0): return ("lightswitch.off", "Off", .gray, true)
		case (1): return ("lightswitch.on", "On", .green, false)
		default: return ("lightswitch.off", "---", .gray, false)
		}
	}
	
    var body: some View {
		Button {
			contentManager.sendCommand(webSocketTask: contentManager.webSocketTask, cmd: "toggleHydroJets", value: hydroJetsState.toggle)
		} label: {
			RoundedRectangle(cornerRadius: 15)
				.aspectRatio(1, contentMode: .fit)
				.foregroundStyle(hydroJetsState.color)
			
				.overlay(alignment: .center) {
				VStack {
					Image(systemName: hydroJetsState.icon)
						.font(.custom("System", size: 30, relativeTo: .largeTitle))
						.foregroundStyle(Color.white)
						.rotationEffect(.degrees(90))
						.frame(maxWidth: .infinity)
					
					VStack(alignment: .leading) {
						Text("HydroJets")
							.font(.custom("System", size: 15, relativeTo: .title))
							.fontWeight(.heavy)
							.foregroundStyle(Color.white)
						
						Text("\(hydroJetsState.description)")
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
	
	HydroJetControlButton()
		.environment(contentManager)
}
