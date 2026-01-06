//
//  StorageProvider.swift
//  Branch iOS SDK - Modern Swift Implementation
//
//  Copyright © 2026 Branch Metrics. All rights reserved.
//  SPDX-License-Identifier: MIT
//

import Foundation

// MARK: - StorageProvider

/// Protocol for persistent storage operations.
///
/// Abstracts UserDefaults and Keychain for testability.
///
/// ## Thread Safety
///
/// Implementations must be thread-safe and Sendable.
public protocol StorageProvider: Sendable {
    // MARK: - Basic Operations

    /// Store a value for the given key
    /// - Parameters:
    ///   - value: The value to store (must be Codable)
    ///   - key: The storage key
    func set(_ value: some Codable & Sendable, forKey key: StorageKey) async

    /// Retrieve a value for the given key
    /// - Parameter key: The storage key
    /// - Returns: The stored value, or nil if not found
    func get<T: Codable & Sendable>(forKey key: StorageKey) async -> T?

    /// Remove the value for the given key
    /// - Parameter key: The storage key
    func remove(forKey key: StorageKey) async

    /// Check if a value exists for the given key
    /// - Parameter key: The storage key
    /// - Returns: True if a value exists
    func contains(key: StorageKey) async -> Bool

    // MARK: - Batch Operations

    /// Remove all stored values
    func clear() async

    /// Get all stored keys
    /// - Returns: Array of all storage keys
    func allKeys() async -> [StorageKey]
}

// MARK: - StorageKey

/// Type-safe storage keys for the SDK
public struct StorageKey: RawRepresentable, Hashable, Sendable {
    // MARK: Lifecycle

    public init(rawValue: String) {
        self.rawValue = rawValue
    }

    // MARK: Public

    public let rawValue: String
}

// MARK: - Predefined Keys

public extension StorageKey {
    // Session
    static let sessionId = StorageKey(rawValue: "branch_session_id")
    static let sessionData = StorageKey(rawValue: "branch_session_data")
    static let lastSessionTime = StorageKey(rawValue: "branch_last_session_time")

    // Identity
    static let identityId = StorageKey(rawValue: "branch_identity_id")
    static let userId = StorageKey(rawValue: "branch_user_id")

    // Device
    static let deviceFingerprint = StorageKey(rawValue: "branch_device_fingerprint")
    static let hardwareId = StorageKey(rawValue: "branch_hardware_id")

    // Links
    static let lastOpenedLink = StorageKey(rawValue: "branch_last_opened_link")
    static let clickedBranchLink = StorageKey(rawValue: "branch_clicked_link")

    // Configuration
    static let apiKey = StorageKey(rawValue: "branch_api_key")
    static let trackingDisabled = StorageKey(rawValue: "branch_tracking_disabled")
}
