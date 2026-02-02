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

/// Coordinates session management between the modern Swift SessionManager and the legacy Objective-C SDK.
///
/// This class provides the bridge layer that allows the existing Objective-C codebase to use
/// the new actor-based SessionManager with task coalescing support for the Double Open Fix (INTENG-21106).
///
/// ## Thread Safety
///
/// This class is thread-safe and uses Swift's structured concurrency to coordinate access
/// to the underlying SessionManager actor. All public methods can be called from any thread.
///
/// ## Usage from Objective-C
///
/// ```objc
/// [[BranchSessionCoordinator shared] initializeSessionWithURL:url completion:^(BranchSession *session, NSError *error) {
///     // Handle result
/// }];
/// ```
@available(iOS 13.0, macOS 10.15, tvOS 13.0, watchOS 6.0, *)
@objc(BranchSessionCoordinator)
public final class BranchSessionCoordinator: NSObject, @unchecked Sendable {
    // MARK: Lifecycle

    override private init() {
        let manager = SessionManager()
        sessionManager = manager
        observableState = BranchObservableState(sessionManager: manager)
        logger = BranchLoggerAdapter.shared
        super.init()
        log(.debug, "BranchSessionCoordinator initialized")
        startStateObservation()
    }

    /// Internal initializer for testing with custom dependencies.
    ///
    /// - Parameter networkService: Custom network service to use (e.g., mock for testing)
    init(networkService: any BranchNetworkService) {
        let manager = SessionManager(networkService: networkService)
        sessionManager = manager
        observableState = BranchObservableState(sessionManager: manager)
        logger = BranchLoggerAdapter.shared
        super.init()
        log(.debug, "BranchSessionCoordinator initialized with custom network service")
        startStateObservation()
    }

    // MARK: Public

    /// Lock for thread-safe access to shared instance
    private static let sharedLock = NSLock()
    private static var _shared: BranchSessionCoordinator = .init()

    /// Shared coordinator instance (thread-safe)
    @objc public static var shared: BranchSessionCoordinator {
        sharedLock.lock()
        defer { sharedLock.unlock() }
        return _shared
    }

    /// Internal storage for test mock network service.
    /// When set, the shared coordinator will be replaced with a new one using this service.
    private(set) nonisolated(unsafe) static var testNetworkService: (any BranchNetworkService)?

    /// Configure the shared coordinator with a mock network service for testing.
    ///
    /// - Parameter networkService: The mock network service to use, or nil to restore default behavior
    public static func configureForTesting(networkService: (any BranchNetworkService)?) {
        sharedLock.lock()
        defer { sharedLock.unlock() }
        testNetworkService = networkService
        if let service = networkService {
            _shared = BranchSessionCoordinator(networkService: service)
        } else {
            _shared = BranchSessionCoordinator()
        }
    }

    /// Reset the shared coordinator to default behavior (for test teardown).
    public static func resetTestConfiguration() {
        sharedLock.lock()
        defer { sharedLock.unlock() }
        testNetworkService = nil
        _shared = BranchSessionCoordinator()
    }

    /// The underlying session manager (for Swift consumers)
    public let sessionManager: SessionManager

    /// Observable state wrapper for SwiftUI and Combine integration.
    ///
    /// Use this property to observe session state changes in SwiftUI views
    /// or with Combine publishers. The state is automatically synchronized
    /// with the underlying SessionManager.
    ///
    /// ## SwiftUI Example
    ///
    /// ```swift
    /// struct ContentView: View {
    ///     @ObservedObject var branchState = BranchSessionCoordinator.shared.observableState
    ///
    ///     var body: some View {
    ///         Text("Status: \(branchState.stateDescription)")
    ///     }
    /// }
    /// ```
    public let observableState: BranchObservableState

    // MARK: - Objective-C Bridge Methods

