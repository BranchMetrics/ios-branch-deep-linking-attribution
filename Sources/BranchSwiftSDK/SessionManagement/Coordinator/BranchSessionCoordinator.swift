//
//  BranchSessionCoordinator.swift
//  Branch iOS SDK - Modern Swift Implementation
//
//  Copyright © 2026 Branch Metrics. All rights reserved.
//  SPDX-License-Identifier: MIT
//

import Foundation

#if canImport(BranchSDK)
    import BranchSDK
#endif

// MARK: - BranchSessionCoordinator

/// Coordinates session management using SessionManager as single source of truth.
///
/// This coordinator provides a simplified API for all SDK consumers.
/// It uses GCD-based SessionManager for iOS 12+ compatibility.
///
/// ## Thread Safety
///
/// This class is thread-safe. All public methods can be called from any thread.
/// Completion handlers are always called on the main thread.
///
/// ## Usage
///
/// ```swift
/// BranchSessionCoordinator.shared.initialize(url: url) { session, error in
///     if let session = session {
///         print("Session ID: \(session.id)")
///     }
/// }
/// ```
///
/// ## Objective-C Usage
///
/// ```objc
/// [[BranchSessionCoordinator shared] initializeWithUrl:url completion:^(Session *session, NSError *error) {
///     // Handle result
/// }];
/// ```
@objc(BranchSessionCoordinator)
public final class BranchSessionCoordinator: NSObject {
    // MARK: - Singleton

    @objc public static let shared = BranchSessionCoordinator()

    // MARK: - Session Manager

    /// The session manager - single source of truth for all session operations.
    ///
    /// Note: This is the ONLY session manager. There is no iOS 13+ actor alternative.
    @objc public let sessionManager = SessionManager.shared

    // MARK: - Convenience Properties

    /// Current session state
    @objc public var state: SessionState {
        sessionManager.state
    }

    /// Current session (nil if not initialized)
    @objc public var currentSession: Session? {
        sessionManager.currentSession
    }

    /// Whether initialization is in progress
    @objc public var isInitializing: Bool {
        sessionManager.isInitializing
    }

    /// Whether SDK is fully initialized
    @objc public var isInitialized: Bool {
        sessionManager.isInitialized
    }

    // MARK: - Private Properties

    /// Logger for SDK diagnostics
    private let logger: Logging = BranchLoggerAdapter.shared

    // MARK: - Initialization

    override private init() {
        super.init()
        log(.debug, "BranchSessionCoordinator initialized")
    }

    // MARK: - Public API

    /// Initialize session with optional URL.
    ///
    /// This method implements task coalescing - if called multiple times concurrently
    /// (e.g., from `didFinishLaunchingWithOptions` and `continueUserActivity`), only one
    /// network request will be made and the URL will be properly merged.
    ///
    /// - Parameters:
    ///   - url: Optional URL that opened the app (Universal Link, URI scheme, etc.)
    ///   - completion: Callback with Session or error (called on main thread)
    @objc public func initialize(
        url: URL?,
        completion: @escaping (Session?, NSError?) -> Void
    ) {
        log(.debug, "initialize called - URL: \(url?.absoluteString ?? "none")")

        let options = InitializationOptions()
        options.url = url
        sessionManager.initialize(options: options, completion: completion)
    }

    /// Initialize session with options.
    ///
    /// - Parameters:
    ///   - options: Initialization options
    ///   - completion: Callback with Session or error (called on main thread)
    @objc public func initialize(
        options: InitializationOptions?,
        completion: @escaping (Session?, NSError?) -> Void
    ) {
        log(.debug, "initialize with options called")
        sessionManager.initialize(options: options, completion: completion)
    }

    /// Initialize session without URL.
    ///
    /// - Parameter completion: Callback with Session or error (called on main thread)
    @objc public func initialize(
        completion: @escaping (Session?, NSError?) -> Void
    ) {
        log(.debug, "initialize called (no URL)")
        sessionManager.initialize(options: nil, completion: completion)
    }

