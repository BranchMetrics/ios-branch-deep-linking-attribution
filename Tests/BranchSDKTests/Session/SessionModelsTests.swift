//
//  SessionModelsTests.swift
//  BranchSDKTests
//
//  Copyright © 2026 Branch Metrics. All rights reserved.
//  SPDX-License-Identifier: MIT
//

@testable import BranchSDK
import XCTest

/// Tests for Session model and related types.
@available(iOS 13.0, macOS 10.15, tvOS 13.0, watchOS 6.0, *)
final class SessionModelsTests: XCTestCase {
    // MARK: - Session Tests

    func testSessionInitialization() {
        let session = Session(
            id: "test-id",
            createdAt: Date(),
            identityId: "identity-123",
            deviceFingerprintId: "fingerprint-456",
            isFirstSession: true,
            linkData: nil,
            userId: nil
        )

        XCTAssertEqual(session.id, "test-id")
        XCTAssertEqual(session.identityId, "identity-123")
        XCTAssertEqual(session.deviceFingerprintId, "fingerprint-456")
        XCTAssertTrue(session.isFirstSession)
        XCTAssertNil(session.linkData)
        XCTAssertNil(session.userId)
    }

    func testSessionWithIdentity() {
        let session = Session(
            identityId: "identity-123",
            deviceFingerprintId: "fingerprint-456",
            isFirstSession: true
        )

        let updatedSession = session.withIdentity("user-789")

        XCTAssertEqual(updatedSession.userId, "user-789")
        XCTAssertEqual(updatedSession.id, session.id)
        XCTAssertEqual(updatedSession.identityId, session.identityId)
    }

    func testSessionWithoutIdentity() {
        let session = Session(
            identityId: "identity-123",
            deviceFingerprintId: "fingerprint-456",
            isFirstSession: true,
            userId: "user-789"
        )

        let updatedSession = session.withoutIdentity()

        XCTAssertNil(updatedSession.userId)
        XCTAssertEqual(updatedSession.id, session.id)
    }

    func testSessionWithLinkData() {
        let session = Session(
            identityId: "identity-123",
            deviceFingerprintId: "fingerprint-456",
            isFirstSession: true
        )

        let linkData = LinkData(url: URL(string: "https://test.app.link/abc")!)
        let updatedSession = session.withLinkData(linkData)

        XCTAssertNotNil(updatedSession.linkData)
        XCTAssertEqual(updatedSession.linkData?.url?.absoluteString, "https://test.app.link/abc")
    }

    func testSessionHasDeepLinkData() {
        let sessionWithoutLink = Session(
            identityId: "identity-123",
            deviceFingerprintId: "fingerprint-456",
            isFirstSession: true
        )
        XCTAssertFalse(sessionWithoutLink.hasDeepLinkData)

        let linkData = LinkData(url: URL(string: "https://test.app.link/abc")!)
        let sessionWithLink = sessionWithoutLink.withLinkData(linkData)
        XCTAssertTrue(sessionWithLink.hasDeepLinkData)
    }

    func testSessionIsIdentified() {
        let sessionWithoutIdentity = Session(
            identityId: "identity-123",
            deviceFingerprintId: "fingerprint-456",
            isFirstSession: true
        )
        XCTAssertFalse(sessionWithoutIdentity.isIdentified)

        let sessionWithIdentity = sessionWithoutIdentity.withIdentity("user-123")
        XCTAssertTrue(sessionWithIdentity.isIdentified)
    }

    func testSessionEquatable() {
        let sharedDate = Date()

        let session1 = Session(
            id: "same-id",
            createdAt: sharedDate,
            identityId: "identity-123",
            deviceFingerprintId: "fingerprint-456",
            isFirstSession: true
        )

        let session2 = Session(
            id: "same-id",
            createdAt: sharedDate,
            identityId: "identity-123",
            deviceFingerprintId: "fingerprint-456",
            isFirstSession: true
        )

        XCTAssertEqual(session1, session2)
    }

    func testSessionDescription() {
        let session = Session(
            identityId: "identity-123",
            deviceFingerprintId: "fingerprint-456",
            isFirstSession: true,
            userId: "user-123"
        )

        let description = session.description
        XCTAssertTrue(description.contains("Session"))
        XCTAssertTrue(description.contains("first"))
        XCTAssertTrue(description.contains("identified"))
    }

