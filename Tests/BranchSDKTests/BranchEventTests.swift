//
//  BranchEventTests.swift
//  Branch iOS SDK - Modern Swift Implementation
//
//  Copyright © 2026 Branch Metrics. All rights reserved.
//  SPDX-License-Identifier: MIT
//

@testable import BranchSDK
import Foundation
import Testing

@Suite("BranchEvent Tests")
struct BranchEventTests {
    // MARK: - Factory Method Tests

    @Test("Purchase event has correct type")
    func purchaseEvent() {
        let event = BranchEvent.purchase()
        #expect(event.eventType == .purchase)
    }

    @Test("Add to cart event has correct type")
    func addToCartEvent() {
        let event = BranchEvent.addToCart()
        #expect(event.eventType == .addToCart)
    }

    @Test("View item event has correct type")
    func viewItemEvent() {
        let event = BranchEvent.viewItem()
        #expect(event.eventType == .viewItem)
    }

    @Test("Search event has correct type")
    func searchEvent() {
        let event = BranchEvent.search()
        #expect(event.eventType == .search)
    }

    @Test("Complete registration event has correct type")
    func completeRegistrationEvent() {
        let event = BranchEvent.completeRegistration()
        #expect(event.eventType == .completeRegistration)
    }

    @Test("Custom event has correct type and name")
    func customEvent() {
        let event = BranchEvent.custom("video_watched")
        #expect(event.eventType == .custom)
        #expect(event.customEventName == "video_watched")
    }

    // MARK: - Builder Pattern Tests

    @Test("Builder sets revenue and currency")
    func revenueBuilder() {
        let event = BranchEvent.purchase()
            .with(revenue: 99.99, currency: "USD")

        #expect(event.revenue == 99.99)
        #expect(event.currency == "USD")
    }

    @Test("Builder sets transaction ID")
    func transactionIdBuilder() {
        let event = BranchEvent.purchase()
            .with(transactionId: "TXN123")

        #expect(event.transactionId == "TXN123")
    }

    @Test("Builder sets shipping and tax")
    func shippingTaxBuilder() {
        let event = BranchEvent.purchase()
            .with(shipping: 5.99)
            .with(tax: 8.50)

        #expect(event.shipping == 5.99)
        #expect(event.tax == 8.50)
    }

    @Test("Builder sets coupon")
    func couponBuilder() {
        let event = BranchEvent.purchase()
            .with(coupon: "SAVE20")

        #expect(event.coupon == "SAVE20")
    }

    @Test("Builder sets search query")
    func searchQueryBuilder() {
        let event = BranchEvent.search()
            .with(searchQuery: "blue shoes")

        #expect(event.searchQuery == "blue shoes")
    }

    @Test("Builder sets custom data")
    func customDataBuilder() {
        let event = BranchEvent.custom("level_up")
            .with(customData: ["level": 5, "character": "warrior"])

        #expect(event.customData["level"]?.value as? Int == 5)
        #expect(event.customData["character"]?.value as? String == "warrior")
    }

    // MARK: - Content Item Tests

    @Test("Builder adds content items")
    func contentItemsBuilder() {
        let item1 = ContentItem(contentId: "SKU123", name: "Blue Shoes", price: 79.99)
        let item2 = ContentItem(contentId: "SKU456", name: "Red Shirt", price: 29.99)

        let event = BranchEvent.purchase()
            .with(contentItems: [item1, item2])

        #expect(event.contentItems.count == 2)
        #expect(event.contentItems[0].contentId == "SKU123")
        #expect(event.contentItems[1].contentId == "SKU456")
    }

    @Test("Builder adds single content item")
    func singleContentItemBuilder() {
        let item = ContentItem(contentId: "SKU789", name: "Green Hat")

        let event = BranchEvent.purchase()
            .with(contentItem: item)

        #expect(event.contentItems.count == 1)
        #expect(event.contentItems[0].contentId == "SKU789")
    }

    // MARK: - Chaining Tests

    @Test("Builder methods can be chained")
    func builderChaining() {
        let event = BranchEvent.purchase()
            .with(revenue: 149.99, currency: "EUR")
            .with(transactionId: "ORDER-2024-001")
            .with(shipping: 10.00)
            .with(tax: 15.00)
            .with(coupon: "WELCOME10")
            .with(affiliation: "Store A")
            .with(description: "Online purchase")
            .with(customData: ["source": "mobile_app"])

        #expect(event.revenue == 149.99)
        #expect(event.currency == "EUR")
        #expect(event.transactionId == "ORDER-2024-001")
        #expect(event.shipping == 10.00)
        #expect(event.tax == 15.00)
        #expect(event.coupon == "WELCOME10")
        #expect(event.affiliation == "Store A")
        #expect(event.eventDescription == "Online purchase")
        #expect(event.customData["source"]?.value as? String == "mobile_app")
    }

    // MARK: - Content Item Tests

    @Test("Content item initialization")
    func contentItemInitialization() {
        let item = ContentItem(
            contentId: "PROD-123",
            name: "Premium Widget",
            contentType: "product",
            price: 49.99,
            quantity: 2
        )

        #expect(item.contentId == "PROD-123")
        #expect(item.name == "Premium Widget")
        #expect(item.contentType == "product")
        #expect(item.price == 49.99)
        #expect(item.quantity == 2)
    }

    // MARK: - Event Type Raw Value Tests

    @Test("Event types have correct raw values")
    func eventTypeRawValues() {
        #expect(BranchEvent.EventType.addToCart.rawValue == "ADD_TO_CART")
        #expect(BranchEvent.EventType.purchase.rawValue == "PURCHASE")
        #expect(BranchEvent.EventType.viewItem.rawValue == "VIEW_ITEM")
        #expect(BranchEvent.EventType.search.rawValue == "SEARCH")
        #expect(BranchEvent.EventType.completeRegistration.rawValue == "COMPLETE_REGISTRATION")
        #expect(BranchEvent.EventType.custom.rawValue == "CUSTOM")
    }
}
