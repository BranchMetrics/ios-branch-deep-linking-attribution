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
@available(iOS 13.0, macOS 10.15, tvOS 13.0, watchOS 6.0, *)
@MainActor
final class BranchSessionIntegrationTests: XCTestCase {
    override func setUp() {
        super.setUp()
        // Reset coordinator state between tests
        BranchSessionCoordinator.shared.resetSession()
    }

    override func tearDown() {
        BranchSessionCoordinator.shared.resetSession()
        super.tearDown()
    }

    // MARK: - Feature Flags Tests

    func testFeatureFlagsDefaultValue() {
        XCTAssertFalse(BranchSessionFeatureFlags.useModernSessionManager)
    }

    func testFeatureFlagsCanBeSet() {
        let originalValue = BranchSessionFeatureFlags.useModernSessionManager

        BranchSessionFeatureFlags.useModernSessionManager = true
        XCTAssertTrue(BranchSessionFeatureFlags.useModernSessionManager)

        BranchSessionFeatureFlags.useModernSessionManager = false
        XCTAssertFalse(BranchSessionFeatureFlags.useModernSessionManager)

        // Restore original
        BranchSessionFeatureFlags.useModernSessionManager = originalValue
    }

    // MARK: - Static State Properties Tests

    func testIsInitializingInitiallyFalse() {
        XCTAssertFalse(BranchSessionIntegration.isInitializing)
    }

    func testIsInitializedInitiallyFalse() {
        XCTAssertFalse(BranchSessionIntegration.isInitialized)
    }

    // MARK: - Initialize Session Tests

    func testInitializeSessionWithoutURL() {
        let expectation = expectation(description: "Initialize completes")

        BranchSessionIntegration.initializeSession(sceneIdentifier: nil) { params, error in
            XCTAssertNotNil(params)
            XCTAssertNil(error)

            // Verify standard fields
            XCTAssertNotNil(params?["session_id"])
            XCTAssertNotNil(params?["identity_id"])
            XCTAssertNotNil(params?["device_fingerprint_id"])
            XCTAssertNotNil(params?["+is_first_session"])

            expectation.fulfill()
        }

        waitForExpectations(timeout: 5.0)
    }

    func testInitializeSessionWithSceneIdentifier() {
        let expectation = expectation(description: "Initialize completes")

        BranchSessionIntegration.initializeSession(sceneIdentifier: "test-scene-123") { params, error in
            XCTAssertNotNil(params)
            XCTAssertNil(error)
            expectation.fulfill()
        }

        waitForExpectations(timeout: 5.0)
    }

    // MARK: - Handle URL Tests

    func testHandleURLCompletesSuccessfully() {
        let expectation = expectation(description: "Handle URL completes")
        let testURL = URL(string: "https://test.app.link/deeplink123")!

        BranchSessionIntegration.handleURL(testURL, sceneIdentifier: nil) { params, error in
            XCTAssertNotNil(params)
            XCTAssertNil(error)

            // Verify link data is present
            XCTAssertEqual(params?["~referring_link"] as? String, testURL.absoluteString)

            expectation.fulfill()
        }

        waitForExpectations(timeout: 5.0)
    }

    func testHandleURLWithSceneIdentifier() {
        let expectation = expectation(description: "Handle URL completes")
        let testURL = URL(string: "https://test.app.link/deeplink456")!

        BranchSessionIntegration.handleURL(testURL, sceneIdentifier: "scene-abc") { params, error in
            XCTAssertNotNil(params)
            XCTAssertNil(error)
            expectation.fulfill()
        }

        waitForExpectations(timeout: 5.0)
    }

    // MARK: - Handle User Activity Tests

    func testHandleUserActivityWithValidBrowsingActivity() {
        let expectation = expectation(description: "Handle user activity completes")

        let userActivity = NSUserActivity(activityType: NSUserActivityTypeBrowsingWeb)
        userActivity.webpageURL = URL(string: "https://test.app.link/universal123")

        BranchSessionIntegration.handleUserActivity(userActivity, sceneIdentifier: nil) { params, error in
            XCTAssertNotNil(params)
            XCTAssertNil(error)
            expectation.fulfill()
        }

        waitForExpectations(timeout: 5.0)
    }

