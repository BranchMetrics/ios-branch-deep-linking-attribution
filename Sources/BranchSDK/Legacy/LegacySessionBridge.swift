//
//  LegacySessionBridge.swift
//  Branch iOS SDK - Modern Swift Implementation
//
//  Copyright © 2026 Branch Metrics. All rights reserved.
//  SPDX-License-Identifier: MIT
//

#if canImport(UIKit)
import UIKit
#endif

import Foundation

// MARK: - LegacySessionBridge

/// Bridges legacy v3 initialization methods to the modern v4 async API.
///
/// This class provides backward-compatible initialization methods that match
/// the v3 SDK's `initSession` method signatures, internally converting them
/// to use the modern `async/await` API.
///
/// ## v3 Method Mapping
///
/// All 9 legacy `initSessionWithLaunchOptions:` variants are supported:
///
/// | v3 Method | v4 Equivalent |
/// |-----------|---------------|
/// | `initSessionWithLaunchOptions:` | `initialize(options:)` |
/// | `initSessionWithLaunchOptions:isReferrable:` | `initialize(options:)` with `isReferrable` |
/// | `initSessionWithLaunchOptions:andRegisterDeepLinkHandler:` | `initialize(options:)` + callback |
/// | ... and 6 more variants | All mapped to single `initialize(options:)` |
///
/// ## Thread Safety
///
/// All callbacks are delivered on the main thread, matching v3 behavior.
///
/// ## Example
///
/// ```swift
/// // Legacy-style initialization
/// LegacySessionBridge.shared.initSession(
///     launchOptions: launchOptions,
///     isReferrable: true,
///     callback: { params, error in
///         // Handle result on main thread
///     }
/// )
/// ```
@MainActor
public final class LegacySessionBridge: Sendable {
    // MARK: Lifecycle

    private init() {}

    // MARK: Public

    /// Shared instance for legacy initialization
    public static let shared = LegacySessionBridge()

    // MARK: - Legacy Init Methods

    #if canImport(UIKit)

    // MARK: Method 1: Basic init

    /// Initialize session with launch options.
    ///
    /// Maps to v3: `initSessionWithLaunchOptions:`
    ///
    /// - Parameter launchOptions: App launch options dictionary
    public func initSession(launchOptions: [UIApplication.LaunchOptionsKey: Any]?) {
        let options = buildOptions(launchOptions: launchOptions)
        startInitialization(options: options, callback: nil)
    }

    // MARK: Method 2: With isReferrable

    /// Initialize session with launch options and referrable flag.
    ///
    /// Maps to v3: `initSessionWithLaunchOptions:isReferrable:`
    ///
    /// - Parameters:
    ///   - launchOptions: App launch options dictionary
    ///   - isReferrable: Whether to force referral status
    public func initSession(
        launchOptions: [UIApplication.LaunchOptionsKey: Any]?,
        isReferrable: Bool
    ) {
        let options = buildOptions(launchOptions: launchOptions, isReferrable: isReferrable)
        startInitialization(options: options, callback: nil)
    }

    // MARK: Method 3: With callback

    /// Initialize session with launch options and deep link handler.
    ///
    /// Maps to v3: `initSessionWithLaunchOptions:andRegisterDeepLinkHandler:`
    ///
    /// - Parameters:
    ///   - launchOptions: App launch options dictionary
    ///   - callback: Callback invoked with session params or error
    public func initSession(
        launchOptions: [UIApplication.LaunchOptionsKey: Any]?,
        andRegisterDeepLinkHandler callback: LegacySessionCallback?
    ) {
        let options = buildOptions(launchOptions: launchOptions)
        startInitialization(options: options, callback: callback)
    }

    // MARK: Method 4: With automaticallyDisplayDeepLinkController

    /// Initialize session with automatic deep link controller display.
    ///
    /// Maps to v3: `initSessionWithLaunchOptions:automaticallyDisplayDeepLinkController:`
    ///
    /// - Parameters:
    ///   - launchOptions: App launch options dictionary
    ///   - automaticallyDisplayDeepLinkController: Whether to auto-display controller
    public func initSession(
        launchOptions: [UIApplication.LaunchOptionsKey: Any]?,
        automaticallyDisplayDeepLinkController: Bool
    ) {
        let options = buildOptions(
            launchOptions: launchOptions,
            automaticallyDisplayDeepLinkController: automaticallyDisplayDeepLinkController
        )
        startInitialization(options: options, callback: nil)
    }

