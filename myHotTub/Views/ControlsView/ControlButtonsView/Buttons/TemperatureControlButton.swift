
import SwiftUI

struct TemperatureControlButton: View {
	@Environment(ContentManager.self) var contentManager
	
	var heaterState: (icon: String, description: String, color: Color) {
		guard contentManager.connectionMonitor.isConnected else {
			return ("antenna.radiowaves.left.and.right.slash", "---", .gray)
		}
	
		switch (contentManager.states.pwr, contentManager.states.flt, contentManager.states.grn, contentManager.states.red) {
		case (0, _, _, _): return ("power", "OFF", .gray)
		case (1, 0, _, _): return ("power", "Filter Off", .gray)
		case (1, 1, 0, 0): return ("arrow.trianglehead.2.counterclockwise", "Filter On", .blue)
		case (1, 1, 1, 0): return ("heat.waves", "Heating - Inactive", .green)
		case (1, 1, 0, 1): return ("heat.waves", "Heating - Active", .orange)
		default: return ("exclamationmark.circle", "---", .gray)
		}
	}
	
	var waterTemperature: (current: Int, target: Int) {
		guard contentManager.connectionMonitor.isConnected else {
			return (0, 0)
		}
		
		switch (contentManager.states.unt) {
		case (0): return (contentManager.states.tmpf, contentManager.states.tgtf)
		case (1): return (contentManager.states.tmpc, contentManager.states.tgtc)
		default: return (contentManager.states.tmp, contentManager.states.tgt)
		}
	}
	
	@State var showTemperatureControlSheet: Bool = false
			
    var body: some View {
		Button {
			showTemperatureControlSheet.toggle()
		} label: {
			ZStack {
				RoundedRectangle(cornerRadius: 15)
					.aspectRatio(1, contentMode: .fit)
					.foregroundStyle(heaterState.color)
				
				.overlay(alignment: .topTrailing) {
					Image(systemName: heaterState.icon)
						.font(.largeTitle)
						.foregroundStyle(Color.white)
						.scaleEffect(1.2, anchor: .topTrailing)
						.padding(.all, 10)
				}
				
				.overlay(alignment: .bottomLeading) {
					VStack(alignment: .leading) {
						Text("\(waterTemperature.current)°")
							.font(.largeTitle)
							.fontWeight(.medium)
							.scaleEffect(1.8, anchor: .leading)
							.foregroundStyle(Color.white)
							.padding(.bottom, 10)
						
						Group {
							Text("Set to ") +
							Text("\(waterTemperature.target)°")
								.fontWeight(.bold)
						}
						.font(.subheadline)
						.foregroundStyle(Color.white)
						
						Text("\(heaterState.description)")
							.font(.subheadline)
							.foregroundStyle(Color.white)
					}
					.padding(.all, 10)
				}
			}
		}
		.buttonStyle(.plain)
		.contentShape(Rectangle())
		.clipShape(RoundedRectangle(cornerRadius: 15))
		.sheet(isPresented: $showTemperatureControlSheet) {
			TemperatureControlSheet()
		}
	}
}

#Preview {
	let contentManager = ContentManager()
	
	TemperatureControlButton()
		.environment(contentManager)
}
