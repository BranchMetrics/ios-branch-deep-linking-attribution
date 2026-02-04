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
///     └─────────────────┘        reset()
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
/// ## Note on iOS 12 Compatibility
///
/// Unlike the iOS 13+ version, this enum does NOT have an associated value
/// for the `.initialized` case. Use `SessionManager.currentSession`
/// or `BranchSessionCoordinator.currentSession` to access the current session.
@objc public enum SessionState: Int {
    /// SDK not configured, no operations allowed
    case uninitialized = 0

    /// Configuration in progress, operations queued
    case initializing = 1

    /// Fully operational, all features available
    case initialized = 2
}

// MARK: - Properties

public extension SessionState {
    /// Human-readable description of the state
    var stateDescription: String {
        switch self {
        case .uninitialized:
            return "Uninitialized"
        case .initializing:
            return "Initializing"
        case .initialized:
            return "Initialized"
        }
    }

    /// Whether the SDK is ready for operations
    var isReady: Bool {
        self == .initialized
    }

    /// Whether the SDK is currently initializing
    var isInitializing: Bool {
        self == .initializing
    }

    /// Whether the SDK needs initialization
    var needsInitialization: Bool {
        self == .uninitialized
    }
}

// MARK: - Transition Validation

public extension SessionState {
    /// Validates if a transition to the target state is allowed
    func canTransition(to target: SessionState) -> Bool {
        switch (self, target) {
        // From uninitialized
        case (.uninitialized, .initializing):
            return true

        // From initializing
        case (.initializing, .initialized):
            return true

        case (.initializing, .uninitialized):
            return true // Error case

        // From initialized
        case (.initialized, .uninitialized):
            return true // Reset
        case (.initialized, .initializing):
            return true // Re-init with new link

        // Same state transitions
        case (.uninitialized, .uninitialized),
             (.initializing, .initializing),
             (.initialized, .initialized):
            return true

        // Invalid transitions
        default:
            return false
        }
    }
}

// MARK: - CustomStringConvertible

extension SessionState: CustomStringConvertible {
    public var description: String {
        stateDescription
    }
}

// MARK: - InvalidStateTransitionError

/// Error thrown when an invalid state transition is attempted
public struct InvalidStateTransitionError: Error, CustomStringConvertible {
    public let from: SessionState
    public let to: SessionState

    public init(from: SessionState, to: SessionState) {
        self.from = from
        self.to = to
    }

    public var description: String {
        "Invalid state transition from \(from) to \(to)"
    }
}
