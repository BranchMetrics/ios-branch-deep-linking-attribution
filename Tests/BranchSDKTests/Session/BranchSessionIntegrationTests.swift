//
//  BranchSessionIntegrationTests.swift
//  BranchSDKTests
//
//  Copyright © 2026 Branch Metrics. All rights reserved.
//  SPDX-License-Identifier: MIT
//

@testable import BranchSDK
import XCTest

/// Tests for BranchSessionIntegration helper class.
///
/// These tests verify the static integration methods used for
/// bridging between Objective-C and Swift session management.
@MainActor
final class BranchSessionIntegrationTests: XCTestCase {
    override func setUp() async throws {
        // Clean up UserDefaults to prevent test pollution
        UserDefaults.standard.removeObject(forKey: "branch_has_installed")

        // Reset coordinator state
        BranchSessionCoordinator.shared.reset()
    }

    override func tearDown() async throws {
        BranchSessionCoordinator.shared.reset()
        // Clean up UserDefaults
        UserDefaults.standard.removeObject(forKey: "branch_has_installed")
    }

    // MARK: - Feature Flags Tests

    func testFeatureFlagsDefaultValue() {
        // Default is true for modern session manager
        XCTAssertTrue(BranchSessionFeatureFlags.useModernSessionManager)
    }

    func testFeatureFlagsCanBeSet() {
        let originalValue = BranchSessionFeatureFlags.useModernSessionManager

        BranchSessionFeatureFlags.useModernSessionManager = false
        XCTAssertFalse(BranchSessionFeatureFlags.useModernSessionManager)

        BranchSessionFeatureFlags.useModernSessionManager = true
        XCTAssertTrue(BranchSessionFeatureFlags.useModernSessionManager)

        // Restore original
        BranchSessionFeatureFlags.useModernSessionManager = originalValue
    }

    func testFeatureFlagsThreadSafety() {
        let iterations = 100
        let expectation = expectation(description: "Thread safety test")
        expectation.expectedFulfillmentCount = iterations * 2

        // Concurrent reads and writes
        for _ in 0 ..< iterations {
            DispatchQueue.global().async {
                BranchSessionFeatureFlags.useModernSessionManager = true
                expectation.fulfill()
            }
            DispatchQueue.global().async {
                _ = BranchSessionFeatureFlags.useModernSessionManager
                expectation.fulfill()
            }
        }

        waitForExpectations(timeout: 10.0)
    }

    // MARK: - Static State Properties Tests

    func testIsInitializingInitiallyFalse() {
        XCTAssertFalse(BranchSessionIntegration.isInitializing)
    }

    func testIsInitializedInitiallyFalse() {
        XCTAssertFalse(BranchSessionIntegration.isInitialized)
    }

    func testCurrentSessionInitiallyNil() {
        XCTAssertNil(BranchSessionIntegration.currentSession)
    }

    // MARK: - Initialize Session Tests

    func testInitializeSessionWithoutURL() {
        let expectation = expectation(description: "Initialize completes")

        BranchSessionIntegration.initializeSession(sceneIdentifier: nil) { session, error in
            XCTAssertNotNil(session)
            XCTAssertNil(error)

            // Verify session properties
            XCTAssertFalse(session?.id.isEmpty ?? true)
            XCTAssertFalse(session?.identityId.isEmpty ?? true)
            XCTAssertFalse(session?.deviceFingerprintId.isEmpty ?? true)

            expectation.fulfill()
        }

        waitForExpectations(timeout: 10.0)
    }

    func testInitializeSessionWithSceneIdentifier() {
        let expectation = expectation(description: "Initialize completes")

        BranchSessionIntegration.initializeSession(sceneIdentifier: "test-scene-123") { session, error in
            XCTAssertNotNil(session)
            XCTAssertNil(error)
            expectation.fulfill()
        }

        waitForExpectations(timeout: 10.0)
    }

    // MARK: - Handle URL Tests

    func testHandleURLCompletesSuccessfully() {
        let expectation = expectation(description: "Handle URL completes")
        let testURL = URL(string: "https://test.app.link/deeplink123")!

        BranchSessionIntegration.handleURL(testURL, sceneIdentifier: nil) { session, error in
            XCTAssertNotNil(session)
            XCTAssertNil(error)

            // URL should be captured in params
            let referringLink = session?.params["~referring_link"] as? String
            XCTAssertNotNil(referringLink)

            expectation.fulfill()
        }

        waitForExpectations(timeout: 10.0)
    }

    func testHandleURLWithSceneIdentifier() {
        let expectation = expectation(description: "Handle URL completes")
        let testURL = URL(string: "https://test.app.link/deeplink456")!

        BranchSessionIntegration.handleURL(testURL, sceneIdentifier: "scene-abc") { session, error in
            XCTAssertNotNil(session)
            XCTAssertNil(error)
            expectation.fulfill()
        }

        waitForExpectations(timeout: 10.0)
    }

    // MARK: - Handle User Activity Tests