    func testSessionDescriptionWithLinkData() {
        let linkData = LinkData(url: URL(string: "https://test.app.link/abc")!)
        let session = Session(
            identityId: "identity-123",
            deviceFingerprintId: "fingerprint-456",
            isFirstSession: false,
            linkData: linkData
        )

        let description = session.description
        XCTAssertTrue(description.contains("Session"))
        XCTAssertTrue(description.contains("hasLinkData"))
        XCTAssertFalse(description.contains("first"))
        XCTAssertFalse(description.contains("identified"))
    }

    func testSessionDescriptionMinimal() {
        let session = Session(
            identityId: "identity-123",
            deviceFingerprintId: "fingerprint-456",
            isFirstSession: false
        )

        let description = session.description
        XCTAssertTrue(description.contains("Session"))
        XCTAssertFalse(description.contains("first"))
        XCTAssertFalse(description.contains("hasLinkData"))
        XCTAssertFalse(description.contains("identified"))
    }

    func testSessionCreatedAtTimestamp() {
        let beforeCreation = Date()
        let session = Session(
            identityId: "identity-123",
            deviceFingerprintId: "fingerprint-456",
            isFirstSession: true
        )
        let afterCreation = Date()

        XCTAssertGreaterThanOrEqual(session.createdAt, beforeCreation)
        XCTAssertLessThanOrEqual(session.createdAt, afterCreation)
    }

    func testSessionIdentifiable() {
        let session = Session(
            id: "test-id-123",
            createdAt: Date(),
            identityId: "identity-123",
            deviceFingerprintId: "fingerprint-456",
            isFirstSession: true
        )

        // Session conforms to Identifiable, so we can use .id
        XCTAssertEqual(session.id, "test-id-123")
    }

    // MARK: - SessionState Tests

    func testSessionStateUninitialized() {
        let state = SessionState.uninitialized

        XCTAssertFalse(state.isReady)
        XCTAssertFalse(state.isInitializing)
        XCTAssertTrue(state.needsInitialization)
        XCTAssertNil(state.session)
        XCTAssertEqual(state.description, "Uninitialized")
    }

    func testSessionStateInitializing() {
        let state = SessionState.initializing

        XCTAssertFalse(state.isReady)
        XCTAssertTrue(state.isInitializing)
        XCTAssertFalse(state.needsInitialization)
        XCTAssertNil(state.session)
        XCTAssertEqual(state.description, "Initializing")
    }

    func testSessionStateInitialized() {
        let session = Session(
            identityId: "identity-123",
            deviceFingerprintId: "fingerprint-456",
            isFirstSession: true
        )
        let state = SessionState.initialized(session)

        XCTAssertTrue(state.isReady)
        XCTAssertFalse(state.isInitializing)
        XCTAssertFalse(state.needsInitialization)
        XCTAssertNotNil(state.session)
        XCTAssertTrue(state.description.contains("Initialized"))
    }

    func testSessionStateCanTransition() {
        // Valid transitions
        XCTAssertTrue(SessionState.uninitialized.canTransition(to: .initializing))
        XCTAssertTrue(SessionState.initializing.canTransition(to: .uninitialized))

        let session = Session(
            identityId: "identity-123",
            deviceFingerprintId: "fingerprint-456",
            isFirstSession: true
        )
        XCTAssertTrue(SessionState.initializing.canTransition(to: .initialized(session)))
        XCTAssertTrue(SessionState.initialized(session).canTransition(to: .uninitialized))
        XCTAssertTrue(SessionState.initialized(session).canTransition(to: .initializing))

        // Invalid transition
        XCTAssertFalse(SessionState.uninitialized.canTransition(to: .initialized(session)))
    }

    func testSessionStateEquatable() {
        let session1 = Session(
            id: "same-id",
            createdAt: Date(),
            identityId: "identity-123",
            deviceFingerprintId: "fingerprint-456",
            isFirstSession: true
        )
        let session2 = Session(
            id: "same-id",
            createdAt: Date(),
            identityId: "identity-123",
            deviceFingerprintId: "fingerprint-456",
            isFirstSession: true
        )

        XCTAssertEqual(SessionState.uninitialized, SessionState.uninitialized)
        XCTAssertEqual(SessionState.initializing, SessionState.initializing)
        XCTAssertEqual(SessionState.initialized(session1), SessionState.initialized(session2))
        XCTAssertNotEqual(SessionState.uninitialized, SessionState.initializing)
    }

