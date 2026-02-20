//
//  BranchEvent+StoreKit2.swift
//  Branch-SDK
//
//  Created by Nidhi Dixit on 09/30/25.
//  Copyright 2024 Branch Metrics. All rights reserved.
//

import Foundation
import StoreKit
import BranchSDK

@available(iOS 15.0, tvOS 15.0, watchOS 8.0, *)
extension BranchEvent {
    
    /// This method extracts detailed product and transaction information from a StoreKit 2 transaction
    /// and logs a Branch PURCHASE event with all the extracted information.
    /// - Parameter transaction: The StoreKit 2 transaction
    public func logEventForTransaction( transaction: Transaction) {
        Task {
            await logEventAsync(with: transaction)
        }
    }
    
    private func logEventAsync(with transaction: Transaction) async {
        do {
            let products = try await Product.products(for: [transaction.productID])
            guard let product = products.first else {
                BranchLogger.shared().logError("Could not load product for transaction: \(transaction.productID)", error: nil)
                return
            }
            self.populateBUO(with: transaction, product: product)
            try await self.logEvent()
            BranchLogger.shared().logDebug("Created and logged StoreKit 2 event: \(self.description)", error: nil)
        } catch {
            BranchLogger.shared().logError("Failed to load product for StoreKit 2 transaction: \(error.localizedDescription)", error: error)
        }
    }
    
    private func populateBUO(with transaction: Transaction, product: Product) {
        let buo = BranchUniversalObject()
        buo.canonicalIdentifier = product.id
        buo.title = product.displayName
        buo.contentDescription = product.description
        buo.contentMetadata.quantity = Double(transaction.purchasedQuantity)
        buo.contentMetadata.price = NSDecimalNumber(decimal: product.price)
        buo.contentMetadata.currency = BNCCurrency(rawValue: product.priceFormatStyle.currencyCode)
        buo.contentMetadata.productName = product.displayName
        
        var customMetadata: [String: Any] = [
            "logged_from_storekit2": true,
            "product_type": product.type.rawValue,
            "transaction_id": String(transaction.id),
            "original_transaction_id": String(transaction.originalID),
            "purchase_date": ISO8601DateFormatter().string(from: transaction.purchaseDate),
            "purchased_quantity": transaction.purchasedQuantity
        ]
        
        if let subscriptionInfo = product.subscription {
            customMetadata["subscription_group_id"] = subscriptionInfo.subscriptionGroupID
            customMetadata["subscription_period"] = formatSubscriptionPeriod(subscriptionInfo.subscriptionPeriod)
            
            if let introductoryOffer = subscriptionInfo.introductoryOffer {
                customMetadata["introductory_offer_type"] = introductoryOffer.type.rawValue
                customMetadata["introductory_offer_period"] = formatSubscriptionPeriod(introductoryOffer.period)
            }
        }
        customMetadata["ownership_type"] = transaction.ownershipType.rawValue
        
        if let revocationDate = transaction.revocationDate {
            customMetadata["revocation_date"] = ISO8601DateFormatter().string(from: revocationDate)
        }
        if let revocationReason = transaction.revocationReason {
            customMetadata["revocation_reason"] = revocationReason.rawValue
        }
        
        buo.contentMetadata.customMetadata = NSMutableDictionary(dictionary: customMetadata)
        
        self.contentItems = [buo]
        self.eventName = "PURCHASE"
        self.transactionID = String(transaction.id)
        self.eventDescription = "StoreKit 2: \(product.displayName)"
        self.currency = BNCCurrency(rawValue: product.priceFormatStyle.currencyCode)
        self.revenue = NSDecimalNumber(decimal: product.price)
        
        switch product.type {
        case .autoRenewable, .nonRenewable:
            self.alias = "Subscription"
        case .consumable, .nonConsumable:
            self.alias = "IAP"
        default:
            self.alias = "IAP"
        }
        
        var eventCustomData: [String: String] = [:]
        eventCustomData["transaction_identifier"] = String(transaction.id)
        eventCustomData["logged_from_storekit2"] = "true"
        self.customData = eventCustomData
    }
    
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
