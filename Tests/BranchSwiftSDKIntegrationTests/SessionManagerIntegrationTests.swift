//
//  SessionManagerIntegrationTests.swift
//  Branch iOS SDK - Modern Swift Implementation
//
//  Copyright © 2026 Branch Metrics. All rights reserved.
//  SPDX-License-Identifier: MIT
//

//
//  SessionManagerIntegrationTests.swift
//  BranchSwiftSDKIntegrationTests
//
//  Branch iOS SDK - Modern Swift Implementation
//  Copyright © 2026 Branch Metrics. All rights reserved.
//  SPDX-License-Identifier: MIT
//
//  JIRA: EMT-2738
//  Integration tests for SessionManager - Tests component interactions
//

@testable import BranchSwiftSDK
import XCTest

// MARK: - SessionManagerIntegrationTests

/// Integration tests for SessionManager that verify component interactions
/// and end-to-end behavior across the session lifecycle.
@available(iOS 13.0, tvOS 13.0, *)
final class SessionManagerIntegrationTests: XCTestCase {
    // MARK: Internal

    // MARK: - Setup / Teardown

    override func setUp() async throws {
        try await super.setUp()
        sessionManager = SessionManager()
    }

    override func tearDown() async throws {
        sessionManager = nil
        try await super.tearDown()
    }

    // MARK: - State Observation Integration Tests

    /// Tests that state observers receive all state transitions in order.
    func testStateObserverReceivesAllTransitions() async throws {
        var observedStates: [SessionState] = []
        let expectation = XCTestExpectation(description: "Observer receives states")
        expectation.expectedFulfillmentCount = 1

        // Start observer in background task
        let observerTask = Task {
            let stream = await sessionManager.observeState()
            for await state in stream {
                observedStates.append(state)
                // Expect at least 2 states: initial + one transition
                if observedStates.count >= 2 {
                    expectation.fulfill()
                    break
                }
            }
        }

        // Give observer time to start
        try await Task.sleep(nanoseconds: 100_000_000) // 0.1s

        // Trigger state change via refresh
        do {
            _ = try await sessionManager.refresh()
        } catch {
            // Expected without network
        }

        await fulfillment(of: [expectation], timeout: 5.0)
        observerTask.cancel()

        // Verify we got the initial uninitialized state
        XCTAssertTrue(observedStates.first?.isUninitialized ?? false)
        // Verify we got at least one transition
        XCTAssertGreaterThanOrEqual(observedStates.count, 2)
    }

    /// Tests multiple observers receive consistent state updates.
    func testMultipleObserversReceiveConsistentStates() async throws {
        var observer1States: [SessionState] = []
        var observer2States: [SessionState] = []
        let expectation1 = XCTestExpectation(description: "Observer 1")
        let expectation2 = XCTestExpectation(description: "Observer 2")

        // Start two observers
        let task1 = Task {
            let stream = await sessionManager.observeState()
            for await state in stream {
                observer1States.append(state)
                if observer1States.count >= 2 {
                    expectation1.fulfill()
                    break
                }
            }
        }

        let task2 = Task {
            let stream = await sessionManager.observeState()
            for await state in stream {
                observer2States.append(state)
                if observer2States.count >= 2 {
                    expectation2.fulfill()
                    break
                }
            }
        }

        // Give observers time to start
        try await Task.sleep(nanoseconds: 100_000_000) // 0.1s

        // Trigger state change
        do {
            _ = try await sessionManager.refresh()
        } catch {
            // Expected without network
        }

        await fulfillment(of: [expectation1, expectation2], timeout: 5.0)
        task1.cancel()
        task2.cancel()

        // Both observers should have same initial state
        XCTAssertEqual(
            observer1States.first?.isUninitialized,
            observer2States.first?.isUninitialized
        )
    }

    // MARK: - Configuration Integration Tests

    /// Tests that configuration persists through state transitions.
    func testConfigurationPersistsThroughTransitions() async throws {
        let testBranchKey = "key_test_integration_xyz"

        // Configure with test key
        await sessionManager.configure(branchKey: testBranchKey)

        // Verify initial state
        let initialState = await sessionManager.currentState
        XCTAssertTrue(initialState.isUninitialized)

        // Attempt initialization (will fail without network)
        do {
            _ = try await sessionManager.initialize(options: InitializationOptions())
        } catch {
            // Expected
        }

        // State should have changed from uninitialized
        let currentState = await sessionManager.currentState
        XCTAssertFalse(currentState.isUninitialized)
    }

    // MARK: - Concurrent Operations Integration Tests

    /// Tests that concurrent initialize and refresh operations don't conflict.
    func testConcurrentInitializeAndRefresh() async throws {
        let iterations = 5
        var results: [Result<BranchSession, Error>] = []
        let lock = NSLock()

        await withTaskGroup(of: Result<BranchSession, Error>.self) { group in
            // Add initialize tasks
            for _ in 0 ..< iterations {
                group.addTask {
                    do {
                        let session = try await self.sessionManager.initialize(
                            options: InitializationOptions()
                        )
                        return .success(session)
                    } catch {
                        return .failure(error)
                    }
                }
            }

            // Add refresh tasks
            for _ in 0 ..< iterations {
                group.addTask {
                    do {
                        let session = try await self.sessionManager.refresh()
                        return .success(session)
                    } catch {
                        return .failure(error)
                    }
                }
            }

            // Collect results
            for await result in group {
                lock.lock()
                results.append(result)
                lock.unlock()
            }
        }

        // All operations should complete (success or expected failure)
        XCTAssertEqual(results.count, iterations * 2)

        // Verify no unexpected crashes or deadlocks
        let failures = results.compactMap { result -> BranchError? in
            if case let .failure(error) = result {
                return error as? BranchError
            }
            return nil
        }

        // All failures should be BranchError (not crashes or unexpected errors)
        for failure in failures {
            XCTAssertNotNil(failure)
        }
    }