    func testSessionStateEquatableWithDifferentSessions() {
        let session1 = Session(
            id: "id-1",
            createdAt: Date(),
            identityId: "identity-1",
            deviceFingerprintId: "fingerprint-1",
            isFirstSession: true
        )
        let session2 = Session(
            id: "id-2",
            createdAt: Date(),
            identityId: "identity-2",
            deviceFingerprintId: "fingerprint-2",
            isFirstSession: false
        )

        XCTAssertNotEqual(SessionState.initialized(session1), SessionState.initialized(session2))
    }

    func testSessionStateCanTransitionSameState() {
        let session = Session(
            identityId: "identity-123",
            deviceFingerprintId: "fingerprint-456",
            isFirstSession: true
        )

        // Same state transitions should be allowed
        XCTAssertTrue(SessionState.uninitialized.canTransition(to: .uninitialized))
        XCTAssertTrue(SessionState.initializing.canTransition(to: .initializing))
        XCTAssertTrue(SessionState.initialized(session).canTransition(to: .initialized(session)))
    }

    func testSessionStateSession() {
        let session = Session(
            identityId: "identity-123",
            deviceFingerprintId: "fingerprint-456",
            isFirstSession: true
        )

        XCTAssertNil(SessionState.uninitialized.session)
        XCTAssertNil(SessionState.initializing.session)
        XCTAssertNotNil(SessionState.initialized(session).session)
        XCTAssertEqual(SessionState.initialized(session).session?.id, session.id)
    }

    // MARK: - InvalidStateTransitionError Tests

    func testInvalidStateTransitionErrorDescription() {
        let session = Session(
            identityId: "identity-123",
            deviceFingerprintId: "fingerprint-456",
            isFirstSession: true
        )

        let error = InvalidStateTransitionError(from: .uninitialized, to: .initialized(session))
        let description = error.description

        XCTAssertTrue(description.contains("Invalid state transition"))
        XCTAssertTrue(description.contains("Uninitialized"))
        XCTAssertTrue(description.contains("Initialized"))
    }

    func testInvalidStateTransitionErrorFromInitializing() {
        let error = InvalidStateTransitionError(from: .initializing, to: .initializing)
        let description = error.description

        XCTAssertTrue(description.contains("Initializing"))
    }

    // MARK: - LinkData Tests

    func testLinkDataInitialization() {
        let url = URL(string: "https://test.app.link/abc123")!
        let linkData = LinkData(
            url: url,
            isClicked: true,
            referringLink: "https://test.app.link/refer",
            parameters: ["key": AnyCodable("value")],
            campaign: "test-campaign",
            channel: "test-channel",
            feature: "test-feature",
            tags: ["tag1", "tag2"],
            stage: "test-stage"
        )

        XCTAssertEqual(linkData.url, url)
        XCTAssertTrue(linkData.isClicked)
        XCTAssertEqual(linkData.campaign, "test-campaign")
        XCTAssertEqual(linkData.channel, "test-channel")
        XCTAssertEqual(linkData.feature, "test-feature")
        XCTAssertEqual(linkData.tags, ["tag1", "tag2"])
        XCTAssertEqual(linkData.stage, "test-stage")
    }

    func testLinkDataStringAccessor() {
        let linkData = LinkData(
            parameters: ["string_key": AnyCodable("string_value")]
        )

        XCTAssertEqual(linkData.string(forKey: "string_key"), "string_value")
        XCTAssertNil(linkData.string(forKey: "nonexistent"))
    }

    func testLinkDataIntAccessor() {
        let linkData = LinkData(
            parameters: ["int_key": AnyCodable(42)]
        )

        XCTAssertEqual(linkData.int(forKey: "int_key"), 42)
        XCTAssertNil(linkData.int(forKey: "nonexistent"))
    }

    func testLinkDataBoolAccessor() {
        let linkData = LinkData(
            parameters: ["bool_key": AnyCodable(true)]
        )

        XCTAssertEqual(linkData.bool(forKey: "bool_key"), true)
        XCTAssertNil(linkData.bool(forKey: "nonexistent"))
    }

    func testLinkDataSubscript() {
        let linkData = LinkData(
            parameters: ["key": AnyCodable("value")]
        )

        XCTAssertEqual(linkData["key"] as? String, "value")
        XCTAssertNil(linkData["nonexistent"])
    }

    func testLinkDataDescription() {
        let linkData = LinkData(
            isClicked: true,
            parameters: ["key": AnyCodable("value")],
            campaign: "summer-sale",
            channel: "facebook"
        )

        let description = linkData.description
        XCTAssertTrue(description.contains("LinkData"))
        XCTAssertTrue(description.contains("clicked"))
        XCTAssertTrue(description.contains("campaign: summer-sale"))
        XCTAssertTrue(description.contains("channel: facebook"))
    }

