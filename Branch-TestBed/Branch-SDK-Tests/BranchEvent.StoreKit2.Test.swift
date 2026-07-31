//
//  BranchEvent.StoreKit2.Test.swift
//  Branch-SDK-Tests
//
//  Exercises the StoreKit 2 mapping in BranchEvent+StoreKit2.swift against a local
//  SKTestSession, so no App Store connection or sandbox account is involved.
//
//  Copyright © 2026 Branch, Inc. All rights reserved.
//

import XCTest
import StoreKit
import StoreKitTest
// The umbrella re-exports BranchSwiftAPI, so the StoreKit 2 API arrives with this single import —
// the same thing a real Swift integrator writes.
import BranchSDK

@available(iOS 15.0, *)
final class BranchEventStoreKit2Tests: XCTestCase {

    private static let consumableID = "io.branch.testbed.testCredits"
    private static let subscriptionID = "io.branch.testbed.testSub"

    private var session: SKTestSession!

    override func setUpWithError() throws {
        try super.setUpWithError()
        session = try SKTestSession(configurationFileNamed: "TestStoreKitConfig")
        session.resetToDefaultState()
        session.disableDialogs = true
        session.askToBuyEnabled = false
        session.clearTransactions()
    }

    override func tearDownWithError() throws {
        session?.clearTransactions()
        session = nil
        try super.tearDownWithError()
    }

    // MARK: - Helpers

    /// Buys `productID` in the test session and returns the resulting transaction and its product.
    private func purchase(_ productID: String) async throws -> (Transaction, Product) {
        let products = try await Product.products(for: [productID])
        let product = try XCTUnwrap(products.first, "No product returned for \(productID)")

        let result = try await product.purchase()
        guard case .success(let verification) = result else {
            throw XCTSkip("Purchase did not succeed in the test session: \(result)")
        }
        guard case .verified(let transaction) = verification else {
            XCTFail("Transaction failed verification for \(productID)")
            throw XCTSkip("unverified transaction")
        }

        await transaction.finish()
        return (transaction, product)
    }

    // MARK: - Consumable

    func testConsumablePopulatesEventFields() async throws {
        let (transaction, product) = try await purchase(Self.consumableID)

        let event = BranchEvent(name: BranchStandardEvent.purchase.rawValue)
        event.populate(with: transaction, product: product)

        XCTAssertEqual(event.transactionID, String(transaction.id))
        XCTAssertEqual(event.revenue, NSDecimalNumber(decimal: product.price))
        XCTAssertEqual(event.revenue, NSDecimalNumber(string: "0.99"))
        XCTAssertEqual(event.currency?.rawValue, "USD")
        XCTAssertEqual(event.alias, "IAP", "Consumables should be aliased as IAP, not Subscription")
        XCTAssertEqual(event.eventDescription, "StoreKit 2: \(product.displayName)")
    }

    func testConsumablePopulatesContentItem() async throws {
        let (transaction, product) = try await purchase(Self.consumableID)

        let event = BranchEvent(name: BranchStandardEvent.purchase.rawValue)
        event.populate(with: transaction, product: product)

        XCTAssertEqual(event.contentItems.count, 1)
        let buo = try XCTUnwrap(event.contentItems.first)
        XCTAssertEqual(buo.canonicalIdentifier, product.id)
        XCTAssertEqual(buo.title, product.displayName)
        XCTAssertEqual(buo.contentDescription, product.description)
        XCTAssertEqual(buo.contentMetadata.quantity, Double(transaction.purchasedQuantity))
        XCTAssertEqual(buo.contentMetadata.price, NSDecimalNumber(decimal: product.price))
        XCTAssertEqual(buo.contentMetadata.currency?.rawValue, "USD")
        XCTAssertEqual(buo.contentMetadata.productName, product.displayName)
    }

