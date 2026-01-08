//
//  SessionState.swift
//  BranchSDK
//
//  Branch iOS SDK - Modern Swift Implementation
//  Copyright © 2026 Branch Metrics. All rights reserved.
//  SPDX-License-Identifier: MIT
//
//  JIRA: EMT-2726, EMT-2733
//  3-State Session Model for SDK Modernization
//

import Foundation

// MARK: - Session State

/// Represents the possible states of the Branch SDK session.
///
/// The SDK follows a strict 3-state model:
/// - `uninitialized`: SDK not configured, no operations allowed
/// - `initializing`: Configuration in progress, operations queued
/// - `initialized`: Fully operational, all features available
///
/// This state machine ensures thread-safe session management and eliminates
/// race conditions that caused the "Double Open Issue" (INTENG-21106).
@available(iOS 13.0, tvOS 13.0, *)
public enum SessionState: Equatable, Sendable {
    /// SDK not configured. No operations allowed.
    /// This is the initial state when the SDK is first loaded.
    case uninitialized

    /// Configuration in progress. Operations are queued until initialization completes.
    /// During this state, concurrent `initialize()` calls are coalesced into a single request.
    case initializing

    /// Fully operational. All SDK features are available.
    /// The associated `BranchSession` contains session data and deep link information.
    case initialized(BranchSession)

    /// Initialization failed with an error.
    /// The SDK can retry initialization from this state.
    case failed(BranchError)

    // MARK: - Equatable

    public static func == (lhs: SessionState, rhs: SessionState) -> Bool {
        switch (lhs, rhs) {
        case (.uninitialized, .uninitialized):
            return true
        case (.initializing, .initializing):
            return true
        case let (.initialized(lhsSession), .initialized(rhsSession)):
            return lhsSession.sessionId == rhsSession.sessionId
        case let (.failed(lhsError), .failed(rhsError)):
            return lhsError.localizedDescription == rhsError.localizedDescription
        default:
            return false
        }
    }

    // MARK: - State Checks

    /// Returns `true` if the SDK is in an uninitialized state.
    public var isUninitialized: Bool {
        if case .uninitialized = self { return true }
        return false
    }

    /// Returns `true` if the SDK is currently initializing.
    public var isInitializing: Bool {
        if case .initializing = self { return true }
        return false
    }

    /// Returns `true` if the SDK is fully initialized.
    public var isInitialized: Bool {
        if case .initialized = self { return true }
        return false
    }

    /// Returns `true` if initialization failed.
    public var isFailed: Bool {
        if case .failed = self { return true }
        return false
    }

    /// Returns the session if in initialized state, nil otherwise.
    public var session: BranchSession? {
        if case let .initialized(session) = self { return session }
        return nil
    }

    /// Returns the error if in failed state, nil otherwise.
    public var error: BranchError? {
        if case let .failed(error) = self { return error }
        return nil
    }
}

// MARK: - State Transition Validation

@available(iOS 13.0, tvOS 13.0, *)
public extension SessionState {
    /// Valid state transitions for the session state machine.
    ///
    /// ```
    ///                     ┌─────────────┐
    ///                     │ uninitialized│
    ///                     └──────┬──────┘
    ///                            │ initialize()
    ///                            ▼
    ///                     ┌─────────────┐
    ///         ┌───────────│ initializing │───────────┐
    ///         │ retry()   └──────┬──────┘            │ error
    ///         │                  │ success           │
    ///         │                  ▼                   ▼
    ///         │           ┌─────────────┐     ┌─────────────┐
    ///         └───────────│ initialized │     │   failed    │
    ///                     └──────┬──────┘     └─────────────┘
    ///                            │ logout()
    ///                            ▼
    ///                     ┌─────────────┐
    ///                     │ uninitialized│
    ///                     └─────────────┘
    /// ```
    ///
    /// - Parameter newState: The target state to transition to.
    /// - Returns: `true` if the transition is valid, `false` otherwise.
    func canTransition(to newState: SessionState) -> Bool {
        switch (self, newState) {
        // From uninitialized: can only start initializing
        case (.uninitialized, .initializing):
            return true

        // From initializing: can succeed or fail
        case (.initializing, .initialized):
            return true

        case (.initializing, .failed):
            return true

        // From initialized: can logout (return to uninitialized)
        case (.initialized, .uninitialized):
            return true

        // From failed: can retry (go to initializing) or reset (go to uninitialized)
        case (.failed, .initializing):
            return true

        case (.failed, .uninitialized):
            return true

        // All other transitions are invalid
        default:
            return false
        }
    }
}

// MARK: - Debug Description

@available(iOS 13.0, tvOS 13.0, *)
extension SessionState: CustomStringConvertible {
    public var description: String {
        switch self {
        case .uninitialized:
            return "SessionState.uninitialized"
        case .initializing:
            return "SessionState.initializing"
        case let .initialized(session):
            return "SessionState.initialized(sessionId: \(session.sessionId ?? "nil"))"
        case let .failed(error):
            return "SessionState.failed(error: \(error.localizedDescription))"
        }
    }
}