    func testLinkDataDictionaryAccessor() {
        let nestedDict: AnyCodable = ["nested_key": "nested_value", "count": 42]
        let linkData = LinkData(
            parameters: ["dict_key": nestedDict]
        )

        let result = linkData.dictionary(forKey: "dict_key")
        XCTAssertNotNil(result)
        XCTAssertEqual(result?["nested_key"] as? String, "nested_value")
        XCTAssertEqual(result?["count"] as? Int, 42)
        XCTAssertNil(linkData.dictionary(forKey: "nonexistent"))
    }

    func testLinkDataArrayAccessor() {
        let array: AnyCodable = ["item1", "item2", 42]
        let linkData = LinkData(
            parameters: ["array_key": array]
        )

        let result = linkData.array(forKey: "array_key")
        XCTAssertNotNil(result)
        XCTAssertEqual(result?.count, 3)
        XCTAssertEqual(result?[0] as? String, "item1")
        XCTAssertEqual(result?[2] as? Int, 42)
        XCTAssertNil(linkData.array(forKey: "nonexistent"))
    }

    func testLinkDataRawDataProperty() {
        let rawData: [String: AnyCodable] = [
            "server_key": AnyCodable("server_value"),
            "data_id": AnyCodable(12345),
        ]
        let linkData = LinkData(
            url: URL(string: "https://test.app.link/test")!,
            rawData: rawData
        )

        XCTAssertEqual(linkData.rawData.count, 2)
        XCTAssertEqual(linkData.rawData["server_key"]?.value as? String, "server_value")
        XCTAssertEqual(linkData.rawData["data_id"]?.value as? Int, 12345)
    }

    func testLinkDataEquatable() {
        let linkData1 = LinkData(
            url: URL(string: "https://test.app.link/abc")!,
            isClicked: true,
            campaign: "test-campaign",
            channel: "test-channel"
        )

        let linkData2 = LinkData(
            url: URL(string: "https://test.app.link/abc")!,
            isClicked: true,
            campaign: "test-campaign",
            channel: "test-channel"
        )

        let linkData3 = LinkData(
            url: URL(string: "https://test.app.link/different")!,
            isClicked: false,
            campaign: "other-campaign"
        )

        XCTAssertEqual(linkData1, linkData2)
        XCTAssertNotEqual(linkData1, linkData3)
    }

    func testLinkDataDescriptionWithNoParams() {
        let linkData = LinkData()

        let description = linkData.description
        XCTAssertTrue(description.contains("LinkData"))
        XCTAssertFalse(description.contains("clicked"))
        XCTAssertFalse(description.contains("campaign"))
        XCTAssertFalse(description.contains("params"))
    }

    // MARK: - InitializationOptions Tests

    func testInitializationOptionsDefaults() {
        let options = InitializationOptions()

        XCTAssertNil(options.url)
        XCTAssertNil(options.sceneIdentifier)
        XCTAssertFalse(options.delayInitialization)
        XCTAssertFalse(options.disableAutomaticSessionTracking)
        XCTAssertTrue(options.checkPasteboardOnInstall)
        XCTAssertNil(options.referralParams)
        XCTAssertNil(options.sourceApplication)
    }

    func testInitializationOptionsBuilderPattern() {
        let url = URL(string: "https://test.app.link/abc")!
        let options = InitializationOptions()
            .with(url: url)
            .with(sceneIdentifier: "scene-123")
            .with(delayInitialization: true)
            .with(disableAutomaticSessionTracking: true)
            .with(checkPasteboardOnInstall: false)
            .with(referralParams: ["ref": "test"])
            .with(sourceApplication: "com.test.app")

        XCTAssertEqual(options.url, url)
        XCTAssertEqual(options.sceneIdentifier, "scene-123")
        XCTAssertTrue(options.delayInitialization)
        XCTAssertTrue(options.disableAutomaticSessionTracking)
        XCTAssertFalse(options.checkPasteboardOnInstall)
        XCTAssertEqual(options.referralParams, ["ref": "test"])
        XCTAssertEqual(options.sourceApplication, "com.test.app")
    }

    func testInitializationOptionsEquatable() {
        let url = URL(string: "https://test.app.link/abc")!

        var options1 = InitializationOptions()
        options1.url = url
        options1.sceneIdentifier = "scene-123"

        var options2 = InitializationOptions()
        options2.url = url
        options2.sceneIdentifier = "scene-123"

        XCTAssertEqual(options1, options2)

        options2.sceneIdentifier = "different"
        XCTAssertNotEqual(options1, options2)
    }

