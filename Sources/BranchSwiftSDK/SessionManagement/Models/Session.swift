//
//  Session.swift
//  Branch iOS SDK - Modern Swift Implementation
//
//  Copyright © 2026 Branch Metrics. All rights reserved.
//  SPDX-License-Identifier: MIT
//

import Foundation

#if canImport(BranchSDK)
    import BranchSDK
#endif

// MARK: - Session

/// Represents an initialized Branch session.
///
/// A session contains all the information about the current user session,
/// including any deep link data that was used to open the app.
///
/// This class provides a typed Swift API for session data, internally bridging
/// from `BNCInitSessionResponse` for iOS 12 compatibility.
///
/// ## Thread Safety
///
/// Session is immutable after creation, safe to share across threads.
@objc public final class Session: NSObject {
    // MARK: - Properties

    /// Unique session identifier
    @objc public let id: String

    /// Timestamp when the session was created
    @objc public let createdAt: Date

    /// The identity ID assigned by Branch
    @objc public let identityId: String

    /// The device fingerprint ID
    @objc public let deviceFingerprintId: String

    /// Whether this is the first session for this device
    @objc public let isFirstSession: Bool

    /// Deep link data, if the session was opened via a Branch link
    #if canImport(BranchSDK)
        @objc public let linkData: BNCLinkData?
    #else
        public let linkData: Any?
    #endif

    /// User identity, if set
    @objc public let userId: String?

    /// Raw params dictionary from the server response
    @objc public let params: [String: Any]

    // MARK: - Initialization

    #if canImport(BranchSDK)
        /// Internal initializer from BNCInitSessionResponse
        init(from response: BNCInitSessionResponse, isFirstSession: Bool) {
            // Convert [AnyHashable: Any] to [String: Any]
            let rawParams = response.params ?? [:]
            var params: [String: Any] = [:]
            for (key, value) in rawParams {
                if let stringKey = key as? String {
                    params[stringKey] = value
                }
            }

            id = params["session_id"] as? String ?? UUID().uuidString
            createdAt = Date()
            identityId = params["identity_id"] as? String ?? UUID().uuidString
            deviceFingerprintId = params["device_fingerprint_id"] as? String ?? UUID().uuidString
            self.isFirstSession = isFirstSession
            userId = params["identity"] as? String
            self.params = params

            // Convert link data if present
            if let clickedBranchLink = params["+clicked_branch_link"] as? Bool, clickedBranchLink {
                let linkData = BNCLinkData()
                if let channel = params["~channel"] as? String {
                    linkData.setupChannel(channel)
                }
                if let campaign = params["~campaign"] as? String {
                    linkData.setupCampaign(campaign)
                }
                if let feature = params["~feature"] as? String {
                    linkData.setupFeature(feature)
                }
                if let tags = params["~tags"] as? [String] {
                    linkData.setupTags(tags)
                }
                if let stage = params["~stage"] as? String {
                    linkData.setupStage(stage)
                }
                // Store custom params
                linkData.setupParams(params)
                self.linkData = linkData
            } else {
                linkData = nil
            }

            super.init()
        }
    #endif

    /// Create session with explicit values
    @objc public init(
        id: String,
        createdAt: Date,
        identityId: String,
        deviceFingerprintId: String,
        isFirstSession: Bool,
        userId: String?,
        params: [String: Any]
    ) {
        self.id = id
        self.createdAt = createdAt
        self.identityId = identityId
        self.deviceFingerprintId = deviceFingerprintId
        self.isFirstSession = isFirstSession
        self.userId = userId
        self.params = params
        #if canImport(BranchSDK)
            linkData = nil
        #else
            linkData = nil
        #endif
        super.init()
    }

    #if canImport(BranchSDK)
        /// Create session with explicit values including link data
        @objc public init(
            id: String,
            createdAt: Date,
            identityId: String,
            deviceFingerprintId: String,
            isFirstSession: Bool,
            linkData: BNCLinkData?,
            userId: String?,
            params: [String: Any]
        ) {
            self.id = id
            self.createdAt = createdAt
            self.identityId = identityId
            self.deviceFingerprintId = deviceFingerprintId
            self.isFirstSession = isFirstSession
            self.linkData = linkData
            self.userId = userId
            self.params = params
            super.init()
        }
    #endif

    // MARK: - Convenience Properties

    /// Whether the session has deep link data
    @objc public var hasDeepLinkData: Bool {
        linkData != nil
    }

    /// Whether the user has been identified
    @objc public var isIdentified: Bool {
        userId != nil
    }

    // MARK: - Copy Methods

    #if canImport(BranchSDK)
        /// Create a copy with updated link data
        @objc public func withLinkData(_ linkData: BNCLinkData?) -> Session {
            Session(
                id: id,
                createdAt: createdAt,
                identityId: identityId,
                deviceFingerprintId: deviceFingerprintId,
                isFirstSession: isFirstSession,
                linkData: linkData,
                userId: userId,
                params: params
            )
        }
    #endif

    /// Create a copy with updated user identity
    @objc public func withIdentity(_ userId: String) -> Session {
        #if canImport(BranchSDK)
            return Session(
                id: id,
                createdAt: createdAt,
                identityId: identityId,
                deviceFingerprintId: deviceFingerprintId,
                isFirstSession: isFirstSession,
                linkData: linkData,
                userId: userId,
                params: params
            )
        #else
            return Session(
                id: id,
                createdAt: createdAt,
                identityId: identityId,
                deviceFingerprintId: deviceFingerprintId,
                isFirstSession: isFirstSession,
                userId: userId,
                params: params
            )
        #endif
    }

    /// Create a copy without user identity (logout)
    @objc public func withoutIdentity() -> Session {
        #if canImport(BranchSDK)
            return Session(
                id: id,
                createdAt: createdAt,
                identityId: identityId,
                deviceFingerprintId: deviceFingerprintId,
                isFirstSession: isFirstSession,
                linkData: linkData,
                userId: nil,
                params: params
            )
        #else
            return Session(
                id: id,
                createdAt: createdAt,
                identityId: identityId,
                deviceFingerprintId: deviceFingerprintId,
                isFirstSession: isFirstSession,
                userId: nil,
                params: params
            )
        #endif
    }

    // MARK: - CustomStringConvertible

    override public var description: String {
        var parts = ["Session(\(id.prefix(8))...)"]

        if isFirstSession {
            parts.append("first")
        }

        if linkData != nil {
            parts.append("hasLinkData")
        }

        if userId != nil {
            parts.append("identified")
        }

        return parts.joined(separator: ", ")
    }
}
