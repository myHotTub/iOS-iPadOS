
import Foundation

@MainActor
@Observable
class ContentManager {
	let other             = Other()
	let states            = States()
	let times             = Times()
	let connectionMonitor = ConnectionMonitor()
	let connectionManager = ConnectionManager()
	let timeConverter     = TimeConverter()
	
	@Observable
	class Other {
		var fw: String?     = nil // The firmware version of the module.
		var hasgod: Bool?   = nil // Whether "Take Control" mode is enabled.
		var hasjets: Bool?  = nil // Whether the Hot Tub has HydroJets.
		var ip: String?     = nil // The IP address assigned to the module.
		var loopfq: Int?    = nil // The loop frequency.
		var model: String?  = nil // The model of the Hot Tub.
		var mqtt: Int?      = nil // MQTT connection status.
		var rssi: Int       = 0 // The Wi-Fi signal strength of the module.
		var ssid: String?   = nil // The Wi-Fi network name the module uses to connect to the network.
	}
	
	@Observable
	class States {
		var air: Int?      = nil // The bubbles state.
		var amb: Int       = 0 // The ambient temperature.
		var ambc: Int      = 0 // The ambient temperature in Celsius.
		var ambf: Int      = 0 // The ambient temperature in Fahrenheit.
		var brt: Int?      = nil // The display brightness.
		var ch1: Int?      = nil // Display characters.
		var ch2: Int?      = nil // Display characters.
		var ch3: Int?      = nil // Display characters.
		var err: Int?      = nil // The error state.
		var flt: Int?      = nil // The pump state.
		var god: Int?      = nil // The take control mode state.
		var grn: Int?      = nil // The heater state.
		var hjt: Int?      = nil // The HydroJets state.
		var lck: Int?      = nil // The lock button state.
		var pwr: Int?      = nil // The power state.
		var red: Int?      = nil // The active heating state.
		var tgt: Int       = 20 // The target temperature.
		var tgtc: Int      = 20// The target temperature in Celsius.
		var tgtf: Int      = 68 // The target temperature in Fahrenheit.
		var time: Int?     = nil // The current module time.
		var tmp: Int       = 0 // The current temperature.
		var tmpc: Int      = 0 // The current temperature in Celsius.
		var tmpf: Int      = 0 // The current temperature in Fahrenheit.
		var unt: Int?      = nil // The temperature unit.
		var vtm: Double?   = nil // The virtual temperature.
		var vtmc: Double?  = nil // The virtual temperature in Celsius.
		var vtmf: Double?  = nil // The virtual temperature in Fahrenheit.
	}
	
	@Observable
	class Times {
		var airtime: TimeInterval?      = nil // The total bubbles runtime.
		var clint: Int?                 = nil // The chlorine addition interval in days.
		var cltime: Int                 = 99999 // The last chlorine addition timestamp.
		var cost: Double?               = nil // The estimated operating cost.
		var dbg: String?                = nil // Debug information.
		var fcle: TimeInterval?         = nil // The last filter clean timestamp.
		var fclei: Int?                 = nil // The filter clean interval in days.
		var frep: Int                   = 99999 // The last filter replacement timestamp.
		var frepi: Int?                 = nil // The filter replacement interval in days.
		var frin: Int                   = 99999 // The last filter rinse timestamp.
		var frini: Int?                 = nil // The filter rinse interval in days.
		var heatingtime: TimeInterval?  = nil // The total heating runtime.
		var jettime: TimeInterval?      = nil // The total HydroJets runtime.
		var kwh: Double?                = nil // The total energy consumption in kWh.
		var kwhd: Double?               = nil // The daily energy consumption in kWh.
		var pumptime: TimeInterval?     = nil // The total pump runtime.
		var rs: String?                 = nil // The ready state.
		var t2r: String                 = "00:00:00" // The amount of time until the Hot Tub target temperature is reached.
		var time: TimeInterval?         = nil // The current module time.
		var uptime: TimeInterval?       = nil // The total uptime of the module.
		var watt: Int?                  = nil // The current power consumption in watts.
	}
	
	@Observable
	class ConnectionMonitor {
		var isConnected: Bool = false
		var connectionAttempt: Int = 0
	}
	
	var webSocketTask: URLSessionWebSocketTask?
	
