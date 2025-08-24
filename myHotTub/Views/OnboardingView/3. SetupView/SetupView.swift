
import SwiftUI
import Network

struct SetupView: View {
	let goNext: () -> Void
	
	@State private var currentStep                 = 0
	@State private var isCheckingNetworkPermission = false
	@State private var hasNetworkPermission        = false
	@State private var showingAlert                = false
	
	private let steps = [
		SetupStep(
			icon: "wifi.circle.fill",
			title: "Connect to Wi-Fi",
			description: "Make sure your \(UIDevice.current.model) is connected to the same Wi-Fi network as your Hot Tub controller.",
			actionTitle: "I'm Connected"
		),
		SetupStep(
			icon: "network",
			title: "Allow Network Access",
			description: "We need permission to find the ESP8266 module on your local network. Everything remains private and secure.",
			actionTitle: "Grant Permission"
		),
		SetupStep(
			icon: "magnifyingglass.circle.fill",
			title: "Searching for the Module",
			description: "We'll automatically find your ESP8266 module on your network.",
			actionTitle: "Start Search"
		)
	]
	
	var body: some View {
		ZStack {
			VStack(spacing: 0) {
				// Header section
				VStack(spacing: 20) {
					Text("Quick Setup")
						.font(.largeTitle.bold())
						.foregroundStyle(Color.white)
						.multilineTextAlignment(.center)
					
					Text("Let's get you connected in just a few steps.")
						.foregroundStyle(Color.white)
						.multilineTextAlignment(.center)
						.opacity(0.8)
				}
				.padding(.horizontal)
				
				Spacer()
				
				// Setup steps
				SetupStepsView(
					currentStep: currentStep,
					steps: steps,
					isCheckingNetworkPermission: isCheckingNetworkPermission,
					hasNetworkPermission: hasNetworkPermission
				)
				
				Spacer()
				
				// Footer section
				VStack(spacing: 20) {
					Button {
						handleStepAction()
					} label: {
						HStack {
							Spacer()
							
							if isCheckingNetworkPermission {
								ProgressView()
									.progressViewStyle(CircularProgressViewStyle(tint: .white))
									.scaleEffect(0.8)
								Text("Checking Permission...")
									.font(.title3.bold())
									.foregroundStyle(Color.white)
							} else {
								Text(steps[currentStep].actionTitle)
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
						.shadow(color: .orange.opacity(0.4), radius: 8, x: 0, y: 4)
					}
					.disabled(isCheckingNetworkPermission)
					.padding(.bottom, hasHomeButton() ? 50 : 20)
				}
			}
			.padding(.horizontal)
		}
		.alert("Local Network Permission Required", isPresented: $showingAlert) {
			Button("Open Settings") {
				if let settingsUrl = URL(string: UIApplication.openSettingsURLString) {
					UIApplication.shared.open(settingsUrl)
				}
			}
			Button("Try Again") {
				checkNetworkPermission()
			}
			Button("Cancel", role: .cancel) { }
		} message: {
			Text("Please enable Local Network access in Settings > Privacy & Security > Local Network to discover your Hot Tub controller.")
		}
	}
	
	private func handleStepAction() {
		switch currentStep {
		case 0:
			// WiFi connection step
			withAnimation(.easeInOut(duration: 0.5)) {
				currentStep = 1
			}
			
		case 1:
			// Local Network permission step
			checkNetworkPermission()
			
		case 2:
			goNext()
			
		default:
			break
		}
	}
	
	private func checkNetworkPermission() {
		isCheckingNetworkPermission = true
		
		// Use a more reliable method to trigger Local Network permission
		Task {
			await triggerLocalNetworkPermission()
		}
	}

	@MainActor
	private func triggerLocalNetworkPermission() async {
		let connection = NWConnection(
			to: .hostPort(host: "224.0.0.251", port: 5353),
			using: .udp
		)
		
		var hasCompleted = false
		
		connection.stateUpdateHandler = { [weak connection] state in
			DispatchQueue.main.async {
				guard !hasCompleted else { return }
				
				switch state {
				case .ready:
					hasCompleted = true
					self.isCheckingNetworkPermission = false
					self.hasNetworkPermission = true
					
					// Small delay to show success state
					DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
						withAnimation(.easeInOut(duration: 0.5)) {
							self.currentStep = 2
						}
					}
					connection?.cancel()
					
				case .failed(let error):
					hasCompleted = true
					self.isCheckingNetworkPermission = false
					print(error)
					let monitor = NWPathMonitor()
					let queue = DispatchQueue(label: "NetworkCheck")
					
					monitor.pathUpdateHandler = { path in
						DispatchQueue.main.async {
							if path.status == .satisfied {
								self.hasNetworkPermission = true
								DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
									withAnimation(.easeInOut(duration: 0.5)) {
										self.currentStep = 2
									}
								}
							} else {
								self.showingAlert = true
							}
						}
						monitor.cancel()
					}
					monitor.start(queue: queue)
					connection?.cancel()
					
				case .cancelled:
					break
					
				default:
					break
				}
			}
		}
		
		// Start the connection on a background queue
		connection.start(queue: DispatchQueue.global(qos: .userInitiated))
		
		// Set a timeout to prevent hanging
		DispatchQueue.main.asyncAfter(deadline: .now() + 5.0) {
			if !hasCompleted {
				hasCompleted = true
				self.isCheckingNetworkPermission = false
				
				// Check if Local Network is available even if connection timed out
				let monitor = NWPathMonitor()
				let queue = DispatchQueue(label: "NetworkTimeoutCheck")
				
				monitor.pathUpdateHandler = { path in
					DispatchQueue.main.async {
						if path.status == .satisfied {
							// Assume permission was granted if we can see network paths
							self.hasNetworkPermission = true
							DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
								withAnimation(.easeInOut(duration: 0.5)) {
									self.currentStep = 2
								}
							}
						} else {
							self.showingAlert = true
						}
					}
					monitor.cancel()
				}
				monitor.start(queue: queue)
				connection.cancel()
			}
		}
	}
	
	func hasHomeButton() -> Bool {
		guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
			  let window = windowScene.windows.first else {
			return false
		}
		return window.safeAreaInsets.bottom == 0
	}
}

