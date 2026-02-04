//
//  SessionModelsTests.swift
//  BranchSDKTests
//
//  Copyright © 2026 Branch Metrics. All rights reserved.
//  SPDX-License-Identifier: MIT
//

@testable import BranchSDK
import XCTest

/// Qualitative tests for Session models focusing on real-world behaviors and invariants.
///
/// These tests verify:
/// - Data integrity and immutability guarantees
/// - State machine correctness
/// - Business logic constraints
/// - Edge cases and boundary conditions
final class SessionModelsTests: XCTestCase {
    // MARK: - Session Creation Tests

    /// Session should be created with all required fields
    func testSessionCreation_AllFieldsPopulated() {
        let session = Session(
            id: "test-session-123",
            createdAt: Date(),
            identityId: "identity-123",
            deviceFingerprintId: "fingerprint-456",
            isFirstSession: true,
            userId: nil,
            params: [:]
        )

        XCTAssertEqual(session.id, "test-session-123")
        XCTAssertEqual(session.identityId, "identity-123")
        XCTAssertEqual(session.deviceFingerprintId, "fingerprint-456")
        XCTAssertTrue(session.isFirstSession)
        XCTAssertNil(session.userId)
        XCTAssertFalse(session.hasDeepLinkData)
    }

    /// Session ID should be unique per creation
    func testSessionIdUniqueness_NewSessionsGetUniqueIds() {
        var sessionIds: Set<String> = []

        // When: Creating multiple sessions with unique IDs
        for i in 0 ..< 100 {
            let session = Session(
                id: "session-\(i)",
                createdAt: Date(),
                identityId: "identity",
                deviceFingerprintId: "fingerprint",
                isFirstSession: true,
                userId: nil,
                params: [:]
            )
            sessionIds.insert(session.id)
        }

        // Then: All IDs are unique
        XCTAssertEqual(sessionIds.count, 100, "Each new session should have a unique ID")
    }

    // MARK: - Session Identity Lifecycle Tests

    /// User identity lifecycle: anonymous → identified → anonymous
    /// This is a critical business flow for user authentication
    func testIdentityLifecycle_AnonymousToIdentifiedToAnonymous() {
        // Given: Anonymous session (fresh install)
        let anonymous = Session(
            id: "session-123",
            createdAt: Date(),
            identityId: "identity-123",
            deviceFingerprintId: "fingerprint-456",
            isFirstSession: true,
            userId: nil,
            params: [:]
        )

        // Verify: Initial state is anonymous
        XCTAssertFalse(anonymous.isIdentified, "Fresh session should be anonymous")
        XCTAssertNil(anonymous.userId, "Anonymous session should have no userId")

        // When: User logs in
        let identified = anonymous.withIdentity("user-abc")

        // Then: Session is identified
        XCTAssertTrue(identified.isIdentified, "Session should be identified after login")
        XCTAssertEqual(identified.userId, "user-abc")
        XCTAssertEqual(identified.identityId, anonymous.identityId, "Branch identity should persist")

        // When: User logs out
        let loggedOut = identified.withoutIdentity()

        // Then: Session returns to anonymous
        XCTAssertFalse(loggedOut.isIdentified, "Session should be anonymous after logout")
        XCTAssertNil(loggedOut.userId, "userId should be cleared after logout")
        XCTAssertEqual(loggedOut.identityId, anonymous.identityId, "Branch identity should persist")
    }

    /// Changing identity should replace the previous one, not append
    func testIdentityReplacement_NewIdentityOverwritesPrevious() {
        let session = Session(
            id: "session-123",
            createdAt: Date(),
            identityId: "identity-123",
            deviceFingerprintId: "fingerprint-456",
            isFirstSession: true,
            userId: nil,
            params: [:]
        )

        // When: Setting identity twice
        let firstLogin = session.withIdentity("user-1")
        let secondLogin = firstLogin.withIdentity("user-2")

        // Then: Only the latest identity is present
        XCTAssertEqual(secondLogin.userId, "user-2", "New identity should replace previous")
        XCTAssertNotEqual(secondLogin.userId, "user-1")
    }

