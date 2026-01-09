//
//  SessionManaging.swift
//  Branch iOS SDK - Modern Swift Implementation
//
//  Copyright © 2026 Branch Metrics. All rights reserved.
//  SPDX-License-Identifier: MIT
//

import Foundation

/// Protocol for managing Branch SDK sessions.
///
/// This protocol defines the core session management interface that enables
/// testability through dependency injection.
///
/// ## Thread Safety
///
/// All implementations must be actor-isolated or otherwise thread-safe.
/// The default implementation uses an actor to guarantee data race freedom.
///
/// ## Usage
///
/// ```swift
/// let manager: any SessionManaging = SessionManager(container: container)
///
/// // Initialize session
/// let session = try await manager.initialize(options: options)
///
/// // Observe state changes (nonisolated - works from SwiftUI)
/// for await state in manager.observeState() {
///     switch state {
///     case .uninitialized: print("Not initialized")
///     case .initializing: print("Initializing...")
///     case .initialized(let session): print("Ready: \(session.identityId)")
///     }
/// }
///
/// // Force refresh when needed
/// let refreshed = try await manager.refresh()
/// ```
public protocol SessionManaging: Sendable {
    /// The current session state
    var state: SessionState { get async }

    /// The current session, if initialized
    var currentSession: Session? { get async }

    /// Initialize a new session with the given options
    /// - Parameter options: Configuration options for initialization
    /// - Returns: The initialized session
    /// - Throws: `BranchError` if initialization fails
    func initialize(options: InitializationOptions) async throws -> Session

    /// Handle an incoming deep link URL
    /// - Parameter url: The deep link URL to process
    /// - Returns: Updated session with link data
    /// - Throws: `BranchError` if processing fails
    func handleDeepLink(_ url: URL) async throws -> Session

    /// Reset the session to uninitialized state
    func reset() async

    /// Set user identity for cross-device tracking
    /// - Parameter userId: The user identifier to set
    /// - Throws: `BranchError` if setting identity fails
    func setIdentity(_ userId: String) async throws

    /// Clear user identity (logout)
    /// - Throws: `BranchError` if logout fails
    func logout() async throws

    /// Force refresh the session by canceling any in-progress initialization and re-initializing.
    ///
    /// This method:
    /// 1. Cancels any existing initialization task
    /// 2. Clears pending link data
    /// 3. Transitions state to `.uninitialized`
    /// 4. Re-initializes with default options
    ///
    /// Use cases:
    /// - User-triggered session refresh
    /// - Recovery from stale session state
    /// - Testing and debugging
    ///
    /// - Returns: The refreshed session
    /// - Throws: `BranchError` if refresh fails
    func refresh() async throws -> Session

    /// Observe session state changes.
    ///
    /// This method is `nonisolated` to allow calling from synchronous contexts
    /// (e.g., SwiftUI's `onAppear`). The returned `AsyncStream` can be consumed
    /// in async contexts.
    ///
    /// ## SwiftUI Integration
    ///
    /// ```swift
    /// struct ContentView: View {
    ///     @State private var sessionState: SessionState = .uninitialized
    ///
    ///     var body: some View {
    ///         Text("State: \(sessionState.description)")
    ///             .task {
    ///                 for await state in sessionManager.observeState() {
    ///                     sessionState = state
    ///                 }
    ///             }
    ///     }
    /// }
    /// ```
    ///
    /// - Returns: An async stream of state changes
    nonisolated func observeState() -> AsyncStream<SessionState>
}