    // MARK: - BranchError Tests

    func testBranchErrorCodes() {
        XCTAssertEqual(BranchError.invalidConfiguration("test").errorCode, 1001)
        XCTAssertEqual(BranchError.notInitialized.errorCode, 1002)
        XCTAssertEqual(BranchError.alreadyInitialized.errorCode, 1003)
        XCTAssertEqual(BranchError.networkError("test").errorCode, 2001)
        XCTAssertEqual(BranchError.timeout.errorCode, 2002)
        XCTAssertEqual(BranchError.serverError(statusCode: 500, message: nil).errorCode, 2003)
        XCTAssertEqual(BranchError.invalidResponse.errorCode, 2004)
        XCTAssertEqual(BranchError.invalidStateTransition(from: "a", to: "b").errorCode, 3001)
        XCTAssertEqual(BranchError.sessionRequired.errorCode, 3002)
        XCTAssertEqual(BranchError.invalidURL("test").errorCode, 4001)
        XCTAssertEqual(BranchError.noURLProvided.errorCode, 4002)
        XCTAssertEqual(BranchError.invalidUserActivity.errorCode, 4004)
        XCTAssertEqual(BranchError.invalidIdentity("test").errorCode, 5001)
    }

    func testBranchErrorDescriptions() {
        XCTAssertTrue(BranchError.notInitialized.errorDescription?.contains("not initialized") ?? false)
        XCTAssertTrue(BranchError.sessionRequired.errorDescription?.contains("requires an initialized session") ?? false)
        XCTAssertTrue(BranchError.timeout.errorDescription?.contains("timed out") ?? false)
        XCTAssertTrue(BranchError.invalidUserActivity.errorDescription?.contains("Invalid user activity") ?? false)
    }

    func testBranchErrorDomain() {
        XCTAssertEqual(BranchError.errorDomain, "io.branch.sdk")
    }

    func testBranchErrorEquatable() {
        XCTAssertEqual(BranchError.sessionRequired, BranchError.sessionRequired)
        XCTAssertEqual(BranchError.timeout, BranchError.timeout)
        XCTAssertNotEqual(BranchError.sessionRequired, BranchError.timeout)
    }

    func testBranchErrorServerErrorDescription() {
        let errorWithMessage = BranchError.serverError(statusCode: 500, message: "Internal Server Error")
        XCTAssertTrue(errorWithMessage.errorDescription?.contains("500") ?? false)
        XCTAssertTrue(errorWithMessage.errorDescription?.contains("Internal Server Error") ?? false)

        let errorWithoutMessage = BranchError.serverError(statusCode: 404, message: nil)
        XCTAssertTrue(errorWithoutMessage.errorDescription?.contains("404") ?? false)
    }

    func testBranchErrorLinkCreationFailed() {
        let error = BranchError.linkCreationFailed("Network unavailable")
        XCTAssertEqual(error.errorCode, 4003)
        XCTAssertTrue(error.errorDescription?.contains("Failed to create link") ?? false)
        XCTAssertTrue(error.errorDescription?.contains("Network unavailable") ?? false)
    }

    func testBranchErrorInvalidEvent() {
        let error = BranchError.invalidEvent("Event name is empty")
        XCTAssertEqual(error.errorCode, 6001)
        XCTAssertTrue(error.errorDescription?.contains("Invalid event") ?? false)
        XCTAssertTrue(error.errorDescription?.contains("Event name is empty") ?? false)
    }

    func testBranchErrorEventTrackingFailed() {
        let error = BranchError.eventTrackingFailed("Server rejected event")
        XCTAssertEqual(error.errorCode, 6002)
        XCTAssertTrue(error.errorDescription?.contains("Failed to track event") ?? false)
        XCTAssertTrue(error.errorDescription?.contains("Server rejected event") ?? false)
    }

    func testBranchErrorStorageError() {
        let error = BranchError.storageError("Failed to write to disk")
        XCTAssertEqual(error.errorCode, 7001)
        XCTAssertTrue(error.errorDescription?.contains("Storage error") ?? false)
        XCTAssertTrue(error.errorDescription?.contains("Failed to write to disk") ?? false)
    }

    func testBranchErrorUnknown() {
        let error = BranchError.unknown("Unexpected condition")
        XCTAssertEqual(error.errorCode, 9001)
        XCTAssertTrue(error.errorDescription?.contains("Unknown error") ?? false)
        XCTAssertTrue(error.errorDescription?.contains("Unexpected condition") ?? false)
    }