	// This function establishes WebSocket connectivity with the ESP8266 module.
	func establishConnection() {
		// Prevents establishConnection() from attempting to establish a new connection if a connection is already established or if a connection attempt is in progress.
		guard !self.connectionMonitor.isConnected else {
			return
		}
		
		// Closes any existing connections (should they be found) before establishing a new connection.
		webSocketTask?.cancel(with: .goingAway, reason: nil)
		
		// Constructs the URL used to connect to the ESP8266 module.
		let moduleUrl = URL(string: "\(connectionManager.configuration.defaultModuleUrl)")!
		
		// Constructs the header information required to connect to the ESP8266 module successfully.
		var request = URLRequest(url: moduleUrl)
		request.setValue("arduino", forHTTPHeaderField: "Sec-WebSocket-Protocol")
		request.timeoutInterval = 3.0
		
		// Establishes the connection to the ESP8266 module.
		webSocketTask = URLSession.shared.webSocketTask(with: request)
		webSocketTask?.resume()
		
		// Call the receiveContent() function.
		receiveContent()
	}
	
	// This function enables the user to pull down to refresh data on the ControlsView().
	func refreshConnection() {
		// Prevents calling establishConnection() if a connection is already established.
		guard !connectionMonitor.isConnected else {
			return
		}
		
		// Call function establishConnection().
		establishConnection()
	}
	
	// This function receives messages from the WebSocket server on the ESP8266 module and assigns them to the appropriate variable in ContentManager().
	func receiveContent() {
		// Start receiving content from the WebSocket server on the ESP8266 module.
		webSocketTask?.receive() { [weak self] contentReceived in
			guard let self = self else {
				return
			}
			
			Task { @MainActor in
				switch contentReceived {
				case .success(let receivedContent):
					connectionMonitor.isConnected       = true
					connectionMonitor.connectionAttempt = 0
					switch receivedContent {
					case .data:
						break
					case .string(let receivedString):
						self.parseReceivedContent(receivedString)
					@unknown default:
						break
					}
					// Ensures that content is continually received when connected.
					self.receiveContent()
				case .failure:
					connectionMonitor.isConnected = false
					connectionMonitor.connectionAttempt += 1
					self.refreshConnection()
				}
			}
		}
	}
	
