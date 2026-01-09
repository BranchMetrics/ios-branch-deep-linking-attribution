//
//  DeviceInfoProvider.swift
//  Branch iOS SDK - Modern Swift Implementation
//
//  Copyright © 2026 Branch Metrics. All rights reserved.
//  SPDX-License-Identifier: MIT
//

import Foundation

// MARK: - DeviceInfoProvider

/// Protocol for collecting and providing device information.
///
/// This protocol abstracts device information collection, enabling
/// testability and platform-specific implementations.
///
/// ## Thread Safety
///
/// Implementations must be thread-safe and Sendable.
///
/// ## Usage Example
///
/// ```swift
/// let provider: DeviceInfoProvider = DefaultDeviceInfoProvider(storage: storage)
/// let deviceInfo = await provider.collectDeviceInfo()
/// ```
public protocol DeviceInfoProvider: Sendable {
    // MARK: - Device Info Collection

    /// Collect current device information.
    ///
    /// This method gathers all device-related data including hardware
    /// identifiers, OS information, screen dimensions, and locale settings.
    ///
    /// - Returns: A `DeviceInfo` struct containing all collected information.
    /// - Note: This operation may be expensive as it queries system APIs.
    func collectDeviceInfo() async -> DeviceInfo

    /// Get the cached device information without re-collecting.
    ///
    /// Returns the most recently collected device info, or collects
    /// it if not yet available.
    ///
    /// - Returns: The cached or freshly collected `DeviceInfo`.
    var currentDeviceInfo: DeviceInfo { get async }

    // MARK: - Hardware ID Management

    /// Refresh the hardware identifier.
    ///
    /// This method re-checks the advertising identifier (IDFA) availability
    /// and updates the hardware ID accordingly. Useful after ATT status changes.
    ///
    /// - Returns: Updated `DeviceInfo` with refreshed hardware identifiers.
    func refreshHardwareId() async -> DeviceInfo

    /// Check and update the ATT (App Tracking Transparency) authorization status.
    ///
    /// - Returns: The current `ATTAuthorizationStatus`.
    func checkATTStatus() async -> ATTAuthorizationStatus

    // MARK: - Plugin Registration

    /// Register a plugin using the SDK.
    ///
    /// Used by wrapper SDKs (React Native, Flutter, etc.) to identify themselves.
    ///
    /// - Parameters:
    ///   - name: The name of the plugin (e.g., "React Native", "Flutter").
    ///   - version: The version of the plugin.
    func registerPlugin(name: String, version: String) async

    // MARK: - Network Information

    /// Get the current local IP address.
    ///
    /// - Returns: The device's local IP address, or nil if unavailable.
    func localIPAddress() async -> String?

    /// Get the current network connection type.
    ///
    /// - Returns: A string describing the connection type (e.g., "wifi", "cellular").
    func connectionType() async -> String

    // MARK: - User Agent

    /// Get the user agent string for web requests.
    ///
    /// - Returns: The WebKit user agent string, or empty string on tvOS.
    func userAgentString() async -> String
}

// MARK: - DeviceInfoProviderError

/// Errors that can occur during device info collection.
public enum DeviceInfoProviderError: Error, Sendable {
    /// Failed to retrieve hardware identifier
    case hardwareIdUnavailable

    /// Failed to collect screen information
    case screenInfoUnavailable

    /// Failed to retrieve locale information
    case localeUnavailable

    /// User agent collection failed or timed out
    case userAgentUnavailable

    /// General collection failure
    case collectionFailed(reason: String)
}
