
import SwiftUI
import LiteSlider

struct TemperatureControlSlider: View {
	@Environment(ContentManager.self) var contentManager
	
	@State private var sliderValue: Double = 30.0
	@State private var isDragging: Bool    = false
	
	var body: some View {
		let thumbView: (Bool) -> some View = { isDragging in
			Text("\(Int(sliderValue))°")
				.font(.system(size: isDragging ? 40 : 32))
				.padding([.vertical], 30)
				.foregroundStyle(.black)
		}
		
		LiteSlider(
			value: $sliderValue,
			in: 20...40,
			step: 1,
			thumbView: thumbView
		)
		.sliderTrackColor(.gray.opacity(0.5))
		.sliderProgressColor(.white)
		.sensoryFeedback(.selection, trigger: Int(sliderValue))
		.onAppear {
			sliderValue = Double(contentManager.states.tgt)
		}
		.onChange(of: contentManager.states.tgt) { oldValue, newValue in
			if !isDragging {
				sliderValue = Double(newValue)
			}
		}
		.onSliderDragEnded {
			let newTarget = Int(sliderValue)
			contentManager.sendCommand(
				webSocketTask: contentManager.webSocketTask,
				cmd: "setTarget",
				value: newTarget
			)
		}
	}
}

#Preview {
	let contentManager = ContentManager()
	
	TemperatureControlSlider()
		.environment(contentManager)
}
