//
//  InitializationOptions.swift
//  BranchSDK
//
//  Branch iOS SDK - Modern Swift Implementation
//  Copyright © 2026 Branch Metrics. All rights reserved.
//  SPDX-License-Identifier: MIT
//
//  JIRA: EMT-2726
//  Initialization options builder for SDK Modernization
//

import Foundation

// MARK: - Initialization Options

/// Configuration options for Branch SDK initialization.
///
/// Use the builder pattern to configure initialization:
/// ```swift
/// let options = InitializationOptions()
///     .withURL(launchURL)
///     .withLaunchOptions(launchOptions)
///     .checkPasteboardOnInstall(true)
/// ```
///
/// - Note: Uses `@unchecked Sendable` because the struct contains Objective-C bridging types
/// (`[String: Any]`, `NSUserActivity`) that cannot be verified at compile time.
@available(iOS 13.0, tvOS 13.0, *)
public struct InitializationOptions: @unchecked Sendable, Equatable {
    // MARK: - Properties

    /// URL that launched the app (from deep link).
    public let launchURL: URL?

    /// Launch options from application delegate.
    public let launchOptions: [String: Any]?

    /// User activity for Universal Links.
    public let userActivity: NSUserActivity?

    /// Whether to check pasteboard for deferred deep links on install.
    public let checkPasteboardOnInstall: Bool

    /// Whether to defer initialization for plugin runtime.
    public let deferInitForPluginRuntime: Bool

    /// Custom referral URL if available.
    public let referringURL: URL?

    /// Whether this is a scene-based launch (iOS 13+).
    public let isSceneBasedLaunch: Bool

    /// Custom request metadata to include with initialization.
    public let customMetadata: [String: String]?

    // MARK: - Initialization

    /// Creates default initialization options.
    public init() {
        launchURL = nil
        launchOptions = nil
        userActivity = nil
        checkPasteboardOnInstall = false
        deferInitForPluginRuntime = false
        referringURL = nil
        isSceneBasedLaunch = false
        customMetadata = nil
    }

    /// Internal initializer for builder pattern.
    private init(
        launchURL: URL?,
        launchOptions: [String: Any]?,
        userActivity: NSUserActivity?,
        checkPasteboardOnInstall: Bool,
        deferInitForPluginRuntime: Bool,
        referringURL: URL?,
        isSceneBasedLaunch: Bool,
        customMetadata: [String: String]?
    ) {
        self.launchURL = launchURL
        self.launchOptions = launchOptions
        self.userActivity = userActivity
        self.checkPasteboardOnInstall = checkPasteboardOnInstall
        self.deferInitForPluginRuntime = deferInitForPluginRuntime
        self.referringURL = referringURL
        self.isSceneBasedLaunch = isSceneBasedLaunch
        self.customMetadata = customMetadata
    }

    // MARK: - Builder Methods

    /// Sets the URL that launched the app.
    public func withURL(_ url: URL?) -> InitializationOptions {
        InitializationOptions(
            launchURL: url,
            launchOptions: launchOptions,
            userActivity: userActivity,
            checkPasteboardOnInstall: checkPasteboardOnInstall,
            deferInitForPluginRuntime: deferInitForPluginRuntime,
            referringURL: referringURL,
            isSceneBasedLaunch: isSceneBasedLaunch,
            customMetadata: customMetadata
        )
    }

    /// Sets the launch options from UIApplicationDelegate.
    public func withLaunchOptions(_ options: [String: Any]?) -> InitializationOptions {
        InitializationOptions(
            launchURL: launchURL,
            launchOptions: options,
            userActivity: userActivity,
            checkPasteboardOnInstall: checkPasteboardOnInstall,
            deferInitForPluginRuntime: deferInitForPluginRuntime,
            referringURL: referringURL,
            isSceneBasedLaunch: isSceneBasedLaunch,
            customMetadata: customMetadata
        )
    }

    /// Sets the user activity for Universal Links.
    public func withUserActivity(_ activity: NSUserActivity?) -> InitializationOptions {
        InitializationOptions(
            launchURL: launchURL,
            launchOptions: launchOptions,
            userActivity: activity,
            checkPasteboardOnInstall: checkPasteboardOnInstall,
            deferInitForPluginRuntime: deferInitForPluginRuntime,
            referringURL: referringURL,
            isSceneBasedLaunch: isSceneBasedLaunch,
            customMetadata: customMetadata
        )
    }

    /// Enables or disables pasteboard checking on install.
    public func checkPasteboardOnInstall(_ enabled: Bool) -> InitializationOptions {
        InitializationOptions(
            launchURL: launchURL,
            launchOptions: launchOptions,
            userActivity: userActivity,
            checkPasteboardOnInstall: enabled,
            deferInitForPluginRuntime: deferInitForPluginRuntime,
            referringURL: referringURL,
            isSceneBasedLaunch: isSceneBasedLaunch,
            customMetadata: customMetadata
        )
    }

