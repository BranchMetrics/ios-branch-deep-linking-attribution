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

/// Integration helper for using the new SessionManager with the existing Objective-C SDK.
///
/// This class provides static methods that can be called from Objective-C to leverage
/// the new Swift SessionManager with task coalescing support.
///
/// ## Usage from BranchScene.m
///
/// ```objc
/// #if BRANCH_USE_MODERN_SESSION_MANAGER
/// @import BranchSwiftSDK;
/// #endif
///
/// - (void)scene:(UIScene *)scene continueUserActivity:(NSUserActivity *)userActivity {
///     #if BRANCH_USE_MODERN_SESSION_MANAGER
///     [BranchSessionIntegration handleUserActivity:userActivity
///                                  sceneIdentifier:scene.session.persistentIdentifier
///                                       completion:^(NSDictionary *params, NSError *error) {
///         // Notify delegate
///     }];
///     #else
///     [[Branch getInstance] continueUserActivity:userActivity sceneIdentifier:identifier];
///     #endif
/// }
/// ```
@available(iOS 13.0, macOS 10.15, tvOS 13.0, watchOS 6.0, *)
@objc(BranchSessionIntegration)
public final class BranchSessionIntegration: NSObject {
    // MARK: Public

    /// Process a Universal Link from NSUserActivity using task coalescing.
    ///
    /// This method integrates with the SessionManager to ensure that concurrent
    /// calls (from didFinishLaunching and continueUserActivity) are coalesced
    /// into a single network request.
    ///
    /// - Parameters:
    ///   - userActivity: The user activity containing the Universal Link
    ///   - sceneIdentifier: Optional scene identifier for multi-window support
    ///   - completion: Callback with session parameters and error
    @objc public static func handleUserActivity(
        _ userActivity: NSUserActivity,
        sceneIdentifier: String?,
        completion: @escaping ([String: Any]?, Error?) -> Void
    ) {
        guard userActivity.activityType == NSUserActivityTypeBrowsingWeb,
              let url = userActivity.webpageURL
        else {
            completion(nil, BranchError.invalidUserActivity)
            return
        }

        handleURL(url, sceneIdentifier: sceneIdentifier, completion: completion)
    }

    /// Process a URL using task coalescing.
    ///
    /// - Parameters:
    ///   - url: The URL to process
    ///   - sceneIdentifier: Optional scene identifier
    ///   - completion: Callback with session parameters and error
    @objc public static func handleURL(
        _ url: URL,
        sceneIdentifier: String?,
        completion: @escaping ([String: Any]?, Error?) -> Void
    ) {
        Task {
            do {
                let coordinator = BranchSessionCoordinator.shared
                var options = InitializationOptions()
                options.url = url
                options.sceneIdentifier = sceneIdentifier

                let session = try await coordinator.sessionManager.initialize(options: options)

                // Convert session to dictionary format expected by legacy SDK
                let params = convertSessionToParams(session)

                await MainActor.run {
                    completion(params, nil)
                }
            } catch {
                await MainActor.run {
                    completion(nil, error)
                }
            }
        }
    }

    /// Initialize session without a URL (called from didFinishLaunchingWithOptions).
    ///
    /// This starts the initialization process. If a URL arrives via continueUserActivity
    /// before this completes, it will be coalesced into the same network request.
    ///
    /// - Parameters:
    ///   - sceneIdentifier: Optional scene identifier
    ///   - completion: Callback with session parameters and error
    @objc public static func initializeSession(
        sceneIdentifier: String?,
        completion: @escaping ([String: Any]?, Error?) -> Void
    ) {
        Task {
            do {
                let coordinator = BranchSessionCoordinator.shared
                var options = InitializationOptions()
                options.sceneIdentifier = sceneIdentifier

                let session = try await coordinator.sessionManager.initialize(options: options)
                let params = convertSessionToParams(session)

                await MainActor.run {
                    completion(params, nil)
                }
            } catch {
                await MainActor.run {
                    completion(nil, error)
                }
            }
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

    // MARK: Private

    /// Convert Session to dictionary format compatible with legacy SDK callbacks.
    private static func convertSessionToParams(_ session: Session) -> [String: Any] {
        var params: [String: Any] = [:]

        // Standard session fields
        params["session_id"] = session.id
        params["identity_id"] = session.identityId
        params["device_fingerprint_id"] = session.deviceFingerprintId
        params["+is_first_session"] = session.isFirstSession

        // User identity
        if let userId = session.userId {
            params["identity"] = userId
        }

        // Link data
        if let linkData = session.linkData {
            params["+clicked_branch_link"] = linkData.isClicked

            if let url = linkData.url {
                params["~referring_link"] = url.absoluteString
            }

            if let campaign = linkData.campaign {
                params["~campaign"] = campaign
            }

            if let channel = linkData.channel {
                params["~channel"] = channel
            }

            if let feature = linkData.feature {
                params["~feature"] = feature
            }

            if let tags = linkData.tags {
                params["~tags"] = tags
            }

            if let stage = linkData.stage {
                params["~stage"] = stage
            }

            // Custom parameters
            for (key, value) in linkData.parameters {
                params[key] = value.value
            }
        } else {
            params["+clicked_branch_link"] = false
        }

        return params
    }
}

// MARK: - Feature Flag

/// Feature flag to enable/disable the modern session manager.
///
/// Set this before initializing Branch to use the new SessionManager
/// with task coalescing support.
@available(iOS 13.0, macOS 10.15, tvOS 13.0, watchOS 6.0, *)
@objc(BranchSessionFeatureFlags)
public final class BranchSessionFeatureFlags: NSObject {
    /// Enable the modern Swift SessionManager with task coalescing.
    ///
    /// When enabled, session initialization uses the new actor-based
    /// SessionManager which prevents double OPEN requests.
    ///
    /// Default: false (uses legacy implementation)
    @objc public nonisolated(unsafe) static var useModernSessionManager: Bool = false
}
