//
//  InitializationOptions.swift
//  Branch iOS SDK - Modern Swift Implementation
//
//  Copyright © 2026 Branch Metrics. All rights reserved.
//  SPDX-License-Identifier: MIT
//

#if canImport(UIKit)
    import UIKit
#endif

import Foundation

// MARK: - InitializationOptions

/// Options for SDK initialization.
///
/// This struct consolidates the various parameters that can be passed
/// during initialization, replacing the 15+ legacy methods with a
/// single, composable options struct.
///
/// ## Example
///
/// ```swift
/// let options = InitializationOptions()
///     .with(launchOptions: launchOptions)
///     .with(url: incomingURL)
///     .with(delayInitialization: false)
/// ```
public struct InitializationOptions: Sendable, Equatable {
    // MARK: Lifecycle

    // MARK: - Initialization

    public init() {
        url = nil
        sceneIdentifier = nil
        delayInitialization = false
        disableAutomaticSessionTracking = false
        checkPasteboardOnInstall = true
        referralParams = nil
        sourceApplication = nil
    }

    // MARK: Public

    /// URL that opened the app (deep link or universal link)
    public var url: URL?

    /// Scene identifier (iOS 13+ multi-window support)
    public var sceneIdentifier: String?

    /// Whether to delay network requests
    public var delayInitialization: Bool

    /// Whether to disable automatic session tracking
    public var disableAutomaticSessionTracking: Bool

    /// Whether to check for deferred deep links
    public var checkPasteboardOnInstall: Bool

    /// Custom referral parameters
    public var referralParams: [String: String]?

    /// Source application bundle ID
    public var sourceApplication: String?

    // MARK: - Equatable

    public static func == (lhs: InitializationOptions, rhs: InitializationOptions) -> Bool {
        lhs.url == rhs.url &&
            lhs.sceneIdentifier == rhs.sceneIdentifier &&
            lhs.delayInitialization == rhs.delayInitialization &&
            lhs.disableAutomaticSessionTracking == rhs.disableAutomaticSessionTracking &&
            lhs.checkPasteboardOnInstall == rhs.checkPasteboardOnInstall &&
            lhs.referralParams == rhs.referralParams &&
            lhs.sourceApplication == rhs.sourceApplication
    }

    // MARK: - Builder Pattern

    /// Set the URL that opened the app
    public func with(url: URL?) -> InitializationOptions {
        var options = self
        options.url = url
        return options
    }

    /// Set the scene identifier
    public func with(sceneIdentifier: String?) -> InitializationOptions {
        var options = self
        options.sceneIdentifier = sceneIdentifier
        return options
    }

    /// Set whether to delay initialization
    public func with(delayInitialization: Bool) -> InitializationOptions {
        var options = self
        options.delayInitialization = delayInitialization
        return options
    }

    /// Set whether to disable automatic session tracking
    public func with(disableAutomaticSessionTracking: Bool) -> InitializationOptions {
        var options = self
        options.disableAutomaticSessionTracking = disableAutomaticSessionTracking
        return options
    }

    /// Set whether to check pasteboard on install
    public func with(checkPasteboardOnInstall: Bool) -> InitializationOptions {
        var options = self
        options.checkPasteboardOnInstall = checkPasteboardOnInstall
        return options
    }

    /// Set custom referral parameters
    public func with(referralParams: [String: String]?) -> InitializationOptions {
        var options = self
        options.referralParams = referralParams
        return options
    }

    /// Set the source application
    public func with(sourceApplication: String?) -> InitializationOptions {
        var options = self
        options.sourceApplication = sourceApplication
        return options
    }

    #if canImport(UIKit)
        /// Configure from launch options
        @MainActor
        public func with(launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> InitializationOptions {
            var options = self

            if let launchURL = launchOptions?[.url] as? URL {
                options.url = launchURL
            }

            if let sourceApp = launchOptions?[.sourceApplication] as? String {
                options.sourceApplication = sourceApp
            }

            return options
        }
    #endif
}
