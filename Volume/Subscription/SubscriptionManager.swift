import Foundation
import OSLog
import StoreKit

/// StoreKit 2 entitlement handling: load products, listen for transactions, know whether
/// the user currently has access.
@MainActor
@Observable
final class SubscriptionManager {

    enum Status: Equatable {
        /// Still checking. The UI must not show a paywall in this state or a subscriber
        /// gets a paywall flash on every cold launch.
        case loading
        case subscribed
        /// Was a subscriber, isn't now. Data stays put; only the UI is gated.
        case expired
        case never
    }

    static let monthlyID = "com.volume.pro.monthly"
    static let annualID = "com.volume.pro.annual"
    static let productIDs: Set<String> = [monthlyID, annualID]

    private static let log = Logger(subsystem: "com.volume.app", category: "storekit")

    private(set) var products: [Product] = []
    private(set) var status: Status = .loading
    private(set) var isWorking = false
    private(set) var productLoadFailed = false
    var errorMessage: String?

    private var updatesTask: Task<Void, Never>?

    var isSubscribed: Bool { status == .subscribed }

    var monthly: Product? { products.first { $0.id == Self.monthlyID } }
    var annual: Product? { products.first { $0.id == Self.annualID } }

    init() {
        // Started before anything else and held for the lifetime of the app, so a
        // renewal, refund or Ask-to-Buy approval that lands while the app is running is
        // picked up rather than waiting for the next launch.
        updatesTask = Task { [weak self] in
            for await update in Transaction.updates {
                await self?.handle(update)
            }
        }
        Task { await refresh() }
    }

    // No `deinit` cancellation: this object is created by `VolumeApp` and lives for the
    // whole process, and a `deinit` can't touch main-actor state anyway. The listener is
    // meant to outlive every view.

    func refresh() async {
        await loadProducts()
        await refreshEntitlements()
    }

    // MARK: - Products

    func loadProducts() async {
        do {
            let loaded = try await Product.products(for: Self.productIDs)
            // Annual first — it's the better value and the default selection.
            products = loaded.sorted { lhs, _ in lhs.id == Self.annualID }
            productLoadFailed = loaded.isEmpty
            if loaded.isEmpty {
                Self.log.warning("No StoreKit products returned. Check the product IDs and the .storekit file wired into the scheme.")
            }
        } catch {
            productLoadFailed = true
            Self.log.error("Product load failed: \(error.localizedDescription, privacy: .public)")
        }
    }

    /// Whether the 7-day free trial is still available to this account.
    func isEligibleForTrial(_ product: Product) async -> Bool {
        guard let subscription = product.subscription else { return false }
        guard subscription.introductoryOffer != nil else { return false }
        return await subscription.isEligibleForIntroOffer
    }

    // MARK: - Entitlements

    func refreshEntitlements() async {
        var isActive = false
        for await result in Transaction.currentEntitlements {
            guard case .verified(let transaction) = result,
                  Self.productIDs.contains(transaction.productID) else { continue }
            let unexpired = transaction.expirationDate.map { $0 > Date() } ?? true
            if transaction.revocationDate == nil && unexpired {
                isActive = true
            }
        }

        if isActive {
            status = .subscribed
            return
        }

        // Distinguish "lapsed" from "never subscribed" so the user sees a resubscribe
        // screen rather than a first-run paywall. Expired subscriptions drop out of
        // `currentEntitlements`, so this has to look at the full history.
        var hasHistory = false
        for await result in Transaction.all {
            guard case .verified(let transaction) = result,
                  Self.productIDs.contains(transaction.productID) else { continue }
            hasHistory = true
            break
        }
        status = hasHistory ? .expired : .never
    }

    // MARK: - Purchase & restore

    func purchase(_ product: Product) async {
        guard !isWorking else { return }
        isWorking = true
        errorMessage = nil
        defer { isWorking = false }

        do {
            switch try await product.purchase() {
            case .success(let verification):
                switch verification {
                case .verified(let transaction):
                    await transaction.finish()
                    await refreshEntitlements()
                    Haptics.newRecord()
                case .unverified:
                    errorMessage = "That purchase couldn't be verified. Nothing was charged."
                }
            case .userCancelled:
                break
            case .pending:
                errorMessage = "Your purchase needs approval before it can finish."
            @unknown default:
                break
            }
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func restore() async {
        guard !isWorking else { return }
        isWorking = true
        errorMessage = nil
        defer { isWorking = false }

        do {
            try await AppStore.sync()
            await refreshEntitlements()
            if status != .subscribed {
                errorMessage = "No active subscription found on this Apple Account."
            }
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    private func handle(_ result: VerificationResult<Transaction>) async {
        guard case .verified(let transaction) = result else { return }
        await transaction.finish()
        await refreshEntitlements()
    }
}