	// This function parses the content received by the function receiveContent() from WebSocket server on the ESP8266 module.
	func parseReceivedContent(_ jsonString: String) {
		guard let data = jsonString.data(using: .utf8) else {
			return
		}
		
		do {
			if let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
			   let content = json["CONTENT"] as? String {
				   switch content {
				   case "OTHER":
					   // Stores the Firmware Version of the ESP8266 module.
					   if let firmwareVersion = json["FW"] as? String {
						   other.fw = firmwareVersion
					   }
					   
					   //' Stores the state of take control mode.
					   if let takeControl = json["HASGOD"] as? Bool {
						   other.hasgod = takeControl
					   }
					   
					   // Stores whether the Hot Tub has HydroJets.
					   if let hasJets = json["HASJETS"] as? Bool {
						   other.hasjets = hasJets
					   }
					   
					   // Stores the IP Address assigned to the ESP8266 module.
					   if let ipAddress = json["IP"] as? String {
						   other.ip = ipAddress
					   }
					   
					   // Stores the loop frequency state.
					   if let loopFrequency = json["loopfq"] as? Int {
						   other.loopfq = loopFrequency
					   }
					   
					   // Stores the Hot Tub Model.
					   if let hotTubModel = json["MODEL"] as? String {
						   other.model = hotTubModel
					   }
					   
					   // Stores the MQTT Connectivity State.
					   if let mqttState = json["MQTT"] as? Int {
						   other.mqtt = mqttState
					   }
					   
					   // Stores the Wi-Fi Signal quality level of the ESP8266 module.
					   if let signalRssi = json["RSSI"] as? Int {
						   other.rssi = signalRssi
					   }
					   
					   // Stores the Wi-Fi name used by the ESP8266 module.
					   if let networkName = json["SSID"] as? String {
						   other.ssid = networkName
					   }
					   
				   case "STATES":
					   // Stores the state of the air bubbles.
					   if let airBubbles = json["AIR"] as? Int {
						   states.air = airBubbles
					   }
					   
					   // Stores the ambient temperature.
					   if let ambientTemperature = json["AMB"] as? Int {
						   states.amb = ambientTemperature
					   }
					   
					   // Stores the ambient temperature in Celsius.
					   if let ambientTemperatureC = json["AMBC"] as? Int {
						   states.ambc = ambientTemperatureC
					   }
					   
					   // Stores the ambient temperature in Fahrenheit.
					   if let ambientTemperatureF = json["AMBF"] as? Int {
						   states.ambf = ambientTemperatureF
					   }
					   
					   // Stores the display brightness level.
					   if let displayBrightness = json["BRT"] as? Int {
						   states.brt = displayBrightness
					   }
					   
					   // Stores the characters to display on the first screen.
					   if let screenOneText = json["CH1"] as? Int {
						   states.ch1 = screenOneText
					   }
					   
					   // Stores the characters to display on the second screen.
					   if let screenTwoText = json["CH2"] as? Int {
						   states.ch2 = screenTwoText
					   }
					   // Stores the characters to display on the third screen.
					   if let screenThreeText = json["CH3"] as? Int {
						   states.ch3 = screenThreeText
					   }
					   
					   // Stores the error state.
					   if let errorState = json["ERR"] as? Int {
						   states.err = errorState
					   }
					   
					   // Stores the state of the pump.
					   if let pumpState = json["FLT"] as? Int {
						   states.flt = pumpState
					   }
					   
					   // Stores the take control mode state.
					   if let takeControlMode = json["GOD"] as? Int {
						   states.god = takeControlMode
					   }
					   
					   // Stores the state of the heater.
					   if let heaterEnabled = json["GRN"] as? Int {
						   states.grn = heaterEnabled
					   }
					   
					   // Stores the state of the HydroJets.
					   if let hydroJets = json["HJT"] as? Int {
						   states.hjt = hydroJets
					   }
					   
					   // Stores the state of the lock button.
					   if let lockButton = json["LCK"] as? Int {
						   states.lck = lockButton
					   }
					   
					   // Stores the power state.
					   if let powerState = json["PWR"] as? Int {
						   states.pwr = powerState
					   }
					   
					   // Stores the actively heating state.
					   if let activelyHeating = json["RED"] as? Int {
						   states.red = activelyHeating
					   }
					   
					   // Stores the target temperature.
					   if let targetTemperature = json["TGT"] as? Int {
						   states.tgt = targetTemperature
					   }
					   
					   // Stores the target temperature in Celsius.
					   if let targetTemperatureC = json["TGTC"] as? Int {
						   states.tgtc = targetTemperatureC
					   }
					   
					   // Stores the target temperature in Fahrenheit.
					   if let targetTemperatureF = json["TGTF"] as? Int {
						   states.tgtf = targetTemperatureF
					   }
					   
					   // Stores the ESP8266 module time.
					   if let moduleTime = json["TIME"] as? Int? {
						   states.time = moduleTime
					   }
					   
					   // Stores the current temperature.
					   if let currentTemperature = json["TMP"] as? Int {
						   states.tmp = currentTemperature
					   }
					   
					   // Stores the current temperature in Celsius.
					   if let currentTemperatureC = json["TMPC"] as? Int {
						   states.tmpc = currentTemperatureC
					   }
					   
					   // Stores the current temperature in Fahrenheit.
					   if let currentTemperatureF = json["TMPF"] as? Int {
						   states.tmpf = currentTemperatureF
					   }
					   
					   // Stores the selected temperature unit.
					   if let temperatureUnit = json["UNT"] as? Int {
						   states.unt = temperatureUnit
					   }
					   
					   // Stores the virtual temperature.
					   if let virtualTemperature = json["VTM"] as? Double {
						   states.vtm = virtualTemperature
					   }
					   
					   // Stores the virtual Temperature in Celsius.
					   if let virtualTemperatureC = json["VTMC"] as? Double {
						   states.vtmc = virtualTemperatureC
					   }
					   
					   // Stores the virtual temperature in Fahrenheit.
					   if let virtualTemperatureF = json["VTMF"] as? Double {
						   states.vtmf = virtualTemperatureF
					   }
					   
				   case "TIMES":
					   // Stores the air bubbles runtime.
					   if let airTime = json["AIRTIME"] as? TimeInterval {
						   times.airtime = airTime
					   }
					   
					   // Stores the Chlorine addition interval.
					   if let chlorineAddInterval = json["CLINT"] as? Int {
						   times.clint = chlorineAddInterval
					   }
					   
					   // Stores the timestamp of the last Chlorine addition.
					   if let chlorineAddTime = json["CLTIME"] as? TimeInterval {
						   times.cltime = Date().daysFrom(timestamp: chlorineAddTime)
					   }
					   
					   // Stores the estimated operating costs.
					   if let estimatedCost = json["COST"] as? Double {
						   times.cost = estimatedCost
					   }
					   
					   // Stores the debug information.
					   if let debugInformation = json["DBG"] as? String {
						   times.dbg = debugInformation
					   }
					   
					   // Stores the last filter clean timestamp.
					   if let lastFilterCleanTime = json["FCLE"] as? TimeInterval {
						   times.fcle = lastFilterCleanTime
					   }
					   
					   // Stores the filter clean interval.
					   if let filterCleanInterval = json["FCLEI"] as? Int {
						   times.fclei = filterCleanInterval
					   }
					   
					   // Stores the last filter replacement timestamp.
					   if let lastFilterReplacementTime = json["FREP"] as? TimeInterval {
						   times.frep = Date().daysFrom(timestamp: lastFilterReplacementTime)
					   }
					   
					   // Stores the filter replacement interval.
					   if let filterReplacementInterval = json["FREPI"] as? Int {
						   times.frepi = filterReplacementInterval
					   }
					   
					   // Stores the last filter rinse timestamp.
					   if let lastFilterRinseTime = json["FRIN"] as? TimeInterval {
						   times.frin = Date().daysFrom(timestamp: lastFilterRinseTime)
					   }
					   
					   // Stores the filter rinse interval.
					   if let filterRinseInterval = json["FRINI"] as? Int {
						   times.frini = filterRinseInterval
					   }
					   
					   // Stores the total heating time.
					   if let totalHeatingTime = json["HEATINGTIME"] as? TimeInterval {
						   times.heatingtime = totalHeatingTime
					   }
					   
					   // Stores the total HydroJet time.
					   if let totalHydroJetTime = json["JETTIME"] as? TimeInterval {
						   times.jettime = totalHydroJetTime
					   }
					   
					   // Stores the estimated total energy consumption.
					   if let totalEnergy = json["KWH"] as? Double {
						   times.kwh = totalEnergy
					   }
					   
					   // Stores the estimated daily energy consumption.
					   if let dailyEnergy = json["KWHD"] as? Double {
						   times.kwhd = dailyEnergy
					   }
					   
					   // Stores the total Pump time.
					   if let pumpTime = json["PUMPTIME"] as? TimeInterval {
						   times.pumptime = pumpTime
					   }
					   
					   // Stores the ready state.
					   if let readyState = json["RS"] as? String {
						   times.rs = readyState
					   }
					   
					   // Stores the amount of time until the Hot Tub target temperature is reached.
					   if let timeToReady = json["T2R"] as? Double {
						   let timeToReady = timeConverter.doubleConverter(timeToReady)
						   times.t2r = timeToReady
					   }
					   
					   // Stores the ESP8266 module time.
					   if let moduleTime = json["TIME"] as? TimeInterval {
						   times.time = moduleTime
					   }
					   
					   // Stores the total ESP8266 module uptime.
					   if let moduleUptime = json["UPTIME"] as? TimeInterval {
						   times.uptime = moduleUptime
					   }
					   
					   // Stores the estimated current power consumption.
					   if let currentConsumption = json["WATT"] as? Int {
						   times.watt = currentConsumption
					   }
				   default:
					   break
				   }
			   }
			} catch {
				print("JSON Parsing Error: \(error)")
		}
	}
	