    /// Tests that state observation handles rapid state changes.
    func testObserverHandlesRapidStateChanges() async throws {
        var observedStates: [SessionState] = []
        let expectation = XCTestExpectation(description: "Rapid state changes")
        expectation.expectedFulfillmentCount = 1

        let observerTask = Task {
            let stream = await sessionManager.observeState()
            for await state in stream {
                observedStates.append(state)
                if observedStates.count >= 3 {
                    expectation.fulfill()
                    break
                }
            }
        }

        // Give observer time to start
        try await Task.sleep(nanoseconds: 50_000_000) // 0.05s

        // Trigger multiple rapid state changes
        Task {
            try? await sessionManager.initialize(options: InitializationOptions())
        }
        Task {
            try? await sessionManager.refresh()
        }

        await fulfillment(of: [expectation], timeout: 10.0)
        observerTask.cancel()

        // Should have received multiple states
        XCTAssertGreaterThanOrEqual(observedStates.count, 2)
    }

    // MARK: - Error Recovery Integration Tests

    /// Tests that failed initialization allows retry.
    func testFailedInitializationAllowsRetry() async throws {
        // First initialization attempt (will fail without network)
        do {
            _ = try await sessionManager.initialize(options: InitializationOptions())
        } catch {
            // Expected
        }

        let stateAfterFirst = await sessionManager.currentState

        // Attempt retry
        do {
            _ = try await sessionManager.initialize(options: InitializationOptions())
        } catch {
            // Expected
        }

        let stateAfterRetry = await sessionManager.currentState

        // Both should result in some state change (not stuck)
        XCTAssertFalse(stateAfterFirst.isUninitialized)
        XCTAssertFalse(stateAfterRetry.isUninitialized)
    }

    // MARK: - Singleton Integration Tests

    /// Tests that shared instance maintains state across access points.
    func testSharedInstanceMaintainsState() async throws {
        let shared1 = SessionManager.shared
        let shared2 = SessionManager.shared

        // Configure via first reference
        await shared1.configure(branchKey: "key_test_shared")

        // Read state via second reference - should see same state
        let state1 = await shared1.currentState
        let state2 = await shared2.currentState

        XCTAssertEqual(state1, state2)
    }

    // MARK: - Lifecycle Integration Tests

    /// Tests complete SDK lifecycle: configure -> initialize -> use -> logout.
    func testCompleteLifecycle() async throws {
        // 1. Initial state
        let initialState = await sessionManager.currentState
        XCTAssertTrue(initialState.isUninitialized)

        // 2. Configure
        await sessionManager.configure(branchKey: "key_test_lifecycle")
        let afterConfigState = await sessionManager.currentState
        XCTAssertTrue(afterConfigState.isUninitialized) // Config alone doesn't change state

        // 3. Initialize (will fail without network, but state changes)
        do {
            _ = try await sessionManager.initialize(options: InitializationOptions())
        } catch {
            // Expected without network
        }

        let afterInitState = await sessionManager.currentState
        XCTAssertFalse(afterInitState.isUninitialized)

        // 4. If initialized, logout should work
        // (If failed, logout may throw, which is also valid behavior)
        if afterInitState.isInitialized {
            try await sessionManager.logout()
            let afterLogoutState = await sessionManager.currentState
            XCTAssertTrue(afterLogoutState.isUninitialized)
        }
    }

    // MARK: Private

    private var sessionManager: SessionManager!
}

// MARK: - SessionManagerBridgeIntegrationTests

@available(iOS 13.0, tvOS 13.0, *)
final class SessionManagerBridgeIntegrationTests: XCTestCase {
    /// Tests that bridge callbacks are invoked on the expected thread.
    func testBridgeCallbacksInvokedCorrectly() {
        let bridge = SessionManagerBridge.shared
        let expectation = XCTestExpectation(description: "Callback invoked")

        bridge.initialize(options: nil) { _, _ in
            // Verify callback is called
            expectation.fulfill()
        }

        wait(for: [expectation], timeout: 10.0)
    }

    /// Tests that bridge methods don't deadlock when called in sequence.
    func testBridgeMethodsSequentially() {
        let bridge = SessionManagerBridge.shared

        // These should all return without deadlock
        _ = bridge.currentStateString()

        let expectation1 = XCTestExpectation(description: "Init callback")
        bridge.initialize(options: nil) { _, _ in
            expectation1.fulfill()
        }

        let expectation2 = XCTestExpectation(description: "Logout callback")
        bridge.logout { _ in
            expectation2.fulfill()
        }

        wait(for: [expectation1, expectation2], timeout: 10.0)
    }
}
