
import SwiftUI

struct ValuePropItem: View {
	let icon: String
	let text: String
	
	var body: some View {
		VStack(spacing: 4) {
			Image(systemName: icon)
				.font(.caption)
				.foregroundColor(.white.opacity(0.9))
			
			Text(text)
				.font(.caption2.bold())
				.foregroundColor(.white.opacity(0.8))
				.multilineTextAlignment(.center)
				.frame(minHeight: 32)
		}
		.frame(maxWidth: 80)
	}
}

struct OnboardingView: View {
	@AppStorage("onboardingCurrentPage") private var savedCurrentPage: Int = 1
	@AppStorage("onboardingComplete") private var onboardingComplete: Bool = false
	
	@Environment(ContentManager.self) var contentManager
		
	@State var currentPage: Int = 1
	
	let totalPages = 5
//	let onComplete: () -> Void
	
	var body: some View {
		ZStack {
			// Background
			LinearGradient(
				gradient: Gradient(colors: [
						Color.cyan.opacity(0.6),
						Color.blue.opacity(1)
					]),
				startPoint: .top,
				endPoint: .bottom
			)
			.edgesIgnoringSafeArea(.all)
			
			TabView(selection: $currentPage) {
				IntroductionView(
					goNext: goNext
				)
					.tag(1)
				BenefitsView(
					goNext: goNext
				)
					.tag(2)
				SetupView(
					goNext: goNext
				)
					.tag(3)
				SearchingView(
					goNext: goNext
				)
					.tag(4)
				PremiumFeaturesView(
					goToApp: goToApp
				)
					.tag(5)
			}
			.tabViewStyle(.page(indexDisplayMode: .always))
			.indexViewStyle(PageIndexViewStyle(backgroundDisplayMode: .always))
			.ignoresSafeArea()
			.onAppear {
				// Load the saved page when the view appears
				currentPage = savedCurrentPage
			}
			.onChange(of: currentPage) { oldValue, newValue in
				// Save the current page whenever it changes
				savedCurrentPage = newValue
			}
		}
	}
	
	func goNext() {
		withAnimation {
			if currentPage < totalPages {
				currentPage += 1
			}
		}
	}
	
	func goToApp() {
		onboardingComplete = true
//		onComplete()
	}
}

//#Preview {
//	let contentManager = ContentManager()
//	
//	OnboardingView(onComplete: {})
//	.environment(contentManager)
//}

#Preview {
	let contentManager = ContentManager()
	
    OnboardingView()
		.environment(contentManager)
}
