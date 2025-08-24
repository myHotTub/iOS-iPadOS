
import SwiftUI

struct SubscriptionPlansView: View {
	@State private var subscriptionManager = SubscriptionManager()
	
	var body: some View {
		VStack(spacing: 20) {
			Text("Try myHotTub Pro Free for 30 Days")
				.font(.headline.bold())
				.foregroundStyle(Color.white)
			
			Button {
				
			} label: {
				HStack(spacing: 16) {
					VStack(spacing: 8) {
						Text("myHotTub Pro")
							.font(.headline.bold())
							.foregroundStyle(Color.white)
						
						Text("\(subscriptionManager.proYearly?.displayPrice ?? "9.99")/yr")
							.font(.title2.bold())
							.foregroundStyle(Color.white)
						
						Text("\(subscriptionManager.proYearly?.displayPrice ?? "9.99")/yr after a 1 month free trial. Auto-renews until cancelled.")
							.font(.caption)
							.foregroundStyle(Color.white.opacity(0.7))
							.multilineTextAlignment(.center)
					}
				}
				.padding()
				.background(
					RoundedRectangle(cornerRadius: 15)
						.fill(Color.white.opacity(0.2))
						.overlay(
							RoundedRectangle(cornerRadius: 15)
								.stroke(Color.orange, lineWidth: 2)
						)
				)
			}
		}
		.padding(.vertical, 12)
		.padding(.horizontal)
		.task {
			await subscriptionManager.loadProducts()
		}
    }
}

#Preview {
    SubscriptionPlansView()
		.background(.blue)
}
