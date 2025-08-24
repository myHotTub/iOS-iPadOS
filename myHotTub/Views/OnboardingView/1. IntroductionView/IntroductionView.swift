
import SwiftUI

struct IntroductionView: View {
	let appName: String = (Bundle.main.infoDictionary?["CFBundleDisplayName"] as? String)!
	let goNext: () -> Void
	
    var body: some View {
		ZStack {
			VStack(spacing: 20) {
				Text("Welcome to \(appName)")
					.font(.largeTitle.bold())
					.foregroundStyle(Color.white)
					.multilineTextAlignment(.center)
				
				Group {
					Text("The ")
					+ Text("fastest ")
						.fontWeight(.bold)
					+ Text("and ")
					+ Text("easiest ")
						.fontWeight(.bold)
					+ Text("way to control your ESP8266 equipped Hot Tub.")
				}
				.foregroundStyle(Color.white)
				.multilineTextAlignment(.center)
				.opacity(0.8)
				
				OnboardingTestimonialView()
				
				VStack(spacing: 20) {
					Button {
						goNext()
					} label: {
						HStack {
							Spacer()
							
							Text("Let's Get Started")
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
					
					VStack(spacing: 8) {
						HStack(spacing: 20) {
							ValuePropItem(icon: "figure.run.circle.fill", text: "Quick Setup")
							ValuePropItem(icon: "wifi.circle.fill", text: "Local Control")
							ValuePropItem(icon: "lock.circle.fill", text: "100% Private")
						}
						.font(.footnote)
						.fontWeight(.bold)
						.foregroundColor(.white.opacity(0.7))
						.multilineTextAlignment(.center)
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
