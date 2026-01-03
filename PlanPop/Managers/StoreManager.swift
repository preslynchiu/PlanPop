//
//  StoreManager.swift
//  PlanPop
//
//  Handles all StoreKit 2 in-app purchase operations
//

import Foundation
import StoreKit

/// Purchase states for UI feedback
enum PurchaseState: Equatable {
    case idle
    case loading
    case purchasing
    case purchased
    case failed(String)
    case pending

    static func == (lhs: PurchaseState, rhs: PurchaseState) -> Bool {
        switch (lhs, rhs) {
        case (.idle, .idle), (.loading, .loading), (.purchasing, .purchasing),
             (.purchased, .purchased), (.pending, .pending):
            return true
        case (.failed(let a), .failed(let b)):
            return a == b
        default:
            return false
        }
    }
}

/// Custom errors for store operations
enum StoreError: LocalizedError {
    case productNotFound
    case purchaseFailed
    case verificationFailed
    case userCancelled
    case networkError
    case unknown

    var errorDescription: String? {
        switch self {
        case .productNotFound:
            return "The product could not be found."
        case .purchaseFailed:
            return "The purchase could not be completed."
        case .verificationFailed:
            return "The purchase could not be verified."
        case .userCancelled:
            return "The purchase was cancelled."
        case .networkError:
            return "Please check your internet connection."
        case .unknown:
            return "An unknown error occurred."
        }
    }
}

/// Manages all StoreKit 2 in-app purchase operations
@MainActor
class StoreManager: ObservableObject {
    // MARK: - Singleton

    static let shared = StoreManager()

    // MARK: - Product IDs

    static let premiumLifetimeID = "com.planpop.app.premium.lifetime"

    // MARK: - Published Properties

    /// The premium product from StoreKit
    @Published private(set) var premiumProduct: Product?

    /// Current purchase state for UI feedback
    @Published private(set) var purchaseState: PurchaseState = .idle

    /// Whether the user has purchased premium
    @Published private(set) var isPremiumPurchased: Bool = false

    /// Formatted price string for display
    var priceString: String {
        premiumProduct?.displayPrice ?? "$4.99"
    }

    // MARK: - Private Properties

    /// Transaction listener task
    private var transactionListener: _Concurrency.Task<Void, Error>?

    // MARK: - Initialization

    private init() {
        // Start listening for transactions immediately
        transactionListener = listenForTransactions()

        // Load products and check entitlements on init
        _Concurrency.Task {
            await loadProducts()
            await updatePurchasedStatus()
        }
    }

    deinit {
        transactionListener?.cancel()
    }

    // MARK: - Product Loading

    /// Load products from App Store
    func loadProducts() async {
        purchaseState = .loading

        do {
            let products = try await Product.products(for: [Self.premiumLifetimeID])

            if let product = products.first {
                premiumProduct = product
                purchaseState = .idle
            } else {
                purchaseState = .failed(StoreError.productNotFound.localizedDescription)
            }
        } catch {
            purchaseState = .failed(StoreError.networkError.localizedDescription)
            print("Failed to load products: \(error)")
        }
    }

    // MARK: - Purchase

    /// Purchase the premium lifetime unlock
    func purchasePremium() async {
        guard let product = premiumProduct else {
            purchaseState = .failed(StoreError.productNotFound.localizedDescription)
            return
        }

        purchaseState = .purchasing

        do {
            let result = try await product.purchase()

            switch result {
            case .success(let verification):
                // Verify the transaction
                let transaction = try checkVerified(verification)

                // Update premium status
                await updatePurchasedStatus()

                // Finish the transaction
                await transaction.finish()

                purchaseState = .purchased

            case .userCancelled:
                purchaseState = .idle

            case .pending:
                // Transaction is pending (e.g., Ask to Buy)
                purchaseState = .pending

            @unknown default:
                purchaseState = .failed(StoreError.unknown.localizedDescription)
            }
        } catch {
            purchaseState = .failed(error.localizedDescription)
            print("Purchase failed: \(error)")
        }
    }

    // MARK: - Restore Purchases

    /// Restore previous purchases
    func restorePurchases() async {
        purchaseState = .loading

        do {
            // Sync with App Store
            try await AppStore.sync()

            // Update status based on current entitlements
            await updatePurchasedStatus()

            if isPremiumPurchased {
                purchaseState = .purchased
            } else {
                purchaseState = .idle
            }
        } catch {
            purchaseState = .failed(error.localizedDescription)
            print("Restore failed: \(error)")
        }
    }

    // MARK: - Entitlement Checking

    /// Update the purchased status by checking current entitlements
    func updatePurchasedStatus() async {
        // Check for existing verified transaction
        for await result in Transaction.currentEntitlements {
            if case .verified(let transaction) = result {
                if transaction.productID == Self.premiumLifetimeID {
                    isPremiumPurchased = true
                    // Sync with UserSettings
                    syncPremiumStatusWithSettings(true)
                    return
                }
            }
        }

        isPremiumPurchased = false
        syncPremiumStatusWithSettings(false)
    }

    // MARK: - Transaction Listener

    /// Listen for transaction updates (handles Ask to Buy, family sharing, etc.)
    private func listenForTransactions() -> _Concurrency.Task<Void, Error> {
        return _Concurrency.Task.detached {
            for await result in Transaction.updates {
                do {
                    let transaction = try await self.checkVerified(result)

                    // Update purchase status on main actor
                    await self.updatePurchasedStatus()

                    // Finish the transaction
                    await transaction.finish()
                } catch {
                    print("Transaction verification failed: \(error)")
                }
            }
        }
    }

    // MARK: - Verification Helper

    /// Verify a transaction result
    private func checkVerified<T>(_ result: VerificationResult<T>) throws -> T {
        switch result {
        case .unverified(_, let error):
            throw error
        case .verified(let safe):
            return safe
        }
    }

    // MARK: - Settings Sync

    /// Sync premium status with PersistenceManager/UserSettings
    private func syncPremiumStatusWithSettings(_ isPremium: Bool) {
        var settings = PersistenceManager.shared.loadSettings()
        if settings.isPremium != isPremium {
            settings.isPremium = isPremium
            PersistenceManager.shared.saveSettings(settings)
        }
    }

    // MARK: - Reset State

    /// Reset purchase state to idle (for dismissing error states)
    func resetState() {
        purchaseState = .idle
    }
}
