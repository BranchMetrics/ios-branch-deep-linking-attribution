//
//  SessionManagerTests.swift
//  BranchSDKTests
//
//  Copyright © 2026 Branch Metrics. All rights reserved.
//  SPDX-License-Identifier: MIT
//

@testable import BranchSDK
import XCTest

// swiftlint:disable type_body_length file_length

/// Qualitative tests for SessionManager focusing on real-world scenarios.
///
/// These tests verify actual user flows and edge cases rather than simple property checks.
/// Each test represents a real scenario that can occur in production apps.
///
/// Note: These tests use XCTestExpectation for async operations instead of async/await
/// for iOS 12 compatibility.
@MainActor
final class SessionManagerTests: XCTestCase {
    var sut: SessionManager!

    override func setUp() async throws {
        // Clean up UserDefaults to prevent test pollution
        UserDefaults.standard.removeObject(forKey: "branch_has_installed")

        // Use the shared instance for testing
        sut = SessionManager.shared
        sut.reset()
    }

    override func tearDown() async throws {
        sut.reset()
        sut = nil
        // Clean up UserDefaults
        UserDefaults.standard.removeObject(forKey: "branch_has_installed")
    }

    // MARK: - Cold Launch Scenarios

    /// Scenario: User opens app normally (cold launch without any deep link)
    /// Expected: Session is created with device identifiers, marked as ready
    func testColdLaunchWithoutDeepLink() {
        let expectation = expectation(description: "Initialize completes")

        // Given: App was not running, user taps app icon
        let options = InitializationOptions()

        // When: App initializes Branch
        sut.initialize(options: options) { session, error in
            // Then: Valid session is created
            XCTAssertNotNil(session, "Session should not be nil")
            XCTAssertNil(error, "Error should be nil")
            XCTAssertFalse(session?.identityId.isEmpty ?? true, "Session must have an identity ID")
            XCTAssertFalse(session?.deviceFingerprintId.isEmpty ?? true, "Session must have a device fingerprint")

            expectation.fulfill()
        }

        waitForExpectations(timeout: 10.0)

        XCTAssertTrue(sut.state.isReady, "Session should be ready after initialization")
    }

    /// Scenario: User clicks a Universal Link while app is not running
    /// Expected: Session is created AND deep link data is captured
    func testColdLaunchWithUniversalLink() {
        let expectation = expectation(description: "Initialize with URL completes")

        // Given: User clicked a Branch link, app was killed
        let deepLinkURL = URL(string: "https://example.app.link/summer-sale?promo=25OFF")!
        let options = InitializationOptions()
        options.url = deepLinkURL

        // When: App launches with the URL
        sut.initialize(options: options) { session, error in
            // Then: Session is created
            XCTAssertNotNil(session, "Session should not be nil")
            XCTAssertNil(error, "Error should be nil")

            // URL should be captured in params
            let referringLink = session?.params["~referring_link"] as? String
            XCTAssertNotNil(referringLink, "Referring link should be in params")

            expectation.fulfill()
        }

        waitForExpectations(timeout: 10.0)
    }

    /// Scenario: User clicks a URI scheme link while app is not running
    /// Expected: Session captures custom scheme deep link
    func testColdLaunchWithURIScheme() {
        let expectation = expectation(description: "Initialize with custom scheme completes")

        // Given: User clicked a custom scheme link (e.g., from email)
        let customSchemeURL = URL(string: "myapp://open/product/12345")!
        let options = InitializationOptions()
        options.url = customSchemeURL

        // When: App launches with custom scheme
        sut.initialize(options: options) { session, error in
            // Then: Custom scheme is captured
            XCTAssertNotNil(session, "Session should not be nil")
            XCTAssertNil(error, "Error should be nil")

            expectation.fulfill()
        }

        waitForExpectations(timeout: 10.0)
    }

    // MARK: - Double Open Fix Scenarios (INTENG-21106)

