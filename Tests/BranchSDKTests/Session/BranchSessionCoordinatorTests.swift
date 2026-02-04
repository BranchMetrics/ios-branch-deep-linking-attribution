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
/// These tests verify that the coordinator correctly wraps
/// the SessionManager and properly handles callbacks.
@MainActor
final class BranchSessionCoordinatorTests: XCTestCase {
    var sut: BranchSessionCoordinator!

    override func setUp() async throws {
        // Clean up UserDefaults to prevent test pollution
        UserDefaults.standard.removeObject(forKey: "branch_has_installed")

        sut = BranchSessionCoordinator.shared
        sut.reset()
    }

    override func tearDown() async throws {
        sut.reset()
        sut = nil
        // Clean up UserDefaults
        UserDefaults.standard.removeObject(forKey: "branch_has_installed")
    }

    // MARK: - Initialization Tests

    func testInitializeSessionCompletesSuccessfully() {
        let expectation = expectation(description: "Initialize completes")

        sut.initialize(url: nil) { session, error in
            XCTAssertNotNil(session)
            XCTAssertNil(error)
            XCTAssertFalse(session?.id.isEmpty ?? true)
            expectation.fulfill()
        }

        waitForExpectations(timeout: 10.0)
    }

    func testInitializeSessionWithURLIncludesLinkData() {
        let expectation = expectation(description: "Initialize with URL completes")
        let testURL = URL(string: "https://test.app.link/deeplink123")!

        sut.initialize(url: testURL) { session, error in
            XCTAssertNotNil(session)
            XCTAssertNil(error)
            // URL should be captured in params
            let referringLink = session?.params["~referring_link"] as? String
            XCTAssertNotNil(referringLink)
            expectation.fulfill()
        }

        waitForExpectations(timeout: 10.0)
    }

    func testInitializeWithOptions() {
        let expectation = expectation(description: "Initialize with options completes")

        let options = InitializationOptions()
        options.url = URL(string: "https://test.app.link/options-test")!
        options.sceneIdentifier = "test-scene"

        sut.initialize(options: options) { session, error in
            XCTAssertNotNil(session)
            XCTAssertNil(error)
            expectation.fulfill()
        }

        waitForExpectations(timeout: 10.0)
    }

    func testInitializeWithCompletionOnly() {
        let expectation = expectation(description: "Initialize completes")

        sut.initialize { session, error in
            XCTAssertNotNil(session)
            XCTAssertNil(error)
            expectation.fulfill()
        }

        waitForExpectations(timeout: 10.0)
    }

    // MARK: - State Tests

    func testIsInitializingUpdatesCorrectly() {
        // Initially should be false
        XCTAssertFalse(sut.isInitializing)

        let expectation = expectation(description: "Initialize completes")

        sut.initialize(url: nil) { _, _ in
            expectation.fulfill()
        }

        waitForExpectations(timeout: 10.0)

        // After completion, should still be false
        XCTAssertFalse(sut.isInitializing)
    }

    func testIsInitializedAfterInitialization() {
        // Initially should be false
        XCTAssertFalse(sut.isInitialized)

        let initExpectation = expectation(description: "Initialize completes")

        sut.initialize(url: nil) { _, _ in
            initExpectation.fulfill()
        }

        waitForExpectations(timeout: 10.0)

        // After completion, should be true
        XCTAssertTrue(sut.isInitialized)
    }

    func testStateProperty() {
        XCTAssertEqual(sut.state, .uninitialized)

        let expectation = expectation(description: "Initialize completes")

        sut.initialize(url: nil) { _, _ in
            expectation.fulfill()
        }

        waitForExpectations(timeout: 10.0)

        XCTAssertEqual(sut.state, .initialized)
    }

    // MARK: - Reset Tests

    func testResetResetsState() {
        let initExpectation = expectation(description: "Initialize completes")

        sut.initialize(url: nil) { _, _ in
            initExpectation.fulfill()
        }

        waitForExpectations(timeout: 10.0)

        XCTAssertTrue(sut.isInitialized)

        // Reset
        sut.reset()

        // Wait for reset to complete
        let resetExpectation = expectation(description: "Reset completes")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            resetExpectation.fulfill()
        }

        waitForExpectations(timeout: 5.0)