    // MARK: Method 5: With isReferrable and callback

    /// Initialize session with referrable flag and deep link handler.
    ///
    /// Maps to v3: `initSessionWithLaunchOptions:isReferrable:andRegisterDeepLinkHandler:`
    ///
    /// - Parameters:
    ///   - launchOptions: App launch options dictionary
    ///   - isReferrable: Whether to force referral status
    ///   - callback: Callback invoked with session params or error
    public func initSession(
        launchOptions: [UIApplication.LaunchOptionsKey: Any]?,
        isReferrable: Bool,
        andRegisterDeepLinkHandler callback: LegacySessionCallback?
    ) {
        let options = buildOptions(launchOptions: launchOptions, isReferrable: isReferrable)
        startInitialization(options: options, callback: callback)
    }

    // MARK: Method 6: With isReferrable and automaticallyDisplayDeepLinkController

    /// Initialize session with referrable and auto-display flags.
    ///
    /// Maps to v3: `initSessionWithLaunchOptions:isReferrable:automaticallyDisplayDeepLinkController:`
    ///
    /// - Parameters:
    ///   - launchOptions: App launch options dictionary
    ///   - isReferrable: Whether to force referral status
    ///   - automaticallyDisplayDeepLinkController: Whether to auto-display controller
    public func initSession(
        launchOptions: [UIApplication.LaunchOptionsKey: Any]?,
        isReferrable: Bool,
        automaticallyDisplayDeepLinkController: Bool
    ) {
        let options = buildOptions(
            launchOptions: launchOptions,
            isReferrable: isReferrable,
            automaticallyDisplayDeepLinkController: automaticallyDisplayDeepLinkController
        )
        startInitialization(options: options, callback: nil)
    }

    // MARK: Method 7: With automaticallyDisplayDeepLinkController and callback

    /// Initialize session with auto-display and deep link handler.
    ///
    /// Maps to v3: `initSessionWithLaunchOptions:automaticallyDisplayDeepLinkController:deepLinkHandler:`
    ///
    /// - Parameters:
    ///   - launchOptions: App launch options dictionary
    ///   - automaticallyDisplayDeepLinkController: Whether to auto-display controller
    ///   - callback: Callback invoked with session params or error
    public func initSession(
        launchOptions: [UIApplication.LaunchOptionsKey: Any]?,
        automaticallyDisplayDeepLinkController: Bool,
        deepLinkHandler callback: LegacySessionCallback?
    ) {
        let options = buildOptions(
            launchOptions: launchOptions,
            automaticallyDisplayDeepLinkController: automaticallyDisplayDeepLinkController
        )
        startInitialization(options: options, callback: callback)
    }

    // MARK: Method 8: Full options (all parameters)

    /// Initialize session with all options.
    ///
    /// Maps to v3: `initSessionWithLaunchOptions:automaticallyDisplayDeepLinkController:isReferrable:deepLinkHandler:`
    ///
    /// - Parameters:
    ///   - launchOptions: App launch options dictionary
    ///   - automaticallyDisplayDeepLinkController: Whether to auto-display controller
    ///   - isReferrable: Whether to force referral status
    ///   - callback: Callback invoked with session params or error
    public func initSession(
        launchOptions: [UIApplication.LaunchOptionsKey: Any]?,
        automaticallyDisplayDeepLinkController: Bool,
        isReferrable: Bool,
        deepLinkHandler callback: LegacySessionCallback?
    ) {
        let options = buildOptions(
            launchOptions: launchOptions,
            isReferrable: isReferrable,
            automaticallyDisplayDeepLinkController: automaticallyDisplayDeepLinkController
        )
        startInitialization(options: options, callback: callback)
    }

    #endif

    // MARK: - Cross-Platform Methods (macOS, watchOS, tvOS)

    /// Initialize session without launch options.
    ///
    /// Use this for platforms without UIApplication.
    public func initSession() {
        startInitialization(options: InitializationOptions(), callback: nil)
    }

    /// Initialize session with callback only.
    ///
    /// - Parameter callback: Callback invoked with session params or error
    public func initSession(callback: LegacySessionCallback?) {
        startInitialization(options: InitializationOptions(), callback: callback)
    }

