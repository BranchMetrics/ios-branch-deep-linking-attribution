//
//  SessionState.swift
//  Branch iOS SDK - Modern Swift Implementation
//
//  Copyright © 2026 Branch Metrics. All rights reserved.
//  SPDX-License-Identifier: MIT
//

import Foundation

// MARK: - SessionState

/// Represents the current state of the Branch session.
///
/// The SDK uses a simplified 3-state model that matches the existing behavior
/// while providing compile-time safety and clear state transitions.
///
/// ## State Diagram
///
/// ```
///     ┌─────────────────┐
///     │  Uninitialized  │ ◄────────────────────┐
///     └────────┬────────┘                      │
///              │                               │
///              │ initialize()                  │ error / reset()
///              ▼                               │
///     ┌─────────────────┐                      │
///     │   Initializing  │ ─────────────────────┤
///     └────────┬────────┘                      │
///              │                               │
///              │ success                       │
///              ▼                               │
///     ┌─────────────────┐                      │
///     │   Initialized   │ ─────────────────────┘
///     │   (session)     │        reset()
///     └─────────────────┘
/// ```
///
/// ## Valid Transitions
///
/// - `uninitialized` → `initializing`: When `initialize()` is called
/// - `initializing` → `initialized`: When initialization succeeds
/// - `initializing` → `uninitialized`: When initialization fails
/// - `initialized` → `uninitialized`: When `reset()` is called
/// - `initialized` → `initializing`: When re-initializing with new link
///
public enum SessionState: Sendable, Equatable, CustomStringConvertible {
    /// SDK not configured, no operations allowed
    case uninitialized

    /// Configuration in progress, operations queued
    case initializing

    /// Fully operational, all features available
    case initialized(Session)

    // MARK: Public

    /// Human-readable description of the state
    public var description: String {
        switch self {
        case .uninitialized:
            "Uninitialized"
        case .initializing:
            "Initializing"
        case let .initialized(session):
            "Initialized (Session: \(session.id.prefix(8))...)"
        }
    }

    /// Whether the SDK is ready for operations
    public var isReady: Bool {
        if case .initialized = self {
            return true
        }
        return false
    }

    /// Whether the SDK is currently initializing
    public var isInitializing: Bool {
        if case .initializing = self {
            return true
        }
        return false
    }

    /// Whether the SDK needs initialization
    public var needsInitialization: Bool {
        if case .uninitialized = self {
            return true
        }
        return false
    }

    /// The current session, if initialized
    public var session: Session? {
        if case let .initialized(session) = self {
            return session
        }
        return nil
    }

    // MARK: Internal

    // MARK: - Transition Validation

    /// Validates if a transition to the target state is allowed
    func canTransition(to target: SessionState) -> Bool {
        switch (self, target) {
        // From uninitialized
        case (.uninitialized, .initializing):
            true

        // From initializing
        case (.initializing, .initialized):
            true

        case (.initializing, .uninitialized):
            true // Error case

        // From initialized
        case (.initialized, .uninitialized):
            true // Reset
        case (.initialized, .initializing):
            true // Re-init with new link

        // Same state transitions
        case (.uninitialized, .uninitialized),
             (.initializing, .initializing),
             (.initialized, .initialized):
            true

        // Invalid transitions
        default:
            false
        }
    }
}

// MARK: - Equatable Conformance

public extension SessionState {
    static func == (lhs: SessionState, rhs: SessionState) -> Bool {
        switch (lhs, rhs) {
        case (.uninitialized, .uninitialized):
            true
        case (.initializing, .initializing):
            true
        case let (.initialized(lhsSession), .initialized(rhsSession)):
            lhsSession.id == rhsSession.id
        default:
            false
        }
    }
}

// MARK: - InvalidStateTransitionError

/// Error thrown when an invalid state transition is attempted
public struct InvalidStateTransitionError: Error, Sendable, CustomStringConvertible {
    public let from: SessionState
    public let to: SessionState

    public var description: String {
        "Invalid state transition from \(from) to \(to)"
    }
}
