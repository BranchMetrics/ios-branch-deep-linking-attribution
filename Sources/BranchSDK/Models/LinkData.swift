//
//  LinkData.swift
//  Branch iOS SDK - Modern Swift Implementation
//
//  Copyright © 2026 Branch Metrics. All rights reserved.
//  SPDX-License-Identifier: MIT
//

import Foundation

// MARK: - LinkData

/// Represents deep link data from a Branch link.
///
/// Contains all the parameters and metadata associated with a Branch link
/// that was used to open the app.
public struct LinkData: Sendable, Equatable, Codable {
    // MARK: Lifecycle

    // MARK: - Initialization

    public init(
        url: URL? = nil,
        isClicked: Bool = false,
        referringLink: String? = nil,
        parameters: [String: AnyCodable] = [:],
        campaign: String? = nil,
        channel: String? = nil,
        feature: String? = nil,
        tags: [String]? = nil,
        stage: String? = nil,
        rawData: [String: AnyCodable] = [:]
    ) {
        self.url = url
        self.isClicked = isClicked
        self.referringLink = referringLink
        self.parameters = parameters
        self.campaign = campaign
        self.channel = channel
        self.feature = feature
        self.tags = tags
        self.stage = stage
        self.rawData = rawData
    }

    // MARK: Public

    /// The original Branch link URL
    public let url: URL?

    /// Whether this was clicked (vs. organic open)
    public let isClicked: Bool

    /// The referring link, if any
    public let referringLink: String?

    /// Custom parameters set when the link was created
    public let parameters: [String: AnyCodable]

    /// The campaign associated with this link
    public let campaign: String?

    /// The channel this link was shared on
    public let channel: String?

    /// The feature this link is associated with
    public let feature: String?

    /// Tags associated with this link
    public let tags: [String]?

    /// The stage in the user journey
    public let stage: String?

    /// Raw server response data
    public let rawData: [String: AnyCodable]

    // MARK: - Convenience Accessors

    /// Get a string parameter value
    public func string(forKey key: String) -> String? {
        parameters[key]?.value as? String
    }

    /// Get an integer parameter value
    public func int(forKey key: String) -> Int? {
        parameters[key]?.value as? Int
    }

    /// Get a boolean parameter value
    public func bool(forKey key: String) -> Bool? {
        parameters[key]?.value as? Bool
    }

    /// Get a dictionary parameter value
    public func dictionary(forKey key: String) -> [String: Any]? {
        parameters[key]?.value as? [String: Any]
    }

    /// Get an array parameter value
    public func array(forKey key: String) -> [Any]? {
        parameters[key]?.value as? [Any]
    }

    /// Access parameters using subscript
    public subscript(key: String) -> Any? {
        parameters[key]?.value
    }
}

// MARK: CustomStringConvertible

extension LinkData: CustomStringConvertible {
    public var description: String {
        var parts = ["LinkData"]

        if isClicked {
            parts.append("clicked")
        }

        if let campaign {
            parts.append("campaign: \(campaign)")
        }

        if let channel {
            parts.append("channel: \(channel)")
        }

        if !parameters.isEmpty {
            parts.append("\(parameters.count) params")
        }

        return parts.joined(separator: ", ")
    }
}
