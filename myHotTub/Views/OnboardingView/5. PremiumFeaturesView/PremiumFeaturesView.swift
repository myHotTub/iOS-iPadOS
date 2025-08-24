
import SwiftUI

struct PremiumFeaturesView: View {
	
	@State private var subscriptionManager = SubscriptionManager()
	
	let goToApp: () -> Void
	
	private let freeFeatures = [
		Feature(
			icon: "thermometer.medium",
			title: "Temperature Control",
			description: "Monitor and adjust your Hot Tub's temperature."
		),
		Feature(
			icon: "arrow.trianglehead.2.counterclockwise",
			title: "Pump Control",
			description: "Control your Hot Tub's water circulation."
		),
		Feature(
			icon: "bubbles.and.sparkles",
			title: "Bubble & HydroJet Controls",
			description: "Turn bubbles and HydroJets on and off."
		)
	]
	
	private let premiumFeatures = [
		Feature(
			icon: "bell.badge.fill",
			title: "Sanitation Reminders",
			description: "Never miss water treatment schedules."
		)
//		Feature(
//			icon: "calendar.badge.clock",
//			title: "Scheduling",
//			description: "Automate your Hot Tub routines."
//		),
//		Feature(
//			icon: "apps.iphone",
//			title: "Widgets",
//			description: "Quick controls from your home screen."
//		)
	]
	
    var body: some View {
		ZStack {
			VStack(spacing: 0) {
				VStack(spacing: 20) {
					Text("Unlock Premium Features")
						.font(.largeTitle.bold())
						.foregroundStyle(Color.white)
						.multilineTextAlignment(.center)
					
					Text("Get the most out of your Hot Tub with advanced controls and automation.")
						.foregroundStyle(Color.white)
						.multilineTextAlignment(.center)
						.opacity(0.8)
				}
				.padding(.horizontal)
				
				Spacer()
				
				ScrollView {
					FeatureComparisonView(
						freeFeatures: freeFeatures,
						premiumFeatures: premiumFeatures
					)
					
					SubscriptionPlansView()
				}
				
				Spacer()
				
				// Footer section
				VStack(spacing: 15) {
					Button {
						Task {
							await subscriptionManager.purchaseProduct()
						}
					} label: {
						HStack {
							Spacer()
							if subscriptionManager.isPurchasing {
								ProgressView()
									.progressViewStyle(CircularProgressViewStyle(tint: .white))
									.scaleEffect(0.8)
								Text("Processing…")
									.font(.title3.bold())
									.foregroundStyle(Color.white)
							} else if subscriptionManager.proYearly == nil {
								Text("Loading…")
									.font(.title3.bold())
									.foregroundStyle(Color.white)
							} else {
								Text("Start Free Trial")
									.font(.title3.bold())
									.foregroundStyle(Color.white)
							}
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
					.disabled(subscriptionManager.isPurchasing || subscriptionManager.proYearly == nil)

					
					Button {
						goToApp()
					} label: {
						Text("Continue with Free Version")
							.font(.subheadline)
							.foregroundStyle(Color.white.opacity(0.7))
							.underline()
					}
					
					Button {
						Task {
							await subscriptionManager.restorePurchases()
						}
					} label: {
						if subscriptionManager.isRestoring {
							HStack(spacing: 4) {
								ProgressView()
									.scaleEffect(0.6)
									.tint(Color.white.opacity(0.5))
								
								Text("Restoring...")
									.font(.caption)
									.foregroundStyle(Color.white)
							}
						} else {
							Text("Restore Purchases")
								.font(.caption)
								.foregroundStyle(Color.white.opacity(0.5))
								.underline()
						}
					}
					.disabled(subscriptionManager.isRestoring)
				}
				.padding(.bottom, hasHomeButton() ? 50 : 20)
			}
			.padding(.horizontal)
		}
		.onChange(of: subscriptionManager.hasActiveSubscription) { _, newValue in
			if newValue {
				// Small delay to ensure UI updates smoothly
				DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
					goToApp()
				}
			}
		}
    }
	
	func hasHomeButton() -> Bool {
		guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
			  let window = windowScene.windows.first else {
			return false
		}
		return window.safeAreaInsets.bottom == 0
	}
}

// MARK: Models

struct Feature {
	let icon: String
	let title: String
	let description: String
}

#Preview {
    PremiumFeaturesView(
		goToApp: {}
	)
}
