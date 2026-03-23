import Foundation
import StoreKit

@Observable
final class SubscriptionManager {

    static let annualProductID = "com.screenstash.pro.annual"
    static let lifetimeProductID = "com.screenstash.pro.lifetime"

    private(set) var isProUser = false
    private(set) var products: [Product] = []
    private var updateListenerTask: Task<Void, Never>?

    var annualProduct: Product? {
        products.first { $0.id == Self.annualProductID }
    }

    var lifetimeProduct: Product? {
        products.first { $0.id == Self.lifetimeProductID }
    }

    func start() {
        updateListenerTask = Task { [weak self] in
            for await result in Transaction.updates {
                if case .verified = result {
                    await self?.checkEntitlements()
                }
            }
        }
        Task {
            await loadProducts()
            await checkEntitlements()
        }
    }

    deinit {
        updateListenerTask?.cancel()
    }

    func loadProducts() async {
        do {
            products = try await Product.products(for: [
                Self.annualProductID,
                Self.lifetimeProductID
            ])
        } catch {
            print("Failed to load products: \(error)")
        }
    }

    func checkEntitlements() async {
        for await result in Transaction.currentEntitlements {
            if case .verified(let transaction) = result {
                if transaction.productID == Self.annualProductID ||
                   transaction.productID == Self.lifetimeProductID {
                    isProUser = true
                    return
                }
            }
        }
        isProUser = false
    }

    @discardableResult
    func purchase(_ product: Product) async throws -> Transaction? {
        let result = try await product.purchase()

        switch result {
        case .success(let verification):
            if case .verified(let transaction) = verification {
                await transaction.finish()
                await checkEntitlements()
                return transaction
            }
            return nil

        case .userCancelled, .pending:
            return nil

        @unknown default:
            return nil
        }
    }

    func restorePurchases() async {
        try? await AppStore.sync()
        await checkEntitlements()
    }
}
