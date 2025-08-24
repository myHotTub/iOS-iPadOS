
import SwiftUI

struct ContentView: View {
	@Environment(ContentManager.self) var contentManager
	
    var body: some View {
		TabView {
			ControlsView()
				.tabItem {Label("Controls", systemImage: "switch.2")}
			SettingsView()
				.tabItem {Label("Settings", systemImage: "gear")}
		}
		.onAppear {
			if contentManager.connectionManager.configuration.userIp.isEmpty {
				contentManager.establishConnection(urlType: .moduleDefault)
			} else {
				contentManager.establishConnection(urlType: .userDefined)
			}
		}
		.dynamicTypeSize(...DynamicTypeSize.xLarge)
	}
}

//struct ContentView: View {
//	@AppStorage("onboardingComplete") private var onboardingComplete: Bool = false
//	
//	@Environment(ContentManager.self) var contentManager
//	
//	var body: some View {
//		ZStack {
//			TabView {
//				ControlsView()
//					.tabItem { Label("Controls", systemImage: "switch.2") }
//				SettingsView()
//					.tabItem { Label("Settings", systemImage: "gear") }
//			}
//			.opacity(onboardingComplete ? 1 : 0)
//			.scaleEffect(onboardingComplete ? 1 : 0.8)
//			
//			if !onboardingComplete {
//				OnboardingView {
//					withAnimation(.easeInOut(duration: 0.8)) {
//						onboardingComplete = true
//					}
//				}
//				.transition(.asymmetric(
//					insertion: .opacity,
//					removal: .scale.combined(with: .opacity)
//				))
//			}
//		}
//		.onAppear {
//			if onboardingComplete {
//				setupConnection()
//			}
//		}
//		.dynamicTypeSize(...DynamicTypeSize.xLarge)
//	}
//	
//	private func setupConnection() {
//		if contentManager.connectionManager.configuration.userIp.isEmpty {
//			contentManager.establishConnection(urlType: .moduleDefault)
//		} else {
//			contentManager.establishConnection(urlType: .userDefined)
//		}
//	}
//}

#Preview {
	let contentManager = ContentManager()
	
    ContentView()
		.environment(contentManager)
}