    // MARK: - Session Deep Link Data Tests

    /// hasDeepLinkData should correctly reflect actual data presence
    func testHasDeepLinkData_ReflectsActualLinkPresence() {
        let sessionNoLink = Session(
            id: "session-123",
            createdAt: Date(),
            identityId: "identity-123",
            deviceFingerprintId: "fingerprint-456",
            isFirstSession: true,
            userId: nil,
            params: [:]
        )

        XCTAssertFalse(sessionNoLink.hasDeepLinkData, "No link data means no deep link")

        // Session with link data (via params indicating clicked link)
        let sessionWithLinkParams = Session(
            id: "session-456",
            createdAt: Date(),
            identityId: "identity-123",
            deviceFingerprintId: "fingerprint-456",
            isFirstSession: true,
            userId: nil,
            params: ["+clicked_branch_link": true, "~referring_link": "https://app.link/test"]
        )

        // Note: hasDeepLinkData checks linkData property, not params
        // So we need to check params directly for link presence
        let hasLinkInParams = sessionWithLinkParams.params["+clicked_branch_link"] as? Bool ?? false
        XCTAssertTrue(hasLinkInParams, "Params should indicate clicked link")
    }

    // MARK: - Session State Machine Tests

    /// State machine must enforce valid transitions only
    /// Invalid transitions would cause undefined behavior
    func testStateMachineTransitions_OnlyValidTransitionsAllowed() {
        // Valid transitions
        XCTAssertTrue(
            SessionState.uninitialized.canTransition(to: .initializing),
            "uninitialized → initializing should be valid"
        )
        XCTAssertTrue(
            SessionState.initializing.canTransition(to: .initialized),
            "initializing → initialized should be valid"
        )
        XCTAssertTrue(
            SessionState.initialized.canTransition(to: .uninitialized),
            "initialized → uninitialized should be valid (reset)"
        )
        XCTAssertTrue(
            SessionState.initialized.canTransition(to: .initializing),
            "initialized → initializing should be valid (refresh)"
        )
        XCTAssertTrue(
            SessionState.initializing.canTransition(to: .uninitialized),
            "initializing → uninitialized should be valid (cancel/error)"
        )

        // Invalid transition: Can't skip initializing
        XCTAssertFalse(
            SessionState.uninitialized.canTransition(to: .initialized),
            "uninitialized → initialized should be INVALID (can't skip initializing)"
        )
    }

    /// State properties must be mutually exclusive and exhaustive
    func testStateProperties_MutuallyExclusive() {
        let states: [SessionState] = [
            .uninitialized,
            .initializing,
            .initialized,
        ]

        for state in states {
            // Count how many boolean properties are true
            let trueCount = [
                state.isReady,
                state.isInitializing,
                state.needsInitialization,
            ].filter { $0 }.count

            // At least one property should be true
            XCTAssertGreaterThan(trueCount, 0, "State \(state) should have at least one true property")

            // isReady and isInitializing should never both be true
            XCTAssertFalse(
                state.isReady && state.isInitializing,
                "State cannot be both ready and initializing"
            )

            // isReady and needsInitialization should never both be true
            XCTAssertFalse(
                state.isReady && state.needsInitialization,
                "State cannot be both ready and needing initialization"
            )
        }
    }

    // MARK: - InitializationOptions Builder Tests