    /// Handle deep link URL.
    ///
    /// If initialization is in progress, the URL will be queued and processed
    /// when initialization completes (task coalescing).
    ///
    /// - Parameters:
    ///   - url: The deep link URL
    ///   - completion: Callback with Session or error (called on main thread)
    @objc public func handleDeepLink(
        _ url: URL,
        completion: @escaping (Session?, NSError?) -> Void
    ) {
        log(.debug, "handleDeepLink called - URL: \(url.absoluteString)")
        sessionManager.handleDeepLink(url, completion: completion)
    }

    /// Handle Universal Link via NSUserActivity.
    ///
    /// Extracts the URL from the user activity and processes it through the session manager.
    ///
    /// - Parameters:
    ///   - userActivity: The user activity containing the Universal Link
    ///   - completion: Callback with Session or error (called on main thread)
    @objc public func continueUserActivity(
        _ userActivity: NSUserActivity,
        completion: @escaping (Session?, NSError?) -> Void
    ) {
        log(.debug, "continueUserActivity called - activityType: \(userActivity.activityType)")

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
        handleDeepLink(url, completion: completion)
    }

    /// Reset session to uninitialized state.
    @objc public func reset() {
        log(.debug, "reset called")
        sessionManager.reset()
    }

    // MARK: - Notification Observation (replaces AsyncStream)

    /// Add observer for session state changes.
    ///
    /// This replaces the iOS 13+ `observeState()` AsyncStream pattern.
    ///
    /// - Parameters:
    ///   - observer: Object to receive notifications
    ///   - selector: Selector to call when state changes
    @objc public func addStateObserver(_ observer: Any, selector: Selector) {
        NotificationCenter.default.addObserver(
            observer,
            selector: selector,
            name: Notification.Name("BranchDidStartSessionNotification"),
            object: sessionManager
        )
        NotificationCenter.default.addObserver(
            observer,
            selector: selector,
            name: Notification.Name("BranchWillStartSessionNotification"),
            object: sessionManager
        )
    }

    /// Remove observer for session state changes.
    @objc public func removeStateObserver(_ observer: Any) {
        NotificationCenter.default.removeObserver(
            observer,
            name: Notification.Name("BranchDidStartSessionNotification"),
            object: sessionManager
        )
        NotificationCenter.default.removeObserver(
            observer,
            name: Notification.Name("BranchWillStartSessionNotification"),
            object: sessionManager
        )
    }

    // MARK: - Private Methods

    /// Convenience logging method using the logger.
    private func log(
        _ level: LogLevel,
        _ message: @autoclosure () -> String,
        file: String = #file,
        function: String = #function,
        line: Int = #line
    ) {
        logger.log(level, message(), file: file, function: function, line: line)
    }
}

// MARK: - Backward Compatibility Bridge

public extension BranchSessionCoordinator {
    /// Convert Session to params dictionary for backward compatibility.
    ///
    /// Use this when you need to pass session data to legacy callbacks
    /// that expect a `[String: Any]` dictionary format.
    ///
    /// - Parameter session: The session to convert
    /// - Returns: Dictionary in legacy params format
    @objc func paramsFromSession(_ session: Session) -> [String: Any] {
        var params: [String: Any] = session.params

        // Ensure standard fields are present
        params["session_id"] = session.id
        params["identity_id"] = session.identityId
        params["device_fingerprint_id"] = session.deviceFingerprintId
        params["+is_first_session"] = session.isFirstSession

        if let userId = session.userId {
            params["identity"] = userId
        }

        #if canImport(BranchSDK)
            if let linkData = session.linkData {
                params["+clicked_branch_link"] = true
                // Access data through the data dictionary
                if let channel = linkData.data["channel"] as? String {
                    params["~channel"] = channel
                }
                if let campaign = linkData.data["campaign"] as? String {
                    params["~campaign"] = campaign
                }
                if let feature = linkData.data["feature"] as? String {
                    params["~feature"] = feature
                }
                if let tags = linkData.data["tags"] as? [String] {
                    params["~tags"] = tags
                }
                if let stage = linkData.data["stage"] as? String {
                    params["~stage"] = stage
                }
            }
        #endif

        return params
    }
}
