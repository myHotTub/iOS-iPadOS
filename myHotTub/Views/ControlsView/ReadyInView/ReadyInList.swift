
import SwiftUI

struct ReadyInList: View {
	@Environment(ContentManager.self) var contentManager
	
	var readyIn: String {
		guard contentManager.connectionMonitor.isConnected else {
			return "---"
		}
				
		switch (contentManager.times.rs) {
		case "Ready": return "Now"
		case "Not Ready": return contentManager.times.t2r
		case "Never": switch (contentManager.states.grn, contentManager.states.red) {
//		case (0, 0): return "Enable Heater to View"
		case (0, 0):
			if (contentManager.states.tmp < contentManager.states.tgt) {
				return ("Enable heater to view")
			} else {
				return ("Now")
			}
		case (1, 0): return "Now"
		case (1, 1): return "contentManager.times.t2r"
		default: return "---"
		}
		default: return "---"
		}
	}
	
    var body: some View {
		Section {
			HStack {
				Text("Ready In: ")
				Spacer()
				Text("\(readyIn)")
			}
		}
    }
}

#Preview {
	let contentManager = ContentManager()
	
    ReadyInList()
		.environment(contentManager)
}
