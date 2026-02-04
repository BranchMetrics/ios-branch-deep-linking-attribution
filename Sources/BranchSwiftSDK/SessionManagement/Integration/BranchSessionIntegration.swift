//
//  BranchSessionIntegration.swift
//  Branch iOS SDK - Modern Swift Implementation
//
//  Copyright © 2026 Branch Metrics. All rights reserved.
//  SPDX-License-Identifier: MIT
//

import Foundation

#if canImport(BranchSDK)
    import BranchSDK
#endif

// MARK: - BranchSessionIntegration

/// Integration helper for using the SessionManager with the existing Objective-C SDK.
///
/// This class provides static methods that can be called from Objective-C to leverage
/// the new GCD-based SessionManager with task coalescing support.
///
/// ## Usage from BranchScene.m
///
/// ```objc
/// - (void)scene:(UIScene *)scene continueUserActivity:(NSUserActivity *)userActivity {
///     [BranchSessionIntegration handleUserActivity:userActivity
///                                  sceneIdentifier:scene.session.persistentIdentifier
///                                       completion:^(Session *session, NSError *error) {
///         // Notify delegate
///     }];
/// }
/// ```
@objc(BranchSessionIntegration)
public final class BranchSessionIntegration: NSObject {
    // MARK: - Private

    /// Shared logger for static methods
    private static let logger: Logging = BranchLoggerAdapter.shared

    /// Convenience logging method for static context.
    private static func log(
        _ level: LogLevel,
        _ message: @autoclosure () -> String,
        file: String = #file,
        function: String = #function,
        line: Int = #line
    ) {
        logger.log(level, message(), file: file, function: function, line: line)
    }

    // MARK: - Public API

    /// Process a Universal Link from NSUserActivity using task coalescing.
    ///
    /// This method integrates with the SessionManager to ensure that concurrent
    /// calls (from didFinishLaunching and continueUserActivity) are coalesced
    /// into a single network request.
    ///
    /// - Parameters:
    ///   - userActivity: The user activity containing the Universal Link
    ///   - sceneIdentifier: Optional scene identifier for multi-window support
    ///   - completion: Callback with Session and error
    @objc public static func handleUserActivity(
        _ userActivity: NSUserActivity,
        sceneIdentifier: String?,
        completion: @escaping (Session?, NSError?) -> Void
    ) {
        log(.debug, "handleUserActivity called - activityType: \(userActivity.activityType), scene: \(sceneIdentifier ?? "nil")")

        guard userActivity.activityType == NSUserActivityTypeBrowsingWeb,
              let url = userActivity.webpageURL
        else {
            log(.warning, "Invalid user activity - type: \(userActivity.activityType), webpageURL: \(userActivity.webpageURL?.absoluteString ?? "nil")")
            let error = NSError(
                domain: "io.branch.sdk",
                code: -1,
                userInfo: [NSLocalizedDescriptionKey: "Invalid user activity"]
            )
            DispatchQueue.main.async {
                completion(nil, error)
            }
            return
        }

        log(.debug, "Processing Universal Link: \(url.absoluteString)")
        handleURL(url, sceneIdentifier: sceneIdentifier, completion: completion)
    }

    /// Process a URL using task coalescing.
    ///
    /// - Parameters:
    ///   - url: The URL to process
    ///   - sceneIdentifier: Optional scene identifier
    ///   - completion: Callback with Session and error
    @objc public static func handleURL(
        _ url: URL,
        sceneIdentifier: String?,
        completion: @escaping (Session?, NSError?) -> Void
    ) {
        log(.debug, "handleURL called - URL: \(url.absoluteString), scene: \(sceneIdentifier ?? "nil")")

        let coordinator = BranchSessionCoordinator.shared
        let options = InitializationOptions()
        options.url = url
        options.sceneIdentifier = sceneIdentifier

        coordinator.initialize(options: options) { session, error in
            if let session = session {
                log(.debug, "handleURL completed successfully - sessionId: \(session.id)")
            } else if let error = error {
                log(.error, "handleURL failed: \(error.localizedDescription)")
            }
            completion(session, error)
        }
    }

    /// Initialize session without a URL (called from didFinishLaunchingWithOptions).
    ///
    /// This starts the initialization process. If a URL arrives via continueUserActivity
    /// before this completes, it will be coalesced into the same network request.
    ///
    /// - Parameters:
    ///   - sceneIdentifier: Optional scene identifier
    ///   - completion: Callback with Session and error
    @objc public static func initializeSession(
        sceneIdentifier: String?,
        completion: @escaping (Session?, NSError?) -> Void
    ) {
        log(.debug, "initializeSession called - scene: \(sceneIdentifier ?? "nil")")

        let coordinator = BranchSessionCoordinator.shared
        let options = InitializationOptions()
        options.sceneIdentifier = sceneIdentifier

        coordinator.initialize(options: options) { session, error in
            if let session = session {
                log(.debug, "Session initialized successfully - sessionId: \(session.id), isFirstSession: \(session.isFirstSession)")
            } else if let error = error {
                log(.error, "Session initialization failed: \(error.localizedDescription)")
            }
            completion(session, error)
        }
    }

    /// Check if a session initialization is currently in progress.
    ///
    /// Use this to determine if a URL should be queued for coalescing.
    @objc public static var isInitializing: Bool {
        BranchSessionCoordinator.shared.isInitializing
    }

    /// Check if a session is initialized.
    @objc public static var isInitialized: Bool {
        BranchSessionCoordinator.shared.isInitialized
    }

    /// Get the current session (nil if not initialized).
    @objc public static var currentSession: Session? {
        BranchSessionCoordinator.shared.currentSession
    }

    // MARK: - Backward Compatibility

    /// Convert Session to dictionary format compatible with legacy SDK callbacks.
    @objc public static func convertSessionToParams(_ session: Session) -> [String: Any] {
        BranchSessionCoordinator.shared.paramsFromSession(session)
    }
}

// MARK: - Feature Flag

/// Feature flag to enable/disable the modern session manager.
///
/// Note: In this iOS 12+ compatible version, there is only ONE session manager
/// (SessionManager). This flag is kept for backward compatibility but
/// has no effect - the "modern" GCD-based manager is always used.
///
/// Thread-safe: All access to the feature flag is synchronized via NSLock.
@objc(BranchSessionFeatureFlags)
public final class BranchSessionFeatureFlags: NSObject {
    // MARK: - Private

    private static let lock = NSLock()
    private static var _useModernSessionManager: Bool = true

    // MARK: - Public

    /// Enable the modern Swift SessionManager with task coalescing.
    ///
    /// Note: In iOS 12+ compatible builds, this is always true.
    /// There is no legacy fallback - SessionManager is the only implementation.
    ///
    /// Default: true (always uses the GCD-based SessionManager)
    ///
    /// Thread-safe: Can be safely read and written from any thread.
    @objc public static var useModernSessionManager: Bool {
        get {
            lock.lock()
            defer { lock.unlock() }
            return _useModernSessionManager
        }
        set {
            lock.lock()
            defer { lock.unlock() }
            // Note: In iOS 12+ builds, this is effectively a no-op
            // SessionManager is always used
            _useModernSessionManager = newValue
        }
    }
}
