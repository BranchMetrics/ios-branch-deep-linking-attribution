//
//  SessionStateTests.swift
//  Branch iOS SDK - Modern Swift Implementation
//
//  Copyright © 2026 Branch Metrics. All rights reserved.
//  SPDX-License-Identifier: MIT
//

//
//  SessionStateTests.swift
//  BranchSwiftSDKTests
//
//  Branch iOS SDK - Modern Swift Implementation
//  Copyright © 2026 Branch Metrics. All rights reserved.
//  SPDX-License-Identifier: MIT
//
//  JIRA: EMT-2737
//  Unit tests for SessionState
//

@testable import BranchSwiftSDK
import XCTest

@available(iOS 13.0, tvOS 13.0, *)
final class SessionStateTests: XCTestCase {
    // MARK: - State Property Tests

    func testUninitializedState() {
        let state = SessionState.uninitialized

        XCTAssertTrue(state.isUninitialized)
        XCTAssertFalse(state.isInitializing)
        XCTAssertFalse(state.isInitialized)
        XCTAssertFalse(state.isFailed)
        XCTAssertNil(state.session)
        XCTAssertNil(state.error)
    }

    func testInitializingState() {
        let state = SessionState.initializing

        XCTAssertFalse(state.isUninitialized)
        XCTAssertTrue(state.isInitializing)
        XCTAssertFalse(state.isInitialized)
        XCTAssertFalse(state.isFailed)
        XCTAssertNil(state.session)
        XCTAssertNil(state.error)
    }

    func testInitializedState() {
        let session = BranchSession(
            sessionId: "test-session-123",
            randomizedBundleToken: "bundle-token",
            randomizedDeviceToken: "device-token"
        )
        let state = SessionState.initialized(session)

        XCTAssertFalse(state.isUninitialized)
        XCTAssertFalse(state.isInitializing)
        XCTAssertTrue(state.isInitialized)
        XCTAssertFalse(state.isFailed)
        XCTAssertNotNil(state.session)
        XCTAssertEqual(state.session?.sessionId, "test-session-123")
        XCTAssertNil(state.error)
    }

    func testFailedState() {
        let error = BranchError.initializationFailed(reason: "Test error")
        let state = SessionState.failed(error)

        XCTAssertFalse(state.isUninitialized)
        XCTAssertFalse(state.isInitializing)
        XCTAssertFalse(state.isInitialized)
        XCTAssertTrue(state.isFailed)
        XCTAssertNil(state.session)
        XCTAssertNotNil(state.error)
    }

    // MARK: - State Transition Tests

    func testValidTransitionFromUninitialized() {
        let state = SessionState.uninitialized

        // Can transition to initializing
        XCTAssertTrue(state.canTransition(to: .initializing))

        // Cannot transition to other states directly
        let session = BranchSession(sessionId: "test")
        XCTAssertFalse(state.canTransition(to: .initialized(session)))
        XCTAssertFalse(state.canTransition(to: .failed(.notInitialized)))
        XCTAssertFalse(state.canTransition(to: .uninitialized))
    }

    func testValidTransitionFromInitializing() {
        let state = SessionState.initializing
        let session = BranchSession(sessionId: "test")

        // Can transition to initialized or failed
        XCTAssertTrue(state.canTransition(to: .initialized(session)))
        XCTAssertTrue(state.canTransition(to: .failed(.networkError(statusCode: 500, message: "Test"))))

        // Cannot transition to uninitialized or stay initializing
        XCTAssertFalse(state.canTransition(to: .uninitialized))
        XCTAssertFalse(state.canTransition(to: .initializing))
    }

    func testValidTransitionFromInitialized() {
        let session = BranchSession(sessionId: "test")
        let state = SessionState.initialized(session)

        // Can transition to uninitialized (logout)
        XCTAssertTrue(state.canTransition(to: .uninitialized))

        // Cannot transition to other states
        XCTAssertFalse(state.canTransition(to: .initializing))
        XCTAssertFalse(state.canTransition(to: .initialized(session)))
        XCTAssertFalse(state.canTransition(to: .failed(.notInitialized)))
    }

    func testValidTransitionFromFailed() {
        let state = SessionState.failed(.initializationFailed(reason: "Test"))

        // Can transition to initializing (retry) or uninitialized (reset)
        XCTAssertTrue(state.canTransition(to: .initializing))
        XCTAssertTrue(state.canTransition(to: .uninitialized))

        // Cannot transition to other states
        let session = BranchSession(sessionId: "test")
        XCTAssertFalse(state.canTransition(to: .initialized(session)))
        XCTAssertFalse(state.canTransition(to: .failed(.networkError(statusCode: 500, message: "Another"))))
    }

    // MARK: - Equatable Tests

    func testEquatableUninitialized() {
        XCTAssertEqual(SessionState.uninitialized, SessionState.uninitialized)
        XCTAssertNotEqual(SessionState.uninitialized, SessionState.initializing)
    }

    func testEquatableInitializing() {
        XCTAssertEqual(SessionState.initializing, SessionState.initializing)
        XCTAssertNotEqual(SessionState.initializing, SessionState.uninitialized)
    }

    func testEquatableInitialized() {
        let session1 = BranchSession(sessionId: "same-id")
        let session2 = BranchSession(sessionId: "same-id")
        let session3 = BranchSession(sessionId: "different-id")

        XCTAssertEqual(
            SessionState.initialized(session1),
            SessionState.initialized(session2)
        )
        XCTAssertNotEqual(
            SessionState.initialized(session1),
            SessionState.initialized(session3)
        )
    }

    func testEquatableFailed() {
        let error1 = BranchError.notInitialized
        let error2 = BranchError.notInitialized
        let error3 = BranchError.timeout

        XCTAssertEqual(SessionState.failed(error1), SessionState.failed(error2))
        XCTAssertNotEqual(SessionState.failed(error1), SessionState.failed(error3))
    }

    // MARK: - Description Tests

    func testDescription() {
        XCTAssertEqual(
            SessionState.uninitialized.description,
            "SessionState.uninitialized"
        )
        XCTAssertEqual(
            SessionState.initializing.description,
            "SessionState.initializing"
        )

        let session = BranchSession(sessionId: "test-123")
        XCTAssertTrue(
            SessionState.initialized(session).description.contains("test-123")
        )

        let error = BranchError.notInitialized
        XCTAssertTrue(
            SessionState.failed(error).description.contains("failed")
        )
    }
}