    /// `customMetadata` is NSDictionary<NSString *, NSString *> on the Obj-C side, so every value
    /// has to arrive as a string — a non-string would be silently unusable downstream.
    func testCustomMetadataValuesAreAllStrings() async throws {
        let (transaction, product) = try await purchase(Self.consumableID)

        let event = BranchEvent(name: BranchStandardEvent.purchase.rawValue)
        event.populate(with: transaction, product: product)

        let metadata = try XCTUnwrap(event.contentItems.first?.contentMetadata.customMetadata)
        XCTAssertEqual(metadata["logged_from_storekit2"] as? String, "true")
        XCTAssertEqual(metadata["product_type"] as? String, Product.ProductType.consumable.rawValue)
        XCTAssertEqual(metadata["transaction_id"] as? String, String(transaction.id))
        XCTAssertEqual(metadata["original_transaction_id"] as? String, String(transaction.originalID))
        XCTAssertEqual(metadata["purchased_quantity"] as? String, String(transaction.purchasedQuantity))
        XCTAssertEqual(metadata["ownership_type"] as? String, transaction.ownershipType.rawValue)
        XCTAssertNotNil(metadata["purchase_date"] as? String)

        for key in metadata.allKeys {
            XCTAssertTrue(metadata[key] is String, "customMetadata[\(key)] is not a String")
        }
    }

    // MARK: - Subscription

    func testSubscriptionUsesSubscriptionAliasAndMetadata() async throws {
        let (transaction, product) = try await purchase(Self.subscriptionID)

        let event = BranchEvent(name: BranchStandardEvent.purchase.rawValue)
        event.populate(with: transaction, product: product)

        XCTAssertEqual(event.alias, "Subscription")
        XCTAssertEqual(event.revenue, NSDecimalNumber(string: "4.99"))

        let metadata = try XCTUnwrap(event.contentItems.first?.contentMetadata.customMetadata)
        XCTAssertEqual(metadata["subscription_group_id"] as? String, "69CDB027")
        // "P1M" in TestStoreKitConfig.storekit — singular, no trailing "s".
        XCTAssertEqual(metadata["subscription_period"] as? String, "1 month")
        XCTAssertEqual(metadata["product_type"] as? String, Product.ProductType.autoRenewable.rawValue)
        // The config declares "introductoryOffer": null, so those keys must be absent.
        XCTAssertNil(metadata["introductory_offer_type"])
    }

    // MARK: - customData merge

    func testPopulatePreservesExistingCustomData() async throws {
        let (transaction, product) = try await purchase(Self.consumableID)

        let event = BranchEvent(name: BranchStandardEvent.purchase.rawValue)
        event.customData = ["existing_key": "existing_value"]
        event.populate(with: transaction, product: product)

        XCTAssertEqual(event.customData["existing_key"], "existing_value")
        XCTAssertEqual(event.customData["transaction_identifier"], String(transaction.id))
        XCTAssertEqual(event.customData["logged_from_storekit2"], "true")
    }

    // MARK: - Async product lookup

    func testPopulateAsyncResolvesProductFromTransaction() async throws {
        let (transaction, product) = try await purchase(Self.consumableID)

        let event = BranchEvent(name: BranchStandardEvent.purchase.rawValue)
        try await event.populate(with: transaction)

        XCTAssertEqual(event.revenue, NSDecimalNumber(decimal: product.price))
        XCTAssertEqual(event.transactionID, String(transaction.id))
        XCTAssertEqual(event.contentItems.first?.canonicalIdentifier, product.id)
    }

    /// The whole point of the awaitable variant: a product-lookup failure has to reach the caller
    /// instead of being swallowed the way the fire-and-forget `logEvent(with:)` swallows it.
    func testPopulateAsyncPropagatesLoadProductsFailure() async throws {
        guard #available(iOS 17.0, *) else {
            throw XCTSkip("setSimulatedError(_:forAPI:) requires iOS 17")
        }
        let (transaction, _) = try await purchase(Self.consumableID)

        try await session.setSimulatedError(.generic(.networkError(URLError(.notConnectedToInternet))),
                                            forAPI: .loadProducts)

        let event = BranchEvent(name: BranchStandardEvent.purchase.rawValue)
        do {
            try await event.populate(with: transaction)
            XCTFail("Expected populate(with:) to throw when the product lookup fails")
        } catch {
            // Any error is acceptable here; what matters is that it is not silently dropped.
            XCTAssertNil(event.contentItems.first, "Event must not be half-populated on failure")
        }
    }
}