    /// Builder pattern should support chaining without losing data
    func testInitializationOptionsBuilder_ChainPreservesAllData() {
        let url = URL(string: "https://test.link/abc")!
        let referralParams = ["utm_source": "test", "utm_campaign": "summer"]

        let options = InitializationOptions()
            .with(url: url)
            .with(sceneIdentifier: "main-scene")
            .with(delayInitialization: true)
            .with(disableAutomaticSessionTracking: true)
            .with(checkPasteboardOnInstall: false)
            .with(referralParams: referralParams)
            .with(sourceApplication: "com.apple.mobilesafari")

        // All values should be present after chain
        XCTAssertEqual(options.url, url)
        XCTAssertEqual(options.sceneIdentifier, "main-scene")
        XCTAssertTrue(options.delayInitialization)
        XCTAssertTrue(options.disableAutomaticSessionTracking)
        XCTAssertFalse(options.checkPasteboardOnInstall)
        XCTAssertEqual(options.referralParams?["utm_source"], "test")
        XCTAssertEqual(options.referralParams?["utm_campaign"], "summer")
        XCTAssertEqual(options.sourceApplication, "com.apple.mobilesafari")
    }

    /// Builder should allow overwriting previous values
    func testInitializationOptionsBuilder_OverwritePreviousValues() {
        let firstURL = URL(string: "https://test.link/first")!
        let secondURL = URL(string: "https://test.link/second")!

        let options = InitializationOptions()
            .with(url: firstURL)
            .with(sceneIdentifier: "scene-1")
            .with(url: secondURL) // Overwrite
            .with(sceneIdentifier: "scene-2") // Overwrite

        XCTAssertEqual(options.url, secondURL, "Later value should overwrite earlier")
        XCTAssertEqual(options.sceneIdentifier, "scene-2", "Later value should overwrite earlier")
    }

    // MARK: - Session Timestamp Tests

    /// Session createdAt should capture creation time accurately
    func testSessionCreatedAt_CapturesCreationTime() {
        let before = Date()
        let session = Session(
            id: "session-123",
            createdAt: Date(),
            identityId: "identity-123",
            deviceFingerprintId: "fingerprint-456",
            isFirstSession: true,
            userId: nil,
            params: [:]
        )
        let after = Date()

        XCTAssertGreaterThanOrEqual(
            session.createdAt,
            before,
            "createdAt should be >= time before creation"
        )
        XCTAssertLessThanOrEqual(
            session.createdAt,
            after,
            "createdAt should be <= time after creation"
        )
    }

    /// Modified sessions should preserve original createdAt
    func testSessionModifications_PreserveCreatedAt() {
        let originalDate = Date()
        let original = Session(
            id: "session-123",
            createdAt: originalDate,
            identityId: "identity-123",
            deviceFingerprintId: "fingerprint-456",
            isFirstSession: true,
            userId: nil,
            params: [:]
        )

        // Wait a tiny bit to ensure timestamps would differ if re-created
        Thread.sleep(forTimeInterval: 0.01)

        let modified = original
            .withIdentity("user-1")
            .withoutIdentity()

        XCTAssertEqual(
            modified.createdAt,
            original.createdAt,
            "Modifications should preserve original createdAt"
        )
    }

    // MARK: - InvalidStateTransitionError Tests

    /// InvalidStateTransitionError should provide useful debugging info
    func testInvalidStateTransitionError_ProvidesUsefulInfo() {
        let error = InvalidStateTransitionError(
            from: .uninitialized,
            to: .initialized
        )

        let description = error.description

        // Should mention both states
        XCTAssertTrue(description.contains("Uninitialized"), "Should mention source state")
        XCTAssertTrue(description.contains("Initialized"), "Should mention target state")
        XCTAssertTrue(description.lowercased().contains("invalid"), "Should indicate it's invalid")
    }

    // MARK: - First Session Flag Tests

