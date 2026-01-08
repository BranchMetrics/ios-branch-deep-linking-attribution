//
//  MockSessionManager.swift
//  Branch iOS SDK - Modern Swift Implementation
//
//  Copyright © 2026 Branch Metrics. All rights reserved.
//  SPDX-License-Identifier: MIT
//

import BranchSDK
import Foundation

/// Mock session manager for testing.
///
/// Provides a controllable session manager that allows testing
/// of session-dependent code paths.
public actor MockSessionManager: SessionManaging {
    // MARK: Lifecycle

    // MARK: - Initialization

    public init() {}

    // MARK: Public

    // MARK: - Configuration

    public var shouldFailInitialization = false
    public var initializationError: Error?
    public var initializationDelay: TimeInterval = 0

    // MARK: - SessionManaging

    public var state: SessionState {
        _state
    }

    public var currentSession: Session? {
        _session
    }

    /// Create a pre-initialized mock
    public static func initialized(
        identityId: String = "test_identity",
        deviceFingerprintId: String = "test_device",
        userId: String? = nil
    ) async -> MockSessionManager {
        let mock = MockSessionManager()
        let session = Session(
            identityId: identityId,
            deviceFingerprintId: deviceFingerprintId,
            isFirstSession: false,
            linkData: nil,
            userId: userId
        )
        await mock.setState(.initialized(session))
        return mock
    }

    public func initialize(options: InitializationOptions) async throws -> Session {
        // Apply delay if configured
        if initializationDelay > 0 {
            try await Task.sleep(nanoseconds: UInt64(initializationDelay * 1_000_000_000))
        }

        // Check for failure mode
        if shouldFailInitialization {
            throw initializationError ?? BranchError.networkError("Mock initialization failure")
        }

        // Create mock session
        let session = Session(
            identityId: "mock_identity_\(UUID().uuidString.prefix(8))",
            deviceFingerprintId: "mock_device_\(UUID().uuidString.prefix(8))",
            isFirstSession: _session == nil,
            linkData: options.url != nil ? LinkData(url: options.url!) : nil
        )

        _session = session
        _state = .initialized(session)

        // Notify observers
        for observer in stateObservers {
            observer.yield(_state)
        }

        return session
    }

    public func handleDeepLink(_ url: URL) async throws -> Session {
        guard case let .initialized(session) = _state else {
            throw BranchError.sessionRequired
        }

        // Create updated session with link data
        let linkData = LinkData(url: url)
        let updatedSession = Session(
            identityId: session.identityId,
            deviceFingerprintId: session.deviceFingerprintId,
            isFirstSession: session.isFirstSession,
            linkData: linkData
        )

        _session = updatedSession
        _state = .initialized(updatedSession)

        return updatedSession
    }

    public func reset() async {
        _session = nil
        _state = .uninitialized

        // Notify observers
        for observer in stateObservers {
            observer.yield(_state)
        }
    }

    public func setIdentity(_ userId: String) async throws {
        guard case let .initialized(session) = _state else {
            throw BranchError.sessionRequired
        }

        let updatedSession = session.withIdentity(userId)
        _session = updatedSession
        _state = .initialized(updatedSession)
    }

    public func logout() async throws {
        guard case let .initialized(session) = _state else {
            throw BranchError.sessionRequired
        }

        let updatedSession = session.withoutIdentity()
        _session = updatedSession
        _state = .initialized(updatedSession)
    }

    public nonisolated func observeState() -> AsyncStream<SessionState> {
        AsyncStream { continuation in
            Task {
                await self.addObserver(continuation)
            }
        }
    }

    // MARK: - Test Helpers

    /// Set the session state directly for testing
    public func setState(_ state: SessionState) {
        _state = state
        if case let .initialized(session) = state {
            _session = session
        } else {
            _session = nil
        }

        for observer in stateObservers {
            observer.yield(state)
        }
    }

    // MARK: Private

    private var _state: SessionState = .uninitialized
    private var _session: Session?
    private var stateObservers: [AsyncStream<SessionState>.Continuation] = []

    private func addObserver(_ continuation: AsyncStream<SessionState>.Continuation) {
        continuation.yield(_state)
        stateObservers.append(continuation)
    }
}
