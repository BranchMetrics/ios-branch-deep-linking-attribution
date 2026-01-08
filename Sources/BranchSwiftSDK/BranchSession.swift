//
//  BranchSession.swift
//  BranchSDK
//
//  Branch iOS SDK - Modern Swift Implementation
//  Copyright © 2026 Branch Metrics. All rights reserved.
//  SPDX-License-Identifier: MIT
//
//  JIRA: EMT-2726
//  Session data model for SDK Modernization
//

import Foundation

// MARK: - Branch Session

/// Represents a Branch SDK session containing session data and deep link information.
///
/// A `BranchSession` is created when the SDK successfully initializes and contains:
/// - Session identifiers (sessionId, randomizedBundleToken, randomizedDeviceToken)
/// - Deep link data (if the app was opened via a Branch link)
/// - Attribution data
///
/// This is the modern Swift equivalent of the Objective-C `BNCInitSessionResponse`.
///
/// - Note: Uses `@unchecked Sendable` because the struct contains dictionary types
/// that cannot be verified at compile time but are safe in practice since they are
/// immutable after construction.
@available(iOS 13.0, tvOS 13.0, *)
public struct BranchSession: @unchecked Sendable, Equatable {
    // MARK: - Properties

    /// Unique identifier for this session.
    public let sessionId: String?

    /// Randomized bundle token for this installation.
    public let randomizedBundleToken: String?

    /// Randomized device token.
    public let randomizedDeviceToken: String?

    /// Deep link parameters if the session was initiated from a Branch link.
    /// Contains all custom data set on the link.
    public let linkParams: [String: Any]?

    /// The URL that opened the app, if applicable.
    public let referringURL: URL?

    /// Indicates whether this is a first-time install.
    public let isFirstSession: Bool

    /// Indicates whether the session was opened from a Branch link.
    public let isFromBranchLink: Bool

    /// Raw server response data for advanced use cases.
    public let rawData: [String: Any]?

    /// Timestamp when the session was created.
    public let createdAt: Date

    // MARK: - Initialization

    /// Creates a new Branch session.
    ///
    /// - Parameters:
    ///   - sessionId: Unique session identifier
    ///   - randomizedBundleToken: Bundle token for this installation
    ///   - randomizedDeviceToken: Device token
    ///   - linkParams: Deep link parameters (if any)
    ///   - referringURL: The URL that opened the app
    ///   - isFirstSession: Whether this is the first session
    ///   - isFromBranchLink: Whether opened from a Branch link
    ///   - rawData: Raw server response
    public init(
        sessionId: String? = nil,
        randomizedBundleToken: String? = nil,
        randomizedDeviceToken: String? = nil,
        linkParams: [String: Any]? = nil,
        referringURL: URL? = nil,
        isFirstSession: Bool = false,
        isFromBranchLink: Bool = false,
        rawData: [String: Any]? = nil
    ) {
        self.sessionId = sessionId
        self.randomizedBundleToken = randomizedBundleToken
        self.randomizedDeviceToken = randomizedDeviceToken
        self.linkParams = linkParams
        self.referringURL = referringURL
        self.isFirstSession = isFirstSession
        self.isFromBranchLink = isFromBranchLink
        self.rawData = rawData
        createdAt = Date()
    }

    // MARK: - Factory Methods

    /// Creates a `BranchSession` from an Objective-C server response.
    ///
    /// - Parameter response: The `BNCServerResponse` from the initialization request.
    /// - Returns: A new `BranchSession` instance.
    public static func from(response: [String: Any]) -> BranchSession {
        let sessionId = response["session_id"] as? String
        let randomizedBundleToken = response["randomized_bundle_token"] as? String
        let randomizedDeviceToken = response["randomized_device_token"] as? String

        // Deep link data
        var linkParams: [String: Any]?
        if let data = response["data"] as? String,
           let jsonData = data.data(using: .utf8),
           let params = try? JSONSerialization.jsonObject(with: jsonData) as? [String: Any]
        {
            linkParams = params
        }

        let referringURLString = (linkParams?["~referring_link"] as? String) ?? (response["referring_url"] as? String)
        let referringURL = referringURLString.flatMap { URL(string: $0) }

        let isFirstSession = (response["is_first_session"] as? Bool) ?? false
        let clickedBranchLink = (linkParams?["+clicked_branch_link"] as? Bool) ?? false

        return BranchSession(
            sessionId: sessionId,
            randomizedBundleToken: randomizedBundleToken,
            randomizedDeviceToken: randomizedDeviceToken,
            linkParams: linkParams,
            referringURL: referringURL,
            isFirstSession: isFirstSession,
            isFromBranchLink: clickedBranchLink,
            rawData: response
        )
    }

    // MARK: - Equatable

    public static func == (lhs: BranchSession, rhs: BranchSession) -> Bool {
        lhs.sessionId == rhs.sessionId &&
            lhs.randomizedBundleToken == rhs.randomizedBundleToken &&
            lhs.createdAt == rhs.createdAt
    }
}

// MARK: - Debug Description

@available(iOS 13.0, tvOS 13.0, *)
extension BranchSession: CustomStringConvertible {
    public var description: String {
        """
        BranchSession(
            sessionId: \(sessionId ?? "nil"),
            isFirstSession: \(isFirstSession),
            isFromBranchLink: \(isFromBranchLink),
            referringURL: \(referringURL?.absoluteString ?? "nil"),
            createdAt: \(createdAt)
        )
        """
    }
}

// MARK: - Link Parameter Accessors

@available(iOS 13.0, tvOS 13.0, *)
public extension BranchSession {
    /// Returns a typed value from the link parameters.
    ///
    /// - Parameter key: The parameter key
    /// - Returns: The value if it exists and is of the expected type
    func linkParam<T>(forKey key: String) -> T? {
        linkParams?[key] as? T
    }

    /// Convenience accessor for the campaign associated with this link.
    var campaign: String? {
        linkParams?["~campaign"] as? String
    }

    /// Convenience accessor for the channel associated with this link.
    var channel: String? {
        linkParams?["~channel"] as? String
    }

    /// Convenience accessor for the feature associated with this link.
    var feature: String? {
        linkParams?["~feature"] as? String
    }

    /// Convenience accessor for custom tags associated with this link.
    var tags: [String]? {
        linkParams?["~tags"] as? [String]
    }

    /// Convenience accessor for the stage associated with this link.
    var stage: String? {
        linkParams?["~stage"] as? String
    }
}
