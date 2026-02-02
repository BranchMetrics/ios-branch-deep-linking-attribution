//
//  SessionManager.swift
//  Branch iOS SDK - Modern Swift Implementation
//
//  Copyright © 2026 Branch Metrics. All rights reserved.
//  SPDX-License-Identifier: MIT
//

import Foundation

// MARK: - SessionManager

/// Actor-based session manager implementation.
///
/// Provides thread-safe session management using Swift's actor model.
///
/// ## Double Open Prevention (INTENG-21106)
///
/// This actor implements task coalescing to prevent the "Double Open" issue that occurs
/// during Universal Link cold starts. When the app opens via a Universal Link:
///
/// 1. `didFinishLaunchingWithOptions` calls `initialize()` with no link data
/// 2. `continueUserActivity` calls `initialize()` with the Universal Link URL
/// 3. Without coalescing, these create two separate network requests
/// 4. Race condition: second response may overwrite first, losing deep link data
///
/// The `initializationTask` property ensures concurrent `initialize()` calls share
/// a single network request, while `pendingLinkData` accumulates any URL that arrives
/// during initialization.
@available(iOS 13.0, macOS 10.15, tvOS 13.0, watchOS 6.0, *)
public actor SessionManager: SessionManaging {
    // MARK: Lifecycle

    // MARK: - Initialization

    public init(
        logger: any Logging = BranchLoggerAdapter.shared,
        networkService: (any BranchNetworkService)? = nil
    ) {
        self.logger = logger
        self.networkService = networkService ?? DefaultBranchNetworkService()
    }

    // MARK: Public

    // MARK: - Protocol Properties

    public var state: SessionState {
        _state
    }

    public var currentSession: Session? {
        _currentSession
    }

    // MARK: - Session Management

    /// Initialize a Branch session with task coalescing support.
    ///
    /// This method implements the Double Open Fix by coalescing concurrent initialization
    /// calls into a single network request. When multiple calls arrive (e.g., from
    /// `didFinishLaunchingWithOptions` and `continueUserActivity`), the first call
    /// creates the initialization task, and subsequent calls await the same task.
    ///
    /// - Parameter options: Configuration options for initialization
    /// - Returns: The initialized session with any accumulated link data
    /// - Throws: `BranchError` if initialization fails
    ///
    /// ## Task Coalescing Pattern
    ///
    /// ```
    /// Call 1 (no URL) ─┬─► Check initializationTask (nil)
    ///                  │   Create new Task
    ///                  │   Store in initializationTask
    ///                  │   Start network request...
    ///                  │
    /// Call 2 (URL) ────┼─► Check initializationTask (exists!)
    ///                  │   Store URL in pendingLinkData
    ///                  │   Await existing task
    ///                  │
    ///                  └─► Task completes, merges pendingLinkData
    ///                      Both callers receive same session
    /// ```
    public func initialize(options: InitializationOptions) async throws -> Session {
        // CRITICAL: Double Open Fix - Check for existing initialization task
        // If another initialize() call is already in progress, coalesce with it
        if let existingTask = initializationTask {
            // Store any link URL for merging (EMT-2741)
            if let url = options.url {
                pendingLinkData = PendingLinkData(url: url, options: options)
                log(.debug, "Coalescing with existing initialization task, URL queued: \(url)")
            } else {
                log(.debug, "Coalescing with existing initialization task (no URL)")
            }
            // Wait for the existing task to complete
            _ = try await existingTask.value

            // Finalize any pending link data (handles race where coalescing caller
            // resumes before original caller runs finalizePendingLinkData)
            guard var finalSession = _currentSession else {
                log(.error, "Session initialization completed but no session stored - unexpected state")
                throw BranchError.sessionRequired
            }
            finalSession = finalizePendingLinkData(into: finalSession)
            if finalSession != _currentSession {
                _currentSession = finalSession
                transitionTo(.initialized(finalSession))
            }
            return finalSession
        }

        log(.debug, "Creating new initialization task")

        // Store link data if present in initial call
        if let url = options.url {
            pendingLinkData = PendingLinkData(url: url, options: options)
            log(.debug, "Initial URL stored for merging: \(url)")
        }

        // Create new initialization task
        // Note: Task inherits actor context, so performInitialization runs actor-isolated
        let task = Task<Session, any Error> { [self] in
            try await performInitialization(options: options)
        }

        initializationTask = task

        do {
            // Get base session from task
            var session = try await task.value

            // Check if a coalescing caller already merged link data into _currentSession
            // This handles the race where coalescing caller resumes before us
            if let existingSession = _currentSession, existingSession.linkData != nil {
                log(.debug, "Coalescing caller already merged link data, using existing session")
                session = existingSession
            } else {
                // EMT-2741: Finalize by merging any pending link data that arrived
                // during the async initialization (handles race condition)
                session = finalizePendingLinkData(into: session)

                // Update stored session with merged data
                _currentSession = session
                if case .initialized = _state {
                    transitionTo(.initialized(session))
                }
            }

            // Clear task after completion
            initializationTask = nil
            return session
        } catch {
            // Clear task on error so retry is possible
            initializationTask = nil
            pendingLinkData = nil
            throw error
        }
    }

    public func handleDeepLink(_ url: URL) async throws -> Session {
        guard case let .initialized(session) = _state else {
            log(.warning, "handleDeepLink called but session not initialized - current state: \(_state.description)")
            throw BranchError.sessionRequired
        }

        log(.debug, "Handling deep link: \(url)")

        // Resolve link via network service
        let responseData = try await networkService.resolveLink(
            url: url,
            sessionId: session.id
        )

        // Parse link data from response
        let linkData = parseLinkData(from: responseData, url: url)

        // Update session with link data
        let updatedSession = session.withLinkData(linkData)
        _currentSession = updatedSession
        transitionTo(.initialized(updatedSession))

        log(.debug, "Deep link resolved successfully")
        return updatedSession
    }

    public func reset() async {
        _currentSession = nil
        transitionTo(.uninitialized)
    }

    public func setIdentity(_ userId: String) async throws {
        guard case let .initialized(session) = _state else {
            log(.warning, "setIdentity called but session not initialized - current state: \(_state.description)")
            throw BranchError.sessionRequired
        }

        guard !userId.isEmpty else {
            log(.warning, "setIdentity called with empty userId")
            throw BranchError.invalidIdentity("User ID cannot be empty")
        }

        log(.debug, "Setting identity: \(userId)")

        // Make API call to set identity
        _ = try await networkService.setIdentity(
            userId: userId,
            sessionId: session.id,
            identityId: session.identityId
        )

        // Update session with new identity
        let updatedSession = session.withIdentity(userId)
        _currentSession = updatedSession
        transitionTo(.initialized(updatedSession))

        log(.debug, "Identity set successfully")
    }

    public func logout() async throws {
        guard case let .initialized(session) = _state else {
            log(.warning, "logout called but session not initialized - current state: \(_state.description)")
            throw BranchError.sessionRequired
        }

        log(.debug, "Logging out user")

        // Make API call to logout
        _ = try await networkService.logout(
            sessionId: session.id,
            identityId: session.identityId
        )

        // Clear identity from session
        let updatedSession = session.withoutIdentity()
        _currentSession = updatedSession
        transitionTo(.initialized(updatedSession))

        log(.debug, "Logout completed successfully")
    }

    /// Force refresh the session by canceling any in-progress initialization
    /// and re-initializing from scratch.
    ///
    /// - Returns: The refreshed session
    /// - Throws: `BranchError` if refresh fails
    public func refresh() async throws -> Session {
        // Cancel existing task if any
        initializationTask?.cancel()
        initializationTask = nil

        // Clear pending data
        pendingLinkData = nil

        // Force transition to uninitialized for refresh
        _state = .uninitialized

        // Notify observers of state change
        for (_, observer) in stateObservers {
            observer.yield(.uninitialized)
        }

        log(.debug, "Session refresh initiated, re-initializing...")

        // Re-initialize with default options
        return try await initialize(options: InitializationOptions())
    }

    /// Observe session state changes.
    ///
    /// This method is `nonisolated` to allow calling from synchronous contexts
    /// (e.g., SwiftUI's `onAppear`). The returned `AsyncStream` can be consumed
    /// in async contexts.
    ///
    /// Usage:
    /// ```swift
    /// for await state in sessionManager.observeState() {
    ///     switch state {
    ///     case .initialized(let session):
    ///         print("Session ready: \(session.identityId)")
    ///     default:
    ///         break
    ///     }
    /// }
    /// ```
    ///
    /// - Returns: An async stream of state changes
    public nonisolated func observeState() -> AsyncStream<SessionState> {
        AsyncStream { continuation in
            let id = UUID()

            // Access actor state via Task (required for nonisolated method)
            Task { [weak self] in
                guard let self else {
                    return
                }

                // Send current state immediately
                let currentState = await state
                continuation.yield(currentState)

                // Store continuation for future updates
                await addObserver(id: id, continuation: continuation)
            }

            // Clean up on termination
            continuation.onTermination = { [weak self] _ in
                Task { [weak self] in
                    await self?.removeObserver(id: id)
                }
            }
        }
    }

    // MARK: Private

    private let logger: any Logging
    private let networkService: any BranchNetworkService
    private var _state: SessionState = .uninitialized
    private var _currentSession: Session?
    private var stateObservers: [UUID: AsyncStream<SessionState>.Continuation] = [:]

    // MARK: - Persistence Keys

    /// Key for storing whether this device has had a previous install
    private static let hasInstalledKey = "branch_has_installed"

    // MARK: - Task Coalescing (EMT-2740: Double Open Fix)

    /// Active initialization task for coalescing concurrent initialize() calls.
    /// When non-nil, subsequent initialize() calls will await this task instead of
    /// creating a new network request.
    private var initializationTask: Task<Session, any Error>?

    /// Pending link data that arrived during an in-flight initialization.
    /// Will be merged into the session when initialization completes.
    private var pendingLinkData: PendingLinkData?

    /// Merges any pending link data into the session and clears the pending state.
    ///
    /// This is called AFTER awaiting the initialization task to ensure we capture
    /// any URLs that arrived during the async network request.
    private func finalizePendingLinkData(into session: Session) -> Session {
        guard let pending = pendingLinkData else {
            return session
        }

        log(.debug, "Merging pending URL into session: \(pending.url)")
        let linkData = LinkData(url: pending.url)
        pendingLinkData = nil
        return session.withLinkData(linkData)
    }

    // MARK: - Private Initialization

    /// Performs the actual initialization logic.
    ///
    /// This is separated from `initialize()` to keep the coalescing logic clean.
    private func performInitialization(options: InitializationOptions) async throws -> Session {
        // Validate state transition
        guard _state.canTransition(to: .initializing) else {
            log(.error, "Invalid state transition from \(_state.description) to Initializing")
            throw BranchError.invalidStateTransition(
                from: _state.description,
                to: "Initializing"
            )
        }

        // Transition to initializing
        transitionTo(.initializing)

        // Determine if this is a first session (install) or returning session (open)
        let isFirstSession = !hasInstalled()

        // Build request data
        let requestData = buildRequestData(options: options, isFirstSession: isFirstSession)

        // Make API call
        let responseData: [String: Any]
        if isFirstSession {
            log(.debug, "Performing install request (first session)")
            responseData = try await networkService.performInstall(requestData: requestData)
            // Mark as installed for future sessions
            markAsInstalled()
        } else {
            log(.debug, "Performing open request (returning session)")
            responseData = try await networkService.performOpen(requestData: requestData)
        }

        // Parse response into session
        let session = parseSession(from: responseData, isFirstSession: isFirstSession, options: options)

        _currentSession = session
        transitionTo(.initialized(session))

        log(.debug, "Session initialized: \(session)")
        return session
    }

    // MARK: - Request Building

    /// Build request data dictionary for install/open requests
    private func buildRequestData(options: InitializationOptions, isFirstSession: Bool) -> [String: Any] {
        var data: [String: Any] = [:]

        // Add URL if present
        if let url = options.url {
            data["external_intent_uri"] = url.absoluteString
        }

        // Add device information (simplified - in production this would use BNCDeviceInfo)
        data["os"] = "iOS"
        data["os_version"] = ProcessInfo.processInfo.operatingSystemVersionString
        data["sdk"] = "ios"
        data["sdk_version"] = "3.0.0"

        // Add install/open flag
        data["is_first_session"] = isFirstSession

        return data
    }

    // MARK: - Response Parsing

    /// Parse session from API response
    private func parseSession(
        from responseData: [String: Any],
        isFirstSession: Bool,
        options: InitializationOptions
    ) -> Session {
        // Extract session fields from response
        let sessionId = responseData["session_id"] as? String ?? UUID().uuidString
        let identityId = responseData["identity_id"] as? String ?? UUID().uuidString
        let deviceFingerprintId = responseData["device_fingerprint_id"] as? String ?? UUID().uuidString
        let userId = responseData["identity"] as? String

        // Parse link data if present
        var linkData: LinkData?
        if let clickedBranchLink = responseData["+clicked_branch_link"] as? Bool, clickedBranchLink {
            linkData = parseLinkData(from: responseData, url: options.url)
        } else if options.url != nil {
            // Even if not a clicked link, store the URL that opened the app
            linkData = LinkData(url: options.url, isClicked: false)
        }

        return Session(
            id: sessionId,
            createdAt: Date(),
            identityId: identityId,
            deviceFingerprintId: deviceFingerprintId,
            isFirstSession: isFirstSession,
            linkData: linkData,
            userId: userId
        )
    }

    /// Parse link data from API response
    private func parseLinkData(from responseData: [String: Any], url: URL?) -> LinkData {
        let isClicked = responseData["+clicked_branch_link"] as? Bool ?? false
        let referringLink = responseData["~referring_link"] as? String
        let campaign = responseData["~campaign"] as? String
        let channel = responseData["~channel"] as? String
        let feature = responseData["~feature"] as? String
        let tags = responseData["~tags"] as? [String]
        let stage = responseData["~stage"] as? String

        // Extract custom parameters (keys that don't start with ~ or +)
        var parameters: [String: AnyCodable] = [:]
        for (key, value) in responseData {
            if !key.hasPrefix("~"), !key.hasPrefix("+"), !isReservedKey(key) {
                parameters[key] = AnyCodable(value)
            }
        }

        // Store raw data
        var rawData: [String: AnyCodable] = [:]
        for (key, value) in responseData {
            rawData[key] = AnyCodable(value)
        }

        return LinkData(
            url: url,
            isClicked: isClicked,
            referringLink: referringLink,
            parameters: parameters,
            campaign: campaign,
            channel: channel,
            feature: feature,
            tags: tags,
            stage: stage,
            rawData: rawData
        )
    }

    /// Check if a key is a reserved Branch key
    private func isReservedKey(_ key: String) -> Bool {
        let reservedKeys = [
            "session_id", "identity_id", "device_fingerprint_id", "identity",
            "link", "data", "source", "branch_key",
        ]
        return reservedKeys.contains(key)
    }

    // MARK: - Install State

    /// Check if this device has been installed before
    private func hasInstalled() -> Bool {
        UserDefaults.standard.bool(forKey: Self.hasInstalledKey)
    }

    /// Mark this device as having been installed
    private func markAsInstalled() {
        UserDefaults.standard.set(true, forKey: Self.hasInstalledKey)
    }

    // MARK: - Private Methods

    private func transitionTo(_ newState: SessionState) {
        _state = newState

        // Notify all observers
        for (_, observer) in stateObservers {
            observer.yield(newState)
        }
    }

    private func addObserver(id: UUID, continuation: AsyncStream<SessionState>.Continuation) {
        stateObservers[id] = continuation
    }

    private func removeObserver(id: UUID) {
        stateObservers.removeValue(forKey: id)
    }

    /// Convenience logging method using the logger.
    private nonisolated func log(
        _ level: LogLevel,
        _ message: @autoclosure () -> String,
        file: String = #file,
        function: String = #function,
        line: Int = #line
    ) {
        logger.log(level, message(), file: file, function: function, line: line)
    }
}

// MARK: - PendingLinkData

/// Holds link data that arrived during an in-flight initialization.
///
/// This struct captures the URL and options from a `continueUserActivity` call
/// that occurred while initialization was already in progress (Double Open scenario).
struct PendingLinkData: Sendable {
    /// The Universal Link URL that was opened
    let url: URL

    /// The full initialization options (for future use with additional parameters)
    let options: InitializationOptions
}
