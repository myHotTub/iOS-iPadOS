
import SwiftUI

@main
struct myHotTubApp: App {
	@AppStorage("onboardingComplete") private var onboardingComplete: Bool = false
	
	@State private var contentManager      = ContentManager()
	@State private var subscriptionManager = SubscriptionManager()
	
    var body: some Scene {
		Group {
			WindowGroup {
				if !onboardingComplete {
					OnboardingView()
				} else {
					ContentView()
				}
			}
			.environment(contentManager)
			.environment(subscriptionManager)
		}
    }
}

//@main
//struct myHotTubApp: App {
//	@State private var contentManager      = ContentManager()
//	@State private var subscriptionManager = SubscriptionManager()
//	
//	var body: some Scene {
//		WindowGroup {
//			ContentView()
//		}
//		.environment(contentManager)
//		.environment(subscriptionManager)
//	}
//}
