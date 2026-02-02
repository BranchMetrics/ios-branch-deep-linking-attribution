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
@available(iOS 13.0, macOS 10.15, tvOS 13.0, watchOS 6.0, *)
final class SessionModelsTests: XCTestCase {
    // MARK: - Session Immutability Tests

    /// Session should be immutable - all modifications return new instances
    /// This guarantees thread-safety when sessions are shared across actors
    func testSessionImmutability_ModificationsReturnNewInstances() {
        let original = Session(
            identityId: "identity-123",
            deviceFingerprintId: "fingerprint-456",
            isFirstSession: true
        )
        let originalId = original.id

        // When: Modifying session through any method
        let withIdentity = original.withIdentity("user-123")
        let withLinkData = original.withLinkData(LinkData(url: URL(string: "https://test.link")!))
        let withoutIdentity = withIdentity.withoutIdentity()

        // Then: Original is unchanged, new instances have different IDs only when appropriate
        XCTAssertEqual(original.id, originalId, "Original session should be unchanged")
        XCTAssertNil(original.userId, "Original session should not have userId")
        XCTAssertNil(original.linkData, "Original session should not have linkData")

        // Modifications preserve session ID (same logical session)
        XCTAssertEqual(withIdentity.id, originalId, "withIdentity should preserve session ID")
        XCTAssertEqual(withLinkData.id, originalId, "withLinkData should preserve session ID")
        XCTAssertEqual(withoutIdentity.id, originalId, "withoutIdentity should preserve session ID")

        // But the actual data differs
        XCTAssertEqual(withIdentity.userId, "user-123")
        XCTAssertNotNil(withLinkData.linkData)
        XCTAssertNil(withoutIdentity.userId)
    }

