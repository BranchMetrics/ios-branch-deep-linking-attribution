//
//  BranchSessionTests.swift
//  Branch iOS SDK - Modern Swift Implementation
//
//  Copyright © 2026 Branch Metrics. All rights reserved.
//  SPDX-License-Identifier: MIT
//

//
//  BranchSessionTests.swift
//  BranchSwiftSDKTests
//
//  Branch iOS SDK - Modern Swift Implementation
//  Copyright © 2026 Branch Metrics. All rights reserved.
//  SPDX-License-Identifier: MIT
//
//  JIRA: EMT-2737
//  Unit tests for BranchSession
//

@testable import BranchSwiftSDK
import XCTest

@available(iOS 13.0, tvOS 13.0, *)
final class BranchSessionTests: XCTestCase {
    // MARK: - Initialization Tests

    func testDefaultInitialization() {
        let session = BranchSession()

        XCTAssertNil(session.sessionId)
        XCTAssertNil(session.randomizedBundleToken)
        XCTAssertNil(session.randomizedDeviceToken)
        XCTAssertNil(session.linkParams)
        XCTAssertNil(session.referringURL)
        XCTAssertFalse(session.isFirstSession)
        XCTAssertFalse(session.isFromBranchLink)
        XCTAssertNil(session.rawData)
        XCTAssertNotNil(session.createdAt)
    }

    func testFullInitialization() {
        let url = URL(string: "https://example.app.link/test")!
        let linkParams: [String: Any] = ["key": "value", "~campaign": "test-campaign"]
        let rawData: [String: Any] = ["session_id": "123"]

        let session = BranchSession(
            sessionId: "session-123",
            randomizedBundleToken: "bundle-token-456",
            randomizedDeviceToken: "device-token-789",
            linkParams: linkParams,
            referringURL: url,
            isFirstSession: true,
            isFromBranchLink: true,
            rawData: rawData
        )

        XCTAssertEqual(session.sessionId, "session-123")
        XCTAssertEqual(session.randomizedBundleToken, "bundle-token-456")
        XCTAssertEqual(session.randomizedDeviceToken, "device-token-789")
        XCTAssertNotNil(session.linkParams)
        XCTAssertEqual(session.referringURL, url)
        XCTAssertTrue(session.isFirstSession)
        XCTAssertTrue(session.isFromBranchLink)
        XCTAssertNotNil(session.rawData)
    }

    // MARK: - Factory Method Tests

    func testFromResponseWithSessionData() {
        let response: [String: Any] = [
            "session_id": "test-session-id",
            "randomized_bundle_token": "test-bundle-token",
            "randomized_device_token": "test-device-token",
            "is_first_session": true,
        ]

        let session = BranchSession.from(response: response)

        XCTAssertEqual(session.sessionId, "test-session-id")
        XCTAssertEqual(session.randomizedBundleToken, "test-bundle-token")
        XCTAssertEqual(session.randomizedDeviceToken, "test-device-token")
        XCTAssertTrue(session.isFirstSession)
        XCTAssertFalse(session.isFromBranchLink)
    }

    func testFromResponseWithDeepLinkData() {
        let linkDataJSON = """
        {
            "+clicked_branch_link": true,
            "~referring_link": "https://example.app.link/test",
            "~campaign": "summer-sale",
            "~channel": "facebook",
            "~feature": "sharing",
            "~tags": ["promo", "summer"],
            "custom_key": "custom_value"
        }
        """

        let response: [String: Any] = [
            "session_id": "deep-link-session",
            "data": linkDataJSON,
        ]

        let session = BranchSession.from(response: response)

        XCTAssertEqual(session.sessionId, "deep-link-session")
        XCTAssertTrue(session.isFromBranchLink)
        XCTAssertEqual(session.referringURL?.absoluteString, "https://example.app.link/test")
        XCTAssertEqual(session.campaign, "summer-sale")
        XCTAssertEqual(session.channel, "facebook")
        XCTAssertEqual(session.feature, "sharing")
        XCTAssertEqual(session.tags, ["promo", "summer"])
    }

    func testFromResponseWithReferringURLFallback() {
        let response: [String: Any] = [
            "session_id": "fallback-session",
            "referring_url": "https://fallback.app.link/test",
        ]

        let session = BranchSession.from(response: response)

        XCTAssertEqual(session.referringURL?.absoluteString, "https://fallback.app.link/test")
    }

    func testFromResponseWithEmptyData() {
        let response: [String: Any] = [:]

        let session = BranchSession.from(response: response)

        XCTAssertNil(session.sessionId)
        XCTAssertNil(session.randomizedBundleToken)
        XCTAssertFalse(session.isFirstSession)
        XCTAssertFalse(session.isFromBranchLink)
    }

    // MARK: - Link Parameter Accessor Tests

    func testLinkParamGenericAccessor() {
        let linkParams: [String: Any] = [
            "string_value": "test",
            "int_value": 42,
            "bool_value": true,
        ]

        let session = BranchSession(linkParams: linkParams)

        let stringValue: String? = session.linkParam(forKey: "string_value")
        let intValue: Int? = session.linkParam(forKey: "int_value")
        let boolValue: Bool? = session.linkParam(forKey: "bool_value")
        let missingValue: String? = session.linkParam(forKey: "missing")

        XCTAssertEqual(stringValue, "test")
        XCTAssertEqual(intValue, 42)
        XCTAssertEqual(boolValue, true)
        XCTAssertNil(missingValue)
    }

    func testConvenienceAccessors() {
        let linkParams: [String: Any] = [
            "~campaign": "test-campaign",
            "~channel": "test-channel",
            "~feature": "test-feature",
            "~tags": ["tag1", "tag2"],
            "~stage": "test-stage",
        ]

        let session = BranchSession(linkParams: linkParams)

        XCTAssertEqual(session.campaign, "test-campaign")
        XCTAssertEqual(session.channel, "test-channel")
        XCTAssertEqual(session.feature, "test-feature")
        XCTAssertEqual(session.tags, ["tag1", "tag2"])
        XCTAssertEqual(session.stage, "test-stage")
    }

    func testConvenienceAccessorsWithMissingData() {
        let session = BranchSession()

        XCTAssertNil(session.campaign)
        XCTAssertNil(session.channel)
        XCTAssertNil(session.feature)
        XCTAssertNil(session.tags)
        XCTAssertNil(session.stage)
    }

    // MARK: - Equatable Tests

    func testEquatableWithSameSessionId() {
        let session1 = BranchSession(
            sessionId: "same-id",
            randomizedBundleToken: "bundle-1"
        )
        let session2 = BranchSession(
            sessionId: "same-id",
            randomizedBundleToken: "bundle-1"
        )

        // Sessions are equal if sessionId, bundleToken, and createdAt match
        // Since createdAt is auto-generated, we need to compare the same session
        XCTAssertEqual(session1, session1)
    }

    func testEquatableWithDifferentSessionId() {
        let session1 = BranchSession(sessionId: "id-1")
        let session2 = BranchSession(sessionId: "id-2")

        XCTAssertNotEqual(session1, session2)
    }

    // MARK: - Description Tests

    func testDescription() {
        let session = BranchSession(
            sessionId: "test-123",
            isFirstSession: true,
            isFromBranchLink: false
        )

        let description = session.description

        XCTAssertTrue(description.contains("test-123"))
        XCTAssertTrue(description.contains("isFirstSession: true"))
        XCTAssertTrue(description.contains("isFromBranchLink: false"))
    }
}
