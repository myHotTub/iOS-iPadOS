
import WhatsNewKit

@MainActor
extension myHotTubApp: @preconcurrency WhatsNewCollectionProvider {
	var whatsNewCollection: WhatsNewCollection {
		WhatsNew(
			version: "1.1.0",
			title: "What's New in myHotTub",
			features: [
				WhatsNew.Feature(
					image: .init(systemName: "calendar"),
					title: "View Your Schedules",
					subtitle: "Viewing your schedules has never been easier — know exactly when your hot tub is heating."
				),
				WhatsNew.Feature(
					image: .init(systemName: "calendar.badge.plus"),
					title: "Add a Schedule",
					subtitle: "Add a new schedule, or two, or three, or even many more! The ability to add schedules has now been added! "
				),
				WhatsNew.Feature(
				  image: .init(systemName: "square.and.arrow.up"),
				  title: "Continue Sharing Feedback",
				  subtitle: "Your feedback helps me prioritise new features and fix bugs. Thank you!"
				)
			],
			primaryAction: .init(
				title: "Continue",
				backgroundColor: .blue,
				foregroundColor: .white,
				hapticFeedback: .notification(.success)
			)
		)
	}
}
