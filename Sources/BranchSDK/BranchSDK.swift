//
//  BranchSDK.swift
//  Branch iOS SDK - Modern Swift Implementation
//
//  Copyright © 2026 Branch Metrics. All rights reserved.
//  SPDX-License-Identifier: MIT
//

import Foundation

/// Branch SDK version
public let branchSDKVersion = "4.0.0-alpha.1"

// MARK: - Branch

/// Main entry point for the Branch SDK
///
/// The `Branch` class provides a modern, actor-based API for session management,
/// deep linking, and attribution tracking.
///
/// ## Quick Start
///
/// ```swift
/// // Configure and initialize
/// let config = BranchConfiguration(apiKey: "key_live_xxx")
/// let session = try await Branch.shared.initialize(with: config)
///
/// // Handle deep link data
/// if let data = session.linkData {
///     print("Deep link: \(data)")
/// }
/// ```
///
/// ## Features
///
/// - **Actor-based concurrency**: Thread-safe by design
/// - **Async/await API**: Modern Swift concurrency
/// - **Protocol-based DI**: Full testability
/// - **Typed errors**: Clear error handling
///
@MainActor
public final class Branch: Sendable {
    // MARK: Lifecycle

    // MARK: - Initialization

    private init() {
        container = BranchContainer.shared
    }

    /// Initialize Branch for testing with custom container
    init(container: BranchContainer) {
        self.container = container
    }

    // MARK: Public

    // MARK: - Singleton

    /// Shared Branch instance
    public static let shared = Branch()

    /// Current session state
    public var state: SessionState {
        get async {
            await container.sessionManager.state
        }
    }

    /// Current session if initialized
    public var currentSession: Session? {
        get async {
            await container.sessionManager.currentSession
        }
    }

    // MARK: - Session Management

    /// Initialize the Branch session
    ///
    /// This is the primary entry point for SDK initialization. It consolidates
    /// the 15+ legacy `initSession` methods into a single, modern API.
    ///
    /// - Parameters:
    ///   - configuration: Branch configuration with API key and settings
    ///   - options: Optional initialization options (launch options, URL, etc.)
    /// - Returns: The initialized session
    /// - Throws: `BranchError` if initialization fails
    ///
    /// ## Example
    ///
    /// ```swift
    /// // Basic initialization
    /// let config = BranchConfiguration(apiKey: "key_live_xxx")
    /// let session = try await Branch.shared.initialize(with: config)
    /// ```
    @discardableResult
    public func initialize(
        with configuration: BranchConfiguration,
        options: InitializationOptions = InitializationOptions()
    ) async throws -> Session {
        // Configure the container
        await container.configure(with: configuration)

        // Initialize session
        return try await container.sessionManager.initialize(options: options)
    }

    /// Handle incoming URL (Universal Links, URI Schemes)
    ///
    /// Call this from `application(_:continue:restorationHandler:)` or
    /// `scene(_:continue:)` to process deep links.
    ///
    /// - Parameter url: The incoming URL
    /// - Returns: Updated session with link data
    @discardableResult
    public func handleDeepLink(_ url: URL) async throws -> Session {
        try await container.sessionManager.handleDeepLink(url)
    }

    /// Reset the session (logout)
    ///
    /// Clears all session data and returns to uninitialized state.
    public func reset() async {
        await container.sessionManager.reset()
    }

    /// Observe session state changes
    ///
    /// Returns an async stream that emits state changes.
    ///
    /// ```swift
    /// for await state in await Branch.shared.observeState() {
    ///     switch state {
    ///     case .uninitialized:
    ///         print("Not initialized")
    ///     case .initializing:
    ///         print("Initializing...")
    ///     case .initialized(let session):
    ///         print("Ready: \(session.id)")
    ///     }
    /// }
    /// ```
    public func observeState() async -> AsyncStream<SessionState> {
        await container.sessionManager.observeState()
    }

    // MARK: - User Identity

    /// Set user identity for cross-device tracking
    public func setIdentity(_ userId: String) async throws {
        try await container.sessionManager.setIdentity(userId)
    }

    /// Clear user identity (logout)
    public func logout() async throws {
        try await container.sessionManager.logout()
    }

    // MARK: - Events

    /// Track a custom event
    public func trackEvent(_ event: BranchEvent) async throws {
        try await container.eventTracker.track(event)
    }

    // MARK: - Deep Links

    /// Create a Branch deep link
    public func createDeepLink(_ properties: LinkProperties) async throws -> URL {
        try await container.linkGenerator.create(with: properties)
    }

    // MARK: - Debugging

    /// Enable debug logging
    public func enableLogging(_ level: LogLevel = .debug) {
        container.logger.minimumLevel = level
    }

    /// Validate SDK integration
    public func validateIntegration() async -> IntegrationValidation {
        await container.integrationValidator.validate()
    }

    // MARK: Private

    /// Dependency injection container
    private let container: BranchContainer
}

// MARK: - UIKit Convenience Extensions

#if canImport(UIKit)
import UIKit

public extension Branch {
    /// Initialize with launch options (convenience method for AppDelegate)
    @discardableResult
    func initialize(
        with configuration: BranchConfiguration,
        launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil
    ) async throws -> Session {
        var options = InitializationOptions()
        if let url = launchOptions?[.url] as? URL {
            options = options.with(url: url)
        }
        return try await initialize(with: configuration, options: options)
    }

    /// Handle URL from `application(_:open:options:)`
    @discardableResult
    func handleURL(
        _ url: URL,
        options _: [UIApplication.OpenURLOptionsKey: Any] = [:]
    ) async throws -> Session {
        try await handleDeepLink(url)
    }

    /// Handle Universal Link from `application(_:continue:restorationHandler:)`
    @discardableResult
    func handleUniversalLink(_ userActivity: NSUserActivity) async throws -> Session {
        guard userActivity.activityType == NSUserActivityTypeBrowsingWeb,
              let url = userActivity.webpageURL
        else {
            throw BranchError.invalidUserActivity
        }
        return try await handleDeepLink(url)
    }
}
#endif

// MARK: - SceneDelegate Support (iOS 13+)

#if canImport(UIKit)
@available(iOS 13.0, tvOS 13.0, *)
public extension Branch {
    /// Handle scene connection with options
    @discardableResult
    func handleSceneConnection(
        _ scene: UIScene,
        options connectionOptions: UIScene.ConnectionOptions
    ) async throws -> Session {
        var initOptions = InitializationOptions()

        // Handle URL contexts
        if let urlContext = connectionOptions.urlContexts.first {
            initOptions = initOptions.with(url: urlContext.url)
        }

        // Handle user activities
        if let userActivity = connectionOptions.userActivities.first,
           let url = userActivity.webpageURL
        {
            initOptions = initOptions.with(url: url)
        }

        initOptions = initOptions.with(sceneIdentifier: scene.session.persistentIdentifier)

        return try await container.sessionManager.initialize(options: initOptions)
    }

    /// Handle scene URL open
    @discardableResult
    func handleSceneURL(_ urlContexts: Set<UIOpenURLContext>) async throws -> Session {
        guard let url = urlContexts.first?.url else {
            throw BranchError.noURLProvided
        }
        return try await handleDeepLink(url)
    }

    /// Handle scene universal link
    @discardableResult
    func handleSceneUserActivity(_ userActivity: NSUserActivity) async throws -> Session {
        try await handleUniversalLink(userActivity)
    }
}
#endif