    func testBranchErrorUnderlying() {
        let underlyingError = NSError(domain: "TestDomain", code: 42, userInfo: [NSLocalizedDescriptionKey: "Underlying issue"])
        let error = BranchError.underlying(underlyingError)
        XCTAssertEqual(error.errorCode, 9002)
        XCTAssertTrue(error.errorDescription?.contains("Underlying error") ?? false)
        XCTAssertTrue(error.errorDescription?.contains("Underlying issue") ?? false)
    }

    func testBranchErrorUserInfo() {
        let error = BranchError.sessionRequired
        let userInfo = error.errorUserInfo

        XCTAssertNotNil(userInfo[NSLocalizedDescriptionKey])
        let description = userInfo[NSLocalizedDescriptionKey] as? String
        XCTAssertEqual(description, error.errorDescription)
    }

    func testBranchErrorAllCodes() {
        // Configuration errors (1xxx)
        XCTAssertEqual(BranchError.invalidConfiguration("test").errorCode, 1001)
        XCTAssertEqual(BranchError.notInitialized.errorCode, 1002)
        XCTAssertEqual(BranchError.alreadyInitialized.errorCode, 1003)

        // Network errors (2xxx)
        XCTAssertEqual(BranchError.networkError("test").errorCode, 2001)
        XCTAssertEqual(BranchError.timeout.errorCode, 2002)
        XCTAssertEqual(BranchError.serverError(statusCode: 500, message: nil).errorCode, 2003)
        XCTAssertEqual(BranchError.invalidResponse.errorCode, 2004)

        // State errors (3xxx)
        XCTAssertEqual(BranchError.invalidStateTransition(from: "a", to: "b").errorCode, 3001)
        XCTAssertEqual(BranchError.sessionRequired.errorCode, 3002)

        // Link errors (4xxx)
        XCTAssertEqual(BranchError.invalidURL("test").errorCode, 4001)
        XCTAssertEqual(BranchError.noURLProvided.errorCode, 4002)
        XCTAssertEqual(BranchError.linkCreationFailed("test").errorCode, 4003)
        XCTAssertEqual(BranchError.invalidUserActivity.errorCode, 4004)

        // Identity errors (5xxx)
        XCTAssertEqual(BranchError.invalidIdentity("test").errorCode, 5001)

        // Event errors (6xxx)
        XCTAssertEqual(BranchError.invalidEvent("test").errorCode, 6001)
        XCTAssertEqual(BranchError.eventTrackingFailed("test").errorCode, 6002)

        // Storage errors (7xxx)
        XCTAssertEqual(BranchError.storageError("test").errorCode, 7001)

        // General errors (9xxx)
        XCTAssertEqual(BranchError.unknown("test").errorCode, 9001)
        XCTAssertEqual(BranchError.underlying(NSError(domain: "", code: 0)).errorCode, 9002)
    }

    func testBranchErrorDescriptionsContainExpectedText() {
        // Test all error descriptions contain expected text
        XCTAssertTrue(BranchError.invalidConfiguration("test").errorDescription?.contains("Invalid configuration") ?? false)
        XCTAssertTrue(BranchError.notInitialized.errorDescription?.contains("not initialized") ?? false)
        XCTAssertTrue(BranchError.alreadyInitialized.errorDescription?.contains("already initialized") ?? false)
        XCTAssertTrue(BranchError.networkError("test").errorDescription?.contains("Network error") ?? false)
        XCTAssertTrue(BranchError.timeout.errorDescription?.contains("timed out") ?? false)
        XCTAssertTrue(BranchError.invalidResponse.errorDescription?.contains("Invalid response") ?? false)
        XCTAssertTrue(BranchError.invalidStateTransition(from: "a", to: "b").errorDescription?.contains("Invalid state transition") ?? false)
        XCTAssertTrue(BranchError.sessionRequired.errorDescription?.contains("requires an initialized session") ?? false)
        XCTAssertTrue(BranchError.invalidURL("test").errorDescription?.contains("Invalid URL") ?? false)
        XCTAssertTrue(BranchError.noURLProvided.errorDescription?.contains("No URL provided") ?? false)
        XCTAssertTrue(BranchError.invalidUserActivity.errorDescription?.contains("Invalid user activity") ?? false)
        XCTAssertTrue(BranchError.invalidIdentity("test").errorDescription?.contains("Invalid identity") ?? false)
    }
}
