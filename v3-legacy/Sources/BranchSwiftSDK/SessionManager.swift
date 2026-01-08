//
//  SessionManager.swift
//  BranchSDK
//
//  Branch iOS SDK - Modern Swift Implementation
//  Copyright © 2026 Branch Metrics. All rights reserved.
//  SPDX-License-Identifier: MIT
//
//  JIRA: EMT-2726, EMT-2733
//  Core Session Manager Actor for SDK Modernization
//  Solves: Double Open Issue (INTENG-21106)
//

import Foundation

#if SWIFT_PACKAGE
    import BranchSDK
#endif

// MARK: - Session Manager Protocol

/// Protocol for session management operations.
/// Enables dependency injection and testing.
@available(iOS 13.0, tvOS 13.0, *)
public protocol SessionManaging: Sendable {
    /// Current session state.
    var currentState: SessionState { get async }

    /// Initializes a Branch session.
    func initialize(options: InitializationOptions) async throws -> BranchSession

    /// Observes state changes via AsyncStream.
    func observeState() -> AsyncStream<SessionState>

    /// Logs out and resets session state.
    func logout() async throws

    /// Forces a session refresh.
    func refresh() async throws -> BranchSession
}

// MARK: - Session Manager Actor

/// Thread-safe session manager using Swift Actor isolation.
///
/// The `SessionManager` solves the "Double Open Issue" (INTENG-21106) through:
/// 1. **Task Coalescing**: Multiple concurrent `initialize()` calls share a single task
/// 2. **State Machine**: Strict 3-state model prevents invalid transitions
/// 3. **Actor Isolation**: Thread-safe without manual locking
///
/// Usage:
/// ```swift
/// let session = try await SessionManager.shared.initialize(options: .appLaunch(options: nil))
/// ```
@available(iOS 13.0, tvOS 13.0, *)
public actor SessionManager: SessionManaging {
    // MARK: - Singleton

    /// Shared session manager instance.
    public static let shared = SessionManager()

    // MARK: - State

    /// Current session state (internal storage).
    private var _currentState: SessionState = .uninitialized

    /// Public accessor for current state.
    public var currentState: SessionState {
        _currentState
    }

    /// Active initialization task for coalescing.
    /// This is the KEY to solving the Double Open Issue.
    private var initializationTask: Task<BranchSession, Error>?

    /// State observation continuations.
    private var stateObservers: [UUID: AsyncStream<SessionState>.Continuation] = [:]

    // MARK: - Dependencies

    /// Server interface for network requests.
    private let serverInterface: BNCServerInterface

    /// Preference helper for persistent storage.
    private let preferenceHelper: BNCPreferenceHelper

    /// Branch key for API requests.
    private var branchKey: String?

    // MARK: - Initialization

    /// Creates a SessionManager with default dependencies.
    public init() {
        serverInterface = BNCServerInterface()
        preferenceHelper = BNCPreferenceHelper.sharedInstance()
    }

    /// Creates a SessionManager with injected dependencies (for testing).
    init(
        serverInterface: BNCServerInterface,
        preferenceHelper: BNCPreferenceHelper
    ) {
        self.serverInterface = serverInterface
        self.preferenceHelper = preferenceHelper
    }

    // MARK: - Configuration

    /// Configures the session manager with a Branch key.
    public func configure(branchKey: String) {
        self.branchKey = branchKey
    }

    // MARK: - Initialization

    /// Initializes a Branch session with the given options.
    ///
    /// This method implements **task coalescing** to prevent multiple concurrent
    /// initialization requests (the "Double Open Issue").
    ///
    /// Behavior:
    /// - If uninitialized: Starts new initialization
    /// - If initializing: Returns existing task (coalesced)
    /// - If initialized: Returns existing session
    /// - If failed: Retries initialization
    ///
    /// - Parameter options: Initialization configuration options.
    /// - Returns: The initialized `BranchSession`.
    /// - Throws: `BranchError` if initialization fails.
    public func initialize(options: InitializationOptions) async throws -> BranchSession {
        // Check current state and handle appropriately
        switch _currentState {
        case .uninitialized, .failed:
            // Start fresh initialization
            return try await startInitialization(options: options)

        case .initializing:
            // TASK COALESCING: Return existing task instead of starting a new one
            // This is the key fix for the Double Open Issue
            if let existingTask = initializationTask {
                BranchLogger.shared().logDebug(
                    "SessionManager: Coalescing initialization request with existing task",
                    error: nil
                )
                return try await existingTask.value
            }
            // Edge case: initializing state but no task (shouldn't happen)
            return try await startInitialization(options: options)

        case let .initialized(session):
            // Already initialized, return existing session
            BranchLogger.shared().logDebug(
                "SessionManager: Already initialized, returning existing session",
                error: nil
            )
            return session
        }
    }

    // MARK: - Private Initialization

    /// Starts a new initialization task.
    private func startInitialization(options: InitializationOptions) async throws -> BranchSession {
        // Validate state transition
        guard _currentState.canTransition(to: .initializing) else {
            throw BranchError.invalidStateTransition(
                from: String(describing: _currentState),
                to: "initializing"
            )
        }

        // Transition to initializing state
        transitionState(to: .initializing)

        // Create the initialization task
        let task = Task<BranchSession, Error> { [weak self] in
            guard let self = self else {
                throw BranchError.general("SessionManager was deallocated")
            }
            return try await self.performInitialization(options: options)
        }

        initializationTask = task

        do {
            let session = try await task.value
            // Transition to initialized state
            await transitionState(to: .initialized(session))
            initializationTask = nil
            return session
        } catch {
            // Transition to failed state
            let branchError = (error as? BranchError) ?? BranchError.unknown(error.localizedDescription)
            await transitionState(to: .failed(branchError))
            initializationTask = nil
            throw branchError
        }
    }

    /// Performs the actual initialization network request.
    private func performInitialization(options: InitializationOptions) async throws -> BranchSession {
        // Validate Branch key
        guard let key = branchKey ?? Branch.branchKey() else {
            throw BranchError.invalidBranchKey("Branch key not configured")
        }

        // Configure options in ConfigurationController
        ConfigurationController.shared.checkPasteboardOnInstall = options.checkPasteboardOnInstall
        ConfigurationController.shared.deferInitForPluginRuntime = options.deferInitForPluginRuntime

        // Determine if this is an install or open request
        let isFirstSession = preferenceHelper.randomizedBundleToken == nil

        // Build request parameters
        var params: [String: Any] = [:]
        params["branch_key"] = key

        if let url = options.launchURL ?? options.referringURL {
            params["external_intent_uri"] = url.absoluteString
        }

        if let activity = options.userActivity,
           let webpageURL = activity.webpageURL
        {
            params["universal_link_url"] = webpageURL.absoluteString
        }

        // Add configuration info
        params.merge(ConfigurationController.shared.getConfiguration()) { _, new in new }

        // Perform network request with continuation bridge
        let response = try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<[String: Any], Error>) in
            let endpoint = isFirstSession ? "v1/install" : "v1/open"

            self.serverInterface.postRequest(
                params,
                url: endpoint,
                key: key
            ) { response, error in
                if let error = error {
                    continuation.resume(throwing: BranchError.from(nsError: error as NSError))
                } else if let data = response?.data as? [String: Any] {
                    continuation.resume(returning: data)
                } else {
                    continuation.resume(
                        throwing: BranchError.initializationFailed(reason: "Invalid server response")
                    )
                }
            }
        }

        // Parse response into BranchSession
        let session = BranchSession.from(response: response)

        // Update preference helper with session data
        if let sessionId = session.sessionId {
            preferenceHelper.sessionID = sessionId
        }
        if let bundleToken = session.randomizedBundleToken {
            preferenceHelper.randomizedBundleToken = bundleToken
        }
        if let deviceToken = session.randomizedDeviceToken {
            preferenceHelper.randomizedDeviceToken = deviceToken
        }

        BranchLogger.shared().logDebug(
            "SessionManager: Initialization complete. Session ID: \(session.sessionId ?? "nil")",
            error: nil
        )

        return session
    }

    // MARK: - State Observation

    /// Observes session state changes via AsyncStream.
    ///
    /// Usage:
    /// ```swift
    /// for await state in sessionManager.observeState() {
    ///     switch state {
    ///     case .initialized(let session):
    ///         print("Session ready: \(session.sessionId)")
    ///     default:
    ///         break
    ///     }
    /// }
    /// ```
    nonisolated public func observeState() -> AsyncStream<SessionState> {
        AsyncStream { continuation in
            let id = UUID()

            // Access actor state via Task
            Task { [weak self] in
                guard let self = self else { return }

                // Send current state immediately
                let currentState = await self.currentState
                continuation.yield(currentState)

                // Store continuation for future updates
                await self.addObserver(id: id, continuation: continuation)
            }

            // Clean up on termination
            continuation.onTermination = { [weak self] _ in
                Task { [weak self] in
                    await self?.removeObserver(id: id)
                }
            }
        }
    }

    /// Adds a state observer.
    private func addObserver(id: UUID, continuation: AsyncStream<SessionState>.Continuation) {
        stateObservers[id] = continuation
    }

    /// Removes a state observer.
    private func removeObserver(id: UUID) {
        stateObservers.removeValue(forKey: id)
    }

    // MARK: - State Transitions

    /// Transitions to a new state and notifies observers.
    private func transitionState(to newState: SessionState) {
        guard _currentState.canTransition(to: newState) else {
            BranchLogger.shared().logWarning(
                "SessionManager: Invalid state transition from \(_currentState) to \(newState)",
                error: nil
            )
            return
        }

        let oldState = _currentState
        _currentState = newState

        BranchLogger.shared().logDebug(
            "SessionManager: State transition \(oldState) -> \(newState)",
            error: nil
        )

        // Notify all observers
        for (_, continuation) in stateObservers {
            continuation.yield(newState)
        }
    }

    // MARK: - Logout

    /// Logs out and resets the session state.
    public func logout() async throws {
        guard _currentState.canTransition(to: .uninitialized) else {
            throw BranchError.invalidStateTransition(
                from: String(describing: _currentState),
                to: "uninitialized"
            )
        }

        // Cancel any in-progress initialization
        initializationTask?.cancel()
        initializationTask = nil

        // Clear session data
        preferenceHelper.sessionID = nil

        // Transition to uninitialized
        transitionState(to: .uninitialized)

        BranchLogger.shared().logDebug(
            "SessionManager: Logged out successfully",
            error: nil
        )
    }

    // MARK: - Refresh

    /// Forces a session refresh by transitioning to uninitialized and re-initializing.
    public func refresh() async throws -> BranchSession {
        // Cancel existing task
        initializationTask?.cancel()
        initializationTask = nil

        // Force transition to uninitialized for refresh
        _currentState = .uninitialized

        // Notify observers
        for (_, continuation) in stateObservers {
            continuation.yield(.uninitialized)
        }

        // Re-initialize with default options
        return try await initialize(options: InitializationOptions())
    }
}

