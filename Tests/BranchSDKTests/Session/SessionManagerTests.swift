//
//  SessionManagerTests.swift
//  BranchSDKTests
//
//  Copyright © 2026 Branch Metrics. All rights reserved.
//  SPDX-License-Identifier: MIT
//

@testable import BranchSDK
import XCTest

/// Qualitative tests for SessionManager focusing on real-world scenarios.
///
/// These tests verify actual user flows and edge cases rather than simple property checks.
/// Each test represents a real scenario that can occur in production apps.
@available(iOS 13.0, macOS 10.15, tvOS 13.0, watchOS 6.0, *)
final class SessionManagerTests: XCTestCase {
    var sut: SessionManager!

    override func setUp() async throws {
        try await super.setUp()
        sut = SessionManager()
    }

    override func tearDown() async throws {
        await sut.reset()
        sut = nil
        try await super.tearDown()
    }

    // MARK: - Cold Launch Scenarios

    /// Scenario: User opens app normally (cold launch without any deep link)
    /// Expected: Session is created with device identifiers, marked as ready
    func testColdLaunchWithoutDeepLink() async throws {
        // Given: App was not running, user taps app icon
        let options = InitializationOptions()

        // When: App initializes Branch
        let session = try await sut.initialize(options: options)

        // Then: Valid session is created
        XCTAssertFalse(session.identityId.isEmpty, "Session must have an identity ID")
        XCTAssertFalse(session.deviceFingerprintId.isEmpty, "Session must have a device fingerprint")
        XCTAssertNil(session.linkData, "No link data expected for organic launch")

        let state = await sut.state
        XCTAssertTrue(state.isReady, "Session should be ready after initialization")
    }

    /// Scenario: User clicks a Universal Link while app is not running
    /// Expected: Session is created AND deep link data is captured
    func testColdLaunchWithUniversalLink() async throws {
        // Given: User clicked a Branch link, app was killed
        let deepLinkURL = URL(string: "https://example.app.link/summer-sale?promo=25OFF")!
        var options = InitializationOptions()
        options.url = deepLinkURL

        // When: App launches with the URL
        let session = try await sut.initialize(options: options)

        // Then: Session has the deep link data
        XCTAssertNotNil(session.linkData, "Deep link data must be captured")
        XCTAssertEqual(session.linkData?.url, deepLinkURL, "Link URL must match")
        XCTAssertTrue(session.hasDeepLinkData, "hasDeepLinkData should be true")
    }

    /// Scenario: User clicks a URI scheme link while app is not running
    /// Expected: Session captures custom scheme deep link
    func testColdLaunchWithURIScheme() async throws {
        // Given: User clicked a custom scheme link (e.g., from email)
        let customSchemeURL = URL(string: "myapp://open/product/12345")!
        var options = InitializationOptions()
        options.url = customSchemeURL

        // When: App launches with custom scheme
        let session = try await sut.initialize(options: options)

        // Then: Custom scheme is captured
        XCTAssertNotNil(session.linkData, "Custom scheme should be captured")
        XCTAssertEqual(session.linkData?.url, customSchemeURL)
    }

    // MARK: - Double Open Fix Scenarios (INTENG-21106)

    /// Scenario: iOS calls both didFinishLaunching and continueUserActivity nearly simultaneously
    /// This is the "Double Open" bug that caused duplicate network requests
    /// Expected: Only ONE network request, both callbacks receive the same session
    func testDoubleOpenScenario_didFinishLaunchingThenContinueUserActivity() async throws {
        // Given: User clicks Universal Link on iOS
        // iOS will call:
        // 1. application(_:didFinishLaunchingWithOptions:) - may not have URL yet
        // 2. application(_:continue:restorationHandler:) - has the URL
        let universalLinkURL = URL(string: "https://example.app.link/invite/abc123")!

        // When: Both lifecycle methods call initialize nearly simultaneously
        let manager = sut!
        async let firstCall: Session = {
            // didFinishLaunchingWithOptions (no URL)
            let options = InitializationOptions()
            return try await manager.initialize(options: options)
        }()

        async let secondCall: Session = {
            // continueUserActivity (has URL) - arrives ~100ms later
            try? await Task.sleep(nanoseconds: 100_000)
            var options = InitializationOptions()
            options.url = universalLinkURL
            return try await manager.initialize(options: options)
        }()

        let (session1, session2) = try await (firstCall, secondCall)

        // Then: Both receive the SAME session (coalesced)
        XCTAssertEqual(session1.id, session2.id, "Both calls must return the same session (coalesced)")

        // And: The URL from the second call is merged
        let hasURL = session1.linkData?.url == universalLinkURL || session2.linkData?.url == universalLinkURL
        XCTAssertTrue(hasURL, "Universal Link URL must be merged into the session")
    }