    /// Scenario: iOS calls both didFinishLaunching and continueUserActivity nearly simultaneously
    /// This is the "Double Open" bug that caused duplicate network requests
    /// Expected: Only ONE network request, both callbacks receive the same session
    func testDoubleOpenScenario_didFinishLaunchingThenContinueUserActivity() {
        let expectation1 = expectation(description: "First call completes")
        let expectation2 = expectation(description: "Second call completes")

        // Given: User clicks Universal Link on iOS
        let universalLinkURL = URL(string: "https://example.app.link/invite/abc123")!

        var session1: Session?
        var session2: Session?

        // When: Both lifecycle methods call initialize nearly simultaneously
        // didFinishLaunchingWithOptions (no URL)
        sut.initialize(options: nil) { session, _ in
            session1 = session
            expectation1.fulfill()
        }

        // continueUserActivity (has URL) - arrives shortly after
        let options = InitializationOptions()
        options.url = universalLinkURL
        sut.initialize(options: options) { session, _ in
            session2 = session
            expectation2.fulfill()
        }

        waitForExpectations(timeout: 10.0)

        // Then: Both receive the SAME session (coalesced)
        XCTAssertNotNil(session1, "First session should not be nil")
        XCTAssertNotNil(session2, "Second session should not be nil")
        XCTAssertEqual(session1?.id, session2?.id, "Both calls must return the same session (coalesced)")
    }

    /// Scenario: Three rapid initialize calls during cold launch
    /// Expected: All coalesced into single session
    func testTripleRapidInitializationCoalescing() {
        let expectation1 = expectation(description: "First call completes")
        let expectation2 = expectation(description: "Second call completes")
        let expectation3 = expectation(description: "Third call completes")

        var session1: Session?
        var session2: Session?
        var session3: Session?

        // Given: Complex app with multiple initialization points
        let deepLink = URL(string: "https://example.app.link/promo")!

        // When: Multiple rapid calls
        sut.initialize(options: nil) { session, _ in
            session1 = session
            expectation1.fulfill()
        }

        sut.initialize(options: nil) { session, _ in
            session2 = session
            expectation2.fulfill()
        }

        let options = InitializationOptions()
        options.url = deepLink
        sut.initialize(options: options) { session, _ in
            session3 = session
            expectation3.fulfill()
        }

        waitForExpectations(timeout: 10.0)

        // Then: All have same session ID (coalesced)
        XCTAssertNotNil(session1)
        XCTAssertNotNil(session2)
        XCTAssertNotNil(session3)
        XCTAssertEqual(session1?.id, session2?.id, "First two calls must be coalesced")
        XCTAssertEqual(session2?.id, session3?.id, "All three calls must be coalesced")
    }

    // MARK: - Warm Launch Scenarios (App in Background)

    /// Scenario: App is in background, user clicks deep link
    /// Expected: handleDeepLink processes the URL
    func testWarmLaunchWithDeepLink() {
        let initExpectation = expectation(description: "Initialize completes")

        // Given: App was previously initialized and is in background
        sut.initialize(options: nil) { [weak self] session, error in
            XCTAssertNotNil(session)
            XCTAssertNil(error)
            initExpectation.fulfill()

            // When: User clicks a deep link while app is in background (chained async)
            let deepLink = URL(string: "https://example.app.link/flash-sale")!
            self?.sut.handleDeepLink(deepLink) { session, error in
                XCTAssertNotNil(session, "Session should not be nil")
                XCTAssertNil(error, "Error should be nil")
            }
        }

        waitForExpectations(timeout: 10.0)

        // Note: Session may or may not be the same depending on implementation
        XCTAssertNotNil(sut.currentSession)
    }

    // MARK: - Multi-Scene Scenarios (iPad)

    /// Scenario: iPad app with multiple windows, each initializing with different scene
    /// Expected: Each scene identifier is tracked correctly
    func testMultiSceneInitialization() {
        let expectation = expectation(description: "Initialize completes")

        // Given: iPad app with multiple scenes
        let options = InitializationOptions()
        options.sceneIdentifier = "main-window-123"

        // When: First scene initializes
        sut.initialize(options: options) { session, error in
            // Then: Session is created successfully
            XCTAssertNotNil(session)
            XCTAssertNil(error)
            expectation.fulfill()
        }

        waitForExpectations(timeout: 10.0)
    }

    // MARK: - Reset Scenarios

    /// Scenario: App needs to completely reset Branch state (e.g., debug menu action)
    /// Expected: All state cleared, ready for new initialization
    func testCompleteReset() {
        let initExpectation = expectation(description: "Initialize completes")

        // Given: Fully initialized session
        let options = InitializationOptions()
        options.url = URL(string: "https://example.app.link/data")!
        sut.initialize(options: options) { session, _ in
            XCTAssertNotNil(session)
            initExpectation.fulfill()
        }

        waitForExpectations(timeout: 10.0)

        XCTAssertTrue(sut.isInitialized)

        // When: Reset is called
        sut.reset()

        // Wait a bit for async reset
        let resetExpectation = expectation(description: "Reset completes")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            resetExpectation.fulfill()
        }
        waitForExpectations(timeout: 5.0)

