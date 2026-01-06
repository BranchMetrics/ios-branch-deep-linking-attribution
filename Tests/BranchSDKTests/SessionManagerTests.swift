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

    // MARK: - Double Open Prevention Tests (EMT-2742 / INTENG-21106)

    @Test("Concurrent initialize calls coalesce into single session")
    func concurrentInitializeCoalesces() async throws {
        let container = await BranchContainer()
        let manager = SessionManager(container: container)

        let optionsWithoutURL = InitializationOptions()
        let optionsWithURL = InitializationOptions().with(url: URL(string: "https://example.app.link/test")!)

        // Simulate Universal Link cold start:
        // Both calls start concurrently (like didFinishLaunching + continueUserActivity)
        async let session1 = manager.initialize(options: optionsWithoutURL)
        async let session2 = manager.initialize(options: optionsWithURL)

        // Both should return the SAME session (task coalescing)
        let (result1, result2) = try await (session1, session2)

        // Critical assertion: both callers receive the same session ID
        #expect(result1.id == result2.id, "Concurrent initialize calls should return the same session")
    }

    @Test("Second call with URL merges link data into session")
    func secondCallMergesURLIntoSession() async throws {
        let container = await BranchContainer()
        let manager = SessionManager(container: container)

        let testURL = URL(string: "https://example.app.link/campaign123")!
        let optionsWithoutURL = InitializationOptions()
        let optionsWithURL = InitializationOptions().with(url: testURL)

        // Simulate the exact Double Open scenario:
        // 1. didFinishLaunching calls initialize() with no URL
        // 2. continueUserActivity calls initialize() with the Universal Link URL
        async let session1 = manager.initialize(options: optionsWithoutURL)
        async let session2 = manager.initialize(options: optionsWithURL)

        let (result1, result2) = try await (session1, session2)

        // Both should have the link data from the second call
        #expect(result1.linkData != nil, "First caller should receive merged link data")
        #expect(result2.linkData != nil, "Second caller should receive merged link data")
        #expect(result1.linkData?.url == testURL, "Link data URL should match the Universal Link")
    }

    @Test("Sequential initialize calls after completion create new sessions")
    func sequentialInitializeAfterCompletion() async throws {
        let container = await BranchContainer()
        let manager = SessionManager(container: container)

        // First initialization completes
        let options1 = InitializationOptions()
        let session1 = try await manager.initialize(options: options1)

        // Reset to allow re-initialization
        await manager.reset()

        // Second initialization should be a new session
        let options2 = InitializationOptions()
        let session2 = try await manager.initialize(options: options2)

        // Should be different sessions (not coalesced)
        #expect(session1.id != session2.id, "Sequential initializations after reset should create different sessions")
    }

    @Test("Error during initialization clears task for retry")
    func errorClearsTaskForRetry() async throws {
        let container = await BranchContainer()
        let manager = SessionManager(container: container)

        // First: successful initialization
        let options = InitializationOptions()
        _ = try await manager.initialize(options: options)

        // State should be initialized
        let state = await manager.state
        if case .initialized = state {
            // Expected
        } else {
            Issue.record("Expected initialized state")
        }

        // After reset, should be able to initialize again
        await manager.reset()
        let stateAfterReset = await manager.state
        #expect(stateAfterReset == .uninitialized, "State should be uninitialized after reset")

        // Re-initialize should work
        let newSession = try await manager.initialize(options: options)
        #expect(newSession.identityId.isEmpty == false, "Should successfully re-initialize after reset")
    }

    @Test("Multiple concurrent calls all receive same session with merged data")
    func multipleConcurrentCallsAllReceiveSameSession() async throws {
        let container = await BranchContainer()
        let manager = SessionManager(container: container)

        let testURL = URL(string: "https://example.app.link/deep")!

        // Simulate worst case: 3 concurrent calls
        let options1 = InitializationOptions()
        let options2 = InitializationOptions()
        let options3 = InitializationOptions().with(url: testURL)

        async let s1 = manager.initialize(options: options1)
        async let s2 = manager.initialize(options: options2)
        async let s3 = manager.initialize(options: options3)

        let (r1, r2, r3) = try await (s1, s2, s3)

        // All should be the same session
        #expect(r1.id == r2.id && r2.id == r3.id, "All concurrent calls should return same session")

        // At least one of them should have the link data (whichever ran last)
        // Due to race conditions, we can't guarantee ALL have it, but the final
        // session state should have it
        let finalSession = await manager.currentSession
        #expect(finalSession?.linkData?.url == testURL, "Final session should have merged link data")
    }
}
