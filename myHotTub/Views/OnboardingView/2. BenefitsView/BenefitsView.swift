
import SwiftUI

struct BenefitsView: View {
	let goNext: () -> Void

	var body: some View {
		ZStack {
			VStack(spacing: 0) {
				// Header section
				VStack(spacing: 20) {
					Text("Take Total Control")
						.font(.largeTitle.bold())
						.foregroundStyle(Color.white)
						.multilineTextAlignment(.center)

					Text("Transform your Hot Tub experience with intelligent controls at your fingertips.")
						.foregroundStyle(Color.white)
						.multilineTextAlignment(.center)
						.opacity(0.8)
				}
				.padding(.horizontal)
				
				Spacer()

				BenefitsCarouselView()
					.padding()

				// Footer section
				VStack(spacing: 20) {
					Button {
						goNext()
					} label: {
						HStack {
							Spacer()

							Text("Continue")
								.font(.title3.bold())
								.foregroundStyle(Color.white)

							Spacer()
						}
						.padding()
						.background(
							LinearGradient(
								colors: [.orange, .red.opacity(0.8)],
								startPoint: .leading,
								endPoint: .trailing
							)
						)
						.cornerRadius(25)
						.shadow(color: .orange.opacity(0.4), radius: 8, x: 0, y: 4)
					}
					.padding(.bottom, hasHomeButton() ? 50 : 20)
				}
			}
			.padding(.horizontal)
		}
	}

	// Used to add padding for devices with a physical Home Button as the safe area for these devices overlaps with the footer text.
	func hasHomeButton() -> Bool {
		guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
			  let window = windowScene.windows.first else {
			return false
		}
		return window.safeAreaInsets.bottom == 0
	}
}