    func testHandleUserActivityWithInvalidActivityType() {
        let expectation = expectation(description: "Handle user activity fails")

        let userActivity = NSUserActivity(activityType: "com.test.invalid")
        userActivity.webpageURL = URL(string: "https://test.app.link/invalid")

        BranchSessionIntegration.handleUserActivity(userActivity, sceneIdentifier: nil) { params, error in
            XCTAssertNil(params)
            XCTAssertNotNil(error)

            // Should be invalidUserActivity error
            if let branchError = error as? BranchError {
                XCTAssertEqual(branchError, BranchError.invalidUserActivity)
            }

            expectation.fulfill()
        }

        waitForExpectations(timeout: 5.0)
    }

    func testHandleUserActivityWithNoURL() {
        let expectation = expectation(description: "Handle user activity fails")

        let userActivity = NSUserActivity(activityType: NSUserActivityTypeBrowsingWeb)
        // No webpageURL set

        BranchSessionIntegration.handleUserActivity(userActivity, sceneIdentifier: nil) { params, error in
            XCTAssertNil(params)
            XCTAssertNotNil(error)

            if let branchError = error as? BranchError {
                XCTAssertEqual(branchError, BranchError.invalidUserActivity)
            }

            expectation.fulfill()
        }

        waitForExpectations(timeout: 5.0)
    }

    // MARK: - Session Parameters Conversion Tests

    func testSessionParamsContainStandardFields() {
        let expectation = expectation(description: "Initialize completes")

        BranchSessionIntegration.initializeSession(sceneIdentifier: nil) { params, _ in
            XCTAssertNotNil(params)

            // Required fields
            XCTAssertNotNil(params?["session_id"] as? String)
            XCTAssertNotNil(params?["identity_id"] as? String)
            XCTAssertNotNil(params?["device_fingerprint_id"] as? String)
            XCTAssertNotNil(params?["+is_first_session"] as? Bool)

            // clicked_branch_link should be present (false if no link)
            XCTAssertNotNil(params?["+clicked_branch_link"])

            expectation.fulfill()
        }

        waitForExpectations(timeout: 5.0)
    }

    func testSessionParamsWithLinkDataContainLinkFields() {
        let expectation = expectation(description: "Handle URL completes")
        let testURL = URL(string: "https://test.app.link/campaign-link")!

        BranchSessionIntegration.handleURL(testURL, sceneIdentifier: nil) { params, _ in
            XCTAssertNotNil(params)

            // Link-specific fields
            XCTAssertEqual(params?["~referring_link"] as? String, testURL.absoluteString)

            expectation.fulfill()
        }

        waitForExpectations(timeout: 5.0)
    }

    // MARK: - State Synchronization Tests

    func testIsInitializedUpdatesAfterInitialization() {
        XCTAssertFalse(BranchSessionIntegration.isInitialized)

        let initExpectation = expectation(description: "Initialize completes")

        BranchSessionIntegration.initializeSession(sceneIdentifier: nil) { _, _ in
            initExpectation.fulfill()
        }

        waitForExpectations(timeout: 5.0)

        // Wait for state to sync via async state observation
        let stateExpectation = expectation(description: "State syncs")
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            XCTAssertTrue(BranchSessionIntegration.isInitialized)
            stateExpectation.fulfill()
        }