// MARK: - Objective-C Bridge

/// Objective-C compatible bridge for SessionManager.
/// Provides callback-based API for legacy code integration.
@available(iOS 13.0, tvOS 13.0, *)
@objc(BranchSessionManagerBridge)
public final class SessionManagerBridge: NSObject, @unchecked Sendable {
    // MARK: - Singleton

    @objc public static let shared = SessionManagerBridge()

    override private init() {
        super.init()
    }

    // MARK: - Initialization

    /// Initializes Branch with callback.
    @objc public func initialize(
        options: [String: Any]?,
        completion: @escaping ([String: Any]?, Error?) -> Void
    ) {
        Task {
            do {
                let initOptions = InitializationOptions()
                    .withLaunchOptions(options)

                let session = try await SessionManager.shared.initialize(options: initOptions)
                await MainActor.run {
                    completion(session.rawData, nil)
                }
            } catch {
                await MainActor.run {
                    completion(nil, error)
                }
            }
        }
    }

    /// Returns the current session state as a string.
    @objc public func currentStateString() -> String {
        // Note: This is not ideal for async context, but needed for Objective-C
        // Returns cached state description
        "SessionManager state (use async API for accurate state)"
    }

    /// Logs out with callback.
    @objc public func logout(completion: @escaping (Error?) -> Void) {
        Task {
            do {
                try await SessionManager.shared.logout()
                await MainActor.run {
                    completion(nil)
                }
            } catch {
                await MainActor.run {
                    completion(error)
                }
            }
        }
    }
}