    /// Initialize a session, optionally with a URL.
    ///
    /// This method implements task coalescing - if called multiple times concurrently
    /// (e.g., from `didFinishLaunchingWithOptions` and `continueUserActivity`), only one
    /// network request will be made and the URL will be properly merged.
    ///
    /// - Parameters:
    ///   - url: Optional URL that opened the app (Universal Link, URI scheme, etc.)
    ///   - completion: Callback with the session result
    @objc public func initializeSession(
        url: URL?,
        completion: @escaping (BranchObjCSession?, Error?) -> Void
    ) {
        log(.debug, "initializeSession called - URL: \(url?.absoluteString ?? "none")")

        Task {
            do {
                var options = InitializationOptions()
                options.url = url

                let session = try await sessionManager.initialize(options: options)
                let objcSession = BranchObjCSession(from: session)

                log(.debug, "Session initialized successfully - sessionId: \(session.id)")

                await MainActor.run {
                    completion(objcSession, nil)
                }
            } catch {
                log(.error, "Session initialization failed: \(error.localizedDescription)")

                await MainActor.run {
                    completion(nil, error)
                }
            }
        }
    }

    /// Check if the SDK is currently initializing.
    ///
    /// Use this to prevent redundant initialize calls.
    /// Thread-safe: acquires lock before reading cached value.
    @objc public var isInitializing: Bool {
        stateLock.lock()
        defer { stateLock.unlock() }
        return _cachedIsInitializing
    }

    /// Check if the SDK is initialized.
    /// Thread-safe: acquires lock before reading cached value.
    @objc public var isInitialized: Bool {
        stateLock.lock()
        defer { stateLock.unlock() }
        return _cachedIsInitialized
    }

    /// Handle a deep link URL.
    ///
    /// If initialization is in progress, the URL will be queued and processed
    /// when initialization completes (task coalescing).
    ///
    /// - Parameters:
    ///   - url: The deep link URL
    ///   - completion: Callback with the updated session
    @objc public func handleDeepLink(
        url: URL,
        completion: @escaping (BranchObjCSession?, Error?) -> Void
    ) {
        log(.debug, "handleDeepLink called - URL: \(url.absoluteString)")

        Task {
            do {
                // If we're currently initializing, queue this URL via initialize with URL
                let state = await sessionManager.state
                if state.isInitializing {
                    log(.debug, "Initialization in progress, coalescing URL")
                    var options = InitializationOptions()
                    options.url = url

                    let session = try await sessionManager.initialize(options: options)
                    let objcSession = BranchObjCSession(from: session)

                    log(.debug, "Deep link handled via coalescing - sessionId: \(session.id)")

                    await MainActor.run {
                        completion(objcSession, nil)
                    }
                } else {
                    let session = try await sessionManager.handleDeepLink(url)
                    let objcSession = BranchObjCSession(from: session)

                    log(.debug, "Deep link handled successfully - sessionId: \(session.id)")

                    await MainActor.run {
                        completion(objcSession, nil)
                    }
                }
            } catch {
                log(.error, "handleDeepLink failed: \(error.localizedDescription)")

                await MainActor.run {
                    completion(nil, error)
                }
            }
        }
    }

    /// Handle a Universal Link via NSUserActivity.
    ///
    /// Extracts the URL from the user activity and processes it through the session manager.
    ///
    /// - Parameters:
    ///   - userActivity: The user activity containing the Universal Link
    ///   - completion: Callback with the updated session
    @objc public func continueUserActivity(
        _ userActivity: NSUserActivity,
        completion: @escaping (BranchObjCSession?, Error?) -> Void
    ) {
        log(.debug, "continueUserActivity called - activityType: \(userActivity.activityType)")

        guard userActivity.activityType == NSUserActivityTypeBrowsingWeb,
              let url = userActivity.webpageURL
        else {
            log(.warning, "Invalid user activity - type: \(userActivity.activityType), webpageURL: \(userActivity.webpageURL?.absoluteString ?? "nil")")
            completion(nil, BranchError.invalidUserActivity)
            return
        }

        log(.debug, "Processing Universal Link: \(url.absoluteString)")
        handleDeepLink(url: url, completion: completion)
    }

    /// Reset the session to uninitialized state.
    @objc public func resetSession() {
        log(.debug, "resetSession called")
        Task {
            await sessionManager.reset()
            updateCachedState(.uninitialized)
            log(.debug, "Session reset completed")
        }
    }