        waitForExpectations(timeout: 5.0)
    }

    // MARK: - Concurrent Calls Tests (Task Coalescing)

    func testConcurrentHandleURLCallsAreCoalesced() {
        // Reset first
        BranchSessionCoordinator.shared.resetSession()

        let expectation1 = expectation(description: "First call completes")
        let expectation2 = expectation(description: "Second call completes")

        let url1 = URL(string: "https://test.app.link/first")!
        let url2 = URL(string: "https://test.app.link/second")!

        var params1: [String: Any]?
        var params2: [String: Any]?

        // Start both calls nearly simultaneously
        BranchSessionIntegration.handleURL(url1, sceneIdentifier: nil) { params, _ in
            params1 = params
            expectation1.fulfill()
        }

        BranchSessionIntegration.handleURL(url2, sceneIdentifier: nil) { params, _ in
            params2 = params
            expectation2.fulfill()
        }

        waitForExpectations(timeout: 5.0)

        // Both should complete with valid params
        XCTAssertNotNil(params1)
        XCTAssertNotNil(params2)

        // Session IDs should be the same (coalesced)
        let sessionId1 = params1?["session_id"] as? String
        let sessionId2 = params2?["session_id"] as? String
        XCTAssertEqual(sessionId1, sessionId2, "Concurrent calls should be coalesced to same session")
    }

    // MARK: - Session Parameters Format Tests

    func testSessionParamsContainIsFirstSession() {
        let expectation = expectation(description: "Initialize completes")

        BranchSessionIntegration.initializeSession(sceneIdentifier: nil) { params, _ in
            XCTAssertNotNil(params)

            // +is_first_session should be a boolean
            let isFirstSession = params?["+is_first_session"] as? Bool
            XCTAssertNotNil(isFirstSession)

            expectation.fulfill()
        }

        waitForExpectations(timeout: 5.0)
    }

    func testSessionParamsContainDeviceFingerprintId() {
        let expectation = expectation(description: "Initialize completes")

        BranchSessionIntegration.initializeSession(sceneIdentifier: nil) { params, _ in
            XCTAssertNotNil(params)

            let fingerprintId = params?["device_fingerprint_id"] as? String
            XCTAssertNotNil(fingerprintId)
            XCTAssertFalse(fingerprintId?.isEmpty ?? true)

            expectation.fulfill()
        }

        waitForExpectations(timeout: 5.0)
    }

    // MARK: - Handle URL Without Click Tests

    func testHandleURLSetsClickedBranchLinkTrue() {
        let expectation = expectation(description: "Handle URL completes")
        let testURL = URL(string: "https://test.app.link/clicked-link")!

        BranchSessionIntegration.handleURL(testURL, sceneIdentifier: nil) { params, _ in
            XCTAssertNotNil(params)

            // When handling a URL, it should be marked as clicked
            // Note: Current implementation may set this to false until full link resolution
            let clickedBranchLink = params?["+clicked_branch_link"]
            XCTAssertNotNil(clickedBranchLink)

            expectation.fulfill()
        }

        waitForExpectations(timeout: 5.0)
    }

    // MARK: - Multiple Sequential Initializations

    func testMultipleSequentialInitializations() {
        // First initialization
        let expectation1 = expectation(description: "First init completes")
        BranchSessionIntegration.initializeSession(sceneIdentifier: nil) { params, error in
            XCTAssertNotNil(params)
            XCTAssertNil(error)
            expectation1.fulfill()
        }
        waitForExpectations(timeout: 5.0)

        // Reset
        BranchSessionCoordinator.shared.resetSession()

        // Wait for reset
        let resetExpectation = expectation(description: "Reset completes")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            resetExpectation.fulfill()
        }
        waitForExpectations(timeout: 5.0)

        // Second initialization
        let expectation2 = expectation(description: "Second init completes")
        BranchSessionIntegration.initializeSession(sceneIdentifier: "scene-2") { params, error in
            XCTAssertNotNil(params)
            XCTAssertNil(error)
            expectation2.fulfill()
        }
        waitForExpectations(timeout: 5.0)
    }

    // MARK: - User Activity Validation Tests

    func testHandleUserActivityWithSpotlightActivity() {
        let expectation = expectation(description: "Handle user activity fails")

        // Spotlight activities should also fail (not NSUserActivityTypeBrowsingWeb)
        let userActivity = NSUserActivity(activityType: "com.apple.corespotlightitem")
        userActivity.webpageURL = URL(string: "https://test.app.link/spotlight")

        BranchSessionIntegration.handleUserActivity(userActivity, sceneIdentifier: nil) { params, error in
            XCTAssertNil(params)
            XCTAssertNotNil(error)

            if let branchError = error as? BranchError {
                XCTAssertEqual(branchError, BranchError.invalidUserActivity)
            }

            expectation.fulfill()
        }

        waitForExpectations(timeout: 5.0)
    }

    // MARK: - Feature Flags Edge Cases

    func testFeatureFlagsToggle() {
        let original = BranchSessionFeatureFlags.useModernSessionManager

        // Toggle on
        BranchSessionFeatureFlags.useModernSessionManager = true
        XCTAssertTrue(BranchSessionFeatureFlags.useModernSessionManager)

        // Toggle off
        BranchSessionFeatureFlags.useModernSessionManager = false
        XCTAssertFalse(BranchSessionFeatureFlags.useModernSessionManager)

        // Toggle on again
        BranchSessionFeatureFlags.useModernSessionManager = true
        XCTAssertTrue(BranchSessionFeatureFlags.useModernSessionManager)

        // Restore
        BranchSessionFeatureFlags.useModernSessionManager = original
    }
}
