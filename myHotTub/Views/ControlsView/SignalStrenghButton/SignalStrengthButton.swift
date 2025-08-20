
import SwiftUI

struct SignalStrengthButton: View {
	@Environment(ContentManager.self) var contentManager
	
	var signalStrength: (icon: String, variable: Double) {
		guard contentManager.connectionMonitor.isConnected else {
			return ("arrow.clockwise", 0)
		}
		
		switch contentManager.other.rssi {
		case ..<(-81):        return ("cellularbars", 0.25)  // Poor signal
		case -81..<(-71):     return ("cellularbars", 0.50)  // Fair signal
		case -71..<(-61):     return ("cellularbars", 0.75)  // Good signal
		case (-61)...:        return ("cellularbars", 1.0)   // Excellent signal
		default:              return ("arrow.clockwise", 0)
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
