import SwiftUI

struct SubscriptionView: View {
	let goToApp: () -> Void
	
	@State private var selectedPlan: SubscriptionPlan = .yearly
	@State private var isPurchasing = false
	@State private var showingAlert = false
	@State private var alertMessage = ""
	
	private let freeFeatures = [
		Feature(icon: "thermometer.medium", title: "Temperature Control", description: "Monitor and adjust your Hot Tub temperature."),
		Feature(icon: "pump.fill", title: "Pump Control", description: "Control your Hot Tub's water circulation."),
		Feature(icon: "bubble.left.and.bubble.right.fill", title: "Bubbles Control", description: "Turn bubbles on and off remotely."),
		Feature(icon: "water.waves", title: "HydroJets Control", description: "Manage your Hot Tub's massage jets.")
	]
	
	private let premiumFeatures = [
		Feature(icon: "bell.badge.fill", title: "Sanitation Reminders", description: "Never miss water treatment schedules."),
		Feature(icon: "calendar.badge.clock", title: "Scheduling", description: "Automate your Hot Tub routines."),
		Feature(icon: "apps.iphone", title: "Widgets", description: "Quick controls from your home screen.")
	]
	
	var body: some View {
		ZStack {
			VStack(spacing: 0) {
				// Header section
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
				
				// Features comparison
//				FeaturesComparisonView(
//					freeFeatures: freeFeatures,
//					premiumFeatures: premiumFeatures
//				)
//				.padding(.horizontal)
				
				Spacer()
				
				// Subscription plans
				SubscriptionPlanView(selectedPlan: $selectedPlan)
					.padding(.horizontal)
				
				Spacer()
				
				// Footer section
				VStack(spacing: 12) {
					Button {
						handlePurchase()
					} label: {
						HStack {
							Spacer()
							
							if isPurchasing {
								ProgressView()
									.progressViewStyle(CircularProgressViewStyle(tint: .white))
									.scaleEffect(0.8)
								Text("Processing...")
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
					.disabled(isPurchasing)
					
					Button {
						goToApp()
					} label: {
						Text("Continue with Free Version")
							.font(.subheadline)
							.foregroundStyle(.white.opacity(0.7))
							.underline()
					}
				}
				.padding(.bottom, hasHomeButton() ? 50 : 20)
			}
			.padding(.horizontal)
		}
		.alert("Purchase Status", isPresented: $showingAlert) {
			Button("OK") {
				if !alertMessage.contains("Error") {
					goToApp()
				}
			}
		} message: {
			Text(alertMessage)
		}
	}
	
	private func handlePurchase() {
		isPurchasing = true
		
		Task {
			await performPurchase()
		}
	}
	
	@MainActor
	private func performPurchase() async {
		// Simulate purchase process
		try? await Task.sleep(for: .seconds(2))
		
		isPurchasing = false
		
		// Simulate successful purchase for demo
		alertMessage = "Welcome to Premium! Your free trial has started."
		showingAlert = true
	}
	
	func hasHomeButton() -> Bool {
		guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
			  let window = windowScene.windows.first else {
			return false
		}
		return window.safeAreaInsets.bottom == 0
	}
}

// MARK: - Supporting Views

struct FeaturesComparisonView: View {
	let freeFeatures: [Feature]
	let premiumFeatures: [Feature]
	
	var body: some View {
		VStack(spacing: 20) {
			// Free Features Section
			VStack(spacing: 16) {
				HStack {
					Image(systemName: "checkmark.circle.fill")
						.foregroundStyle(.green)
						.font(.title2)
					
					Text("Included Free")
						.font(.headline.bold())
						.foregroundStyle(.white)
					
					Spacer()
				}
				
				LazyVStack(spacing: 12) {
					ForEach(freeFeatures, id: \.title) { feature in
						FeatureRowView(feature: feature, isIncluded: true)
					}
				}
			}
			.padding()
			.background(
				RoundedRectangle(cornerRadius: 16)
					.fill(Color.white.opacity(0.1))
					.overlay(
						RoundedRectangle(cornerRadius: 16)
							.stroke(Color.white.opacity(0.2), lineWidth: 1)
					)
			)
			
			// Premium Features Section
			VStack(spacing: 16) {
				HStack {
					Image(systemName: "crown.fill")
						.foregroundStyle(.orange)
						.font(.title2)
						.frame(width: 2)
					
					Text("Premium Only")
						.font(.headline.bold())
						.foregroundStyle(.white)
					
					Spacer()
				}
				
				LazyVStack(spacing: 12) {
					ForEach(premiumFeatures, id: \.title) { feature in
						FeatureRowView(feature: feature, isIncluded: false)
					}
				}
			}
			.padding()
			.background(
				RoundedRectangle(cornerRadius: 16)
					.fill(
						LinearGradient(
							colors: [Color.orange.opacity(0.2), Color.red.opacity(0.1)],
							startPoint: .topLeading,
							endPoint: .bottomTrailing
						)
					)
					.overlay(
						RoundedRectangle(cornerRadius: 16)
							.stroke(Color.orange.opacity(0.4), lineWidth: 1)
					)
			)
		}
	}
}

struct FeatureRowView: View {
	let feature: Feature
	let isIncluded: Bool
	
	var body: some View {
		HStack(spacing: 12) {
			Image(systemName: feature.icon)
				.font(.title3)
				.foregroundStyle(isIncluded ? .green : .orange)
				.frame(width: 24)
			
			VStack(alignment: .leading, spacing: 2) {
				Text(feature.title)
					.font(.subheadline.bold())
					.foregroundStyle(.white)
				
				Text(feature.description)
					.font(.caption)
					.foregroundStyle(.white.opacity(0.7))
					.multilineTextAlignment(.leading)
			}
			
			Spacer()
			
			Image(systemName: isIncluded ? "checkmark.circle.fill" : "lock.circle.fill")
				.foregroundStyle(isIncluded ? .green : .orange)
				.font(.title3)
		}
		.padding(.vertical, 4)
	}
}

struct SubscriptionPlanView: View {
	@Binding var selectedPlan: SubscriptionPlan
	
	var body: some View {
		VStack(spacing: 12) {
			Text("Choose Your Plan")
				.font(.headline.bold())
				.foregroundStyle(.white)
			
			HStack(spacing: 16) {
				PlanCardView(
					plan: .monthly,
					isSelected: selectedPlan == .monthly
				) {
					selectedPlan = .monthly
				}
				
				PlanCardView(
					plan: .yearly,
					isSelected: selectedPlan == .yearly
				) {
					selectedPlan = .yearly
				}
			}
		}
	}
}

struct PlanCardView: View {
	let plan: SubscriptionPlan
	let isSelected: Bool
	let onTap: () -> Void
	
	var body: some View {
		Button(action: onTap) {
			VStack(spacing: 8) {
				Text(plan.title)
					.font(.headline.bold())
					.foregroundStyle(.white)
				
				Text(plan.price)
					.font(.title2.bold())
					.foregroundStyle(.white)
				
				Text(plan.subtitle)
					.font(.caption)
					.foregroundStyle(.white.opacity(0.7))
					.multilineTextAlignment(.center)
				
				if plan == .yearly {
					Text("SAVE 20%")
						.font(.caption2.bold())
						.foregroundStyle(.orange)
						.padding(.horizontal, 8)
						.padding(.vertical, 2)
						.background(
							RoundedRectangle(cornerRadius: 4)
								.fill(Color.orange.opacity(0.2))
						)
				}
			}
			.frame(maxWidth: .infinity)
			.padding()
			.background(
				RoundedRectangle(cornerRadius: 12)
					.fill(isSelected ? Color.white.opacity(0.2) : Color.white.opacity(0.1))
					.overlay(
						RoundedRectangle(cornerRadius: 12)
							.stroke(isSelected ? Color.orange : Color.white.opacity(0.3), lineWidth: isSelected ? 2 : 1)
					)
			)
		}
		.buttonStyle(PlainButtonStyle())
	}
}

// MARK: - Models

//struct Feature {
//	let icon: String
//	let title: String
//	let description: String
//}

enum SubscriptionPlan: CaseIterable {
	case monthly
	case yearly
	case premium // For backwards compatibility
	
	var title: String {
		switch self {
		case .monthly:
			return "Monthly"
		case .yearly:
			return "Yearly"
		case .premium:
			return "Premium"
		}
	}
	
	var price: String {
		switch self {
		case .monthly:
			return "$4.99/mo"
		case .yearly:
			return "$47.99/yr"
		case .premium:
			return "$4.99/mo"
		}
	}
	
	var subtitle: String {
		switch self {
		case .monthly:
			return "Billed monthly"
		case .yearly:
			return "$3.99/mo when billed yearly"
		case .premium:
			return "Cancel anytime"
		}
	}
}

#Preview {
	SubscriptionView(
		goToApp: {}
	)
	.background(.blue)
}
