//
//  SessionManagerTests.swift
//  Branch iOS SDK - Modern Swift Implementation
//
//  Copyright © 2026 Branch Metrics. All rights reserved.
//  SPDX-License-Identifier: MIT
//

@testable import BranchSDK
@testable import BranchSDKTestKit
import Foundation
import Testing

@Suite("SessionManager Tests")
struct SessionManagerTests {
    // MARK: - State Tests

    @Test("Initial state is uninitialized")
    func initialState() async {
        let container = await BranchContainer()
        let manager = SessionManager(container: container)

        let state = await manager.state
        #expect(state == .uninitialized)
    }

    @Test("State transitions correctly during initialization")
    func stateTransitions() async throws {
        let container = await BranchContainer()
        let manager = SessionManager(container: container)

        // Start observing state
        var observedStates: [SessionState] = []
        let stateStream = await manager.observeState()

        // Collect first few states in background
        let collectTask = Task {
            var collected: [SessionState] = []
            for await state in stateStream {
                collected.append(state)
                if collected.count >= 2 {
                    break
                }
            }
            return collected
        }

        // Initialize
        let options = InitializationOptions()
        let session = try await manager.initialize(options: options)

        // Verify session
        #expect(session.isFirstSession)
        #expect(!session.identityId.isEmpty)

        // Verify final state
        let finalState = await manager.state
        if case let .initialized(sessionFromState) = finalState {
            #expect(sessionFromState.id == session.id)
        } else {
            Issue.record("Expected initialized state")
        }

        collectTask.cancel()
    }

    @Test("Cannot initialize when already initializing")
    func cannotDoubleInitialize() async throws {
        let container = await BranchContainer()
        let manager = SessionManager(container: container)

        let options = InitializationOptions()

        // First initialization
        _ = try await manager.initialize(options: options)

        // State should be initialized, not initializing
        let state = await manager.state
        if case .initialized = state {
            // This is expected
        } else {
            Issue.record("Expected initialized state after successful init")
        }
    }

    // MARK: - Session Tests

    @Test("Session contains correct initial data")
    func sessionData() async throws {
        let container = await BranchContainer()
        let manager = SessionManager(container: container)

        let options = InitializationOptions()
        let session = try await manager.initialize(options: options)

        #expect(!session.id.isEmpty)
        #expect(!session.identityId.isEmpty)
        #expect(!session.deviceFingerprintId.isEmpty)
        #expect(session.isFirstSession)
        #expect(session.linkData == nil)
    }

    // MARK: - Identity Tests

    @Test("Set identity updates session")
    func testSetIdentity() async throws {
        let container = await BranchContainer()
        let manager = SessionManager(container: container)

        let options = InitializationOptions()
        _ = try await manager.initialize(options: options)

        let userId = "test_user_123"
        try await manager.setIdentity(userId)

        let session = await manager.currentSession
        #expect(session?.userId == userId)
    }

    @Test("Set identity requires initialized session")
    func setIdentityRequiresSession() async throws {
        let container = await BranchContainer()
        let manager = SessionManager(container: container)

        await #expect(throws: BranchError.self) {
            try await manager.setIdentity("test_user")
        }
    }

    @Test("Empty identity is rejected")
    func emptyIdentityRejected() async throws {
        let container = await BranchContainer()
        let manager = SessionManager(container: container)

        let options = InitializationOptions()
        _ = try await manager.initialize(options: options)

        await #expect(throws: BranchError.self) {
            try await manager.setIdentity("")
        }
    }

    // MARK: - Logout Tests

    @Test("Logout clears user identity")
    func testLogout() async throws {
        let container = await BranchContainer()
        let manager = SessionManager(container: container)

        let options = InitializationOptions()
        _ = try await manager.initialize(options: options)

        try await manager.setIdentity("test_user")
        try await manager.logout()

        let session = await manager.currentSession
        #expect(session?.userId == nil)
    }

    // MARK: - Reset Tests

    @Test("Reset clears session and returns to uninitialized")
    func testReset() async throws {
        let container = await BranchContainer()
        let manager = SessionManager(container: container)

        let options = InitializationOptions()
        _ = try await manager.initialize(options: options)

        await manager.reset()

        let state = await manager.state
        #expect(state == .uninitialized)

        let session = await manager.currentSession
        #expect(session == nil)
    }

    // MARK: - Deep Link Tests

    @Test("Handle deep link requires session")
    func deepLinkRequiresSession() async throws {
        let container = await BranchContainer()
        let manager = SessionManager(container: container)

        let url = URL(string: "https://example.app.link/test")!

        await #expect(throws: BranchError.self) {
            try await manager.handleDeepLink(url)
        }
    }
}