    func testHandleUserActivityWithValidBrowsingActivity() {
        let expectation = expectation(description: "Handle user activity completes")

        let userActivity = NSUserActivity(activityType: NSUserActivityTypeBrowsingWeb)
        userActivity.webpageURL = URL(string: "https://test.app.link/universal123")

        BranchSessionIntegration.handleUserActivity(userActivity, sceneIdentifier: nil) { session, error in
            XCTAssertNotNil(session)
            XCTAssertNil(error)
            expectation.fulfill()
        }

        waitForExpectations(timeout: 10.0)
    }

    func testHandleUserActivityWithInvalidActivityType() {
        let expectation = expectation(description: "Handle user activity fails")

        let userActivity = NSUserActivity(activityType: "com.test.invalid")
        userActivity.webpageURL = URL(string: "https://test.app.link/invalid")

        BranchSessionIntegration.handleUserActivity(userActivity, sceneIdentifier: nil) { session, error in
            XCTAssertNil(session)
            XCTAssertNotNil(error)

            // Should be an NSError with Branch domain
            if let nsError = error {
                XCTAssertEqual(nsError.domain, "io.branch.sdk")
            }

            expectation.fulfill()
        }

        waitForExpectations(timeout: 10.0)
    }

    func testHandleUserActivityWithNoURL() {
        let expectation = expectation(description: "Handle user activity fails")

        let userActivity = NSUserActivity(activityType: NSUserActivityTypeBrowsingWeb)
        // No webpageURL set

        BranchSessionIntegration.handleUserActivity(userActivity, sceneIdentifier: nil) { session, error in
            XCTAssertNil(session)
            XCTAssertNotNil(error)

            if let nsError = error {
                XCTAssertEqual(nsError.domain, "io.branch.sdk")
            }

            expectation.fulfill()
        }

        waitForExpectations(timeout: 10.0)
    }

    func testHandleUserActivityWithSpotlightActivity() {
        let expectation = expectation(description: "Handle user activity fails")

        // Spotlight activities should also fail (not NSUserActivityTypeBrowsingWeb)
        let userActivity = NSUserActivity(activityType: "com.apple.corespotlightitem")
        userActivity.webpageURL = URL(string: "https://test.app.link/spotlight")

        BranchSessionIntegration.handleUserActivity(userActivity, sceneIdentifier: nil) { session, error in
            XCTAssertNil(session)
            XCTAssertNotNil(error)

            if let nsError = error {
                XCTAssertEqual(nsError.domain, "io.branch.sdk")
            }

            expectation.fulfill()
        }

        waitForExpectations(timeout: 10.0)
    }

    // MARK: - Session Parameters Conversion Tests

    func testConvertSessionToParams() {
        let expectation = expectation(description: "Initialize completes")

        BranchSessionIntegration.initializeSession(sceneIdentifier: nil) { session, _ in
            XCTAssertNotNil(session)

            if let session = session {
                let params = BranchSessionIntegration.convertSessionToParams(session)

                // Required fields
                XCTAssertNotNil(params["session_id"] as? String)
                XCTAssertNotNil(params["identity_id"] as? String)
                XCTAssertNotNil(params["device_fingerprint_id"] as? String)
                XCTAssertNotNil(params["+is_first_session"] as? Bool)
            }

            expectation.fulfill()
        }

        waitForExpectations(timeout: 10.0)
    }

    // MARK: - State Synchronization Tests

    func testIsInitializedUpdatesAfterInitialization() {
        XCTAssertFalse(BranchSessionIntegration.isInitialized)

        let initExpectation = expectation(description: "Initialize completes")

        BranchSessionIntegration.initializeSession(sceneIdentifier: nil) { _, _ in
            initExpectation.fulfill()
        }

        waitForExpectations(timeout: 10.0)

        XCTAssertTrue(BranchSessionIntegration.isInitialized)
    }

    func testCurrentSessionUpdatesAfterInitialization() {
        XCTAssertNil(BranchSessionIntegration.currentSession)

        let expectation = expectation(description: "Initialize completes")

        BranchSessionIntegration.initializeSession(sceneIdentifier: nil) { _, _ in
            expectation.fulfill()
        }

        waitForExpectations(timeout: 10.0)

        XCTAssertNotNil(BranchSessionIntegration.currentSession)
    }

    // MARK: - Concurrent Calls Tests (Task Coalescing)

    func testConcurrentHandleURLCallsAreCoalesced() {
        let expectation1 = expectation(description: "First call completes")
        let expectation2 = expectation(description: "Second call completes")

        let url1 = URL(string: "https://test.app.link/first")!
        let url2 = URL(string: "https://test.app.link/second")!

        var session1: Session?
        var session2: Session?

        // Start both calls nearly simultaneously
        BranchSessionIntegration.handleURL(url1, sceneIdentifier: nil) { session, _ in
            session1 = session
            expectation1.fulfill()
        }

        BranchSessionIntegration.handleURL(url2, sceneIdentifier: nil) { session, _ in
            session2 = session
            expectation2.fulfill()
        }

        waitForExpectations(timeout: 10.0)

        // Both should complete with valid sessions
        XCTAssertNotNil(session1)
        XCTAssertNotNil(session2)

        // Session IDs should be the same (coalesced)
        XCTAssertEqual(session1?.id, session2?.id, "Concurrent calls should be coalesced to same session")
    }

