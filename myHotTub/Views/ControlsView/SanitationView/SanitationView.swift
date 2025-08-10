
import SwiftUI

struct SanitationView: View {
	@Environment(ContentManager.self) var contentManager
	
	var chlorineTime: String {
		guard contentManager.connectionMonitor.isConnected else {
			return "---"
		}
		
		switch (contentManager.times.cltime) {
		case ..<(1): return "Today"
		case 1: return "Yesterday"
		case 1..<20000: return "\(contentManager.times.cltime) Days Ago"
		case (20000)...: return "Never"
		default: return "Unknown"
		}
	}
	
	var replaceTime: String {
		guard contentManager.connectionMonitor.isConnected else {
			return "---"
		}
		
		switch (contentManager.times.frep) {
		case ..<(1): return "Today"
		case 1: return "Yesterday"
		case 1..<20000: return "\(contentManager.times.frep) Days Ago"
		case (20000)...: return "Never"
		default: return "Unknown"
		}
	}
	
	var rinseTime: String {
		guard contentManager.connectionMonitor.isConnected else {
			return "---"
		}
		
		switch (contentManager.times.frin) {
		case ..<(1): return "Today"
		case 1: return "Yesterday"
		case 1..<20000: return "\(contentManager.times.frin) Days Ago"
		case (20000)...: return "Never"
		default: return "Unknown"
		}
	}

    var body: some View {
		Section(header: Text("Sanitation")) {
			HStack {
				Text("Chlorine Last Added:")
				Spacer()
				Text("\(chlorineTime)")
			}
			HStack {
				Text("Filter Last Changed:")
				Spacer()
				Text("\(replaceTime)")
			}
			HStack {
				Text("Filter Last Rinsed:")
				Spacer()
				Text("\(rinseTime)")
			}
		}
    }
}

#Preview {
	let contentManager = ContentManager()
	
    SanitationView()
		.environment(contentManager)
}
