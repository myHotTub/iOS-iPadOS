
import StoreKit
import SwiftUI
import Observation

@MainActor
@Observable
class SubscriptionManager {
	var proYearly: Product?
	var isLoading = false
	var isPurchasing = false
	var hasActiveSubscription = false
	var isRestoring = false
	
	private let productId = "myHotTub_Pro_12_20250822"
	
	init() {
		Task {
			await loadProducts()
			await checkSubscriptionStatus()
		}
		listenForTransactions()
	}
	
	func loadProducts() async {
		guard !isLoading else { return }
		isLoading = true
		defer { isLoading = false }
		
		do {
			let products = try await Product.products(for: [productId])
			proYearly = products.first
			if let product = proYearly {
				print("💰 Price: \(product.displayPrice)")
			} else {
				print("Product not found")
			}
		} catch {
			print("Failed to fetch products: \(error)")
			proYearly = nil
		}
	}
	
	func purchaseProduct() async {
		if proYearly == nil {
			await loadProducts()
		}
		guard let product = proYearly else {
			print("Product still not loaded")
			return
		}
		
		isPurchasing = true
		defer { isPurchasing = false }
		
		do {
			let result = try await product.purchase()
			switch result {
			case .success(let verificationResult):
				switch verificationResult {
				case .verified(let transaction):
					hasActiveSubscription = true
					await transaction.finish()
				case .unverified(_, let error):
					print("Unverified transaction: \(error)")
				}
			case .userCancelled:
				print("User cancelled purchase")
			case .pending:
				print("Purchase pending")
			@unknown default:
				break
			}
		} catch {
			print("Purchase failed: \(error)")
		}
	}
	
	func checkSubscriptionStatus() async {
		for await result in Transaction.currentEntitlements {
			if case .verified(let transaction) = result,
			   transaction.productID == productId {
				hasActiveSubscription = true
				return
			}
		}
		hasActiveSubscription = false
	}
	
	func restorePurchases() async {
		isRestoring = true
		defer { isRestoring = false }
		
		do {
			try await AppStore.sync()
			await checkSubscriptionStatus()
		} catch {
			print("Failed to restore purchases: \(error)")
		}
	}
	
	private func listenForTransactions() {
		Task {
			for await result in Transaction.updates {
				switch result {
				case .verified(let transaction):
					if transaction.productID == productId {
						hasActiveSubscription = true
					}
					await transaction.finish()
				case .unverified(_, let error):
					print("Unverified transaction: \(error)")
				}
			}
		}
	}
}
