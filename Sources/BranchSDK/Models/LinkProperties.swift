//
//  LinkProperties.swift
//  Branch iOS SDK - Modern Swift Implementation
//
//  Copyright © 2026 Branch Metrics. All rights reserved.
//  SPDX-License-Identifier: MIT
//

import Foundation

/// Properties for creating a Branch deep link.
///
/// ## Example
///
/// ```swift
/// let properties = LinkProperties()
///     .with(channel: "facebook")
///     .with(feature: "sharing")
///     .with(campaign: "holiday_2024")
///     .with(customData: ["product_id": "123"])
/// ```
public struct LinkProperties: Sendable, Equatable {
    // MARK: Lifecycle

    // MARK: - Initialization

    public init() {
        channel = nil
        feature = nil
        campaign = nil
        stage = nil
        tags = []
        alias = nil
        linkType = 0
        matchDuration = nil
        customData = [:]
        controlParams = [:]
    }

    // MARK: Public

    /// The channel the link will be shared on
    public var channel: String?

    /// The feature this link is associated with
    public var feature: String?

    /// The campaign this link belongs to
    public var campaign: String?

    /// The stage in the user journey
    public var stage: String?

    /// Tags for categorization
    public var tags: [String]

    /// Alias for the link (custom slug)
    public var alias: String?

    /// Link type (0 = default, 1 = one-time use, 2 = marketing)
    public var linkType: Int

    /// Duration in days to match on install
    public var matchDuration: Int?

    /// Custom data to include in the link
    public var customData: [String: AnyCodable]

    /// Control parameters for link behavior
    public var controlParams: [String: AnyCodable]

    // MARK: - Builder Pattern

    /// Set the channel
    public func with(channel: String) -> LinkProperties {
        var props = self
        props.channel = channel
        return props
    }

    /// Set the feature
    public func with(feature: String) -> LinkProperties {
        var props = self
        props.feature = feature
        return props
    }

    /// Set the campaign
    public func with(campaign: String) -> LinkProperties {
        var props = self
        props.campaign = campaign
        return props
    }

    /// Set the stage
    public func with(stage: String) -> LinkProperties {
        var props = self
        props.stage = stage
        return props
    }

    /// Set the tags
    public func with(tags: [String]) -> LinkProperties {
        var props = self
        props.tags = tags
        return props
    }

    /// Add a tag
    public func with(tag: String) -> LinkProperties {
        var props = self
        props.tags.append(tag)
        return props
    }

    /// Set the alias
    public func with(alias: String) -> LinkProperties {
        var props = self
        props.alias = alias
        return props
    }

    /// Set the link type
    public func with(linkType: Int) -> LinkProperties {
        var props = self
        props.linkType = linkType
        return props
    }

    /// Set the match duration
    public func with(matchDuration: Int) -> LinkProperties {
        var props = self
        props.matchDuration = matchDuration
        return props
    }

    /// Set custom data
    public func with(customData: [String: any Sendable]) -> LinkProperties {
        var props = self
        props.customData = customData.mapValues { AnyCodable($0) }
        return props
    }

    /// Add a custom data field
    public func with(key: String, value: some Sendable) -> LinkProperties {
        var props = self
        props.customData[key] = AnyCodable(value)
        return props
    }

    /// Set control parameters
    public func with(controlParams: [String: any Sendable]) -> LinkProperties {
        var props = self
        props.controlParams = controlParams.mapValues { AnyCodable($0) }
        return props
    }

    // MARK: - Control Parameter Convenience

    /// Set the iOS URL redirect
    public func with(iOSURL: URL) -> LinkProperties {
        var props = self
        props.controlParams["$ios_url"] = AnyCodable(iOSURL.absoluteString)
        return props
    }

    /// Set the Android URL redirect
    public func with(androidURL: URL) -> LinkProperties {
        var props = self
        props.controlParams["$android_url"] = AnyCodable(androidURL.absoluteString)
        return props
    }

    /// Set the desktop URL redirect
    public func with(desktopURL: URL) -> LinkProperties {
        var props = self
        props.controlParams["$desktop_url"] = AnyCodable(desktopURL.absoluteString)
        return props
    }

    /// Set the fallback URL
    public func with(fallbackURL: URL) -> LinkProperties {
        var props = self
        props.controlParams["$fallback_url"] = AnyCodable(fallbackURL.absoluteString)
        return props
    }

    /// Set deep link path
    public func with(deepLinkPath: String) -> LinkProperties {
        var props = self
        props.controlParams["$deeplink_path"] = AnyCodable(deepLinkPath)
        return props
    }

    /// Set OG title
    public func with(ogTitle: String) -> LinkProperties {
        var props = self
        props.controlParams["$og_title"] = AnyCodable(ogTitle)
        return props
    }

    /// Set OG description
    public func with(ogDescription: String) -> LinkProperties {
        var props = self
        props.controlParams["$og_description"] = AnyCodable(ogDescription)
        return props
    }

    /// Set OG image URL
    public func with(ogImageURL: URL) -> LinkProperties {
        var props = self
        props.controlParams["$og_image_url"] = AnyCodable(ogImageURL.absoluteString)
        return props
    }
}