	func sendCommand(
		webSocketTask: URLSessionWebSocketTask?,
		cmd: String,
		value: Any = 0
	) {
		print(cmd)
		
		// Command mappings - using the actual numeric values from your JavaScript
		let cmdMap: [String: Int] = [
			"setTarget": 0,
			"setTargetSelector": 0,
			"toggleUnit": 1,
			"toggleBubbles": 2,
			"toggleHeater": 3,
			"togglePump": 4,           
			"restartEsp": 6,
			"resetTotals": 8,
			"resetTimerChlorine": 9,
			"resetTimerReplaceFilter": 10,
			"toggleHydroJets": 11,
			"setBrightness": 12,
			"setBrightnessSelector": 12,
			"setBeep": 13,
			"setAmbientF": 14,
			"setAmbient": 15,
			"setAmbientSelector": 15,
			"setAmbientC": 15,
			"resetDaily": 16,
			"toggleGodmode": 17,
			"setFullpower": 18,
			"printText": 19,
			"setReady": 20,
			"setR": 21,
			"resetTimerRinseFilter": 22,
			"resetTimerCleanFilter": 23
		]
		
		// Check if command is valid
		guard let mappedCmd = cmdMap[cmd] else {
			print("invalid command")
			return
		}
		
		// Create command object
		let commandObj: [String: Any] = [
			"CMD": mappedCmd,
			"VALUE": value,
			"XTIME": Int(Date().timeIntervalSince1970),
			"INTERVAL": 0,
			"TXT": ""
		]
		
		// Convert to JSON and send
		do {
			let jsonData = try JSONSerialization.data(withJSONObject: commandObj, options: [])
			if let jsonString = String(data: jsonData, encoding: .utf8) {
				let message = URLSessionWebSocketTask.Message.string(jsonString)
				webSocketTask?.send(message) { error in
					if let error = error {
						print("WebSocket send error: \(error)")
					} else {
						print("Sent: \(jsonString)")
					}
				}
			}
		} catch {
			print("JSON encoding error: \(error)")
		}
	}
}