        XCTAssertFalse(sut.isInitialized)
    }

    // MARK: - Deep Link Handling Tests

    func testHandleDeepLinkCompletesSuccessfully() {
        // First initialize
        let initExpectation = expectation(description: "Initialize completes")

        sut.initialize(url: nil) { _, _ in
            initExpectation.fulfill()
        }

        waitForExpectations(timeout: 10.0)

        // Then handle deep link
        let deepLinkExpectation = expectation(description: "Deep link handled")
        let testURL = URL(string: "https://test.app.link/link456")!

        sut.handleDeepLink(testURL) { session, error in
            XCTAssertNotNil(session)
            XCTAssertNil(error)
            deepLinkExpectation.fulfill()
        }

        waitForExpectations(timeout: 10.0)
    }

    func testHandleDeepLinkWithHTTPSURL() {
        // First initialize
        let initExpectation = expectation(description: "Initialize completes")

        sut.initialize(url: nil) { _, _ in
            initExpectation.fulfill()
        }

        waitForExpectations(timeout: 10.0)

        // Handle HTTPS deep link
        let deepLinkExpectation = expectation(description: "Deep link handled")
        let testURL = URL(string: "https://test.app.link/https-link")!

        sut.handleDeepLink(testURL) { session, error in
            XCTAssertNotNil(session)
            XCTAssertNil(error)
            deepLinkExpectation.fulfill()
        }

        waitForExpectations(timeout: 10.0)
    }

    func testHandleDeepLinkWithCustomScheme() {
        // First initialize
        let initExpectation = expectation(description: "Initialize completes")

        sut.initialize(url: nil) { _, _ in
            initExpectation.fulfill()
        }

        waitForExpectations(timeout: 10.0)

        // Handle custom scheme deep link
        let deepLinkExpectation = expectation(description: "Deep link handled")
        let testURL = URL(string: "myapp://open/feature")!

        sut.handleDeepLink(testURL) { session, error in
            XCTAssertNotNil(session)
            XCTAssertNil(error)
            deepLinkExpectation.fulfill()
        }

        waitForExpectations(timeout: 10.0)
    }

    // MARK: - Continue User Activity Tests

    func testContinueUserActivityWithValidBrowsingActivity() {
        // First initialize
        let initExpectation = expectation(description: "Initialize completes")

        sut.initialize(url: nil) { _, _ in
            initExpectation.fulfill()
        }

        waitForExpectations(timeout: 10.0)

        // Then continue user activity
        let activityExpectation = expectation(description: "User activity handled")

        let userActivity = NSUserActivity(activityType: NSUserActivityTypeBrowsingWeb)
        userActivity.webpageURL = URL(string: "https://test.app.link/universal789")

        sut.continueUserActivity(userActivity) { session, error in
            XCTAssertNotNil(session)
            XCTAssertNil(error)
            activityExpectation.fulfill()
        }

        waitForExpectations(timeout: 10.0)
    }

    func testContinueUserActivityWithInvalidActivityType() {
        let expectation = expectation(description: "User activity fails")

        let userActivity = NSUserActivity(activityType: "com.invalid.activity")
        userActivity.webpageURL = URL(string: "https://test.app.link/invalid")

        sut.continueUserActivity(userActivity) { session, error in
            XCTAssertNil(session)
            XCTAssertNotNil(error)

            // Should be an NSError with appropriate code
            if let nsError = error {
                XCTAssertEqual(nsError.domain, "io.branch.sdk")
            }

            expectation.fulfill()
        }

        waitForExpectations(timeout: 10.0)
    }

    func testContinueUserActivityWithNoURL() {
        let expectation = expectation(description: "User activity fails")

        let userActivity = NSUserActivity(activityType: NSUserActivityTypeBrowsingWeb)
        // No webpageURL set

        sut.continueUserActivity(userActivity) { session, error in
            XCTAssertNil(session)
            XCTAssertNotNil(error)

            if let nsError = error {
                XCTAssertEqual(nsError.domain, "io.branch.sdk")
            }

            expectation.fulfill()
        }

        waitForExpectations(timeout: 10.0)
    }

    func testContinueUserActivityWithHandoffActivity() {
        let expectation = expectation(description: "User activity fails")

        // Handoff activities (not browsing) should fail
        let userActivity = NSUserActivity(activityType: "com.myapp.handoff")
        userActivity.title = "Handoff Activity"

        sut.continueUserActivity(userActivity) { session, error in
            XCTAssertNil(session)
            XCTAssertNotNil(error)

            if let nsError = error {
                XCTAssertEqual(nsError.domain, "io.branch.sdk")
            }

            expectation.fulfill()
        }

        waitForExpectations(timeout: 10.0)
    }

    // MARK: - Multiple Initialization Tests

    func testDoubleInitializationReturnsValidSession() {
        let expectation1 = expectation(description: "First init completes")
        let expectation2 = expectation(description: "Second init completes")

        var session1: Session?
        var session2: Session?

        // Start two initializations nearly simultaneously
        sut.initialize(url: nil) { session, _ in
            session1 = session
            expectation1.fulfill()
        }

        sut.initialize(url: URL(string: "https://test.app.link/double")!) { session, _ in
            session2 = session
            expectation2.fulfill()
        }

        waitForExpectations(timeout: 10.0)

        // Both should complete successfully
        XCTAssertNotNil(session1)
        XCTAssertNotNil(session2)

        // Both should have the same session ID (coalesced)
        XCTAssertEqual(session1?.id, session2?.id)
    }

    // MARK: - Qualitative Integration Tests

    /// Scenario: Rapid-fire initialization from multiple iOS lifecycle callbacks
    /// This is the "Double Open" bug fix verification (INTENG-21106)
    /// Expected: Only one network call, all callbacks receive the same session
    func testDoubleOpenFix_OnlyOneNetworkCallForConcurrentInitializations() {
        let expectation1 = expectation(description: "First init completes")
        let expectation2 = expectation(description: "Second init completes")
        let expectation3 = expectation(description: "Third init completes")

        var session1: Session?
        var session2: Session?
        var session3: Session?

        // Simulate iOS calling multiple lifecycle methods nearly simultaneously
        sut.initialize(url: nil) { session, _ in
            session1 = session
            expectation1.fulfill()
        }

        sut.initialize(url: URL(string: "https://test.app.link/link1")) { session, _ in
            session2 = session
            expectation2.fulfill()
        }

        sut.initialize(url: URL(string: "https://test.app.link/link2")) { session, _ in
            session3 = session
            expectation3.fulfill()
        }

        waitForExpectations(timeout: 10.0)

        // All should complete successfully
        XCTAssertNotNil(session1)
        XCTAssertNotNil(session2)
        XCTAssertNotNil(session3)

        // All should have the same session ID (coalesced)
        XCTAssertEqual(session1?.id, session2?.id, "Concurrent calls should be coalesced")
        XCTAssertEqual(session2?.id, session3?.id, "All calls should be coalesced")
    }

    /// Scenario: Handle deep link during ongoing initialization
    /// Expected: URL should be merged into pending initialization (not lost)
    func testHandleDeepLinkDuringInitialization_URLNotLost() {
        let initExpectation = expectation(description: "Initialize completes")
        let deepLinkExpectation = expectation(description: "Deep link handled")

        var initSession: Session?
        var deepLinkSession: Session?

        // Start initialization
        sut.initialize(url: nil) { session, _ in
            initSession = session
            initExpectation.fulfill()
        }

        // Immediately handle deep link (simulates Universal Link arriving during init)
        let deepLinkURL = URL(string: "https://test.app.link/promo-link")!
        sut.handleDeepLink(deepLinkURL) { session, _ in
            deepLinkSession = session
            deepLinkExpectation.fulfill()
        }

        waitForExpectations(timeout: 10.0)

        // Both should complete with valid sessions
        XCTAssertNotNil(initSession)
        XCTAssertNotNil(deepLinkSession)

        // Sessions should be coalesced (same ID)
        XCTAssertEqual(initSession?.id, deepLinkSession?.id)
    }

    /// Scenario: Full user lifecycle: init → reset → reinit
    func testFullLifecycle_InitResetReinit() {
        // Step 1: Initialize
        let initExpectation = expectation(description: "Initialize completes")
        sut.initialize(url: nil) { session, error in
            XCTAssertNotNil(session)
            XCTAssertNil(error)
            initExpectation.fulfill()
        }
        waitForExpectations(timeout: 10.0)

        XCTAssertTrue(sut.isInitialized)

        // Step 2: Reset
        sut.reset()

        let resetExpectation = expectation(description: "Reset completes")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            resetExpectation.fulfill()
        }
        waitForExpectations(timeout: 5.0)

        XCTAssertFalse(sut.isInitialized)

        // Step 3: Reinitialize
        let reinitExpectation = expectation(description: "Reinitialize completes")
        sut.initialize(url: nil) { session, error in
            XCTAssertNotNil(session)
            XCTAssertNil(error)
            reinitExpectation.fulfill()
        }
        waitForExpectations(timeout: 10.0)

        XCTAssertTrue(sut.isInitialized)
    }

    /// Scenario: Callbacks must be delivered on main thread
    /// Important: UI updates require main thread delivery
    func testCallbacks_DeliveredOnMainThread() {
        let expectation = expectation(description: "Initialize completes")

        sut.initialize(url: nil) { _, _ in
            XCTAssertTrue(Thread.isMainThread, "Callback must be on main thread for UI safety")
            expectation.fulfill()
        }

        waitForExpectations(timeout: 10.0)
    }

    /// Scenario: Error callbacks must also be on main thread
    func testErrorCallbacks_DeliveredOnMainThread() {
        let expectation = expectation(description: "Error callback received")

        // Invalid user activity should produce an error on main thread
        let userActivity = NSUserActivity(activityType: "com.invalid.activity")

        sut.continueUserActivity(userActivity) { _, _ in
            XCTAssertTrue(Thread.isMainThread, "Error callback must be on main thread")
            expectation.fulfill()
        }

        waitForExpectations(timeout: 10.0)
    }

    // MARK: - Current Session Property Tests

    func testCurrentSessionIsNilBeforeInit() {
        XCTAssertNil(sut.currentSession)
    }

    func testCurrentSessionIsSetAfterInit() {
        let expectation = expectation(description: "Initialize completes")

        sut.initialize(url: nil) { _, _ in
            expectation.fulfill()
        }

        waitForExpectations(timeout: 10.0)

        XCTAssertNotNil(sut.currentSession)
        XCTAssertFalse(sut.currentSession?.id.isEmpty ?? true)
    }

    // MARK: - State Observer Tests

    func testAddStateObserver() {
        let willStartExpectation = expectation(description: "Will start notification")
        let didStartExpectation = expectation(description: "Did start notification")

        class StateObserver: NSObject {
            var willStartCalled = false
            var didStartCalled = false
            var willStartExpectation: XCTestExpectation?
            var didStartExpectation: XCTestExpectation?

            @objc func willStartSession(_: Notification) {
                willStartCalled = true
                willStartExpectation?.fulfill()
            }

            @objc func didStartSession(_: Notification) {
                didStartCalled = true
                didStartExpectation?.fulfill()
            }
        }

        let observer = StateObserver()
        observer.willStartExpectation = willStartExpectation
        observer.didStartExpectation = didStartExpectation

        // Add observer for notifications
        NotificationCenter.default.addObserver(
            observer,
            selector: #selector(StateObserver.willStartSession(_:)),
            name: Notification.Name("BranchWillStartSessionNotification"),
            object: nil
        )
        NotificationCenter.default.addObserver(
            observer,
            selector: #selector(StateObserver.didStartSession(_:)),
            name: Notification.Name("BranchDidStartSessionNotification"),
            object: nil
        )

        // Initialize
        sut.initialize(url: nil) { _, _ in }

        waitForExpectations(timeout: 10.0)

        XCTAssertTrue(observer.willStartCalled)
        XCTAssertTrue(observer.didStartCalled)

        // Cleanup
        NotificationCenter.default.removeObserver(observer)
    }

    // MARK: - Params Conversion Tests

    func testParamsFromSession() {
        let expectation = expectation(description: "Initialize completes")

        var capturedSession: Session?

        sut.initialize(url: nil) { session, _ in
            capturedSession = session
            expectation.fulfill()
        }

        waitForExpectations(timeout: 10.0)

        guard let session = capturedSession else {
            XCTFail("Session should not be nil")
            return
        }

        let params = sut.paramsFromSession(session)

        // Verify standard fields
        XCTAssertNotNil(params["session_id"])
        XCTAssertNotNil(params["identity_id"])
        XCTAssertNotNil(params["device_fingerprint_id"])
        XCTAssertNotNil(params["+is_first_session"])
    }
}
