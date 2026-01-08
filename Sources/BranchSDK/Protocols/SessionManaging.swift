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
/// let manager: any SessionManaging = SessionManager()
/// let session = try await manager.initialize(options: options)
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

    /// Observe session state changes
    /// - Returns: An async stream of state changes
    func observeState() async -> AsyncStream<SessionState>
}