    /// Enables or disables deferred initialization for plugin runtime.
    public func deferInitForPluginRuntime(_ enabled: Bool) -> InitializationOptions {
        InitializationOptions(
            launchURL: launchURL,
            launchOptions: launchOptions,
            userActivity: userActivity,
            checkPasteboardOnInstall: checkPasteboardOnInstall,
            deferInitForPluginRuntime: enabled,
            referringURL: referringURL,
            isSceneBasedLaunch: isSceneBasedLaunch,
            customMetadata: customMetadata
        )
    }

    /// Sets a custom referring URL.
    public func withReferringURL(_ url: URL?) -> InitializationOptions {
        InitializationOptions(
            launchURL: launchURL,
            launchOptions: launchOptions,
            userActivity: userActivity,
            checkPasteboardOnInstall: checkPasteboardOnInstall,
            deferInitForPluginRuntime: deferInitForPluginRuntime,
            referringURL: url,
            isSceneBasedLaunch: isSceneBasedLaunch,
            customMetadata: customMetadata
        )
    }

    /// Marks this as a scene-based launch (iOS 13+).
    public func asSceneBasedLaunch(_ isSceneBased: Bool) -> InitializationOptions {
        InitializationOptions(
            launchURL: launchURL,
            launchOptions: launchOptions,
            userActivity: userActivity,
            checkPasteboardOnInstall: checkPasteboardOnInstall,
            deferInitForPluginRuntime: deferInitForPluginRuntime,
            referringURL: referringURL,
            isSceneBasedLaunch: isSceneBased,
            customMetadata: customMetadata
        )
    }

    /// Adds custom metadata to the initialization request.
    public func withCustomMetadata(_ metadata: [String: String]?) -> InitializationOptions {
        InitializationOptions(
            launchURL: launchURL,
            launchOptions: launchOptions,
            userActivity: userActivity,
            checkPasteboardOnInstall: checkPasteboardOnInstall,
            deferInitForPluginRuntime: deferInitForPluginRuntime,
            referringURL: referringURL,
            isSceneBasedLaunch: isSceneBasedLaunch,
            customMetadata: metadata
        )
    }

    // MARK: - Equatable

    public static func == (lhs: InitializationOptions, rhs: InitializationOptions) -> Bool {
        lhs.launchURL == rhs.launchURL &&
            lhs.checkPasteboardOnInstall == rhs.checkPasteboardOnInstall &&
            lhs.deferInitForPluginRuntime == rhs.deferInitForPluginRuntime &&
            lhs.referringURL == rhs.referringURL &&
            lhs.isSceneBasedLaunch == rhs.isSceneBasedLaunch &&
            lhs.customMetadata == rhs.customMetadata
    }
}

// MARK: - Convenience Factory Methods

@available(iOS 13.0, tvOS 13.0, *)
public extension InitializationOptions {
    /// Creates options for a standard app launch.
    /// - Parameter launchOptions: The launch options from UIApplicationDelegate.
    static func appLaunch(options: [String: Any]?) -> InitializationOptions {
        InitializationOptions()
            .withLaunchOptions(options)
    }

    /// Creates options for a Universal Link launch.
    /// - Parameter userActivity: The NSUserActivity from the Universal Link.
    static func universalLink(activity: NSUserActivity) -> InitializationOptions {
        InitializationOptions()
            .withUserActivity(activity)
            .withURL(activity.webpageURL)
    }

    /// Creates options for a URL scheme deep link.
    /// - Parameter url: The deep link URL.
    static func deepLink(url: URL) -> InitializationOptions {
        InitializationOptions()
            .withURL(url)
    }

    /// Creates options for a scene-based launch (iOS 13+).
    /// - Parameters:
    ///   - connectionOptions: Scene connection options (as dictionary).
    ///   - userActivity: Optional user activity.
    static func sceneLaunch(
        connectionOptions: [String: Any]?,
        userActivity: NSUserActivity? = nil
    ) -> InitializationOptions {
        InitializationOptions()
            .withLaunchOptions(connectionOptions)
            .withUserActivity(userActivity)
            .asSceneBasedLaunch(true)
    }
}

// MARK: - Debug Description

@available(iOS 13.0, tvOS 13.0, *)
extension InitializationOptions: CustomStringConvertible {
    public var description: String {
        """
        InitializationOptions(
            launchURL: \(launchURL?.absoluteString ?? "nil"),
            hasLaunchOptions: \(launchOptions != nil),
            hasUserActivity: \(userActivity != nil),
            checkPasteboardOnInstall: \(checkPasteboardOnInstall),
            deferInitForPluginRuntime: \(deferInitForPluginRuntime),
            isSceneBasedLaunch: \(isSceneBasedLaunch)
        )
        """
    }
}
