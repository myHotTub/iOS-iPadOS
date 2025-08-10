
import Foundation

extension Date {
	func daysFrom(timestamp: TimeInterval) -> Int {
		let otherDate = Date(timeIntervalSince1970: timestamp)
		let calendar = Calendar.current
		let components = calendar.dateComponents([.day], from: otherDate, to: self)
		
		return components.day ?? 0
	}
}
