import Foundation
import StoreKit
import os
import Combine

@MainActor
class BillingManager: ObservableObject {
    @Published var isPro: Bool = false
    
    private let productId = Constants.productIdPro
    private var updatesTask: Task<Void, Never>? = nil
    private let logger = Logger(subsystem: Constants.logTagBilling, category: "Billing")
    
    init() {
        updatesTask = listenForTransactions()
        Task {
            await updatePurchasedStatus()
        }
    }
    
    deinit {
        updatesTask?.cancel()
    }
    
    private func listenForTransactions() -> Task<Void, Never> {
        Task.detached {
            for await result in Transaction.updates {
                do {
                    let transaction = try self.checkVerified(result)
                    await self.updatePurchasedStatus()
                    await transaction.finish()
                } catch {
                    self.logger.error("Transaction failed verification")
                }
            }
        }
    }
    
    func updatePurchasedStatus() async {
        for await result in Transaction.currentEntitlements {
            guard case .verified(let transaction) = result else { continue }
            if transaction.productID == productId {
                isPro = true
                return
            }
        }
        isPro = false
    }
    
    func buyPro() async {
        do {
            let products = try await Product.products(for: [productId])
            guard let product = products.first else {
                logger.error("Product \(self.productId) not found in App Store Connect")
                return
            }
            
            let result = try await product.purchase()
            
            switch result {
            case .success(let verification):
                let transaction = try checkVerified(verification)
                isPro = true
                await transaction.finish()
            case .userCancelled:
                logger.debug("User cancelled purchase")
            case .pending:
                logger.debug("Purchase pending approval")
            @unknown default:
                logger.warning("Unknown purchase result")
            }
        } catch {
            logger.error("Failed to purchase: \(error.localizedDescription)")
        }
    }
    
    nonisolated private func checkVerified<T>(_ result: VerificationResult<T>) throws -> T {
            switch result {
            case .unverified:
                throw StoreError.failedVerification
            case .verified(let safe):
                return safe
            }
        }
}

enum StoreError: Error {
    case failedVerification
}
// 90 lines in v1.1
