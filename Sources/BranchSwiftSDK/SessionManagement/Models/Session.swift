//
//  Session.swift
//  Branch iOS SDK - Modern Swift Implementation
//
//  Copyright © 2026 Branch Metrics. All rights reserved.
//  SPDX-License-Identifier: MIT
//

import Foundation

// MARK: - Session

/// Represents an initialized Branch session.
///
/// A session contains all the information about the current user session,
/// including any deep link data that was used to open the app.
///
/// ## Thread Safety
///
/// Session is immutable and Sendable, safe to share across actors.
public struct Session: Sendable, Equatable, Identifiable, Codable {
    // MARK: Lifecycle

    // MARK: - Initialization

    /// Create a new session
    public init(
        id: String = UUID().uuidString,
        createdAt: Date = Date(),
        identityId: String,
        deviceFingerprintId: String,
        isFirstSession: Bool,
        linkData: LinkData? = nil,
        userId: String? = nil
    ) {
        self.id = id
        self.createdAt = createdAt
        self.identityId = identityId
        self.deviceFingerprintId = deviceFingerprintId
        self.isFirstSession = isFirstSession
        self.linkData = linkData
        self.userId = userId
    }

    // MARK: Public

    /// Unique session identifier
    public let id: String

    /// Timestamp when the session was created
    public let createdAt: Date

    /// The identity ID assigned by Branch
    public let identityId: String

    /// The device fingerprint ID
    public let deviceFingerprintId: String

    /// Whether this is the first session for this device
    public let isFirstSession: Bool

    /// Deep link data, if the session was opened via a Branch link
    public let linkData: LinkData?

    /// User identity, if set
    public let userId: String?
}

// MARK: CustomStringConvertible

extension Session: CustomStringConvertible {
    public var description: String {
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

// MARK: - Convenience

public extension Session {
    /// Whether the session has deep link data
    var hasDeepLinkData: Bool {
        linkData != nil
    }

    /// Whether the user has been identified
    var isIdentified: Bool {
        userId != nil
    }

    /// Create a copy with updated user identity
    func withIdentity(_ userId: String) -> Session {
        Session(
            id: id,
            createdAt: createdAt,
            identityId: identityId,
            deviceFingerprintId: deviceFingerprintId,
            isFirstSession: isFirstSession,
            linkData: linkData,
            userId: userId
        )
    }

    /// Create a copy with cleared identity
    func withoutIdentity() -> Session {
        Session(
            id: id,
            createdAt: createdAt,
            identityId: identityId,
            deviceFingerprintId: deviceFingerprintId,
            isFirstSession: isFirstSession,
            linkData: linkData,
            userId: nil
        )
    }

    /// Create a copy with link data
    func withLinkData(_ linkData: LinkData) -> Session {
        Session(
            id: id,
            createdAt: createdAt,
            identityId: identityId,
            deviceFingerprintId: deviceFingerprintId,
            isFirstSession: isFirstSession,
            linkData: linkData,
            userId: userId
        )
    }
}
