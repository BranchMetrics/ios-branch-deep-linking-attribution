//
//  BranchEvent+StoreKit2.swift
//  BranchSDK
//
//  Created by Nidhi Dixit on 09/30/25.
//  Copyright 2024 Branch Metrics. All rights reserved.
//

import Foundation
import StoreKit

#if SWIFT_PACKAGE
import BranchSDK
import BranchObjCSDK
#endif

// MARK: - StoreKit 2 Extensions
@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
extension BranchEvent {

    /// Errors surfaced while building a Branch event from a StoreKit 2 transaction.
    public enum StoreKit2Error: Error, CustomStringConvertible {
        /// The App Store returned no `Product` for the transaction's product identifier.
        case productNotFound(productID: String)

        public var description: String {
            switch self {
            case .productNotFound(let productID):
                return "Could not load product for transaction: \(productID)"
            }
        }
    }

    /// Logs a Branch event from a StoreKit 2 transaction.
    /// This method extracts detailed product and transaction information.
    ///
    /// This is fire-and-forget: it returns immediately and does the product lookup and the log on a
    /// detached `Task`, so failures are only reported through `BranchLogger`. Because the work
    /// outlives the call, an app that is backgrounded or terminated right after the purchase can
    /// drop the event. Prefer `logEventAsync(with:)` where you can await the result.
    /// - Parameter transaction: The StoreKit 2 transaction
    public func logEvent(with transaction: Transaction) {
        Task {
            do {
                try await logEventAsync(with: transaction)
            } catch {
                BranchLogger.shared().logError("Failed to log StoreKit 2 transaction: \(error.localizedDescription)", error: error)
            }
        }
    }

    /// Logs a Branch event from a StoreKit 2 transaction, awaiting the product lookup.
    ///
    /// Unlike `logEvent(with:)` this keeps the work inside the caller's task, so the caller controls
    /// its lifetime and sees any error. It returns once the event has been handed to the Branch
    /// request queue — not once the server has acknowledged it.
    /// - Parameter transaction: The StoreKit 2 transaction
    /// - Throws: `StoreKit2Error.productNotFound`, or any error raised by `Product.products(for:)`.
    public func logEventAsync(with transaction: Transaction) async throws {
        try await populate(with: transaction)

        await MainActor.run {
            self.logEvent()
            BranchLogger.shared().logDebug("Created and logged StoreKit 2 event: \(self.description)", error: nil)
        }
    }

    /// Populates the event from a StoreKit 2 transaction, looking the `Product` up from the App Store.
    ///
    /// Use this when you want to enrich the event further before logging it yourself.
    /// - Parameter transaction: The StoreKit 2 transaction
    /// - Throws: `StoreKit2Error.productNotFound`, or any error raised by `Product.products(for:)`.
    public func populate(with transaction: Transaction) async throws {
        let products = try await Product.products(for: [transaction.productID])
        guard let product = products.first else {
            let error = StoreKit2Error.productNotFound(productID: transaction.productID)
            BranchLogger.shared().logError(error.description, error: nil)
            throw error
        }

        await MainActor.run {
            self.populate(with: transaction, product: product)
        }
    }

    /// Populates the BranchEvent with data from StoreKit 2 transaction and product.
    ///
    /// Performs no I/O — use it when you already hold the `Product`.
    public func populate(with transaction: Transaction, product: Product) {
        let currencyCode = product.priceFormatStyle.currencyCode

        // Create BranchUniversalObject for the product
        let buo = BranchUniversalObject()
        buo.canonicalIdentifier = product.id
        buo.title = product.displayName
        buo.contentDescription = product.description
        buo.contentMetadata.quantity = Double(transaction.purchasedQuantity)
        buo.contentMetadata.price = NSDecimalNumber(decimal: product.price)
        buo.contentMetadata.currency = BNCCurrency(rawValue: currencyCode)
        buo.contentMetadata.productName = product.displayName

        // Build custom metadata. `customMetadata` is typed NSDictionary<NSString *, NSString *>
        // on the Obj-C side, so every value is stringified before it is handed over.
        var customMetadata: [String: String] = [
            "logged_from_storekit2": "true",
            "product_type": product.type.rawValue,
            "transaction_id": String(transaction.id),
            "original_transaction_id": String(transaction.originalID),
            "purchase_date": ISO8601DateFormatter().string(from: transaction.purchaseDate),
            "purchased_quantity": String(transaction.purchasedQuantity)
        ]

        // Add subscription information if available
        if let subscriptionInfo = product.subscription {
            customMetadata["subscription_group_id"] = subscriptionInfo.subscriptionGroupID
            customMetadata["subscription_period"] = formatSubscriptionPeriod(subscriptionInfo.subscriptionPeriod)

            if let introductoryOffer = subscriptionInfo.introductoryOffer {
                customMetadata["introductory_offer_type"] = introductoryOffer.type.rawValue
                customMetadata["introductory_offer_period"] = formatSubscriptionPeriod(introductoryOffer.period)
            }
        }

        // Add transaction state information
        if #available(iOS 17.0, macOS 14.0, tvOS 17.0, watchOS 10.0, *) {
            customMetadata["transaction_reason"] = transaction.reason.rawValue
        }
        customMetadata["ownership_type"] = transaction.ownershipType.rawValue

        // Add revocation information if available
        if let revocationDate = transaction.revocationDate {
            customMetadata["revocation_date"] = ISO8601DateFormatter().string(from: revocationDate)
        }
        if let revocationReason = transaction.revocationReason {
            customMetadata["revocation_reason"] = String(revocationReason.rawValue)
        }

        buo.contentMetadata.customMetadata = NSMutableDictionary(dictionary: customMetadata)

        // Configure the event. `eventName` is fixed at init time, so the caller decides whether this
        // is BranchStandardEventPurchase or a custom event before handing the event to us.
        self.contentItems = [buo]
        self.transactionID = String(transaction.id)
        self.eventDescription = "StoreKit 2: \(product.displayName)"
        self.currency = BNCCurrency(rawValue: currencyCode)
        self.revenue = NSDecimalNumber(decimal: product.price)

        // Set alias based on product type
        switch product.type {
        case .autoRenewable, .nonRenewable:
            self.alias = "Subscription"
        case .consumable, .nonConsumable:
            self.alias = "IAP"
        default:
            self.alias = "IAP"
        }

        // Merge with existing custom data
        var eventCustomData = self.customData
        eventCustomData["transaction_identifier"] = String(transaction.id)
        eventCustomData["logged_from_storekit2"] = "true"
        self.customData = eventCustomData
    }

    /// Formats a subscription period into a readable string
    private func formatSubscriptionPeriod(_ period: Product.SubscriptionPeriod) -> String {
        let unitString: String
        switch period.unit {
        case .day:
            unitString = "day"
        case .week:
            unitString = "week"
        case .month:
            unitString = "month"
        case .year:
            unitString = "year"
        @unknown default:
            unitString = "unknown"
        }
        return "\(period.value) \(unitString)\(period.value > 1 ? "s" : "")"
    }
}