    /// Initialize session with URL.
    ///
    /// - Parameters:
    ///   - url: Deep link or universal link URL
    ///   - callback: Callback invoked with session params or error
    public func initSession(url: URL?, callback: LegacySessionCallback?) {
        var options = InitializationOptions()
        options.url = url
        startInitialization(options: options, callback: callback)
    }

    // MARK: Private

    #if canImport(UIKit)
    /// Builds InitializationOptions from legacy parameters.
    private func buildOptions(
        launchOptions: [UIApplication.LaunchOptionsKey: Any]?,
        isReferrable: Bool? = nil,
        automaticallyDisplayDeepLinkController: Bool = false
    ) -> InitializationOptions {
        var options = InitializationOptions()
            .with(launchOptions: launchOptions)
            .with(automaticallyDisplayDeepLinkController: automaticallyDisplayDeepLinkController)

        if let isReferrable {
            options = options.with(isReferrable: isReferrable)
        }

        return options
    }
    #endif

    /// Starts initialization and bridges async result to callback.
    private func startInitialization(
        options: InitializationOptions,
        callback: LegacySessionCallback?
    ) {
        Task { @MainActor in
            do {
                // Try to get existing session, otherwise initialize
                let session: Session = if let existingSession = await Branch.shared.currentSession {
                    existingSession
                } else {
                    try await initializeIfNeeded(options: options)
                }

                // Convert session to legacy dictionary format
                let params = session.legacyDictionary

                // Invoke callback on main thread
                if let callback {
                    callback(params, nil)
                }
            } catch {
                // Invoke callback with error on main thread
                if let callback {
                    callback(nil, error)
                }
            }
        }
    }

    /// Initializes Branch if not already initialized.
    private func initializeIfNeeded(options: InitializationOptions) async throws -> Session {
        // Get current state to check if already initialized
        let state = await Branch.shared.state

        switch state {
        case let .initialized(session):
            return session
        case .initializing,
             .uninitialized:
            // For legacy initialization, we need configuration to be set separately
            // This matches v3 behavior where configuration was set before init
            // Use the internal initialization method via Branch
            return try await Branch.shared.initializeSession(options: options)
        }
    }
}

// MARK: - Branch Legacy Extensions

#if canImport(UIKit)
public extension Branch {
    // MARK: - Legacy Init Methods

    /// Initialize session with launch options (legacy compatibility).
    ///
    /// - Parameter launchOptions: App launch options dictionary
    @available(*, deprecated, message: "Use async initialize(with:options:) instead")
    func initSession(launchOptions: [UIApplication.LaunchOptionsKey: Any]?) {
        LegacySessionBridge.shared.initSession(launchOptions: launchOptions)
    }

    /// Initialize session with launch options and callback (legacy compatibility).
    ///
    /// - Parameters:
    ///   - launchOptions: App launch options dictionary
    ///   - callback: Callback invoked with session params or error
    @available(*, deprecated, message: "Use async initialize(with:options:) instead")
    func initSession(
        launchOptions: [UIApplication.LaunchOptionsKey: Any]?,
        andRegisterDeepLinkHandler callback: LegacySessionCallback?
    ) {
        LegacySessionBridge.shared.initSession(
            launchOptions: launchOptions,
            andRegisterDeepLinkHandler: callback
        )
    }

    /// Initialize session with all legacy options (legacy compatibility).
    ///
    /// - Parameters:
    ///   - launchOptions: App launch options dictionary
    ///   - automaticallyDisplayDeepLinkController: Whether to auto-display controller
    ///   - isReferrable: Whether to force referral status
    ///   - callback: Callback invoked with session params or error
    @available(*, deprecated, message: "Use async initialize(with:options:) instead")
    func initSession(
        launchOptions: [UIApplication.LaunchOptionsKey: Any]?,
        automaticallyDisplayDeepLinkController: Bool,
        isReferrable: Bool,
        deepLinkHandler callback: LegacySessionCallback?
    ) {
        LegacySessionBridge.shared.initSession(
            launchOptions: launchOptions,
            automaticallyDisplayDeepLinkController: automaticallyDisplayDeepLinkController,
            isReferrable: isReferrable,
            deepLinkHandler: callback
        )
    }
}
#endif