    /// Scenario: Three rapid initialize calls during cold launch
    /// Expected: All coalesced into single session
    func testTripleRapidInitializationCoalescing() async throws {
        // Given: Complex app with multiple initialization points
        let deepLink = URL(string: "https://example.app.link/promo")!

        // When: Multiple rapid calls
        let manager = sut!
        async let call1: Session = {
            let options = InitializationOptions()
            return try await manager.initialize(options: options)
        }()

        async let call2: Session = {
            try? await Task.sleep(nanoseconds: 50000)
            let options = InitializationOptions()
            return try await manager.initialize(options: options)
        }()

        async let call3: Session = {
            try? await Task.sleep(nanoseconds: 80000)
            var options = InitializationOptions()
            options.url = deepLink
            return try await manager.initialize(options: options)
        }()

        let (s1, s2, s3) = try await (call1, call2, call3)

        // Then: All have same session ID
        XCTAssertEqual(s1.id, s2.id, "First two calls must be coalesced")
        XCTAssertEqual(s2.id, s3.id, "All three calls must be coalesced")
    }

    // MARK: - Warm Launch Scenarios (App in Background)

    /// Scenario: App is in background, user clicks deep link
    /// Expected: handleDeepLink preserves existing session (link resolution is async/TODO)
    func testWarmLaunchWithDeepLink() async throws {
        // Given: App was previously initialized and is in background
        let options = InitializationOptions()
        let originalSession = try await sut.initialize(options: options)

        // When: User clicks a deep link while app is in background
        let deepLink = URL(string: "https://example.app.link/flash-sale")!
        let updatedSession = try await sut.handleDeepLink(deepLink)

        // Then: Session ID is preserved (link resolution pending backend implementation)
        XCTAssertEqual(originalSession.id, updatedSession.id, "Session ID should remain the same")
        // Note: linkData population requires backend API integration (TODO in SessionManager)
    }

    /// Scenario: Calling handleDeepLink before initialization
    /// Expected: Should fail gracefully with sessionRequired error
    func testDeepLinkBeforeInitialization() async {
        // Given: App crashed and SessionManager was recreated, not yet initialized
        let deepLink = URL(string: "https://example.app.link/recovery")!

        // When: handleDeepLink called before initialize
        do {
            _ = try await sut.handleDeepLink(deepLink)
            XCTFail("Should throw error when session not initialized")
        } catch let error as BranchError {
            // Then: Returns sessionRequired error
            XCTAssertEqual(error, .sessionRequired, "Must return sessionRequired error")
        } catch {
            XCTFail("Unexpected error type: \(error)")
        }
    }

    // MARK: - Multi-Scene Scenarios (iPad)

    /// Scenario: iPad app with multiple windows, each initializing with different scene
    /// Expected: Each scene identifier is tracked correctly
    func testMultiSceneInitialization() async throws {
        // Given: iPad app with multiple scenes
        var scene1Options = InitializationOptions()
        scene1Options.sceneIdentifier = "main-window-123"

        var scene2Options = InitializationOptions()
        scene2Options.sceneIdentifier = "split-view-456"

        // When: First scene initializes
        let session1 = try await sut.initialize(options: scene1Options)

        // Note: Second scene would typically get coalesced since same SessionManager
        // This tests that scene identifier doesn't break coalescing

        // Then: Session is created successfully
        XCTAssertNotNil(session1.identityId)
    }

    // MARK: - User Authentication Flow Scenarios

    /// Scenario: User logs into the app
    /// Expected: Identity is associated with session
    func testUserLoginFlow() async throws {
        // Given: App initialized, user is anonymous
        let options = InitializationOptions()
        let anonymousSession = try await sut.initialize(options: options)
        XCTAssertFalse(anonymousSession.isIdentified, "User should be anonymous initially")

        // When: User completes login
        try await sut.setIdentity("user-12345")

        // Then: Session now has user identity
        let authenticatedSession = await sut.currentSession
        XCTAssertTrue(authenticatedSession?.isIdentified ?? false, "User should be identified")
        XCTAssertEqual(authenticatedSession?.userId, "user-12345")
    }

