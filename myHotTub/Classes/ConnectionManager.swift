
import Foundation

@Observable
class ConnectionManager {
	let configuration = Configuration()
		
	class Configuration {
		enum WebSocketSchemes: String {
			case webSocket       = "ws://"
			case webSocketSecure = "wss://"
		}
		
		static let defaultHostname: String = "layzspa.local"
		static let defaultIp: String       = "192.168.4.2"
		static let defaultPort: Int        = 81
		
		let defaultModuleUrl: String  = "\(WebSocketSchemes.webSocket.rawValue)\(defaultHostname):\(defaultPort)"
		let fallbackModuleUrl: String = "\(WebSocketSchemes.webSocket.rawValue)\(defaultIp):\(defaultPort)"
	}
}
