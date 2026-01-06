//
//  LinkPropertiesTests.swift
//  Branch iOS SDK - Modern Swift Implementation
//
//  Copyright © 2026 Branch Metrics. All rights reserved.
//  SPDX-License-Identifier: MIT
//

@testable import BranchSDK
import Foundation
import Testing

@Suite("LinkProperties Tests")
struct LinkPropertiesTests {
    // MARK: - Initialization Tests

    @Test("Default initialization has empty values")
    func defaultInitialization() {
        let props = LinkProperties()

        #expect(props.channel == nil)
        #expect(props.feature == nil)
        #expect(props.campaign == nil)
        #expect(props.stage == nil)
        #expect(props.tags.isEmpty)
        #expect(props.alias == nil)
        #expect(props.linkType == 0)
        #expect(props.matchDuration == nil)
        #expect(props.customData.isEmpty)
        #expect(props.controlParams.isEmpty)
    }

    // MARK: - Builder Pattern Tests

    @Test("Builder sets channel")
    func channelBuilder() {
        let props = LinkProperties()
            .with(channel: "facebook")

        #expect(props.channel == "facebook")
    }

    @Test("Builder sets feature")
    func featureBuilder() {
        let props = LinkProperties()
            .with(feature: "sharing")

        #expect(props.feature == "sharing")
    }

    @Test("Builder sets campaign")
    func campaignBuilder() {
        let props = LinkProperties()
            .with(campaign: "holiday_2024")

        #expect(props.campaign == "holiday_2024")
    }

    @Test("Builder sets stage")
    func stageBuilder() {
        let props = LinkProperties()
            .with(stage: "checkout")

        #expect(props.stage == "checkout")
    }

    @Test("Builder sets tags array")
    func tagsArrayBuilder() {
        let props = LinkProperties()
            .with(tags: ["promo", "seasonal", "limited"])

        #expect(props.tags == ["promo", "seasonal", "limited"])
    }

    @Test("Builder adds single tag")
    func singleTagBuilder() {
        let props = LinkProperties()
            .with(tag: "featured")
            .with(tag: "new")

        #expect(props.tags == ["featured", "new"])
    }

    @Test("Builder sets alias")
    func aliasBuilder() {
        let props = LinkProperties()
            .with(alias: "my-custom-link")

        #expect(props.alias == "my-custom-link")
    }

    @Test("Builder sets link type")
    func linkTypeBuilder() {
        let props = LinkProperties()
            .with(linkType: 1)

        #expect(props.linkType == 1)
    }

    @Test("Builder sets match duration")
    func matchDurationBuilder() {
        let props = LinkProperties()
            .with(matchDuration: 7)

        #expect(props.matchDuration == 7)
    }

    // MARK: - Custom Data Tests

    @Test("Builder sets custom data")
    func customDataBuilder() {
        let props = LinkProperties()
            .with(customData: ["product_id": "SKU123", "discount": 20])

        #expect(props.customData["product_id"]?.value as? String == "SKU123")
        #expect(props.customData["discount"]?.value as? Int == 20)
    }

    @Test("Builder adds single key-value")
    func keyValueBuilder() {
        let props = LinkProperties()
            .with(key: "referrer", value: "user_123")

        #expect(props.customData["referrer"]?.value as? String == "user_123")
    }

    // MARK: - Control Parameters Tests

    @Test("Builder sets iOS URL")
    func iOSURLBuilder() {
        let url = URL(string: "myapp://product/123")!
        let props = LinkProperties()
            .with(iOSURL: url)

        #expect(props.controlParams["$ios_url"]?.value as? String == "myapp://product/123")
    }

    @Test("Builder sets Android URL")
    func androidURLBuilder() {
        let url = URL(string: "myapp://product/123")!
        let props = LinkProperties()
            .with(androidURL: url)

        #expect(props.controlParams["$android_url"]?.value as? String == "myapp://product/123")
    }

    @Test("Builder sets desktop URL")
    func desktopURLBuilder() {
        let url = URL(string: "https://example.com/product/123")!
        let props = LinkProperties()
            .with(desktopURL: url)

        #expect(props.controlParams["$desktop_url"]?.value as? String == "https://example.com/product/123")
    }

    @Test("Builder sets fallback URL")
    func fallbackURLBuilder() {
        let url = URL(string: "https://example.com/fallback")!
        let props = LinkProperties()
            .with(fallbackURL: url)

        #expect(props.controlParams["$fallback_url"]?.value as? String == "https://example.com/fallback")
    }

    @Test("Builder sets deep link path")
    func deepLinkPathBuilder() {
        let props = LinkProperties()
            .with(deepLinkPath: "products/electronics/phones")

        #expect(props.controlParams["$deeplink_path"]?.value as? String == "products/electronics/phones")
    }

    // MARK: - OG Tags Tests

    @Test("Builder sets OG title")
    func oGTitleBuilder() {
        let props = LinkProperties()
            .with(ogTitle: "Check out this product!")

        #expect(props.controlParams["$og_title"]?.value as? String == "Check out this product!")
    }

    @Test("Builder sets OG description")
    func oGDescriptionBuilder() {
        let props = LinkProperties()
            .with(ogDescription: "The best product you'll ever find")

        #expect(props.controlParams["$og_description"]?.value as? String == "The best product you'll ever find")
    }

    @Test("Builder sets OG image URL")
    func oGImageURLBuilder() {
        let url = URL(string: "https://example.com/image.jpg")!
        let props = LinkProperties()
            .with(ogImageURL: url)

        #expect(props.controlParams["$og_image_url"]?.value as? String == "https://example.com/image.jpg")
    }

    // MARK: - Chaining Tests

    @Test("Builder methods can be chained")
    func builderChaining() {
        let props = LinkProperties()
            .with(channel: "twitter")
            .with(feature: "referral")
            .with(campaign: "launch_2024")
            .with(tag: "viral")
            .with(alias: "special-offer")
            .with(key: "promo_code", value: "SAVE50")
            .with(ogTitle: "Amazing Deal!")

        #expect(props.channel == "twitter")
        #expect(props.feature == "referral")
        #expect(props.campaign == "launch_2024")
        #expect(props.tags == ["viral"])
        #expect(props.alias == "special-offer")
        #expect(props.customData["promo_code"]?.value as? String == "SAVE50")
        #expect(props.controlParams["$og_title"]?.value as? String == "Amazing Deal!")
    }

    // MARK: - Equatable Tests

    @Test("Properties with same values are equal")
    func equality() {
        let props1 = LinkProperties()
            .with(channel: "email")
            .with(feature: "invite")

        let props2 = LinkProperties()
            .with(channel: "email")
            .with(feature: "invite")

        #expect(props1 == props2)
    }

    @Test("Properties with different values are not equal")
    func inequality() {
        let props1 = LinkProperties()
            .with(channel: "email")

        let props2 = LinkProperties()
            .with(channel: "sms")

        #expect(props1 != props2)
    }
}