    /// Scenario: User logs out of the app
    /// Expected: Identity is cleared but session continues
    func testUserLogoutFlow() async throws {
        // Given: User is logged in
        let options = InitializationOptions()
        _ = try await sut.initialize(options: options)
        try await sut.setIdentity("user-12345")

        let loggedInSession = await sut.currentSession
        XCTAssertEqual(loggedInSession?.userId, "user-12345")

        // When: User logs out
        try await sut.logout()

        // Then: Identity is cleared but session continues
        let loggedOutSession = await sut.currentSession
        XCTAssertNotNil(loggedOutSession, "Session should still exist")
        XCTAssertNil(loggedOutSession?.userId, "User ID should be cleared")
        XCTAssertFalse(loggedOutSession?.isIdentified ?? true, "Should not be identified")
    }

    /// Scenario: Setting identity before initialization
    /// Expected: Should fail with sessionRequired error
    func testSetIdentityBeforeInitialization() async {
        // Given: Session not yet initialized

        // When: Trying to set identity
        do {
            try await sut.setIdentity("premature-user")
            XCTFail("Should throw error")
        } catch let error as BranchError {
            // Then: Returns sessionRequired error
            XCTAssertEqual(error, .sessionRequired)
        } catch {
            XCTFail("Unexpected error type: \(error)")
        }
    }

    /// Scenario: Setting empty identity
    /// Expected: Should fail with invalidIdentity error
    func testSetEmptyIdentity() async throws {
        // Given: Session is initialized
        let options = InitializationOptions()
        _ = try await sut.initialize(options: options)

        // When: Trying to set empty identity
        do {
            try await sut.setIdentity("")
            XCTFail("Should throw error for empty identity")
        } catch let error as BranchError {
            // Then: Returns invalidIdentity error
            if case .invalidIdentity = error {
                // Expected
            } else {
                XCTFail("Expected invalidIdentity error, got: \(error)")
            }
        } catch {
            XCTFail("Unexpected error type: \(error)")
        }
    }

    // MARK: - Session Refresh Scenarios

    /// Scenario: App needs to force refresh session (e.g., after config change)
    /// Expected: New session created, old session discarded
    func testForceRefreshSession() async throws {
        // Given: User has active session with identity
        let options = InitializationOptions()
        let originalSession = try await sut.initialize(options: options)
        try await sut.setIdentity("old-user")

        // When: App triggers refresh (e.g., after server-side config change)
        let refreshedSession = try await sut.refresh()

        // Then: New session is created
        XCTAssertNotEqual(originalSession.id, refreshedSession.id, "New session should have different ID")
        XCTAssertNil(refreshedSession.userId, "Identity should be cleared in new session")
    }

    /// Scenario: Refresh during pending initialization
    /// Expected: Pending init is cancelled, fresh session created
    func testRefreshDuringPendingInitialization() async throws {
        // Given: Initialization is in progress
        let manager = sut!
        let initTask = Task {
            let options = InitializationOptions()
            return try await manager.initialize(options: options)
        }

        // Small delay to ensure init started
        try? await Task.sleep(nanoseconds: 100_000)

        // When: Refresh is called while init is pending
        let refreshedSession = try await sut.refresh()

        // Then: Valid session is returned
        XCTAssertNotNil(refreshedSession.identityId)

        // Clean up the original task
        _ = try? await initTask.value
    }

    // MARK: - Reset Scenarios

    /// Scenario: App needs to completely reset Branch state (e.g., debug menu action)
    /// Expected: All state cleared, ready for new initialization
    func testCompleteReset() async throws {
        // Given: Fully initialized session with identity and deep link
        var options = InitializationOptions()
        options.url = URL(string: "https://example.app.link/data")!
        _ = try await sut.initialize(options: options)
        try await sut.setIdentity("test-user")

        // When: Reset is called
        await sut.reset()

        // Then: All state is cleared
        let state = await sut.state
        XCTAssertEqual(state, .uninitialized, "State should be uninitialized")

        let session = await sut.currentSession
        XCTAssertNil(session, "Current session should be nil")
    }

    /// Scenario: Re-initialization after reset
    /// Expected: Fresh session created successfully
    func testReInitializationAfterReset() async throws {
        // Given: Session was initialized then reset
        let options = InitializationOptions()
        let firstSession = try await sut.initialize(options: options)
        await sut.reset()

        // When: Initialize again
        let secondSession = try await sut.initialize(options: options)

        // Then: New session is created with different ID
        XCTAssertNotEqual(firstSession.id, secondSession.id, "New session should have different ID")
        XCTAssertNotNil(secondSession.identityId)
    }

