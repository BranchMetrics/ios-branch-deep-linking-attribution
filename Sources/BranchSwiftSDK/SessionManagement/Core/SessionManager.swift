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

    public init(logger: any Logging = BranchLoggerAdapter.shared) {
        self.logger = logger
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

    public func handleDeepLink(_: URL) async throws -> Session {
        guard case let .initialized(session) = _state else {
            throw BranchError.sessionRequired
        }

        // TODO: Implement deep link handling
        // 1. Parse URL
        // 2. Make API call to resolve link
        // 3. Update session with link data

        return session
    }

    public func reset() async {
        _currentSession = nil
        transitionTo(.uninitialized)
    }

    public func setIdentity(_ userId: String) async throws {
        guard case let .initialized(session) = _state else {
            throw BranchError.sessionRequired
        }

        guard !userId.isEmpty else {
            throw BranchError.invalidIdentity("User ID cannot be empty")
        }

        // TODO: Implement identity setting
        // 1. Make API call to /v1/profile
        // 2. Update session

        let updatedSession = session.withIdentity(userId)
        _currentSession = updatedSession
        transitionTo(.initialized(updatedSession))
    }

    public func logout() async throws {
        guard case let .initialized(session) = _state else {
            throw BranchError.sessionRequired
        }

        // TODO: Implement logout
        // 1. Make API call to /v1/logout
        // 2. Clear identity

        let updatedSession = session.withoutIdentity()
        _currentSession = updatedSession
        transitionTo(.initialized(updatedSession))
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
    private var _state: SessionState = .uninitialized
    private var _currentSession: Session?
    private var stateObservers: [UUID: AsyncStream<SessionState>.Continuation] = [:]

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
    private func performInitialization(options _: InitializationOptions) async throws -> Session {
        // Validate state transition
        guard _state.canTransition(to: .initializing) else {
            throw BranchError.invalidStateTransition(
                from: _state.description,
                to: "Initializing"
            )
        }

        // Transition to initializing
        transitionTo(.initializing)

        // TODO: Implement actual initialization logic
        // 1. Check for existing session
        // 2. Make API call to /v1/open or /v1/install
        // 3. Process response

        // Simulate network latency to allow other tasks to run
        // This ensures concurrent initialize() calls can coalesce properly
        // In production, this will be replaced by actual network calls
        try await Task.sleep(nanoseconds: 1_000_000) // 1ms

        // For now, create a mock session
        // Note: Link data merging is handled by finalizePendingLinkData() in initialize()
        let session = Session(
            identityId: UUID().uuidString,
            deviceFingerprintId: UUID().uuidString,
            isFirstSession: true,
            linkData: nil
        )

        _currentSession = session
        transitionTo(.initialized(session))

        return session
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
