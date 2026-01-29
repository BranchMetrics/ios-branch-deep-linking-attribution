//
//  BranchSessionCoordinatorTests.swift
//  BranchSDKTests
//
//  Copyright © 2026 Branch Metrics. All rights reserved.
//  SPDX-License-Identifier: MIT
//

@testable import BranchSDK
import XCTest

/// Tests for BranchSessionCoordinator bridging functionality.
///
/// These tests verify that the Objective-C bridge correctly wraps
/// the Swift SessionManager and properly handles callbacks.
@available(iOS 13.0, macOS 10.15, tvOS 13.0, watchOS 6.0, *)
@MainActor
final class BranchSessionCoordinatorTests: XCTestCase {
    nonisolated(unsafe) var sut: BranchSessionCoordinator!

    override func setUp() {
        super.setUp()
        // Note: In production, we'd use dependency injection to get a fresh coordinator.
        // For these tests, we use the shared instance and reset between tests.
        sut = BranchSessionCoordinator.shared
    }

    override func tearDown() {
        sut.resetSession()
        super.tearDown()
    }

    // MARK: - Initialization Tests

    func testInitializeSessionCompletesSuccessfully() {
        let expectation = expectation(description: "Initialize completes")

        sut.initializeSession(url: nil) { session, error in
            XCTAssertNotNil(session)
            XCTAssertNil(error)
            XCTAssertFalse(session?.sessionId.isEmpty ?? true)
            expectation.fulfill()
        }

        waitForExpectations(timeout: 5.0)
    }

    func testInitializeSessionWithURLIncludesLinkData() {
        let expectation = expectation(description: "Initialize with URL completes")
        let testURL = URL(string: "https://test.app.link/deeplink123")!

        sut.initializeSession(url: testURL) { session, error in
            XCTAssertNotNil(session)
            XCTAssertNil(error)
            // URL should be captured in link data
            XCTAssertEqual(session?.linkUrl, testURL)
            expectation.fulfill()
        }

        waitForExpectations(timeout: 5.0)
    }

    // MARK: - State Tests

    func testIsInitializingUpdatesCorrectly() {
        // Initially should be false
        XCTAssertFalse(sut.isInitializing)

        let expectation = expectation(description: "Initialize completes")

        sut.initializeSession(url: nil) { _, _ in
            expectation.fulfill()
        }

        waitForExpectations(timeout: 5.0)

        // After completion, should still be false
        XCTAssertFalse(sut.isInitializing)
    }

    func testIsInitializedAfterInitialization() {
        // Initially should be false
        XCTAssertFalse(sut.isInitialized)

        let initExpectation = expectation(description: "Initialize completes")

        sut.initializeSession(url: nil) { _, _ in
            initExpectation.fulfill()
        }

        waitForExpectations(timeout: 5.0)

        // Need to wait for cached state to update
        // This is async via state observation, so give it a moment
        let checkExpectation = expectation(description: "State check")
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            // After completion, should be true
            XCTAssertTrue(self.sut.isInitialized)
            checkExpectation.fulfill()
        }

