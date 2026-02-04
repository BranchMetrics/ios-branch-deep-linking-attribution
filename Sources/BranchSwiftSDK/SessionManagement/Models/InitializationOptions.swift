//
//  InitializationOptions.swift
//  Branch iOS SDK - Modern Swift Implementation
//
//  Copyright © 2026 Branch Metrics. All rights reserved.
//  SPDX-License-Identifier: MIT
//

import Foundation

#if canImport(UIKit)
    import UIKit
#endif

// MARK: - InitializationOptions

/// Options for SDK initialization (iOS 12+ compatible).
///
/// This class consolidates the various parameters that can be passed
/// during initialization, replacing the 15+ legacy methods with a
/// single, composable options class.
///
/// ## Example
///
/// ```swift
/// let options = InitializationOptions()
/// options.url = incomingURL
/// options.delayInitialization = false
///
/// // Or using builder pattern
/// let options = InitializationOptions()
///     .with(url: incomingURL)
///     .with(delayInitialization: false)
/// ```
@objc public final class InitializationOptions: NSObject {
    // MARK: - Properties

    /// URL that opened the app (deep link or universal link)
    @objc public var url: URL?

    /// Scene identifier (iOS 13+ multi-window support)
    @objc public var sceneIdentifier: String?

    /// Whether to delay network requests
    @objc public var delayInitialization: Bool

    /// Whether to disable automatic session tracking
    @objc public var disableAutomaticSessionTracking: Bool

    /// Whether to check for deferred deep links
    @objc public var checkPasteboardOnInstall: Bool

    /// Custom referral parameters
    @objc public var referralParams: [String: String]?

    /// Source application bundle ID
    @objc public var sourceApplication: String?

    // MARK: - Initialization

    @objc override public init() {
        url = nil
        sceneIdentifier = nil
        delayInitialization = false
        disableAutomaticSessionTracking = false
        checkPasteboardOnInstall = true
        referralParams = nil
        sourceApplication = nil
        super.init()
    }

    // MARK: - Configuration Methods

    #if canImport(UIKit)
        /// Configure from launch options
        @objc public func configure(with launchOptions: [UIApplication.LaunchOptionsKey: Any]?) {
            if let launchURL = launchOptions?[.url] as? URL {
                url = launchURL
            }
            if let sourceApp = launchOptions?[.sourceApplication] as? String {
                sourceApplication = sourceApp
            }
        }
    #endif

    // MARK: - Builder Pattern (for Swift callers)

    /// Set the URL that opened the app
    public func with(url: URL?) -> InitializationOptions {
        self.url = url
        return self
    }

    /// Set the scene identifier
    public func with(sceneIdentifier: String?) -> InitializationOptions {
        self.sceneIdentifier = sceneIdentifier
        return self
    }

    /// Set whether to delay initialization
    public func with(delayInitialization: Bool) -> InitializationOptions {
        self.delayInitialization = delayInitialization
        return self
    }

    /// Set whether to disable automatic session tracking
    public func with(disableAutomaticSessionTracking: Bool) -> InitializationOptions {
        self.disableAutomaticSessionTracking = disableAutomaticSessionTracking
        return self
    }

    /// Set whether to check pasteboard on install
    public func with(checkPasteboardOnInstall: Bool) -> InitializationOptions {
        self.checkPasteboardOnInstall = checkPasteboardOnInstall
        return self
    }

    /// Set custom referral parameters
    public func with(referralParams: [String: String]?) -> InitializationOptions {
        self.referralParams = referralParams
        return self
    }

    /// Set the source application
    public func with(sourceApplication: String?) -> InitializationOptions {
        self.sourceApplication = sourceApplication
        return self
    }

    #if canImport(UIKit)
        /// Configure from launch options (builder pattern)
        public func with(launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> InitializationOptions {
            configure(with: launchOptions)
            return self
        }
    #endif
}