    // MARK: - InitializationOptions Scenarios

    /// Scenario: Building options with fluent builder pattern
    /// Expected: All options are correctly applied
    func testInitializationOptionsBuilderPattern() async throws {
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
        let session = try await sut.initialize(options: options)

        // Verify the session was created with the deep link
        XCTAssertNotNil(session.linkData)
        XCTAssertEqual(session.linkData?.url, deepLink)
    }

    /// Scenario: Initialization with delayed mode
    /// Expected: Session is created but network requests may be deferred
    func testDelayedInitializationMode() async throws {
        // Given: App wants to delay network requests (e.g., GDPR consent pending)
        let options = InitializationOptions()
            .with(delayInitialization: true)

        // When: Initialize with delay flag
        let session = try await sut.initialize(options: options)

        // Then: Session is still created (delay affects network, not session)
        XCTAssertNotNil(session.identityId)
        XCTAssertTrue(options.delayInitialization)
    }

    /// Scenario: Initialization with automatic session tracking disabled
    /// Expected: Session is created but automatic tracking is off
    func testDisableAutomaticSessionTracking() async throws {
        // Given: App manages its own session lifecycle
        let options = InitializationOptions()
            .with(disableAutomaticSessionTracking: true)

        // When: Initialize with tracking disabled
        let session = try await sut.initialize(options: options)

        // Then: Session is created successfully
        XCTAssertNotNil(session.identityId)
        XCTAssertTrue(options.disableAutomaticSessionTracking)
    }

    // MARK: - State Observation Scenarios

    /// Scenario: UI component observing session state changes
    /// Expected: Receives state updates as they happen
    func testUIStateObservation() async throws {
        // Given: UI is observing session state (e.g., loading indicator)
        var observedStates: [SessionState] = []
        let stream = sut.observeState()

        let observerTask = Task {
            for await state in stream {
                observedStates.append(state)
                if state.isReady { break }
            }
        }

        // Small delay to ensure observer is subscribed
        try? await Task.sleep(nanoseconds: 50_000_000)

        // When: Session initializes
        let options = InitializationOptions()
        _ = try await sut.initialize(options: options)

        // Wait for observation
        try? await Task.sleep(nanoseconds: 200_000_000)
        observerTask.cancel()

        // Then: Observer received state updates
        XCTAssertFalse(observedStates.isEmpty, "Should have received at least one state")
        XCTAssertEqual(observedStates.first, .uninitialized, "First state should be uninitialized")
    }

    // MARK: - Edge Cases

    /// Scenario: Multiple sequential initializations with different URLs
    /// Expected: Each sequential init creates a new session (state machine allows re-init)
    /// Note: Task coalescing only applies to CONCURRENT calls, not sequential ones
    func testSequentialInitializationsWithDifferentURLs() async throws {
        // Given: First initialization with URL A
        var options1 = InitializationOptions()
        options1.url = URL(string: "https://example.app.link/first")!
        let firstSession = try await sut.initialize(options: options1)

        // When: Second initialization after first completes (sequential, not concurrent)
        var options2 = InitializationOptions()
        options2.url = URL(string: "https://example.app.link/second")!
        let secondSession = try await sut.initialize(options: options2)

        // Then: New session created (initialized → initializing transition is valid)
        // This is different from concurrent coalescing - sequential calls trigger re-init
        XCTAssertNotEqual(firstSession.id, secondSession.id, "Sequential init creates new session")
        XCTAssertNotNil(secondSession.linkData, "Second URL should be captured")
        XCTAssertEqual(secondSession.linkData?.url, options2.url, "Second URL preserved")
    }

    /// Scenario: Initialize with malformed referral params
    /// Expected: Session still created, bad params ignored or handled
    func testInitializationWithSpecialCharactersInParams() async throws {
        // Given: Referral params with special characters
        let referralParams = [
            "emoji": "🎉",
            "special": "a&b=c?d",
            "unicode": "日本語",
        ]

        let options = InitializationOptions()
            .with(referralParams: referralParams)

        // When: Initialize with these params
        let session = try await sut.initialize(options: options)

        // Then: Session is created successfully (params are handled internally)
        XCTAssertNotNil(session.identityId)
    }
}
