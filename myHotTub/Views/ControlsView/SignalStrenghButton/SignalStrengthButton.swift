
import SwiftUI

struct SignalStrengthButton: View {
	@Environment(ContentManager.self) var contentManager
	
	var signalStrength: (icon: String, variable: Double) {
		guard contentManager.connectionMonitor.isConnected else {
			return ("arrow.clockwise", 0)
		}
		
		switch (contentManager.other.rssi) {
		case ..<(79): return ("cellularbars", 0.25)
		case -80..<(-71): return ("cellularbars", 0.50)
		case -70..<(-61): return ("cellularbars", 0.75)
		case (-60)...: return ("cellularbars", 0.75)
		default: return ("arrow.clockwise", 0)
		}
	}
	
    var body: some View {
		Button {
			contentManager.refreshConnection()
		} label: {
			Image(systemName: signalStrength.icon, variableValue: signalStrength.variable)
				.animation(.easeInOut(duration: 0.3), value: signalStrength.variable)
		}
		.disabled(contentManager.connectionMonitor.isConnected)
    }
}

#Preview {
	let contentManager = ContentManager()
	
    SignalStrengthButton()
		.environment(contentManager)
}
