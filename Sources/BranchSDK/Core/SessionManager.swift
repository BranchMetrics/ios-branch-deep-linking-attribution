//
//  SessionManager.swift
//  Branch iOS SDK - Modern Swift Implementation
//
//  Copyright © 2026 Branch Metrics. All rights reserved.
//  SPDX-License-Identifier: MIT
//

import Foundation

/// Actor-based session manager implementation.
///
/// Provides thread-safe session management using Swift's actor model.
public actor SessionManager: SessionManaging {
    // MARK: Lifecycle

    // MARK: - Initialization

    public init(container: BranchContainer) {
        self.container = container
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

    public func initialize(options _: InitializationOptions) async throws -> Session {
        // Validate state transition
        guard _state.canTransition(to: .initializing) else {
            throw BranchError.invalidStateTransition(
                from: _state.description,
                to: "Initializing"
            )
        }

        // Transition to initializing
        transitionTo(.initializing)

        do {
            // TODO: Implement actual initialization logic
            // 1. Check for existing session
            // 2. Make API call to /v1/open or /v1/install
            // 3. Process response

            // For now, create a mock session
            let session = Session(
                identityId: UUID().uuidString,
                deviceFingerprintId: UUID().uuidString,
                isFirstSession: true,
                linkData: nil
            )

            _currentSession = session
            transitionTo(.initialized(session))

            return session
        } catch {
            // Reset to uninitialized on error
            transitionTo(.uninitialized)
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

    public func observeState() async -> AsyncStream<SessionState> {
        let observerId = UUID()
        let currentState = _state

        return AsyncStream { continuation in
            // Send current state immediately
            continuation.yield(currentState)

            // Store continuation for future updates
            Task { [weak self] in
                await self?.addObserver(id: observerId, continuation: continuation)
            }

            continuation.onTermination = { [weak self] _ in
                Task { [weak self] in
                    await self?.removeObserver(id: observerId)
                }
            }
        }
    }

    // MARK: Private

    private let container: BranchContainer
    private var _state: SessionState = .uninitialized
    private var _currentSession: Session?
    private var stateObservers: [UUID: AsyncStream<SessionState>.Continuation] = [:]

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
}
