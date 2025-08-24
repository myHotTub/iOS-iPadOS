
import SwiftUI
import Network

struct SearchingView: View {
//	#if DEBUG
//	@State private var debugState: SearchState? = .notFound  // Change this to test different states
//	#endif
	
	let goNext: () -> Void
	
	@Environment(ContentManager.self) var contentManager
	
	@State private var searchState: SearchState         = .searching
	@State private var foundDevices: [DiscoveredDevice] = []
	@State private var selectedDevice: DiscoveredDevice?
	@State private var searchProgress: Double           = 0.0
	@State private var searchText: String               = "Scanning your network..."
	@State private var showingManualSetup               = false
	
	private let maxSearchTime: Double = 15.0
	
	var body: some View {
		ZStack {
			VStack(spacing: 0) {
				// Header section
				VStack(spacing: 20) {
					Text(searchState.title)
						.font(.largeTitle.bold())
						.foregroundStyle(Color.white)
						.multilineTextAlignment(.center)
						.animation(.easeInOut(duration: 0.5), value: searchState)
					
					Text(searchState.subtitle)
						.foregroundStyle(Color.white)
						.multilineTextAlignment(.center)
						.opacity(0.8)
						.animation(.easeInOut(duration: 0.5), value: searchState)
				}
				.padding(.horizontal)
				
				Spacer()
				
				// Main content area
				Group {
					switch searchState {
					case .searching:
						SearchingContentView(
							progress: searchProgress,
							searchText: searchText
						)
					case .found:
						DevicesFoundView(
							devices: foundDevices,
							selectedDevice: $selectedDevice
						)
					case .notFound:
						NotFoundContentView(
							showManualSetup: $showingManualSetup
						)
					}
				}
				.padding(.horizontal)
				
				Spacer()
				
				// Footer section
				VStack(spacing: 20) {
					Button {
						handleMainAction()
					} label: {
						HStack {
							Spacer()
							
							Text(searchState.actionTitle)
								.font(.title3.bold())
								.foregroundStyle(Color.white)
							
							Spacer()
						}
						.padding()
						.background(
							LinearGradient(
								colors: searchState == .searching ?
									[.gray.opacity(0.6), .gray.opacity(0.8)] :
									[.orange, .red.opacity(0.8)],
								startPoint: .leading,
								endPoint: .trailing
							)
						)
						.cornerRadius(25)
						.shadow(
							color: searchState == .searching ? .clear : .orange.opacity(0.4),
							radius: 8, x: 0, y: 4
						)
					}
					.disabled(searchState == .searching)
				}
				.padding(.bottom, hasHomeButton() ? 50 : 20)
			}
			.padding(.horizontal)
		}
		.onAppear {
			startDeviceSearch()
		}
//		.onAppear {
//			#if DEBUG
//			if let debugState = debugState {
//				searchState = debugState
//				if debugState == .found {
//					foundDevices = [DiscoveredDevice(id: UUID(), name: "Debug Device", hostName: "debug.local", ipAddress: "192.168.1.99", signalStrength: -50)]
//					selectedDevice = foundDevices.first
//				}
//				return
//			}
//			#endif
//			startDeviceSearch()
//		}
		.sheet(isPresented: $showingManualSetup) {
			ManualSetupView(
				onComplete: { device in
					// Handle manual device setup
					selectedDevice = device
					searchState = .found
					foundDevices = [device]
				},
				onCancel: {
					showingManualSetup = false
				}
			)
			.environment(contentManager)
		}
	}
	
	private func handleMainAction() {
		switch searchState {
		case .searching:
			break // Disabled during search
		case .found:
			if selectedDevice != nil {
				goNext()
			}
		case .notFound:
			showingManualSetup = true
		}
	}
	
	private func startDeviceSearch() {
		searchState = .searching
		searchProgress = 0.0
		foundDevices = []
		
		Task {
			await performDeviceSearch()
		}
	}
	
	@MainActor
	private func performDeviceSearch() async {
		let searchTexts = [
			"Scanning your network...",
			"Looking for ESP8266 modules...",
			"Checking for Hot Tub controllers...",
			"Almost done..."
		]
		
		if contentManager.connectionManager.configuration.userIp.isEmpty {
			contentManager.establishConnection(urlType: .moduleDefault)
		} else {
			contentManager.establishConnection(urlType: .userDefined)
		}
				
		// Animate search progress
		for i in 0..<Int(maxSearchTime) {
			try? await Task.sleep(for: .seconds(1))
			
			let progress = Double(i + 1) / maxSearchTime
			withAnimation(.easeInOut(duration: 0.5)) {
				searchProgress = progress
			}
			
			// Update search text periodically
			if i % 4 == 0 && i / 4 < searchTexts.count {
				withAnimation(.easeInOut(duration: 0.3)) {
					searchText = searchTexts[i / 4]
				}
			}
			
			// Simulate finding devices at random times
			if i == 3 && foundDevices.isEmpty {
				let foundModule = DiscoveredDevice(
					id: UUID(),
					name: "Hot Tub Module",
					hostName: "layzspa.local",
					ipAddress: "\(contentManager.other.ip ?? "")",
					signalStrength: contentManager.other.rssi
				)
				foundDevices.append(foundModule)
			}
		}
		
		// Determine final state
		withAnimation(.easeInOut(duration: 0.5)) {
			if foundDevices.isEmpty {
				searchState = .notFound
			} else {
				searchState = .found
				selectedDevice = foundDevices.first
			}
		}
	}
	
