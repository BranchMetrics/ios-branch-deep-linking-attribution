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
    nonisolated(unsafe) var mockNetworkService: MockBranchNetworkService!

    override func setUp() {
        super.setUp()
        // Clean up UserDefaults to prevent test pollution
        UserDefaults.standard.removeObject(forKey: "branch_has_installed")

        // Use mock network service with standard responses
        mockNetworkService = MockBranchNetworkService.withStandardResponses()
        sut = BranchSessionCoordinator(networkService: mockNetworkService)
    }

    override func tearDown() {
        sut.resetSession()
        mockNetworkService?.resetCallTracking()
        mockNetworkService = nil
        // Clean up UserDefaults
        UserDefaults.standard.removeObject(forKey: "branch_has_installed")
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

    // MARK: - Qualitative Integration Tests

    /// Scenario: Rapid-fire initialization from multiple iOS lifecycle callbacks
    /// This is the "Double Open" bug fix verification (INTENG-21106)
    /// Expected: Only one network call, all callbacks receive the same session
    func testDoubleOpenFix_OnlyOneNetworkCallForConcurrentInitializations() {
        let expectation1 = expectation(description: "First init completes")
        let expectation2 = expectation(description: "Second init completes")
        let expectation3 = expectation(description: "Third init completes")

        var session1: BranchObjCSession?
        var session2: BranchObjCSession?
        var session3: BranchObjCSession?

        // Simulate iOS calling multiple lifecycle methods nearly simultaneously
        // This happens with Universal Links: didFinishLaunching + continueUserActivity
        sut.initializeSession(url: nil) { session, _ in
            session1 = session
            expectation1.fulfill()
        }

        sut.initializeSession(url: URL(string: "https://test.app.link/link1")) { session, _ in
            session2 = session
            expectation2.fulfill()
        }

        sut.initializeSession(url: URL(string: "https://test.app.link/link2")) { session, _ in
            session3 = session
            expectation3.fulfill()
        }

        waitForExpectations(timeout: 5.0)

        // All should complete successfully
        XCTAssertNotNil(session1)
        XCTAssertNotNil(session2)
        XCTAssertNotNil(session3)

        // All should have the same session ID (coalesced)
        XCTAssertEqual(session1?.sessionId, session2?.sessionId, "Concurrent calls should be coalesced")
        XCTAssertEqual(session2?.sessionId, session3?.sessionId, "All calls should be coalesced")

        // Verify only one network call was made (coalescing worked)
        let totalNetworkCalls = mockNetworkService.installCallCount + mockNetworkService.openCallCount
        XCTAssertEqual(totalNetworkCalls, 1, "Task coalescing should result in single network call")
    }

    /// Scenario: Network failure should propagate correctly through the callback
    /// Important: Error handling in ObjC callbacks must work correctly
    func testNetworkFailure_PropagatesErrorThroughCallback() {
        mockNetworkService.shouldFail = true
        mockNetworkService.failureError = BranchError.networkError("Connection lost")

        let expectation = expectation(description: "Initialize fails with error")

        sut.initializeSession(url: nil) { session, error in
            XCTAssertNil(session, "Session should be nil on network failure")
            XCTAssertNotNil(error, "Error should be provided on failure")

            if let branchError = error as? BranchError {
                if case let .networkError(message) = branchError {
                    XCTAssertEqual(message, "Connection lost")
                } else {
                    XCTFail("Expected networkError, got: \(branchError)")
                }
            } else {
                XCTFail("Error should be BranchError type")
            }

            expectation.fulfill()
        }

        waitForExpectations(timeout: 5.0)
    }

    /// Scenario: Server error (500) should be handled gracefully
    func testServerError_HandledGracefully() {
        mockNetworkService.shouldFail = true
        mockNetworkService.failureError = BranchError.serverError(statusCode: 500, message: "Internal Server Error")

        let expectation = expectation(description: "Initialize fails with server error")

        sut.initializeSession(url: nil) { session, error in
            XCTAssertNil(session)
            XCTAssertNotNil(error)

            if let branchError = error as? BranchError {
                if case let .serverError(code, message) = branchError {
                    XCTAssertEqual(code, 500)
                    XCTAssertEqual(message, "Internal Server Error")
                } else {
                    XCTFail("Expected serverError")
                }
            }

            expectation.fulfill()
        }

        waitForExpectations(timeout: 5.0)
    }

    /// Scenario: Handle deep link during ongoing initialization
    /// Expected: URL should be merged into pending initialization (not lost)
    func testHandleDeepLinkDuringInitialization_URLNotLost() {
        let initExpectation = expectation(description: "Initialize completes")
        let deepLinkExpectation = expectation(description: "Deep link handled")

        var initSession: BranchObjCSession?
        var deepLinkSession: BranchObjCSession?

        // Start initialization
        sut.initializeSession(url: nil) { session, _ in
            initSession = session
            initExpectation.fulfill()
        }

        // Immediately handle deep link (simulates Universal Link arriving during init)
        let deepLinkURL = URL(string: "https://test.app.link/promo-link")!
        sut.handleDeepLink(url: deepLinkURL) { session, _ in
            deepLinkSession = session
            deepLinkExpectation.fulfill()
        }

        waitForExpectations(timeout: 5.0)

        // Both should complete with valid sessions
        XCTAssertNotNil(initSession)
        XCTAssertNotNil(deepLinkSession)

        // Sessions should be coalesced (same ID)
        XCTAssertEqual(initSession?.sessionId, deepLinkSession?.sessionId)
    }

    /// Scenario: Sequential operations should work correctly
    /// Important: init → setIdentity → logout → reinit flow
    func testFullUserLifecycle_InitIdentityLogoutReinit() {
        // Step 1: Initialize
        let initExpectation = expectation(description: "Initialize completes")
        sut.initializeSession(url: nil) { session, error in
            XCTAssertNotNil(session)
            XCTAssertNil(error)
            initExpectation.fulfill()
        }
        waitForExpectations(timeout: 5.0)

        // Step 2: Set Identity (user logs in)
        let identityExpectation = expectation(description: "Identity set")
        sut.setIdentity("user-lifecycle-test") { error in
            XCTAssertNil(error, "setIdentity should succeed")
            identityExpectation.fulfill()
        }
        waitForExpectations(timeout: 5.0)

        // Step 3: Verify network call was made for identity
        XCTAssertEqual(mockNetworkService.identityCallCount, 1, "Identity API should be called")
        XCTAssertEqual(mockNetworkService.lastIdentityUserId, "user-lifecycle-test")

        // Step 4: Logout (user logs out)
        let logoutExpectation = expectation(description: "Logout completes")
        sut.logout { error in
            XCTAssertNil(error, "Logout should succeed")
            logoutExpectation.fulfill()
        }
        waitForExpectations(timeout: 5.0)

        // Step 5: Verify logout API was called
        XCTAssertEqual(mockNetworkService.logoutCallCount, 1, "Logout API should be called")

        // Step 6: Reset and reinitialize (simulate app restart)
        sut.resetSession()

        let reinitWait = expectation(description: "Wait for reset")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            reinitWait.fulfill()
        }
        waitForExpectations(timeout: 5.0)

        let reinitExpectation = expectation(description: "Reinitialize completes")
        sut.initializeSession(url: nil) { session, error in
            XCTAssertNotNil(session)
            XCTAssertNil(error)
            reinitExpectation.fulfill()
        }
        waitForExpectations(timeout: 5.0)
    }

    /// Scenario: Callbacks must be delivered on main thread
    /// Important: UI updates require main thread delivery
    func testCallbacks_DeliveredOnMainThread() {
        let expectation = expectation(description: "Initialize completes")

        sut.initializeSession(url: nil) { _, _ in
            XCTAssertTrue(Thread.isMainThread, "Callback must be on main thread for UI safety")
            expectation.fulfill()
        }

        waitForExpectations(timeout: 5.0)
    }

    /// Scenario: Error callbacks must also be on main thread
    func testErrorCallbacks_DeliveredOnMainThread() {
        mockNetworkService.shouldFail = true

        let expectation = expectation(description: "Initialize fails")

        sut.initializeSession(url: nil) { _, _ in
            XCTAssertTrue(Thread.isMainThread, "Error callback must be on main thread")
            expectation.fulfill()
        }

        waitForExpectations(timeout: 5.0)
    }

    /// Scenario: Observable state reflects correct transitions
    /// Important: SwiftUI/Combine observers depend on accurate state
    func testObservableState_ReflectsCorrectTransitions() async throws {
        // Initially uninitialized
        let initialState = await sut.state
        XCTAssertEqual(initialState, .uninitialized)

        // Initialize
        let options = InitializationOptions()
        _ = try await sut.sessionManager.initialize(options: options)

        // Should now be initialized
        let afterInitState = await sut.state
        XCTAssertTrue(afterInitState.isReady, "State should be ready after init")

        // Reset
        await sut.sessionManager.reset()

        // Should be back to uninitialized
        let afterResetState = await sut.state
        XCTAssertEqual(afterResetState, .uninitialized)
    }

    /// Scenario: BranchObjCSession correctly wraps Swift Session
    /// Important: All data must transfer correctly to ObjC layer
    func testBranchObjCSession_CorrectlyWrapsSwiftSession() {
        let expectation = expectation(description: "Initialize completes")
        let testURL = URL(string: "https://test.app.link/objc-test")!

        sut.initializeSession(url: testURL) { session, _ in
            guard let session = session else {
                XCTFail("Session should not be nil")
                return
            }

            // Verify all fields are correctly mapped
            XCTAssertFalse(session.sessionId.isEmpty, "sessionId should be populated")
            XCTAssertFalse(session.identityId.isEmpty, "identityId should be populated")
            XCTAssertFalse(session.deviceFingerprintId.isEmpty, "deviceFingerprintId should be populated")

            // URL should be captured
            XCTAssertEqual(session.linkUrl, testURL, "linkUrl should match input URL")

            // isFirstSession should be a valid boolean (either true or false is fine)
            // Just verify it's accessible
            _ = session.isFirstSession

            expectation.fulfill()
        }

        waitForExpectations(timeout: 5.0)
    }

    /// Scenario: Verify request data is correctly populated
    func testRequestData_CorrectlyPopulated() {
        let expectation = expectation(description: "Initialize completes")
        let testURL = URL(string: "https://test.app.link/request-test?param=value")!

        sut.initializeSession(url: testURL) { _, _ in
            expectation.fulfill()
        }

        waitForExpectations(timeout: 5.0)

        // Verify install request was made with correct data
        XCTAssertNotNil(mockNetworkService.lastInstallRequest)
    }
}