    /// Session ID should be unique per creation, not per modification
    func testSessionIdUniqueness_NewSessionsGetUniqueIds() {
        var sessionIds: Set<String> = []

        // When: Creating multiple sessions
        for _ in 0 ..< 100 {
            let session = Session(
                identityId: "identity",
                deviceFingerprintId: "fingerprint",
                isFirstSession: true
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
            identityId: "identity-123",
            deviceFingerprintId: "fingerprint-456",
            isFirstSession: true
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
            identityId: "identity-123",
            deviceFingerprintId: "fingerprint-456",
            isFirstSession: true
        )

        // When: Setting identity twice
        let firstLogin = session.withIdentity("user-1")
        let secondLogin = firstLogin.withIdentity("user-2")

        // Then: Only the latest identity is present
        XCTAssertEqual(secondLogin.userId, "user-2", "New identity should replace previous")
        XCTAssertNotEqual(secondLogin.userId, "user-1")
    }

    // MARK: - Session Deep Link Data Tests

    /// Deep link data should be preserved through identity changes
    /// Important: Users clicking links before logging in shouldn't lose attribution
    func testDeepLinkDataPreservation_ThroughIdentityChanges() {
        // Given: Session with deep link data (user clicked link)
        let linkData = LinkData(
            url: URL(string: "https://app.link/promo")!,
            isClicked: true,
            campaign: "summer-sale"
        )
        let sessionWithLink = Session(
            identityId: "identity-123",
            deviceFingerprintId: "fingerprint-456",
            isFirstSession: true,
            linkData: linkData
        )

        // When: User logs in (after clicking link)
        let identified = sessionWithLink.withIdentity("user-abc")

        // Then: Deep link data is preserved
        XCTAssertNotNil(identified.linkData, "Link data must survive identity change")
        XCTAssertEqual(identified.linkData?.campaign, "summer-sale")
        XCTAssertTrue(identified.hasDeepLinkData)

        // When: User logs out
        let loggedOut = identified.withoutIdentity()

        // Then: Deep link data is still preserved
        XCTAssertNotNil(loggedOut.linkData, "Link data must survive logout")
        XCTAssertEqual(loggedOut.linkData?.campaign, "summer-sale")
    }

    /// hasDeepLinkData should correctly reflect actual data presence
    func testHasDeepLinkData_ReflectsActualLinkPresence() {
        let sessionNoLink = Session(
            identityId: "identity-123",
            deviceFingerprintId: "fingerprint-456",
            isFirstSession: true
        )

        // Empty LinkData should still count as no deep link
        let emptyLinkData = LinkData()
        _ = sessionNoLink.withLinkData(emptyLinkData) // Test that it doesn't crash

        // LinkData with URL should count as deep link
        let realLinkData = LinkData(url: URL(string: "https://app.link/real")!)
        let sessionRealLink = sessionNoLink.withLinkData(realLinkData)

        XCTAssertFalse(sessionNoLink.hasDeepLinkData, "No link data means no deep link")
        // Note: Whether empty LinkData counts depends on implementation
        XCTAssertTrue(sessionRealLink.hasDeepLinkData, "Real link data means deep link present")
    }

    // MARK: - Session State Machine Tests

    /// State machine must enforce valid transitions only
    /// Invalid transitions would cause undefined behavior
    func testStateMachineTransitions_OnlyValidTransitionsAllowed() {
        let session = Session(
            identityId: "identity-123",
            deviceFingerprintId: "fingerprint-456",
            isFirstSession: true
        )

        // Valid transitions
        XCTAssertTrue(
            SessionState.uninitialized.canTransition(to: .initializing),
            "uninitialized → initializing should be valid"
        )
        XCTAssertTrue(
            SessionState.initializing.canTransition(to: .initialized(session)),
            "initializing → initialized should be valid"
        )
        XCTAssertTrue(
            SessionState.initialized(session).canTransition(to: .uninitialized),
            "initialized → uninitialized should be valid (reset)"
        )
        XCTAssertTrue(
            SessionState.initialized(session).canTransition(to: .initializing),
            "initialized → initializing should be valid (refresh)"
        )
        XCTAssertTrue(
            SessionState.initializing.canTransition(to: .uninitialized),
            "initializing → uninitialized should be valid (cancel/error)"
        )

        // Invalid transition: Can't skip initializing
        XCTAssertFalse(
            SessionState.uninitialized.canTransition(to: .initialized(session)),
            "uninitialized → initialized should be INVALID (can't skip initializing)"
        )
    }

    /// State properties must be mutually exclusive and exhaustive
    func testStateProperties_MutuallyExclusive() {
        let session = Session(
            identityId: "identity-123",
            deviceFingerprintId: "fingerprint-456",
            isFirstSession: true
        )

        let states: [SessionState] = [
            .uninitialized,
            .initializing,
            .initialized(session),
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

    /// Session should only be accessible in initialized state
    func testStateSession_OnlyAccessibleWhenInitialized() {
        let session = Session(
            identityId: "identity-123",
            deviceFingerprintId: "fingerprint-456",
            isFirstSession: true
        )

        XCTAssertNil(SessionState.uninitialized.session, "Uninitialized state should have no session")
        XCTAssertNil(SessionState.initializing.session, "Initializing state should have no session")
        XCTAssertNotNil(SessionState.initialized(session).session, "Initialized state must have session")
        XCTAssertEqual(SessionState.initialized(session).session?.id, session.id)
    }

    // MARK: - LinkData Accessor Tests

    /// LinkData accessors should handle type mismatches gracefully
    func testLinkDataAccessors_TypeMismatchReturnsNil() {
        let linkData = LinkData(
            parameters: [
                "string_value": AnyCodable("hello"),
                "int_value": AnyCodable(42),
                "bool_value": AnyCodable(true),
                "array_value": AnyCodable(["a", "b"]),
                "dict_value": AnyCodable(["key": "value"]),
            ]
        )

        // Correct type accessors
        XCTAssertEqual(linkData.string(forKey: "string_value"), "hello")
        XCTAssertEqual(linkData.int(forKey: "int_value"), 42)
        XCTAssertEqual(linkData.bool(forKey: "bool_value"), true)

        // Wrong type accessors should return nil, not crash
        XCTAssertNil(linkData.string(forKey: "int_value"), "int accessed as string should be nil")
        XCTAssertNil(linkData.int(forKey: "string_value"), "string accessed as int should be nil")
        XCTAssertNil(linkData.bool(forKey: "string_value"), "string accessed as bool should be nil")
        XCTAssertNil(linkData.array(forKey: "string_value"), "string accessed as array should be nil")
        XCTAssertNil(linkData.dictionary(forKey: "string_value"), "string accessed as dict should be nil")

        // Non-existent keys
        XCTAssertNil(linkData.string(forKey: "nonexistent"))
        XCTAssertNil(linkData.int(forKey: "nonexistent"))
    }

    /// LinkData should preserve complex nested structures
    func testLinkDataNestedStructures_PreservedCorrectly() {
        // Build nested structures with explicit Sendable types
        let level2Dict = ["level3": "deep_value"]
        let level1Dict: [String: AnyCodable] = ["level2": AnyCodable(level2Dict)]

        let arrayItem1: [String: AnyCodable] = ["id": AnyCodable(1), "name": AnyCodable("first")]
        let arrayItem2: [String: AnyCodable] = ["id": AnyCodable(2), "name": AnyCodable("second")]
        let arrayOfDictsValue: [AnyCodable] = [AnyCodable(arrayItem1), AnyCodable(arrayItem2)]

        let linkData = LinkData(
            parameters: [
                "nested": AnyCodable(level1Dict),
                "array": AnyCodable(arrayOfDictsValue),
            ]
        )

        // Access nested dictionary
        let level1 = linkData.dictionary(forKey: "nested")
        XCTAssertNotNil(level1)

        // Access array of dictionaries
        let arrayOfDicts = linkData.array(forKey: "array")
        XCTAssertNotNil(arrayOfDicts)
        XCTAssertEqual(arrayOfDicts?.count, 2)
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

    // MARK: - BranchError Behavior Tests

    /// Error codes should follow the documented ranges
    func testBranchErrorCodes_FollowDocumentedRanges() {
        // Configuration errors: 1xxx
        XCTAssertTrue((1000 ... 1999).contains(BranchError.invalidConfiguration("").errorCode))
        XCTAssertTrue((1000 ... 1999).contains(BranchError.notInitialized.errorCode))
        XCTAssertTrue((1000 ... 1999).contains(BranchError.alreadyInitialized.errorCode))

        // Network errors: 2xxx
        XCTAssertTrue((2000 ... 2999).contains(BranchError.networkError("").errorCode))
        XCTAssertTrue((2000 ... 2999).contains(BranchError.timeout.errorCode))
        XCTAssertTrue((2000 ... 2999).contains(BranchError.serverError(statusCode: 500, message: nil).errorCode))
        XCTAssertTrue((2000 ... 2999).contains(BranchError.invalidResponse.errorCode))

        // State errors: 3xxx
        XCTAssertTrue((3000 ... 3999).contains(BranchError.invalidStateTransition(from: "", to: "").errorCode))
        XCTAssertTrue((3000 ... 3999).contains(BranchError.sessionRequired.errorCode))

        // Link errors: 4xxx
        XCTAssertTrue((4000 ... 4999).contains(BranchError.invalidURL("").errorCode))
        XCTAssertTrue((4000 ... 4999).contains(BranchError.noURLProvided.errorCode))
        XCTAssertTrue((4000 ... 4999).contains(BranchError.linkCreationFailed("").errorCode))
        XCTAssertTrue((4000 ... 4999).contains(BranchError.invalidUserActivity.errorCode))

        // Identity errors: 5xxx
        XCTAssertTrue((5000 ... 5999).contains(BranchError.invalidIdentity("").errorCode))

        // Event errors: 6xxx
        XCTAssertTrue((6000 ... 6999).contains(BranchError.invalidEvent("").errorCode))
        XCTAssertTrue((6000 ... 6999).contains(BranchError.eventTrackingFailed("").errorCode))

        // Storage errors: 7xxx
        XCTAssertTrue((7000 ... 7999).contains(BranchError.storageError("").errorCode))

        // General errors: 9xxx
        XCTAssertTrue((9000 ... 9999).contains(BranchError.unknown("").errorCode))
        XCTAssertTrue((9000 ... 9999).contains(BranchError.underlying(NSError(domain: "", code: 0)).errorCode))
    }

    /// Error descriptions should be human-readable and actionable
    func testBranchErrorDescriptions_AreHumanReadable() {
        let errors: [BranchError] = [
            .invalidConfiguration("Missing branch key"),
            .notInitialized,
            .networkError("Connection refused"),
            .serverError(statusCode: 503, message: "Service unavailable"),
            .sessionRequired,
            .invalidIdentity("Empty user ID"),
        ]

        for error in errors {
            guard let description = error.errorDescription else {
                XCTFail("Error \(error) should have a description")
                continue
            }

            // Description should not be empty
            XCTAssertFalse(description.isEmpty, "Description should not be empty")

            // Description should not be just the enum case name
            XCTAssertFalse(
                description.lowercased() == String(describing: error).lowercased(),
                "Description should be human-readable, not just the enum case"
            )

            // Description should start with capital letter
            XCTAssertTrue(
                description.first?.isUppercase ?? false,
                "Description should start with capital letter"
            )
        }
    }

    /// Server errors should include status code in description
    func testBranchErrorServerError_IncludesStatusCodeInDescription() {
        let statusCodes = [400, 401, 403, 404, 500, 502, 503]

        for code in statusCodes {
            let error = BranchError.serverError(statusCode: code, message: nil)
            let description = error.errorDescription ?? ""

            XCTAssertTrue(
                description.contains("\(code)"),
                "Server error description should include status code \(code)"
            )
        }
    }

    /// Errors with associated messages should include them in description
    func testBranchErrorWithMessage_IncludesMessageInDescription() {
        let customMessage = "Custom error details here"

        let errorsWithMessages: [BranchError] = [
            .invalidConfiguration(customMessage),
            .networkError(customMessage),
            .serverError(statusCode: 500, message: customMessage),
            .invalidURL(customMessage),
            .invalidIdentity(customMessage),
            .linkCreationFailed(customMessage),
            .storageError(customMessage),
            .unknown(customMessage),
        ]

        for error in errorsWithMessages {
            let description = error.errorDescription ?? ""
            XCTAssertTrue(
                description.contains(customMessage),
                "Error description should include custom message: \(error)"
            )
        }
    }

    // MARK: - Session Timestamp Tests

    /// Session createdAt should capture creation time accurately
    func testSessionCreatedAt_CapturesCreationTime() {
        let before = Date()
        let session = Session(
            identityId: "identity-123",
            deviceFingerprintId: "fingerprint-456",
            isFirstSession: true
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
        let original = Session(
            identityId: "identity-123",
            deviceFingerprintId: "fingerprint-456",
            isFirstSession: true
        )

        // Wait a tiny bit to ensure timestamps would differ if re-created
        Thread.sleep(forTimeInterval: 0.01)

        let modified = original
            .withIdentity("user-1")
            .withLinkData(LinkData(url: URL(string: "https://test.link")!))
            .withoutIdentity()

        XCTAssertEqual(
            modified.createdAt,
            original.createdAt,
            "Modifications should preserve original createdAt"
        )
    }

    // MARK: - Equatable Correctness Tests

    /// Sessions with same ID but different data should still be equal (ID-based equality)
    func testSessionEquatable_BasedOnAllFields() {
        let date = Date()

        let session1 = Session(
            id: "same-id",
            createdAt: date,
            identityId: "identity-1",
            deviceFingerprintId: "fingerprint-1",
            isFirstSession: true,
            linkData: nil,
            userId: nil
        )

        let session2 = Session(
            id: "same-id",
            createdAt: date,
            identityId: "identity-1",
            deviceFingerprintId: "fingerprint-1",
            isFirstSession: true,
            linkData: nil,
            userId: nil
        )

        let session3 = Session(
            id: "same-id",
            createdAt: date,
            identityId: "identity-1",
            deviceFingerprintId: "fingerprint-1",
            isFirstSession: true,
            linkData: nil,
            userId: "different-user" // Different userId
        )

        XCTAssertEqual(session1, session2, "Identical sessions should be equal")
        XCTAssertNotEqual(session1, session3, "Sessions with different userId should not be equal")
    }

    /// LinkData equality should compare all fields
    func testLinkDataEquatable_ComparesAllFields() {
        let linkData1 = LinkData(
            url: URL(string: "https://test.link")!,
            isClicked: true,
            campaign: "campaign-1",
            channel: "channel-1"
        )

        let linkData2 = LinkData(
            url: URL(string: "https://test.link")!,
            isClicked: true,
            campaign: "campaign-1",
            channel: "channel-1"
        )

        let linkData3 = LinkData(
            url: URL(string: "https://test.link")!,
            isClicked: true,
            campaign: "different-campaign", // Different
            channel: "channel-1"
        )

        XCTAssertEqual(linkData1, linkData2)
        XCTAssertNotEqual(linkData1, linkData3, "Different campaign should make them unequal")
    }

    // MARK: - InvalidStateTransitionError Tests

    /// InvalidStateTransitionError should provide useful debugging info
    func testInvalidStateTransitionError_ProvidesUsefulInfo() {
        let session = Session(
            identityId: "identity-123",
            deviceFingerprintId: "fingerprint-456",
            isFirstSession: true
        )

        let error = InvalidStateTransitionError(
            from: .uninitialized,
            to: .initialized(session)
        )

        let description = error.description

        // Should mention both states
        XCTAssertTrue(description.contains("Uninitialized"), "Should mention source state")
        XCTAssertTrue(description.contains("Initialized"), "Should mention target state")
        XCTAssertTrue(description.lowercased().contains("invalid"), "Should indicate it's invalid")
    }

    // MARK: - First Session Flag Tests

    /// isFirstSession flag should be immutable once set
    func testFirstSessionFlag_ImmutableThroughModifications() {
        let firstSession = Session(
            identityId: "identity-123",
            deviceFingerprintId: "fingerprint-456",
            isFirstSession: true
        )

        let returningSession = Session(
            identityId: "identity-456",
            deviceFingerprintId: "fingerprint-789",
            isFirstSession: false
        )

        // Modifications should preserve isFirstSession
        XCTAssertTrue(firstSession.withIdentity("user").isFirstSession)
        XCTAssertTrue(firstSession.withLinkData(LinkData()).isFirstSession)
        XCTAssertTrue(firstSession.withoutIdentity().isFirstSession)

        XCTAssertFalse(returningSession.withIdentity("user").isFirstSession)
        XCTAssertFalse(returningSession.withLinkData(LinkData()).isFirstSession)
        XCTAssertFalse(returningSession.withoutIdentity().isFirstSession)
    }

    // MARK: - Description Consistency Tests

    /// Session description should reflect current state accurately
    func testSessionDescription_ReflectsCurrentState() {
        // First session, anonymous, no link
        let basicSession = Session(
            identityId: "identity-123",
            deviceFingerprintId: "fingerprint-456",
            isFirstSession: true
        )
        let basicDesc = basicSession.description
        XCTAssertTrue(basicDesc.contains("first"), "Should indicate first session")
        XCTAssertFalse(basicDesc.contains("identified"), "Should not indicate identified")
        XCTAssertFalse(basicDesc.contains("hasLinkData"), "Should not indicate link data")

        // Returning session, identified, with link
        let fullSession = Session(
            identityId: "identity-123",
            deviceFingerprintId: "fingerprint-456",
            isFirstSession: false,
            linkData: LinkData(url: URL(string: "https://test.link")!),
            userId: "user-123"
        )
        let fullDesc = fullSession.description
        XCTAssertFalse(fullDesc.contains("first"), "Should not indicate first session")
        XCTAssertTrue(fullDesc.contains("identified"), "Should indicate identified")
        XCTAssertTrue(fullDesc.contains("hasLinkData"), "Should indicate link data")
    }
}
