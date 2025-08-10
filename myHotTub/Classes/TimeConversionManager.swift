
import Foundation

class TimeConverter {
	func doubleConverter(_ hoursDouble: Double) -> String {
		let interval                     = hoursDouble * 3600
		let formatter                    = DateComponentsFormatter()
		
		formatter.allowedUnits           = [.hour, .minute, .second]
		formatter.unitsStyle             = .positional
		formatter.zeroFormattingBehavior = .pad
		
		return formatter.string(from: interval) ?? "00:00:00"
	}
	
	func intConverter(_ secondsInt: Int) -> String {
		let interval                     = TimeInterval(secondsInt)
		let formatter                    = DateComponentsFormatter()
		
		formatter.allowedUnits           = [.hour, .minute, .second]
		formatter.unitsStyle             = .positional
		formatter.zeroFormattingBehavior = .pad
		
		return formatter.string(from: interval) ?? "00:00:00"
	}
}