    /// Set user identity.
    ///
    /// - Parameters:
    ///   - userId: The user identifier
    ///   - completion: Callback with result
    @objc public func setIdentity(
        _ userId: String,
        completion: @escaping (Error?) -> Void
    ) {
        log(.debug, "setIdentity called - userId: \(userId)")

        Task {
            do {
                try await sessionManager.setIdentity(userId)
                log(.debug, "Identity set successfully")
                await MainActor.run {
                    completion(nil)
                }
            } catch {
                log(.error, "setIdentity failed: \(error.localizedDescription)")
                await MainActor.run {
                    completion(error)
                }
            }
        }
    }

    /// Clear user identity (logout).
    ///
    /// - Parameter completion: Callback with result
    @objc public func logout(
        completion: @escaping (Error?) -> Void
    ) {
        log(.debug, "logout called")

        Task {
            do {
                try await sessionManager.logout()
                log(.debug, "Logout completed successfully")
                await MainActor.run {
                    completion(nil)
                }
            } catch {
                log(.error, "logout failed: \(error.localizedDescription)")
                await MainActor.run {
                    completion(error)
                }
            }
        }
    }

    // MARK: - Swift-Native Methods

    /// Observe session state changes (for Swift consumers).
    ///
    /// - Returns: AsyncStream of state changes
    public func observeState() -> AsyncStream<SessionState> {
        sessionManager.observeState()
    }

    /// Get current session state (async).
    public var state: SessionState {
        get async {
            await sessionManager.state
        }
    }

    /// Get current session (async).
    public var currentSession: Session? {
        get async {
            await sessionManager.currentSession
        }
    }

    // MARK: Private

    /// Logger for SDK diagnostics
    private let logger: any Logging

    /// Cached state flags for synchronous access from Objective-C
    private var _cachedIsInitializing: Bool = false
    private var _cachedIsInitialized: Bool = false
    private let stateLock = NSLock()

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

    /// Start observing state to keep cached values updated.
    ///
    /// Called automatically when the coordinator is first accessed.
    private func startStateObservation() {
        Task {
            for await state in sessionManager.observeState() {
                updateCachedState(state)
            }
        }
    }

    private func updateCachedState(_ state: SessionState) {
        stateLock.lock()
        defer { stateLock.unlock() }

        _cachedIsInitializing = state.isInitializing
        _cachedIsInitialized = state.isReady
    }
}

// MARK: - BranchObjCSession

/// Objective-C compatible session wrapper.
///
/// Wraps the Swift Session struct for use from Objective-C code.
@available(iOS 13.0, macOS 10.15, tvOS 13.0, watchOS 6.0, *)
@objc(BranchSession)
public final class BranchObjCSession: NSObject {
    // MARK: Lifecycle

    init(from session: Session) {
        sessionId = session.id
        identityId = session.identityId
        deviceFingerprintId = session.deviceFingerprintId
        isFirstSession = session.isFirstSession
        userId = session.userId
        linkUrl = session.linkData?.url

        // Convert [String: AnyCodable] to [String: Any] for Objective-C
        if let parameters = session.linkData?.parameters {
            var converted: [String: Any] = [:]
            for (key, value) in parameters {
                converted[key] = value.value
            }
            linkData = converted
        } else {
            linkData = [:]
        }

        super.init()
    }

    // MARK: Public

    /// The unique session identifier
    @objc public let sessionId: String

    /// The Branch identity ID
    @objc public let identityId: String

    /// The device fingerprint ID
    @objc public let deviceFingerprintId: String

    /// Whether this is the first session (install)
    @objc public let isFirstSession: Bool

    /// The user ID, if set
    @objc public let userId: String?

    /// The URL that opened the app, if any
    @objc public let linkUrl: URL?

    /// The deep link parameters, if any
    @objc public let linkData: [String: Any]
}

// MARK: - Initialization Convenience

@available(iOS 13.0, macOS 10.15, tvOS 13.0, watchOS 6.0, *)
public extension BranchSessionCoordinator {
    /// Initialize with default options.
    ///
    /// - Parameter completion: Callback with the session result
    @objc func initializeSession(
        completion: @escaping (BranchObjCSession?, Error?) -> Void
    ) {
        initializeSession(url: nil, completion: completion)
    }
}
