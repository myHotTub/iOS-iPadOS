
import SwiftUI

struct ControlsView: View {
	@Environment(ContentManager.self) var contentManager
	
	var body: some View {
		NavigationStack {
			GeometryReader { geometry in
				List {
					ControlButtonsView(availableSize: geometry.size)
					ReadyInList()
					SanitationView()
				}
				.navigationTitle("Controls")
				.navigationBarTitleDisplayMode(.automatic)
				.toolbar {
					ToolbarItem(placement: .topBarLeading) {
						SignalStrengthButton()
					}
//					Removed until toggling power is supported.
//					ToolbarItem(placement: .topBarTrailing) {
//						PowerButton()
//					}
				}
				.refreshable {
					contentManager.refreshConnection()
					try? await Task.sleep(for: .seconds(0.5))
				}
			}
		}
	}
}

#Preview {
	let contentManager = ContentManager()
	
    ControlsView()
		.environment(contentManager)
}
