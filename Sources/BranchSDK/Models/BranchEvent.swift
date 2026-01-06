//
//  BranchEvent.swift
//  Branch iOS SDK - Modern Swift Implementation
//
//  Copyright © 2026 Branch Metrics. All rights reserved.
//  SPDX-License-Identifier: MIT
//

import Foundation

// MARK: - BranchEvent

/// Represents a Branch event for tracking.
///
/// Events can be standard commerce events or custom events.
///
/// ## Standard Events
///
/// ```swift
/// let event = BranchEvent.purchase()
///     .with(revenue: 99.99, currency: "USD")
///     .with(transactionId: "TXN123")
/// ```
///
/// ## Custom Events
///
/// ```swift
/// let event = BranchEvent.custom("video_watched")
///     .with(customData: ["video_id": "123", "duration": 120])
/// ```
public struct BranchEvent: Sendable, Equatable {
    // MARK: Lifecycle

    // MARK: - Initialization

    private init(eventType: EventType, customEventName: String? = nil) {
        self.eventType = eventType
        self.customEventName = customEventName
        revenue = nil
        currency = nil
        transactionId = nil
        shipping = nil
        tax = nil
        coupon = nil
        affiliation = nil
        eventDescription = nil
        searchQuery = nil
        customData = [:]
        contentItems = []
    }

    // MARK: Public

    // MARK: - Event Type

    /// The type of event
    public enum EventType: String, Sendable, Codable {
        // Commerce Events
        case addToCart = "ADD_TO_CART"
        case addToWishlist = "ADD_TO_WISHLIST"
        case viewCart = "VIEW_CART"
        case initiateCheckout = "INITIATE_CHECKOUT"
        case addPaymentInfo = "ADD_PAYMENT_INFO"
        case purchase = "PURCHASE"
        case spendCredits = "SPEND_CREDITS"

        // Content Events
        case search = "SEARCH"
        case viewItem = "VIEW_ITEM"
        case viewItems = "VIEW_ITEMS"
        case rate = "RATE"
        case share = "SHARE"

        // User Lifecycle Events
        case completeRegistration = "COMPLETE_REGISTRATION"
        case completeTutorial = "COMPLETE_TUTORIAL"
        case achieveLevel = "ACHIEVE_LEVEL"
        case unlockAchievement = "UNLOCK_ACHIEVEMENT"

        /// Custom
        case custom = "CUSTOM"
    }

    /// The event type
    public let eventType: EventType

    /// Custom event name (for custom events)
    public let customEventName: String?

    /// Revenue amount
    public var revenue: Decimal?

    /// Currency code (ISO 4217)
    public var currency: String?

    /// Transaction ID
    public var transactionId: String?

    /// Shipping amount
    public var shipping: Decimal?

    /// Tax amount
    public var tax: Decimal?

    /// Coupon code
    public var coupon: String?

    /// Affiliation (e.g., store name)
    public var affiliation: String?

    /// Event description
    public var eventDescription: String?

    /// Search query (for search events)
    public var searchQuery: String?

    /// Custom data
    public var customData: [String: AnyCodable]

    /// Associated content items
    public var contentItems: [ContentItem]

    // MARK: - Factory Methods

    /// Create a purchase event
    public static func purchase() -> BranchEvent {
        BranchEvent(eventType: .purchase)
    }

    /// Create an add to cart event
    public static func addToCart() -> BranchEvent {
        BranchEvent(eventType: .addToCart)
    }

    /// Create a view item event
    public static func viewItem() -> BranchEvent {
        BranchEvent(eventType: .viewItem)
    }

    /// Create a search event
    public static func search() -> BranchEvent {
        BranchEvent(eventType: .search)
    }

    /// Create a complete registration event
    public static func completeRegistration() -> BranchEvent {
        BranchEvent(eventType: .completeRegistration)
    }

    /// Create a custom event
    public static func custom(_ name: String) -> BranchEvent {
        BranchEvent(eventType: .custom, customEventName: name)
    }

    // MARK: - Builder Pattern

    /// Set revenue and currency
    public func with(revenue: Decimal, currency: String = "USD") -> BranchEvent {
        var event = self
        event.revenue = revenue
        event.currency = currency
        return event
    }

    /// Set transaction ID
    public func with(transactionId: String) -> BranchEvent {
        var event = self
        event.transactionId = transactionId
        return event
    }

    /// Set shipping amount
    public func with(shipping: Decimal) -> BranchEvent {
        var event = self
        event.shipping = shipping
        return event
    }

    /// Set tax amount
    public func with(tax: Decimal) -> BranchEvent {
        var event = self
        event.tax = tax
        return event
    }

    /// Set coupon code
    public func with(coupon: String) -> BranchEvent {
        var event = self
        event.coupon = coupon
        return event
    }

    /// Set affiliation
    public func with(affiliation: String) -> BranchEvent {
        var event = self
        event.affiliation = affiliation
        return event
    }

    /// Set description
    public func with(description: String) -> BranchEvent {
        var event = self
        event.eventDescription = description
        return event
    }

    /// Set search query
    public func with(searchQuery: String) -> BranchEvent {
        var event = self
        event.searchQuery = searchQuery
        return event
    }

    /// Set custom data
    public func with(customData: [String: any Sendable]) -> BranchEvent {
        var event = self
        event.customData = customData.mapValues { AnyCodable($0) }
        return event
    }

    /// Add content items
    public func with(contentItems: [ContentItem]) -> BranchEvent {
        var event = self
        event.contentItems = contentItems
        return event
    }

    /// Add a single content item
    public func with(contentItem: ContentItem) -> BranchEvent {
        var event = self
        event.contentItems.append(contentItem)
        return event
    }
}

// MARK: - ContentItem

/// Represents a content item associated with an event.
public struct ContentItem: Sendable, Equatable, Codable {
    // MARK: Lifecycle

    public init(
        contentId: String? = nil,
        name: String? = nil,
        contentType: String? = nil,
        price: Decimal? = nil,
        quantity: Int? = nil
    ) {
        self.contentId = contentId
        self.name = name
        self.contentType = contentType
        self.price = price
        self.quantity = quantity
        brand = nil
        category = nil
        sku = nil
        variant = nil
        metadata = [:]
    }

    // MARK: Public

    /// Unique identifier for the content
    public var contentId: String?

    /// Name of the content
    public var name: String?

    /// Type of content (e.g., "product", "article")
    public var contentType: String?

    /// Price of the item
    public var price: Decimal?

    /// Quantity
    public var quantity: Int?

    /// Brand
    public var brand: String?

    /// Category
    public var category: String?

    /// SKU
    public var sku: String?

    /// Product variant
    public var variant: String?

    /// Custom metadata
    public var metadata: [String: AnyCodable]
}