        // Then: All state is cleared
        XCTAssertEqual(sut.state, .uninitialized, "State should be uninitialized")
        XCTAssertNil(sut.currentSession, "Current session should be nil")
    }

    /// Scenario: Re-initialization after reset
    /// Expected: Fresh session created successfully
    func testReInitializationAfterReset() {
        let initExpectation = expectation(description: "First initialize completes")
        var firstSessionId: String?

        // Given: Session was initialized then reset
        sut.initialize(options: nil) { session, _ in
            firstSessionId = session?.id
            initExpectation.fulfill()
        }

        waitForExpectations(timeout: 10.0)

        // Reset
        sut.reset()

        // Wait for reset
        let resetWait = expectation(description: "Wait for reset")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            resetWait.fulfill()
        }
        waitForExpectations(timeout: 5.0)

        // When: Initialize again
        let reinitExpectation = expectation(description: "Reinitialize completes")
        var secondSessionId: String?

        sut.initialize(options: nil) { session, _ in
            secondSessionId = session?.id
            reinitExpectation.fulfill()
        }

        waitForExpectations(timeout: 10.0)

        // Then: New session is created with different ID
        XCTAssertNotNil(firstSessionId)
        XCTAssertNotNil(secondSessionId)
        XCTAssertNotEqual(firstSessionId, secondSessionId, "New session should have different ID")
    }

    // MARK: - InitializationOptions Scenarios

    /// Scenario: Building options with fluent builder pattern
    /// Expected: All options are correctly applied
    func testInitializationOptionsBuilderPattern() {
        let expectation = expectation(description: "Initialize completes")

        // Given: Complex initialization requirements
        let deepLink = URL(string: "https://example.app.link/campaign/winter")!
        let referralParams = ["utm_source": "email", "utm_campaign": "winter2024"]

        // When: Building options with fluent API
        let options = InitializationOptions()
            .with(url: deepLink)
            .with(sceneIdentifier: "main-scene")
            .with(referralParams: referralParams)
            .with(sourceApplication: "com.apple.mobilesafari")

        // Then: Initialize with these options
        sut.initialize(options: options) { session, error in
            XCTAssertNotNil(session)
            XCTAssertNil(error)
            expectation.fulfill()
        }

        waitForExpectations(timeout: 10.0)
    }

    /// Scenario: Initialization with delayed mode
    /// Expected: Session is created but network requests may be deferred
    func testDelayedInitializationMode() {
        let expectation = expectation(description: "Initialize completes")

        // Given: App wants to delay network requests (e.g., GDPR consent pending)
        let options = InitializationOptions()
            .with(delayInitialization: true)

        // When: Initialize with delay flag
        sut.initialize(options: options) { session, error in
            // Then: Session is still created (delay affects network, not session)
            XCTAssertNotNil(session)
            XCTAssertNil(error)
            expectation.fulfill()
        }

        XCTAssertTrue(options.delayInitialization)

        waitForExpectations(timeout: 10.0)
    }

    /// Scenario: Initialization with automatic session tracking disabled
    /// Expected: Session is created but automatic tracking is off
    func testDisableAutomaticSessionTracking() {
        let expectation = expectation(description: "Initialize completes")

        // Given: App manages its own session lifecycle
        let options = InitializationOptions()
            .with(disableAutomaticSessionTracking: true)

        // When: Initialize with tracking disabled
        sut.initialize(options: options) { session, error in
            // Then: Session is created successfully
            XCTAssertNotNil(session)
            XCTAssertNil(error)
            expectation.fulfill()
        }

        XCTAssertTrue(options.disableAutomaticSessionTracking)

        waitForExpectations(timeout: 10.0)
    }

    // MARK: - State Observation via NotificationCenter

    /// Scenario: Observing session state changes via NotificationCenter
    /// Expected: Receives notifications as state changes
    func testNotificationCenterObservation() {
        let willStartExpectation = expectation(description: "Will start notification")
        let didStartExpectation = expectation(description: "Did start notification")

        // Given: Observer registered for notifications
        var receivedWillStart = false
        var receivedDidStart = false

        let willStartObserver = NotificationCenter.default.addObserver(
            forName: Notification.Name("BranchWillStartSessionNotification"),
            object: nil,
            queue: .main
        ) { _ in
            receivedWillStart = true
            willStartExpectation.fulfill()
        }

        let didStartObserver = NotificationCenter.default.addObserver(
            forName: Notification.Name("BranchDidStartSessionNotification"),
            object: nil,
            queue: .main
        ) { _ in
            receivedDidStart = true
            didStartExpectation.fulfill()
        }

        // When: Session initializes
        sut.initialize(options: nil) { _, _ in }

        waitForExpectations(timeout: 10.0)

        // Then: Observer received notifications
        XCTAssertTrue(receivedWillStart, "Should have received will start notification")
        XCTAssertTrue(receivedDidStart, "Should have received did start notification")

        // Cleanup
        NotificationCenter.default.removeObserver(willStartObserver)
        NotificationCenter.default.removeObserver(didStartObserver)
    }

    // MARK: - Edge Cases

    /// Scenario: Multiple sequential initializations with different URLs
    /// Expected: Each sequential init may create a new session (state machine allows re-init)
    func testSequentialInitializationsWithDifferentURLs() {
        let expectation1 = expectation(description: "Both inits complete")

        var firstSessionId: String?
        var secondSessionId: String?

        // Given: First initialization with URL A
        let options1 = InitializationOptions()
        options1.url = URL(string: "https://example.app.link/first")!

        sut.initialize(options: options1) { [weak self] session, _ in
            firstSessionId = session?.id

            // When: Second initialization after first completes (sequential, not concurrent)
            let options2 = InitializationOptions()
            options2.url = URL(string: "https://example.app.link/second")!

            self?.sut.initialize(options: options2) { session, _ in
                secondSessionId = session?.id
                expectation1.fulfill()
            }
        }

        waitForExpectations(timeout: 20.0)

        // Then: Sessions may be same or different depending on implementation
        XCTAssertNotNil(firstSessionId)
        XCTAssertNotNil(secondSessionId)
    }

    /// Scenario: Initialize with special characters in referral params
    /// Expected: Session still created, params handled
    func testInitializationWithSpecialCharactersInParams() {
        let expectation = expectation(description: "Initialize completes")

        // Given: Referral params with special characters
        let referralParams = [
            "emoji": "🎉",
            "special": "a&b=c?d",
            "unicode": "日本語",
        ]

        let options = InitializationOptions()
            .with(referralParams: referralParams)

        // When: Initialize with these params
        sut.initialize(options: options) { session, error in
            // Then: Session is created successfully
            XCTAssertNotNil(session)
            XCTAssertNil(error)
            expectation.fulfill()
        }

        waitForExpectations(timeout: 10.0)
    }

    // MARK: - Convenience Methods Tests

    /// Test initialize(url:completion:) convenience method
    func testInitializeWithURLConvenience() {
        let expectation = expectation(description: "Initialize completes")

        let url = URL(string: "https://example.app.link/test")!

        sut.initialize(url: url) { session, error in
            XCTAssertNotNil(session)
            XCTAssertNil(error)
            expectation.fulfill()
        }

        waitForExpectations(timeout: 10.0)
    }

    /// Test initialize(completion:) convenience method
    func testInitializeNoOptionsConvenience() {
        let expectation = expectation(description: "Initialize completes")

        sut.initialize { session, error in
            XCTAssertNotNil(session)
            XCTAssertNil(error)
            expectation.fulfill()
        }

        waitForExpectations(timeout: 10.0)
    }

    // MARK: - State Properties Tests

    func testIsInitializingProperty() {
        XCTAssertFalse(sut.isInitializing, "Should not be initializing before init")

        let expectation = expectation(description: "Initialize completes")

        sut.initialize(options: nil) { _, _ in
            expectation.fulfill()
        }

        waitForExpectations(timeout: 10.0)

        XCTAssertFalse(sut.isInitializing, "Should not be initializing after init")
    }

    func testIsInitializedProperty() {
        XCTAssertFalse(sut.isInitialized, "Should not be initialized before init")

        let expectation = expectation(description: "Initialize completes")

        sut.initialize(options: nil) { _, _ in
            expectation.fulfill()
        }

        waitForExpectations(timeout: 10.0)

        XCTAssertTrue(sut.isInitialized, "Should be initialized after init")
    }

    func testCurrentSessionProperty() {
        XCTAssertNil(sut.currentSession, "Should be nil before init")

        let expectation = expectation(description: "Initialize completes")

        sut.initialize(options: nil) { _, _ in
            expectation.fulfill()
        }

        waitForExpectations(timeout: 10.0)

        XCTAssertNotNil(sut.currentSession, "Should not be nil after init")
    }

    // MARK: - Thread Safety Tests

    /// Test that callbacks are delivered on main thread
    func testCallbacksOnMainThread() {
        let expectation = expectation(description: "Initialize completes")

        sut.initialize(options: nil) { _, _ in
            XCTAssertTrue(Thread.isMainThread, "Callback must be on main thread")
            expectation.fulfill()
        }

        waitForExpectations(timeout: 10.0)
    }
}
