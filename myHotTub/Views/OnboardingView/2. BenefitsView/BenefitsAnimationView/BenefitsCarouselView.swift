
import SwiftUI

struct BenefitItem {
	let icon: String
	let title: String
	let description: String
	let color: Color
}

struct BenefitsCarouselView: View {
	@State private var currentBenefitIndex = 0

	private let benefits = [
		BenefitItem(
			icon: "thermometer.high",
			title: "The Perfect Temperature",
			description: "Set your ideal temperature with precision control.",
			color: .white
		),
		BenefitItem(
			icon: "clock.badge.checkmark",
			title: "At The Perfect Time",
			description: "No more guessing when the Hot Tub is ready.",
			color: .white
		),
		BenefitItem(
			icon: "bubbles.and.sparkles",
			title: "Relaxing Bubbles",
			description: "Turn on the bubbles for the ultimate relaxation experience.",
			color: .white
		),
		BenefitItem(
			icon: "shower.sidejet",
			title: "Powerful HydroJets",
			description: "Enable the HydroJets for extra therapeutic relief.",
			color: .white
		)
	]

	var body: some View {
		// Rotating Benefits Carousel
		VStack(spacing: 20) {
			VStack(spacing: 24) {
				
				// Icon section with fixed height
				VStack {
					Image(systemName: benefits[currentBenefitIndex].icon)
						.font(.system(size: 72, weight: .regular))
						.foregroundStyle(benefits[currentBenefitIndex].color)
				}
				.frame(height: 120)
				
				VStack(spacing: 10) {
					Text(benefits[currentBenefitIndex].title)
						.font(.headline.bold())
						.foregroundStyle(.white)

					Text(benefits[currentBenefitIndex].description)
						.font(.subheadline)
						.foregroundStyle(.white)
						.multilineTextAlignment(.center)
						.fixedSize(horizontal: false, vertical: true)
				}
				.frame(maxWidth: .infinity)
			}
			.frame(maxWidth: .infinity, minHeight: 200)
			.padding()
			.background(
				RoundedRectangle(cornerRadius: 15)
					.fill(Color.white.opacity(0.1))
					.overlay(
						RoundedRectangle(cornerRadius: 15)
							.stroke(Color.white.opacity(0.2), lineWidth: 1)
					)
			)

			HStack {
				ForEach(0..<benefits.count, id: \.self) { index in
					Circle()
						.fill(index == currentBenefitIndex ? Color.white : Color.white.opacity(0.4))
						.frame(width: 8, height: 8)
						.scaleEffect(index == currentBenefitIndex ? 1.2 : 1.0)
						.animation(.easeInOut(duration: 0.3), value: currentBenefitIndex)
				}
			}
		}
		.onAppear {
			startBenefitRotation()
		}
	}

	private func startBenefitRotation() {
		Task { @MainActor in
			while !Task.isCancelled {
				try? await Task.sleep(for: .seconds(3))
				withAnimation(.easeInOut(duration: 0.5)) {
					currentBenefitIndex = (currentBenefitIndex + 1) % benefits.count
				}
			}
		}
	}
}

#Preview {
	BenefitsCarouselView()
}
