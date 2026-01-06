//
//  BranchConfiguration.swift
//  Branch iOS SDK - Modern Swift Implementation
//
//  Copyright © 2026 Branch Metrics. All rights reserved.
//  SPDX-License-Identifier: MIT
//

import Foundation

// MARK: - BranchConfiguration

/// Configuration for initializing the Branch SDK.
///
/// This struct contains all the settings needed to configure the SDK.
/// Use the builder pattern for a fluent configuration experience.
///
/// ## Example
///
/// ```swift
/// let config = BranchConfiguration(apiKey: "key_live_xxx")
///     .withDebugMode(true)
///     .withNetworkTimeout(30)
/// ```
public struct BranchConfiguration: Sendable, Equatable {
    // MARK: Lifecycle

    // MARK: - Initialization

    /// Create a new configuration with the given API key
    /// - Parameter apiKey: Your Branch API key
    public init(apiKey: String) {
        self.apiKey = apiKey
        isDebugMode = false
        networkTimeout = 10
        retryCount = 3
        retryDelay = 1.0
        isTrackingDisabled = false
        isAdNetworkCalloutsDisabled = false
        baseURL = nil
        cdnURL = nil
    }

    // MARK: Public

    // MARK: - Required Properties

    /// The Branch API key (live or test)
    public let apiKey: String

    // MARK: - Optional Properties

    /// Enable debug/test mode
    public var isDebugMode: Bool

    /// Network request timeout in seconds
    public var networkTimeout: TimeInterval

    /// Retry count for failed requests
    public var retryCount: Int

    /// Retry delay in seconds
    public var retryDelay: TimeInterval

    /// Disable tracking entirely (GDPR compliance)
    public var isTrackingDisabled: Bool

    /// Disable Ad Network callouts
    public var isAdNetworkCalloutsDisabled: Bool

    /// Custom base URL for API requests (for testing)
    public var baseURL: URL?

    /// Custom CDN URL for link resolution
    public var cdnURL: URL?

    // MARK: - Builder Pattern

    /// Enable or disable debug mode
    public func withDebugMode(_ enabled: Bool) -> BranchConfiguration {
        var config = self
        config.isDebugMode = enabled
        return config
    }

    /// Set network timeout
    public func withNetworkTimeout(_ timeout: TimeInterval) -> BranchConfiguration {
        var config = self
        config.networkTimeout = timeout
        return config
    }

    /// Set retry count for failed requests
    public func withRetryCount(_ count: Int) -> BranchConfiguration {
        var config = self
        config.retryCount = count
        return config
    }

    /// Set retry delay between attempts
    public func withRetryDelay(_ delay: TimeInterval) -> BranchConfiguration {
        var config = self
        config.retryDelay = delay
        return config
    }

    /// Disable tracking (for GDPR/privacy compliance)
    public func withTrackingDisabled(_ disabled: Bool) -> BranchConfiguration {
        var config = self
        config.isTrackingDisabled = disabled
        return config
    }

    /// Disable Ad Network callouts
    public func withAdNetworkCalloutsDisabled(_ disabled: Bool) -> BranchConfiguration {
        var config = self
        config.isAdNetworkCalloutsDisabled = disabled
        return config
    }

    /// Set a custom base URL (for testing)
    public func withBaseURL(_ url: URL) -> BranchConfiguration {
        var config = self
        config.baseURL = url
        return config
    }

    /// Set a custom CDN URL (for testing)
    public func withCDNURL(_ url: URL) -> BranchConfiguration {
        var config = self
        config.cdnURL = url
        return config
    }
}

// MARK: - Validation

public extension BranchConfiguration {
    /// Validate the configuration
    /// - Throws: `BranchError.invalidConfiguration` if validation fails
    func validate() throws {
        // Validate API key format
        guard !apiKey.isEmpty else {
            throw BranchError.invalidConfiguration("API key cannot be empty")
        }

        guard apiKey.hasPrefix("key_live_") || apiKey.hasPrefix("key_test_") else {
            throw BranchError.invalidConfiguration(
                "API key must start with 'key_live_' or 'key_test_'"
            )
        }

        // Validate timeouts
        guard networkTimeout > 0 else {
            throw BranchError.invalidConfiguration("Network timeout must be positive")
        }

        guard retryCount >= 0 else {
            throw BranchError.invalidConfiguration("Retry count cannot be negative")
        }
    }

    /// Whether this is a test/sandbox configuration
    var isTestMode: Bool {
        apiKey.hasPrefix("key_test_")
    }
}
