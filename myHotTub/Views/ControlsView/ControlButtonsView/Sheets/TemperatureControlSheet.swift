
import SwiftUI

struct TemperatureControlSheet: View {
	@Environment(ContentManager.self) var contentManager
	@Environment(\.dismiss) private var dismiss
	
	var heaterState: (icon: String, description: String, color: Color, ready: String) {
		guard contentManager.connectionMonitor.isConnected else {
			return ("antenna.radiowaves.left.and.right.slash", "--", .gray, "Not Connected")
		}
	
		switch (contentManager.states.pwr, contentManager.states.flt, contentManager.states.grn, contentManager.states.red) {
		case (0, _, _, _): return ("power", "OFF", .gray, "Enable heater to view the ready in estimate")
		case (1, 0, _, _): return ("power", "Filter Off", .gray, "Enable heater to view the ready in estimate")
		case (1, 1, 0, 0):
			if (contentManager.states.tmp < contentManager.states.tgt) {
				return ("arrow.trianglehead.2.counterclockwise", "Filter On", .blue, "Enable heater to view the ready in estimate")
			} else {
				return ("arrow.trianglehead.2.counterclockwise", "Filter On", .blue, "Now")
			}
		case (1, 1, 1, 0): return ("heat.waves", "Heating - Inactive", .green, "Now")
		case (1, 1, 0, 1): return ("heat.waves", "Heating - Active", .orange, "\(contentManager.times.t2r)")
		default: return ("exclamationmark.circle", "---", .gray, "Unknown")
		}
	}
	
	var temperature: (water: Int, ambient: Int) {
		guard contentManager.connectionMonitor.isConnected else {
			return (0, 0)
		}
		
		switch (contentManager.states.unt) {
		case (0): return (contentManager.states.tmpf, contentManager.states.ambf)
		case (1): return (contentManager.states.tmpc, contentManager.states.ambc)
		default: return (contentManager.states.tmp, contentManager.states.amb)
		}
	}
	
    var body: some View {
		NavigationStack {
			VStack {
				HStack {
					Group {
						Text("Temperature ") +
						Text("\(temperature.water)°")
							.fontWeight(.bold)
					}
					
					Group {
						Text("Ambient ") +
						Text("\(temperature.ambient)°")
							.fontWeight(.bold)
					}
				}
				.foregroundColor(.white)
				
				HStack {
					Text("\(heaterState.description)")
				}
				.font(.largeTitle)
				.foregroundColor(.white)
				
				TemperatureControlSlider()
				
				Spacer()
				
				Text("Ready In: \(heaterState.ready)")
					.foregroundColor(.white)
					.multilineTextAlignment(.center)
					.frame(maxWidth: .infinity, alignment: .center)
					.padding(.all, 20)
			}
			.frame(maxWidth: .infinity, maxHeight: .infinity)
			.toolbar {
				ToolbarItemGroup(placement: .cancellationAction) {
					Button {
						dismiss()
					} label: {
						Image(systemName: "xmark")
							.fontWeight(.medium)
							.foregroundColor(.white)
					}
				}
				ToolbarItem(placement: .principal) {
					Text("Hot Tub")
						.foregroundColor(.white)
				}
			}
			.background(
				LinearGradient(
					gradient: Gradient(colors: [
						heaterState.color.opacity(0.9),
						heaterState.color
					]),
					startPoint: .top,
					endPoint: .bottom
				)
			)
		}
		
    }
}

#Preview {
	let contentManager = ContentManager()
	
    TemperatureControlSheet()
		.environment(contentManager)
}