    func testTripleConcurrentInitializeCalls() {
        let expectation1 = expectation(description: "First call completes")
        let expectation2 = expectation(description: "Second call completes")
        let expectation3 = expectation(description: "Third call completes")

        var session1: Session?
        var session2: Session?
        var session3: Session?

        BranchSessionIntegration.initializeSession(sceneIdentifier: nil) { session, _ in
            session1 = session
            expectation1.fulfill()
        }

        BranchSessionIntegration.initializeSession(sceneIdentifier: "scene-2") { session, _ in
            session2 = session
            expectation2.fulfill()
        }

        BranchSessionIntegration.initializeSession(sceneIdentifier: "scene-3") { session, _ in
            session3 = session
            expectation3.fulfill()
        }

        waitForExpectations(timeout: 10.0)

        // All should complete with valid sessions
        XCTAssertNotNil(session1)
        XCTAssertNotNil(session2)
        XCTAssertNotNil(session3)

        // All should be coalesced
        XCTAssertEqual(session1?.id, session2?.id)
        XCTAssertEqual(session2?.id, session3?.id)
    }

    // MARK: - Multiple Sequential Initializations

    func testMultipleSequentialInitializations() {
        // First initialization
        let expectation1 = expectation(description: "First init completes")
        BranchSessionIntegration.initializeSession(sceneIdentifier: nil) { session, error in
            XCTAssertNotNil(session)
            XCTAssertNil(error)
            expectation1.fulfill()
        }
        waitForExpectations(timeout: 10.0)

        // Reset
        BranchSessionCoordinator.shared.reset()

        // Wait for reset
        let resetExpectation = expectation(description: "Reset completes")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            resetExpectation.fulfill()
        }
        waitForExpectations(timeout: 5.0)

        // Second initialization
        let expectation2 = expectation(description: "Second init completes")
        BranchSessionIntegration.initializeSession(sceneIdentifier: "scene-2") { session, error in
            XCTAssertNotNil(session)
            XCTAssertNil(error)
            expectation2.fulfill()
        }
        waitForExpectations(timeout: 10.0)
    }

    // MARK: - Thread Safety Tests

    func testCallbacksOnMainThread() {
        let expectation = expectation(description: "Initialize completes")

        BranchSessionIntegration.initializeSession(sceneIdentifier: nil) { _, _ in
            XCTAssertTrue(Thread.isMainThread, "Callback must be on main thread")
            expectation.fulfill()
        }

        waitForExpectations(timeout: 10.0)
    }

    func testErrorCallbacksOnMainThread() {
        let expectation = expectation(description: "Error callback completes")

        let userActivity = NSUserActivity(activityType: "com.invalid.activity")

        BranchSessionIntegration.handleUserActivity(userActivity, sceneIdentifier: nil) { _, _ in
            XCTAssertTrue(Thread.isMainThread, "Error callback must be on main thread")
            expectation.fulfill()
        }

        waitForExpectations(timeout: 10.0)
    }

    // MARK: - Feature Flags Edge Cases

    func testFeatureFlagsToggle() {
        let original = BranchSessionFeatureFlags.useModernSessionManager

        // Toggle multiple times
        BranchSessionFeatureFlags.useModernSessionManager = true
        XCTAssertTrue(BranchSessionFeatureFlags.useModernSessionManager)

        BranchSessionFeatureFlags.useModernSessionManager = false
        XCTAssertFalse(BranchSessionFeatureFlags.useModernSessionManager)

        BranchSessionFeatureFlags.useModernSessionManager = true
        XCTAssertTrue(BranchSessionFeatureFlags.useModernSessionManager)

        // Restore
        BranchSessionFeatureFlags.useModernSessionManager = original
    }

    // MARK: - First Session Flag Tests

    func testFirstSessionFlagInParams() {
        let expectation = expectation(description: "Initialize completes")

        BranchSessionIntegration.initializeSession(sceneIdentifier: nil) { session, _ in
            XCTAssertNotNil(session)

            // isFirstSession should be a valid boolean
            let isFirst = session?.isFirstSession
            XCTAssertNotNil(isFirst)

            expectation.fulfill()
        }

        waitForExpectations(timeout: 10.0)
    }

    // MARK: - Device Fingerprint Tests

    func testDeviceFingerprintInParams() {
        let expectation = expectation(description: "Initialize completes")

        BranchSessionIntegration.initializeSession(sceneIdentifier: nil) { session, _ in
            XCTAssertNotNil(session)

            let fingerprintId = session?.deviceFingerprintId
            XCTAssertNotNil(fingerprintId)
            XCTAssertFalse(fingerprintId?.isEmpty ?? true)

            expectation.fulfill()
        }

        waitForExpectations(timeout: 10.0)
    }
}
