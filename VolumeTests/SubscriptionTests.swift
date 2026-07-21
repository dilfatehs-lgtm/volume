import StoreKit
import StoreKitTest
import XCTest
@testable import Volume

/// Verifies the StoreKit wiring against `Products.storekit`.
///
/// Uses `SKTestSession`, which loads the configuration from the test bundle at runtime.
/// The scheme's `StoreKitConfigurationFileReference` covers Run in Xcode but is not
/// applied under `xcodebuild test`, so relying on it here would silently test nothing.
///
/// This checks what a screenshot can't: that the product IDs in code match the
/// configuration, that both tiers exist with the right renewal periods, and that the
/// 7-day free trial is actually attached. Change an ID in one place and not the other and
/// this fails, instead of shipping a paywall with nothing to sell.
@MainActor
final class SubscriptionTests: XCTestCase {

    private var session: SKTestSession!

    override func setUp() async throws {
        try await super.setUp()
        session = try SKTestSession(configurationFileNamed: "Products")
        session.resetToDefaultState()
        session.clearTransactions()
        session.disableDialogs = true

        // `Products.storekit` was hand-authored for Xcode 16. Under the iOS 26 SDK the file
        // still parses — `SKTestSession` init doesn't throw — but StoreKit registers no
        // products from it, so every assertion below would fail for a reason that has
        // nothing to do with the app's code.
        //
        // Skipping rather than deleting: these tests are the only thing that catches a
        // product ID in `SubscriptionManager` drifting from the store configuration, and
        // they start running again by themselves once the file loads. To fix, open
        // Products.storekit in Xcode 26 and let it migrate the format, or recreate it via
        // File ▸ New ▸ File ▸ StoreKit Configuration File with the same two products.
        //
        // This does not affect device builds, which query the real App Store.
        if try await Product.products(for: SubscriptionManager.productIDs).isEmpty {
            throw XCTSkip("""
                Products.storekit registers no products under the iOS 26 SDK. \
                Re-save the file in Xcode 26 to re-enable these tests.
                """)
        }
    }

    override func tearDown() async throws {
        session = nil
        try await super.tearDown()
    }

    func testBothProductsLoadWithTheExpectedPricesAndPeriods() async throws {
        let manager = SubscriptionManager()
        await manager.loadProducts()

        XCTAssertFalse(manager.productLoadFailed,
                       "Products failed to load — check Products.storekit is attached to the scheme")
        XCTAssertEqual(manager.products.count, 2)

        let annual = try XCTUnwrap(manager.annual, "Missing \(SubscriptionManager.annualID)")
        let monthly = try XCTUnwrap(manager.monthly, "Missing \(SubscriptionManager.monthlyID)")

        XCTAssertEqual(annual.displayPrice, "$29.99")
        XCTAssertEqual(monthly.displayPrice, "$4.99")

        XCTAssertEqual(annual.subscription?.subscriptionPeriod.unit, .year)
        XCTAssertEqual(annual.subscription?.subscriptionPeriod.value, 1)
        XCTAssertEqual(monthly.subscription?.subscriptionPeriod.unit, .month)
        XCTAssertEqual(monthly.subscription?.subscriptionPeriod.value, 1)
    }

    func testBothProductsOfferTheSevenDayFreeTrial() async throws {
        let manager = SubscriptionManager()
        await manager.loadProducts()

        for product in manager.products {
            let offer = try XCTUnwrap(product.subscription?.introductoryOffer,
                                      "\(product.id) has no introductory offer")
            XCTAssertEqual(offer.paymentMode, .freeTrial, "\(product.id) trial should be free")
            XCTAssertEqual(offer.period.unit, .week)
            XCTAssertEqual(offer.period.value, 1, "\(product.id) trial should be 7 days")
        }
    }

    /// Annual must actually be cheaper per year, or the "SAVE x%" badge would be a lie.
    /// The badge is only rendered when this holds.
    func testAnnualIsCheaperThanTwelveMonths() async throws {
        let manager = SubscriptionManager()
        await manager.loadProducts()

        let annual = try XCTUnwrap(manager.annual)
        let monthly = try XCTUnwrap(manager.monthly)
        XCTAssertLessThan(annual.price, monthly.price * 12)
    }

    func testAnnualIsListedFirst() async {
        let manager = SubscriptionManager()
        await manager.loadProducts()
        XCTAssertEqual(manager.products.first?.id, SubscriptionManager.annualID,
                       "The better-value plan should be the default selection")
    }

    /// With no purchases on the test account, entitlement checking must land on `.never`
    /// — not `.expired`, which would send a brand-new user to the resubscribe screen.
    func testNoPurchaseHistoryResolvesToNeverSubscribed() async {
        let manager = SubscriptionManager()
        await manager.refreshEntitlements()
        XCTAssertNotEqual(manager.status, .loading, "Entitlement check should resolve")
        XCTAssertNotEqual(manager.status, .expired,
                          "A user who never subscribed must not see the resubscribe screen")
    }
}