	// Used to add padding for devices with a physical Home Button
	func hasHomeButton() -> Bool {
		guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
			  let window = windowScene.windows.first else {
			return false
		}
		return window.safeAreaInsets.bottom == 0
	}
}

// MARK: - Search States
enum SearchState {
	case searching
	case found
	case notFound
	
	var title: String {
		switch self {
		case .searching:
			return "Finding Your Controller"
		case .found:
			return "Controller Found!"
		case .notFound:
			return "No Controller Found"
		}
	}
	
	var subtitle: String {
		switch self {
		case .searching:
			return "We're scanning your network for ESP8266 modules."
		case .found:
			return "We found your Hot Tub controller. Select it to continue."
		case .notFound:
			return "We couldn't find any controllers. Let's try manual setup."
		}
	}
	
	var actionTitle: String {
		switch self {
		case .searching:
			return "Searching..."
		case .found:
			return "Connect to Controller"
		case .notFound:
			return "Manual Setup"
		}
	}
}

// MARK: - Device Model
struct DiscoveredDevice: Identifiable, Hashable {
	let id: UUID
	let name: String
	let hostName: String
	let ipAddress: String
	let signalStrength: Int // dBm
	
	var signalQuality: String {
		switch signalStrength {
		case -60...0:
			return "Excellent"
		case -70...(-61):
			return "Good"
		case -80...(-71):
			return "Fair"
		default:
			return "---"
		}
	}
	
	var signalIcon: String {
		switch signalStrength {
		case -60...0:
			return "wifi"
		case -70...(-61):
			return "wifi"
		case -80...(-71):
			return "wifi"
		default:
			return "wifi.slash"
		}
	}
}

// MARK: - Content Views
struct SearchingContentView: View {
	let progress: Double
	let searchText: String
	
	var body: some View {
		VStack(spacing: 40) {
			// Animated search icon
			ZStack {
				Circle()
					.stroke(Color.white.opacity(0.2), lineWidth: 4)
					.frame(width: 120, height: 120)
				
				Circle()
					.trim(from: 0, to: progress)
					.stroke(Color.white, style: StrokeStyle(lineWidth: 4, lineCap: .round))
					.frame(width: 120, height: 120)
					.rotationEffect(.degrees(-90))
					.animation(.easeInOut(duration: 0.5), value: progress)
				
				Image(systemName: "wifi.circle.fill")
					.font(.system(size: 50))
					.foregroundStyle(.white)
					.scaleEffect(1.0 + sin(Date().timeIntervalSince1970 * 2) * 0.1)
					.animation(.easeInOut(duration: 1.0).repeatForever(autoreverses: true), value: progress)
			}
			
			VStack(spacing: 16) {
				Text(searchText)
					.font(.headline)
					.foregroundStyle(.white)
					.multilineTextAlignment(.center)
				
				Text("\(Int(progress * 100))%")
					.font(.title2.bold())
					.foregroundStyle(.white.opacity(0.8))
			}
		}
	}
}

struct DevicesFoundView: View {
	let devices: [DiscoveredDevice]
	@Binding var selectedDevice: DiscoveredDevice?
	
	var body: some View {
		VStack(spacing: 20) {
			Image(systemName: "checkmark.circle.fill")
				.font(.system(size: 80))
				.foregroundStyle(.green)
			
			Text("Select Your Controller")
				.font(.headline)
				.foregroundStyle(.white)
			
			LazyVStack(spacing: 12) {
				ForEach(devices) { device in
					DeviceRowView(
						device: device,
						isSelected: selectedDevice?.id == device.id
					) {
						selectedDevice = device
					}
				}
			}
		}
	}
}

struct DeviceRowView: View {
	let device: DiscoveredDevice
	let isSelected: Bool
	let onTap: () -> Void
	