        waitForExpectations(timeout: 5.0)
    }

    // MARK: - Reset Tests

    func testResetSessionResetsState() {
        let initExpectation = expectation(description: "Initialize completes")

        sut.initializeSession(url: nil) { _, _ in
            initExpectation.fulfill()
        }

        waitForExpectations(timeout: 5.0)

        // Reset
        sut.resetSession()

        // Wait for reset to complete
        let resetExpectation = expectation(description: "Reset completes")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            XCTAssertFalse(self.sut.isInitialized)
            resetExpectation.fulfill()
        }

        waitForExpectations(timeout: 5.0)
    }

    // MARK: - Deep Link Handling Tests

    func testHandleDeepLinkCompletesSuccessfully() {
        // First initialize
        let initExpectation = expectation(description: "Initialize completes")

        sut.initializeSession(url: nil) { _, _ in
            initExpectation.fulfill()
        }

        waitForExpectations(timeout: 5.0)

        // Then handle deep link
        let deepLinkExpectation = expectation(description: "Deep link handled")
        let testURL = URL(string: "https://test.app.link/link456")!

        sut.handleDeepLink(url: testURL) { session, error in
            XCTAssertNotNil(session)
            XCTAssertNil(error)
            deepLinkExpectation.fulfill()
        }

        waitForExpectations(timeout: 5.0)
    }

    // MARK: - Identity Tests

    func testSetIdentityCompletesSuccessfully() {
        // First initialize
        let initExpectation = expectation(description: "Initialize completes")

        sut.initializeSession(url: nil) { _, _ in
            initExpectation.fulfill()
        }

        waitForExpectations(timeout: 5.0)

        // Then set identity
        let identityExpectation = expectation(description: "Identity set")

        sut.setIdentity("test_user_456") { error in
            XCTAssertNil(error)
            identityExpectation.fulfill()
        }

        waitForExpectations(timeout: 5.0)
    }

    func testLogoutCompletesSuccessfully() {
        // First initialize and set identity
        let initExpectation = expectation(description: "Initialize completes")

        sut.initializeSession(url: nil) { _, _ in
            initExpectation.fulfill()
        }

        waitForExpectations(timeout: 5.0)

        let identityExpectation = expectation(description: "Identity set")

        sut.setIdentity("test_user_789") { error in
            XCTAssertNil(error)
            identityExpectation.fulfill()
        }

        waitForExpectations(timeout: 5.0)

        // Then logout
        let logoutExpectation = expectation(description: "Logout completes")

        sut.logout { error in
            XCTAssertNil(error)
            logoutExpectation.fulfill()
        }

        waitForExpectations(timeout: 5.0)
    }

    // MARK: - Continue User Activity Tests

    func testContinueUserActivityWithValidBrowsingActivity() {
        // First initialize
        let initExpectation = expectation(description: "Initialize completes")

        sut.initializeSession(url: nil) { _, _ in
            initExpectation.fulfill()
        }

        waitForExpectations(timeout: 5.0)

        // Then continue user activity
        let activityExpectation = expectation(description: "User activity handled")

        let userActivity = NSUserActivity(activityType: NSUserActivityTypeBrowsingWeb)
        userActivity.webpageURL = URL(string: "https://test.app.link/universal789")

        sut.continueUserActivity(userActivity) { session, error in
            XCTAssertNotNil(session)
            XCTAssertNil(error)
            activityExpectation.fulfill()
        }

        waitForExpectations(timeout: 5.0)
    }

    func testContinueUserActivityWithInvalidActivityType() {
        let expectation = expectation(description: "User activity fails")

        let userActivity = NSUserActivity(activityType: "com.invalid.activity")
        userActivity.webpageURL = URL(string: "https://test.app.link/invalid")

        sut.continueUserActivity(userActivity) { session, error in
            XCTAssertNil(session)
            XCTAssertNotNil(error)

            if let branchError = error as? BranchError {
                XCTAssertEqual(branchError, BranchError.invalidUserActivity)
            }

            expectation.fulfill()
        }

        waitForExpectations(timeout: 5.0)
    }

    func testContinueUserActivityWithNoURL() {
        let expectation = expectation(description: "User activity fails")

        let userActivity = NSUserActivity(activityType: NSUserActivityTypeBrowsingWeb)
        // No webpageURL set

        sut.continueUserActivity(userActivity) { session, error in
            XCTAssertNil(session)
            XCTAssertNotNil(error)

            if let branchError = error as? BranchError {
                XCTAssertEqual(branchError, BranchError.invalidUserActivity)
            }

            expectation.fulfill()
        }

        waitForExpectations(timeout: 5.0)
    }

    // MARK: - Swift Native API Tests

    func testObserveStateReturnsStream() async {
        let stream = sut.observeState()

        var receivedStates: [SessionState] = []
        let task = Task {
            for await state in stream {
                receivedStates.append(state)
                if receivedStates.count >= 1 {
                    break
                }
            }
        }

        // Wait a bit for first state
        try? await Task.sleep(nanoseconds: 10_000_000) // 10ms
        task.cancel()

        XCTAssertFalse(receivedStates.isEmpty)
    }

    func testCurrentSessionAsync() async throws {
        // Initialize first
        let options = InitializationOptions()
        _ = try await sut.sessionManager.initialize(options: options)

        let session = await sut.currentSession
        XCTAssertNotNil(session)
    }

    // MARK: - Multiple Initialization Tests

    func testDoubleInitializationReturnsValidSession() {
        let expectation1 = expectation(description: "First init completes")
        let expectation2 = expectation(description: "Second init completes")

        var session1: BranchObjCSession?
        var session2: BranchObjCSession?

        // Start two initializations nearly simultaneously
        sut.initializeSession(url: nil) { session, _ in
            session1 = session
            expectation1.fulfill()
        }

        sut.initializeSession(url: URL(string: "https://test.app.link/double")!) { session, _ in
            session2 = session
            expectation2.fulfill()
        }

        waitForExpectations(timeout: 5.0)

        // Both should complete successfully
        XCTAssertNotNil(session1)
        XCTAssertNotNil(session2)

        // Both should have the same session ID (coalesced)
        XCTAssertEqual(session1?.sessionId, session2?.sessionId)
    }

    // MARK: - Deep Link Handling with Different URL Types

    func testHandleDeepLinkWithHTTPSURL() {
        // First initialize
        let initExpectation = expectation(description: "Initialize completes")

        sut.initializeSession(url: nil) { _, _ in
            initExpectation.fulfill()
        }

        waitForExpectations(timeout: 5.0)

        // Handle HTTPS deep link
        let deepLinkExpectation = expectation(description: "Deep link handled")
        let testURL = URL(string: "https://test.app.link/https-link")!

        sut.handleDeepLink(url: testURL) { session, error in
            XCTAssertNotNil(session)
            XCTAssertNil(error)
            deepLinkExpectation.fulfill()
        }

        waitForExpectations(timeout: 5.0)
    }

    func testHandleDeepLinkWithCustomScheme() {
        // First initialize
        let initExpectation = expectation(description: "Initialize completes")

        sut.initializeSession(url: nil) { _, _ in
            initExpectation.fulfill()
        }

        waitForExpectations(timeout: 5.0)

        // Handle custom scheme deep link
        let deepLinkExpectation = expectation(description: "Deep link handled")
        let testURL = URL(string: "myapp://open/feature")!

        sut.handleDeepLink(url: testURL) { session, error in
            XCTAssertNotNil(session)
            XCTAssertNil(error)
            deepLinkExpectation.fulfill()
        }

        waitForExpectations(timeout: 5.0)
    }

    // MARK: - Reset Edge Cases

    func testResetAfterIdentitySet() {
        // Initialize and set identity
        let initExpectation = expectation(description: "Initialize completes")

        sut.initializeSession(url: nil) { _, _ in
            initExpectation.fulfill()
        }

        waitForExpectations(timeout: 5.0)

        let identityExpectation = expectation(description: "Identity set")

        sut.setIdentity("user_before_reset") { error in
            XCTAssertNil(error)
            identityExpectation.fulfill()
        }

        waitForExpectations(timeout: 5.0)

        // Reset
        sut.resetSession()

        // Verify reset clears everything
        let checkExpectation = expectation(description: "State check")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            XCTAssertFalse(self.sut.isInitialized)
            checkExpectation.fulfill()
        }

        waitForExpectations(timeout: 5.0)
    }

    // MARK: - State Properties Tests

    func testIsInitializingDuringInitialization() {
        // Start initialization
        let expectation = expectation(description: "Initialize completes")

        sut.initializeSession(url: nil) { _, _ in
            expectation.fulfill()
        }

        // Note: isInitializing might be true during this brief moment
        // but this is hard to test reliably due to timing

        waitForExpectations(timeout: 5.0)

        // After completion, should be false
        XCTAssertFalse(sut.isInitializing)
    }

    // MARK: - User Activity Edge Cases

    func testContinueUserActivityWithHandoffActivity() {
        let expectation = expectation(description: "User activity fails")

        // Handoff activities (not browsing) should fail
        let userActivity = NSUserActivity(activityType: "com.myapp.handoff")
        userActivity.title = "Handoff Activity"

        sut.continueUserActivity(userActivity) { session, error in
            XCTAssertNil(session)
            XCTAssertNotNil(error)

            if let branchError = error as? BranchError {
                XCTAssertEqual(branchError, BranchError.invalidUserActivity)
            }

            expectation.fulfill()
        }

        waitForExpectations(timeout: 5.0)
    }
}