struct SetupStep {
	let icon: String
	let title: String
	let description: String
	let actionTitle: String
}

struct SetupStepsView: View {
	let currentStep: Int
	let steps: [SetupStep]
	let isCheckingNetworkPermission: Bool
	let hasNetworkPermission: Bool
	
	var body: some View {
		VStack(spacing: 30) {
			ForEach(Array(steps.enumerated()), id: \.offset) { index, step in
				HStack(spacing: 16) {
					// Step indicator
					ZStack {
						Circle()
							.fill(stepBackgroundColor(for: index))
							.frame(width: 50, height: 50)
						
						if index < currentStep || (index == 1 && hasNetworkPermission) {
							Image(systemName: "checkmark")
								.font(.title2.bold())
								.foregroundStyle(.white)
						} else if index == currentStep && isCheckingNetworkPermission {
							ProgressView()
								.progressViewStyle(CircularProgressViewStyle(tint: .blue))
								.scaleEffect(0.8)
						} else {
							Image(systemName: step.icon)
								.font(.title2)
								.foregroundStyle(stepIconColor(for: index))
						}
					}
					
					// Step content
					VStack(alignment: .leading, spacing: 8) {
						Text(step.title)
							.font(.headline.bold())
							.foregroundStyle(stepTitleColor(for: index))
						
						Text(step.description)
							.font(.subheadline)
							.foregroundStyle(stepDescriptionColor(for: index))
							.fixedSize(horizontal: false, vertical: true)
					}
					
					Spacer()
				}
				.padding(.horizontal)
				.opacity(stepOpacity(for: index))
				.scaleEffect(stepScale(for: index))
				.animation(.easeInOut(duration: 0.3), value: currentStep)
				.animation(.easeInOut(duration: 0.3), value: hasNetworkPermission)
			}
		}
	}
	
	private func stepBackgroundColor(for index: Int) -> Color {
		if index < currentStep || (index == 1 && hasNetworkPermission) {
			return .green
		} else if index == currentStep {
			return .white
		} else {
			return .white.opacity(0.3)
		}
	}
	
	private func stepIconColor(for index: Int) -> Color {
		let bg = stepBackgroundColor(for: index)
		if bg == .white {
			return .blue
		}
		if index == currentStep {
			return .blue
		} else {
			return .white.opacity(0.7)
		}
	}
	
	private func stepTitleColor(for index: Int) -> Color {
		if index <= currentStep {
			return .white
		} else {
			return .white.opacity(0.6)
		}
	}
	
	private func stepDescriptionColor(for index: Int) -> Color {
		if index <= currentStep {
			return .white.opacity(0.8)
		} else {
			return .white.opacity(0.5)
		}
	}
	
	private func stepOpacity(for index: Int) -> Double {
		if index <= currentStep {
			return 1.0
		} else {
			return 0.6
		}
	}
	
	private func stepScale(for index: Int) -> Double {
		if index == currentStep {
			return 1.05
		} else {
			return 1.0
		}
	}
}

#Preview {
	SetupView(goNext: {})
}
