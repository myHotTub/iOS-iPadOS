
import SwiftUI

struct FeatureRowsView: View {
	let feature: Feature
	let isIncluded: Bool
	
    var body: some View {
		HStack(spacing: 12) {
			Image(systemName: feature.icon)
				.font(.title3)
				.foregroundStyle(isIncluded ? .white : .orange)
				.frame(width: 22)
			
			VStack(alignment: .leading, spacing: 2) {
				Text(feature.title)
					.font(.subheadline.bold())
					.foregroundStyle(Color.white)
				
				Text(feature.description)
					.font(.caption)
					.foregroundStyle(Color.white)
					.multilineTextAlignment(.leading)
			}
			
			Spacer()
			
			Image(systemName: isIncluded ? "checkmark.circle.fill" : "lock.circle.fill")
				.font(.title3)
				.foregroundStyle(isIncluded ? .white : .orange)
		}
    }
}

//#Preview {
//    FeatureRowsView()
//}