	var body: some View {
		Button(action: onTap) {
			HStack(spacing: 16) {
				Image(systemName: "wifi.router.fill")
					.font(.title2)
					.foregroundStyle(.white)
					.frame(width: 30)
				
				VStack(alignment: .leading, spacing: 4) {
					Text(device.name)
						.font(.headline)
						.foregroundStyle(.white)
					
					Text(device.ipAddress)
						.font(.subheadline)
						.foregroundStyle(.white.opacity(0.7))
				}
				
				Spacer()
				
				VStack(alignment: .center, spacing: 4) {
					Image(systemName: device.signalIcon)
						.foregroundStyle(.white)
					
					Text(device.signalQuality)
						.font(.caption)
						.foregroundStyle(.white.opacity(0.7))
				}
				.padding(.horizontal)
			}
			.padding()
			.background(
				RoundedRectangle(cornerRadius: 12)
					.fill(isSelected ? Color.white.opacity(0.2) : Color.white.opacity(0.1))
					.overlay(
						RoundedRectangle(cornerRadius: 12)
							.stroke(isSelected ? Color.white : Color.white.opacity(0.3), lineWidth: isSelected ? 2 : 1)
					)
			)
		}
		.buttonStyle(PlainButtonStyle())
	}
}

struct NotFoundContentView: View {
	@Binding var showManualSetup: Bool
	
	var body: some View {
		VStack(spacing: 40) {
			Image(systemName: "wifi.exclamationmark")
				.font(.system(size: 80))
				.foregroundStyle(.orange)
			
			VStack(spacing: 16) {
				Text("Don't worry!")
					.font(.headline)
					.foregroundStyle(.white)
				
				VStack(spacing: 12) {
					Text("• Make sure your ESP8266 is powered on")
					Text("• Check that it's connected to your Wi-Fi")
					Text("• Ensure you're on the same network")
				}
				.font(.subheadline)
				.foregroundStyle(.white.opacity(0.8))
				.multilineTextAlignment(.leading)
			}
		}
	}
}

// MARK: - Manual Setup View
struct ManualSetupView: View {
	let onComplete: (DiscoveredDevice) -> Void
	let onCancel: () -> Void
	
	@AppStorage("userDefinedModuleUrl") private var userDefinedModuleUrl: String = ""
	
	@Environment(ContentManager.self) var contentManager
	@Environment(\.dismiss) private var dismiss
	
	@State private var ipAddress = ""
	@State private var deviceName = "Hot Tub Controller"
	@State private var isConnecting = false
		
	var body: some View {
		NavigationView {
			ZStack {
				LinearGradient(
					gradient: Gradient(colors: [
						Color.cyan.opacity(0.6),
						Color.blue.opacity(1)
					]),
					startPoint: .top,
					endPoint: .bottom
				)
				.edgesIgnoringSafeArea(.all)
				
				VStack(spacing: 30) {
					VStack(spacing: 16) {
						Text("Manual Setup")
							.font(.largeTitle.bold())
							.foregroundStyle(.white)
						
						Text("Enter your controller's details manually")
							.foregroundStyle(.white.opacity(0.8))
							.multilineTextAlignment(.center)
					}
					
					VStack(spacing: 20) {
						VStack(alignment: .leading, spacing: 8) {
							Text("IP Address")
								.foregroundStyle(.white)
								.font(.headline)
							
							TextField("", text: $ipAddress)
								.keyboardType(.decimalPad)
								.textFieldStyle(RoundedBorderTextFieldStyle())
						}
					}
					
					Button {
						connectManually()
					} label: {
						HStack {
							Spacer()
							
							if isConnecting {
								ProgressView()
									.progressViewStyle(CircularProgressViewStyle(tint: .white))
									.scaleEffect(0.8)
								Text("Connecting...")
									.font(.title3.bold())
									.foregroundStyle(Color.white)
							} else {
								Text("Connect")
									.font(.title3.bold())
									.foregroundStyle(Color.white)
							}
							
							Spacer()
						}
						.padding()
						.background(
							LinearGradient(
								colors: [.orange, .red.opacity(0.8)],
								startPoint: .leading,
								endPoint: .trailing
							)
						)
						.cornerRadius(25)
					}
					.disabled(ipAddress.isEmpty || isConnecting)
					
					Spacer()
				}
				.padding()
			}
			.navigationBarTitleDisplayMode(.inline)
			.toolbar {
				ToolbarItem(placement: .navigationBarLeading) {
					Button("Cancel") {
						onCancel()
					}
					.foregroundStyle(.white)
				}
			}
		}
	}
	
	private func connectManually() {
		isConnecting = true
	
		userDefinedModuleUrl                                  = ipAddress
		contentManager.connectionManager.configuration.userIp = userDefinedModuleUrl
				
		contentManager.establishConnection(urlType: .userDefined)
						
		DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
			let manualDevice = DiscoveredDevice(
				id: UUID(),
				name: deviceName,
				hostName: "layzspa.local",
				ipAddress: ipAddress,
				signalStrength: contentManager.other.rssi
			)
			
			isConnecting = false
			onComplete(manualDevice)
			
			print(contentManager.connectionMonitor.isConnected)
			
			if contentManager.connectionMonitor.isConnected {
				dismiss()
			}
		}
	}
}

#Preview {
	let contentManager = ContentManager()
	
	SearchingView(
		goNext: {}
	)
	.environment(contentManager)
}