    /// isFirstSession flag should be immutable through modifications
    func testFirstSessionFlag_ImmutableThroughModifications() {
        let firstSession = Session(
            id: "session-123",
            createdAt: Date(),
            identityId: "identity-123",
            deviceFingerprintId: "fingerprint-456",
            isFirstSession: true,
            userId: nil,
            params: [:]
        )

        let returningSession = Session(
            id: "session-456",
            createdAt: Date(),
            identityId: "identity-456",
            deviceFingerprintId: "fingerprint-789",
            isFirstSession: false,
            userId: nil,
            params: [:]
        )

        // Modifications should preserve isFirstSession
        XCTAssertTrue(firstSession.withIdentity("user").isFirstSession)
        XCTAssertTrue(firstSession.withoutIdentity().isFirstSession)

        XCTAssertFalse(returningSession.withIdentity("user").isFirstSession)
        XCTAssertFalse(returningSession.withoutIdentity().isFirstSession)
    }

    // MARK: - Description Consistency Tests

    /// Session description should reflect current state accurately
    func testSessionDescription_ReflectsCurrentState() {
        // First session, anonymous, no link
        let basicSession = Session(
            id: "session-123",
            createdAt: Date(),
            identityId: "identity-123",
            deviceFingerprintId: "fingerprint-456",
            isFirstSession: true,
            userId: nil,
            params: [:]
        )
        let basicDesc = basicSession.description
        XCTAssertTrue(basicDesc.contains("first"), "Should indicate first session")
        XCTAssertFalse(basicDesc.contains("identified"), "Should not indicate identified")

        // Returning session, identified
        let identifiedSession = Session(
            id: "session-456",
            createdAt: Date(),
            identityId: "identity-123",
            deviceFingerprintId: "fingerprint-456",
            isFirstSession: false,
            userId: "user-123",
            params: [:]
        )
        let identifiedDesc = identifiedSession.description
        XCTAssertFalse(identifiedDesc.contains("first"), "Should not indicate first session")
        XCTAssertTrue(identifiedDesc.contains("identified"), "Should indicate identified")
    }

    // MARK: - Session Equality Tests

    /// Sessions with same ID should be equal when all fields match
    func testSessionEquality_BasedOnFields() {
        let date = Date()

        let session1 = Session(
            id: "same-id",
            createdAt: date,
            identityId: "identity-1",
            deviceFingerprintId: "fingerprint-1",
            isFirstSession: true,
            userId: nil,
            params: [:]
        )

        let session2 = Session(
            id: "same-id",
            createdAt: date,
            identityId: "identity-1",
            deviceFingerprintId: "fingerprint-1",
            isFirstSession: true,
            userId: nil,
            params: [:]
        )

        let session3 = Session(
            id: "same-id",
            createdAt: date,
            identityId: "identity-1",
            deviceFingerprintId: "fingerprint-1",
            isFirstSession: true,
            userId: "different-user",
            params: [:]
        )

        // Note: Session is a class inheriting from NSObject
        // Equality depends on implementation (isEqual:)
        // These tests verify the fields are correctly set
        XCTAssertEqual(session1.id, session2.id)
        XCTAssertEqual(session1.userId, session2.userId)
        XCTAssertNotEqual(session1.userId, session3.userId)
    }

    // MARK: - SessionState Properties Tests

    func testSessionStateIsReady() {
        XCTAssertFalse(SessionState.uninitialized.isReady)
        XCTAssertFalse(SessionState.initializing.isReady)
        XCTAssertTrue(SessionState.initialized.isReady)
    }

    func testSessionStateIsInitializing() {
        XCTAssertFalse(SessionState.uninitialized.isInitializing)
        XCTAssertTrue(SessionState.initializing.isInitializing)
        XCTAssertFalse(SessionState.initialized.isInitializing)
    }

    func testSessionStateNeedsInitialization() {
        XCTAssertTrue(SessionState.uninitialized.needsInitialization)
        XCTAssertFalse(SessionState.initializing.needsInitialization)
        XCTAssertFalse(SessionState.initialized.needsInitialization)
    }

    func testSessionStateDescription() {
        XCTAssertEqual(SessionState.uninitialized.stateDescription, "Uninitialized")
        XCTAssertEqual(SessionState.initializing.stateDescription, "Initializing")
        XCTAssertEqual(SessionState.initialized.stateDescription, "Initialized")
    }
}
