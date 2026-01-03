//
//  StoreManager.swift
//  PlanPop
//
//  Handles all StoreKit 2 in-app purchase operations
//

import Foundation
import StoreKit

/// Type alias to disambiguate from app's Task model
private typealias ConcurrencyTask = _Concurrency.Task

/// Purchase states for UI feedback
enum PurchaseState: Equatable {
    case idle
    case loading
    case purchasing
    case purchased
    case failed(String)
    case pending
    case restored  // New state to distinguish successful restore

    static func == (lhs: PurchaseState, rhs: PurchaseState) -> Bool {
        switch (lhs, rhs) {
        case (.idle, .idle), (.loading, .loading), (.purchasing, .purchasing),
             (.purchased, .purchased), (.pending, .pending), (.restored, .restored):
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
    case purchaseInProgress
    case unknown

    var errorDescription: String? {
        switch self {
        case .productNotFound:
            return "The product could not be found. Please try again later."
        case .purchaseFailed:
            return "The purchase could not be completed. Please try again."
        case .verificationFailed:
            return "The purchase could not be verified. Please contact support."
        case .userCancelled:
            return "The purchase was cancelled."
        case .networkError:
            return "Please check your internet connection and try again."
        case .purchaseInProgress:
            return "A purchase is already in progress."
        case .unknown:
            return "An unknown error occurred. Please try again."
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
    private var transactionListener: ConcurrencyTask<Void, Never>?

    /// Flag to prevent concurrent status updates
    private var isUpdatingStatus: Bool = false

    /// Flag to prevent concurrent purchases
    private var isPurchasing: Bool = false

    /// Retry count for product loading
    private var productLoadRetryCount: Int = 0
    private let maxProductLoadRetries: Int = 3

    // MARK: - Initialization

    private init() {
        // Start listening for transactions on MainActor
        transactionListener = ConcurrencyTask { [weak self] in
            await self?.listenForTransactions()
        }

        // Load products and check entitlements on init
        ConcurrencyTask { [weak self] in
            await self?.loadProducts()
            await self?.updatePurchasedStatus()
        }
    }

    deinit {
        transactionListener?.cancel()
    }

    // MARK: - Product Loading

    /// Load products from App Store with retry mechanism
    func loadProducts() async {
        // Don't show loading state on retry
        if productLoadRetryCount == 0 {
            purchaseState = .loading
        }

        do {
            let products = try await Product.products(for: [Self.premiumLifetimeID])

            if let product = products.first {
                // Validate that product ID matches what we expect
                guard product.id == Self.premiumLifetimeID else {
                    purchaseState = .failed(StoreError.productNotFound.localizedDescription)
                    return
                }
                premiumProduct = product
                purchaseState = .idle
                productLoadRetryCount = 0  // Reset retry count on success
            } else {
                purchaseState = .failed(StoreError.productNotFound.localizedDescription)
            }
        } catch {
            print("Failed to load products: \(error)")

            // Retry with exponential backoff
            if productLoadRetryCount < maxProductLoadRetries {
                productLoadRetryCount += 1
                let delay = UInt64(pow(2.0, Double(productLoadRetryCount))) * 1_000_000_000  // seconds to nanoseconds
                try? await ConcurrencyTask<Never, Never>.sleep(nanoseconds: delay)
                await loadProducts()
            } else {
                purchaseState = .failed(StoreError.networkError.localizedDescription)
                productLoadRetryCount = 0  // Reset for manual retry
            }
        }
    }

    /// Manually retry loading products
    func retryLoadProducts() async {
        productLoadRetryCount = 0
        await loadProducts()
    }

    // MARK: - Purchase

    /// Purchase the premium lifetime unlock
    func purchasePremium() async {
        // Guard against double purchase
        guard !isPurchasing else {
            purchaseState = .failed(StoreError.purchaseInProgress.localizedDescription)
            return
        }

        // Already premium? Don't purchase again
        guard !isPremiumPurchased else {
            purchaseState = .purchased
            return
        }

        guard let product = premiumProduct else {
            purchaseState = .failed(StoreError.productNotFound.localizedDescription)
            return
        }

        isPurchasing = true
        purchaseState = .purchasing

        defer {
            isPurchasing = false
        }

        do {
            let result = try await product.purchase()

            switch result {
            case .success(let verification):
                // Verify the transaction
                let transaction = try checkVerified(verification)

                // Update premium status BEFORE finishing transaction
                // to ensure we persist the purchase
                await updatePurchasedStatus()

                // Only finish transaction after confirming status update
                if isPremiumPurchased {
                    await transaction.finish()
                    purchaseState = .purchased
                } else {
                    // Status didn't update - try direct sync
                    isPremiumPurchased = true
                    syncPremiumStatusWithSettings(true)
                    await transaction.finish()
                    purchaseState = .purchased
                }

            case .userCancelled:
                purchaseState = .idle

            case .pending:
                // Transaction is pending (e.g., Ask to Buy)
                purchaseState = .pending

            @unknown default:
                purchaseState = .failed(StoreError.unknown.localizedDescription)
            }
        } catch {
            purchaseState = .failed(StoreError.purchaseFailed.localizedDescription)
            print("Purchase failed: \(error)")
        }
    }

    // MARK: - Restore Purchases

    /// Restore previous purchases
    func restorePurchases() async {
        // Already premium? Just confirm
        if isPremiumPurchased {
            purchaseState = .purchased
            return
        }

        purchaseState = .loading

        do {
            // Sync with App Store
            try await AppStore.sync()

            // Update status based on current entitlements
            await updatePurchasedStatus()

            if isPremiumPurchased {
                purchaseState = .restored
            } else {
                // Restore succeeded but no purchases found
                purchaseState = .idle
            }
        } catch {
            purchaseState = .failed("Could not connect to App Store. Please check your connection and try again.")
            print("Restore failed: \(error)")
        }
    }

    // MARK: - Entitlement Checking

    /// Update the purchased status by checking current entitlements
    func updatePurchasedStatus() async {
        // Prevent concurrent updates
        guard !isUpdatingStatus else { return }
        isUpdatingStatus = true

        defer {
            isUpdatingStatus = false
        }

        // Check for existing verified transaction
        for await result in Transaction.currentEntitlements {
            if case .verified(let transaction) = result {
                if transaction.productID == Self.premiumLifetimeID {
                    // Only update if different to prevent unnecessary saves
                    if !isPremiumPurchased {
                        isPremiumPurchased = true
                        syncPremiumStatusWithSettings(true)
                    }
                    return
                }
            }
        }

        // No premium entitlement found
        if isPremiumPurchased {
            isPremiumPurchased = false
            syncPremiumStatusWithSettings(false)
        }
    }

    // MARK: - Transaction Listener

    /// Listen for transaction updates (handles Ask to Buy, family sharing, etc.)
    private func listenForTransactions() async {
        // Listen on MainActor to avoid threading issues
        for await result in Transaction.updates {
            do {
                let transaction = try checkVerified(result)

                // Update purchase status
                await updatePurchasedStatus()

                // Finish the transaction
                await transaction.finish()

                // Update UI state if we became premium
                if isPremiumPurchased && purchaseState != .purchased {
                    purchaseState = .purchased
                }
            } catch {
                print("Transaction verification failed: \(error)")
                // Don't finish unverified transactions
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
        // Use atomic update to prevent race conditions
        PersistenceManager.shared.updateSettings { settings in
            if settings.isPremium != isPremium {
                settings.isPremium = isPremium
            }
        }
    }

    // MARK: - Reset State

    /// Reset purchase state to idle (for dismissing error states)
    func resetState() {
        purchaseState = .idle
    }
}
