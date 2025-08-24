
import SwiftUI

struct FeatureComparisonView: View {
	let freeFeatures: [Feature]
	let premiumFeatures: [Feature]
	
    var body: some View {
		VStack(spacing: 20) {
			// Free Features Section
			VStack(spacing: 16) {
				HStack {
					Image(systemName: "checkmark.circle.fill")
						.font(.title2)
						.foregroundStyle(Color.white)
						.frame(width: 25)
					
					Text("Get Started Free")
						.font(.headline.bold())
						.foregroundStyle(Color.white)
					
					Spacer()
				}
				
				LazyVStack(spacing: 12) {
					ForEach(freeFeatures, id: \.title) { feature in
						FeatureRowsView(feature: feature, isIncluded: true)
					}
				}
			}
			.padding()
			.background(
				RoundedRectangle(cornerRadius: 15)
					.fill(Color.white.opacity(0.1))
					.overlay(
						RoundedRectangle(cornerRadius: 15)
							.stroke(Color.white.opacity(0.2), lineWidth: 1)
					)
			)
			
			VStack(spacing: 16) {
				HStack {
					Image(systemName: "crown.fill")
						.font(.title2)
						.foregroundStyle(Color.orange)
						.frame(width: 25)
					
					Text("Automate & Simplify")
						.font(.headline.bold())
						.foregroundStyle(Color.white)
					
					Spacer()
				}
				
				LazyVStack(spacing: 12) {
					ForEach(premiumFeatures, id: \.title) { feature in
						FeatureRowsView(feature: feature, isIncluded: false)
					}
				}
			}
			.padding()
			.background(
				RoundedRectangle(cornerRadius: 15)
					.fill(Color.white.opacity(0.1))
					.overlay(
						RoundedRectangle(cornerRadius: 15)
							.stroke(Color.white.opacity(0.2), lineWidth: 1)
					)
			)
		}
		.padding(.horizontal)
    }
}

//#Preview {
//    FeatureComparisonView()
//}
