
import SwiftUI

struct ControlButtonsView: View {
	@Environment(\.verticalSizeClass) var verticalSizeClass
	
	let availableSize: CGSize
	
	var body: some View {
		let isIPhoneLandscape = verticalSizeClass == .compact
		
		let maxSize: CGFloat = {
			if isIPhoneLandscape {
				return max(availableSize.height * 1, 375)
			} else {
				return min(availableSize.height, availableSize.width, 450)
			}
		}()
		
		VStack {
			HStack {
				TemperatureControlButton()
				VStack {
					PumpControlButton()
					BubbleControlButton()
				}
			}
			.fixedSize(horizontal: false, vertical: true)
			.frame(maxWidth: maxSize, maxHeight: maxSize)
		}
		.listRowBackground(Color.clear)
		.listRowInsets(EdgeInsets())
	}
}

#Preview {
	let contentManager = ContentManager()
	
	GeometryReader { geometry in
		ControlButtonsView(availableSize: geometry.size)
			.environment(contentManager)
	}
}
