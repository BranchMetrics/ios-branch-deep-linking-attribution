//
//  BranchErrorTests.swift
//  BranchSwiftSDKTests
//
//  Branch iOS SDK - Modern Swift Implementation
//  Copyright © 2026 Branch Metrics. All rights reserved.
//  SPDX-License-Identifier: MIT
//
//  JIRA: EMT-2737
//  Unit tests for BranchError
//

import XCTest

@testable import BranchSwiftSDK

@available(iOS 13.0, tvOS 13.0, *)
final class BranchErrorTests: XCTestCase {
    // MARK: - Error Description Tests

    func testNotInitializedDescription() {
        let error = BranchError.notInitialized
        XCTAssertEqual(
            error.errorDescription,
            "Branch SDK not initialized. Call initialize() first."
        )
    }

    func testInitializationInProgressDescription() {
        let error = BranchError.initializationInProgress
        XCTAssertEqual(
            error.errorDescription,
            "Branch SDK initialization is already in progress."
        )
    }

    func testInitializationFailedDescription() {
        let error = BranchError.initializationFailed(reason: "Network timeout")
        XCTAssertEqual(
            error.errorDescription,
            "Branch SDK initialization failed: Network timeout"
        )
    }

    func testInvalidBranchKeyDescription() {
        let error = BranchError.invalidBranchKey("key_test_xxx")
        XCTAssertEqual(
            error.errorDescription,
            "Invalid Branch key: key_test_xxx"
        )
    }

    func testMissingConfigurationDescription() {
        let error = BranchError.missingConfiguration("Branch key required")
        XCTAssertEqual(
            error.errorDescription,
            "Missing required configuration: Branch key required"
        )
    }

    func testNetworkErrorWithStatusCodeDescription() {
        let error = BranchError.networkError(statusCode: 500, message: "Server error")
        XCTAssertEqual(
            error.errorDescription,
            "Network error (HTTP 500): Server error"
        )
    }

    func testNetworkErrorWithoutStatusCodeDescription() {
        let error = BranchError.networkError(statusCode: nil, message: "Connection failed")
        XCTAssertEqual(
            error.errorDescription,
            "Network error: Connection failed"
        )
    }

    func testTimeoutDescription() {
        let error = BranchError.timeout
        XCTAssertEqual(error.errorDescription, "Request timed out.")
    }

    func testNoConnectivityDescription() {
        let error = BranchError.noConnectivity
        XCTAssertEqual(error.errorDescription, "No network connectivity available.")
    }

    func testDnsBlockedDescription() {
        let error = BranchError.dnsBlocked
        XCTAssertEqual(
            error.errorDescription,
            "Request blocked by DNS filtering (ad blocker detected)."
        )
    }

    func testVpnBlockedDescription() {
        let error = BranchError.vpnBlocked
        XCTAssertEqual(error.errorDescription, "Request blocked by VPN filtering.")
    }

    func testServerErrorWithMessageDescription() {
        let error = BranchError.serverError(statusCode: 503, message: "Service unavailable")
        XCTAssertEqual(
            error.errorDescription,
            "Server error (HTTP 503): Service unavailable"
        )
    }

    func testServerErrorWithoutMessageDescription() {
        let error = BranchError.serverError(statusCode: 500, message: nil)
        XCTAssertEqual(error.errorDescription, "Server error (HTTP 500)")
    }

    func testInvalidURLWithURLDescription() {
        let error = BranchError.invalidURL("not-a-valid-url")
        XCTAssertEqual(error.errorDescription, "Invalid URL: not-a-valid-url")
    }

    func testInvalidURLWithoutURLDescription() {
        let error = BranchError.invalidURL(nil)
        XCTAssertEqual(error.errorDescription, "Invalid URL provided.")
    }

    func testNoURLProvidedDescription() {
        let error = BranchError.noURLProvided
        XCTAssertEqual(
            error.errorDescription,
            "No URL provided for deep link handling."
        )
    }

    func testInvalidUserActivityDescription() {
        let error = BranchError.invalidUserActivity
        XCTAssertEqual(
            error.errorDescription,
            "Invalid NSUserActivity for deep link handling."
        )
    }

    func testDeepLinkParsingFailedDescription() {
        let error = BranchError.deepLinkParsingFailed("Invalid JSON")
        XCTAssertEqual(
            error.errorDescription,
            "Deep link parsing failed: Invalid JSON"
        )
    }

    func testInvalidStateTransitionDescription() {
        let error = BranchError.invalidStateTransition(
            from: "uninitialized",
            to: "initialized"
        )
        XCTAssertEqual(
            error.errorDescription,
            "Invalid state transition from uninitialized to initialized."
        )
    }

    func testSessionExpiredDescription() {
        let error = BranchError.sessionExpired
        XCTAssertEqual(error.errorDescription, "Session has expired or is invalid.")
    }

    func testDuplicateRequestDescription() {
        let error = BranchError.duplicateRequest
        XCTAssertEqual(error.errorDescription, "Duplicate request detected.")
    }

    func testTrackingDisabledDescription() {
        let error = BranchError.trackingDisabled
        XCTAssertEqual(
            error.errorDescription,
            "Tracking is disabled by user or system settings."
        )
    }

    func testSpotlightNotAvailableDescription() {
        let error = BranchError.spotlightNotAvailable
        XCTAssertEqual(
            error.errorDescription,
            "Spotlight indexing is not available on this device."
        )
    }

    func testSpotlightInvalidIdentifierDescription() {
        let error = BranchError.spotlightInvalidIdentifier
        XCTAssertEqual(
            error.errorDescription,
            "Invalid Spotlight content identifier."
        )
    }

    func testSpotlightTitleRequiredDescription() {
        let error = BranchError.spotlightTitleRequired
        XCTAssertEqual(
            error.errorDescription,
            "Spotlight content requires a title."
        )
    }

    func testQrCodeGenerationFailedDescription() {
        let error = BranchError.qrCodeGenerationFailed("Invalid data")
        XCTAssertEqual(
            error.errorDescription,
            "QR code generation failed: Invalid data"
        )
    }

    func testGeneralDescription() {
        let error = BranchError.general("Something went wrong")
        XCTAssertEqual(
            error.errorDescription,
            "Branch SDK error: Something went wrong"
        )
    }

    func testUnknownWithMessageDescription() {
        let error = BranchError.unknown("Unexpected error")
        XCTAssertEqual(error.errorDescription, "Unknown error: Unexpected error")
    }

    func testUnknownWithoutMessageDescription() {
        let error = BranchError.unknown(nil)
        XCTAssertEqual(error.errorDescription, "An unknown error occurred.")
    }

    // MARK: - Error Code Mapping Tests

    func testNotInitializedErrorCode() {
        let error = BranchError.notInitialized
        XCTAssertEqual(error.errorCode, 1000)
    }

    func testInitializationInProgressErrorCode() {
        let error = BranchError.initializationInProgress
        XCTAssertEqual(error.errorCode, 1000)
    }

    func testInitializationFailedErrorCode() {
        let error = BranchError.initializationFailed(reason: "Test")
        XCTAssertEqual(error.errorCode, 1000)
    }

    func testDuplicateRequestErrorCode() {
        let error = BranchError.duplicateRequest
        XCTAssertEqual(error.errorCode, 1001)
    }

    func testInvalidBranchKeyErrorCode() {
        let error = BranchError.invalidBranchKey("test")
        XCTAssertEqual(error.errorCode, 1003)
    }

    func testMissingConfigurationErrorCode() {
        let error = BranchError.missingConfiguration("test")
        XCTAssertEqual(error.errorCode, 1003)
    }

    func testInvalidURLErrorCode() {
        let error = BranchError.invalidURL("test")
        XCTAssertEqual(error.errorCode, 1003)
    }

    func testNoURLProvidedErrorCode() {
        let error = BranchError.noURLProvided
        XCTAssertEqual(error.errorCode, 1003)
    }

    func testInvalidUserActivityErrorCode() {
        let error = BranchError.invalidUserActivity
        XCTAssertEqual(error.errorCode, 1003)
    }

    func testServerErrorErrorCode() {
        let error = BranchError.serverError(statusCode: 500, message: nil)
        XCTAssertEqual(error.errorCode, 1004)
    }

    func testNetworkErrorErrorCode() {
        let error = BranchError.networkError(statusCode: nil, message: "Test")
        XCTAssertEqual(error.errorCode, 1007)
    }

    func testTimeoutErrorCode() {
        let error = BranchError.timeout
        XCTAssertEqual(error.errorCode, 1007)
    }

    func testNoConnectivityErrorCode() {
        let error = BranchError.noConnectivity
        XCTAssertEqual(error.errorCode, 1007)
    }

    func testSpotlightNotAvailableErrorCode() {
        let error = BranchError.spotlightNotAvailable
        XCTAssertEqual(error.errorCode, 1010)
    }

    func testSpotlightTitleRequiredErrorCode() {
        let error = BranchError.spotlightTitleRequired
        XCTAssertEqual(error.errorCode, 1011)
    }

    func testSpotlightInvalidIdentifierErrorCode() {
        let error = BranchError.spotlightInvalidIdentifier
        XCTAssertEqual(error.errorCode, 1013)
    }

    func testTrackingDisabledErrorCode() {
        let error = BranchError.trackingDisabled
        XCTAssertEqual(error.errorCode, 1015)
    }

    func testDnsBlockedErrorCode() {
        let error = BranchError.dnsBlocked
        XCTAssertEqual(error.errorCode, 1017)
    }

    func testVpnBlockedErrorCode() {
        let error = BranchError.vpnBlocked
        XCTAssertEqual(error.errorCode, 1018)
    }

    func testGeneralErrorCode() {
        let error = BranchError.general("Test")
        XCTAssertEqual(error.errorCode, 1016)
    }

    func testUnknownErrorCode() {
        let error = BranchError.unknown(nil)
        XCTAssertEqual(error.errorCode, 1016)
    }

    // MARK: - NSError Conversion Tests

    func testFromNSErrorInitError() {
        let nsError = NSError(
            domain: "io.branch.sdk.error",
            code: 1000,
            userInfo: [NSLocalizedDescriptionKey: "Init failed"]
        )

        let branchError = BranchError.from(nsError: nsError)

        if case let .initializationFailed(reason) = branchError {
            XCTAssertEqual(reason, "Init failed")
        } else {
            XCTFail("Expected initializationFailed error")
        }
    }

    func testFromNSErrorDuplicateRequest() {
        let nsError = NSError(
            domain: "io.branch.sdk.error",
            code: 1001,
            userInfo: nil
        )

        let branchError = BranchError.from(nsError: nsError)

        XCTAssertEqual(branchError, .duplicateRequest)
    }

    func testFromNSErrorNetworkError() {
        let nsError = NSError(
            domain: "io.branch.sdk.error",
            code: 1007,
            userInfo: [NSLocalizedDescriptionKey: "Network failed"]
        )

        let branchError = BranchError.from(nsError: nsError)

        if case let .networkError(statusCode, message) = branchError {
            XCTAssertNil(statusCode)
            XCTAssertEqual(message, "Network failed")
        } else {
            XCTFail("Expected networkError error")
        }
    }

    func testFromNSErrorSpotlightErrors() {
        XCTAssertEqual(
            BranchError.from(nsError: NSError(domain: "", code: 1010, userInfo: nil)),
            .spotlightNotAvailable
        )
        XCTAssertEqual(
            BranchError.from(nsError: NSError(domain: "", code: 1011, userInfo: nil)),
            .spotlightTitleRequired
        )
        XCTAssertEqual(
            BranchError.from(nsError: NSError(domain: "", code: 1013, userInfo: nil)),
            .spotlightInvalidIdentifier
        )
    }

    func testFromNSErrorTrackingDisabled() {
        let nsError = NSError(domain: "", code: 1015, userInfo: nil)
        XCTAssertEqual(BranchError.from(nsError: nsError), .trackingDisabled)
    }

    func testFromNSErrorDnsBlocked() {
        let nsError = NSError(domain: "", code: 1017, userInfo: nil)
        XCTAssertEqual(BranchError.from(nsError: nsError), .dnsBlocked)
    }

    func testFromNSErrorVpnBlocked() {
        let nsError = NSError(domain: "", code: 1018, userInfo: nil)
        XCTAssertEqual(BranchError.from(nsError: nsError), .vpnBlocked)
    }

    func testFromNSErrorUnknownCode() {
        let nsError = NSError(
            domain: "io.branch.sdk.error",
            code: 9999,
            userInfo: [NSLocalizedDescriptionKey: "Unknown error"]
        )

        let branchError = BranchError.from(nsError: nsError)

        if case let .unknown(message) = branchError {
            XCTAssertEqual(message, "Unknown error")
        } else {
            XCTFail("Expected unknown error")
        }
    }

    func testToNSError() {
        let branchError = BranchError.networkError(statusCode: 500, message: "Server error")

        let nsError = branchError.toNSError()

        XCTAssertEqual(nsError.domain, "io.branch.sdk.error")
        XCTAssertEqual(nsError.code, 1007)
        XCTAssertTrue(
            nsError.localizedDescription.contains("Network error")
        )
    }

    // MARK: - Equatable Tests

    func testEquatableSimpleErrors() {
        XCTAssertEqual(BranchError.notInitialized, BranchError.notInitialized)
        XCTAssertEqual(BranchError.timeout, BranchError.timeout)
        XCTAssertEqual(BranchError.noConnectivity, BranchError.noConnectivity)
        XCTAssertNotEqual(BranchError.timeout, BranchError.noConnectivity)
    }

    func testEquatableErrorsWithAssociatedValues() {
        XCTAssertEqual(
            BranchError.initializationFailed(reason: "Test"),
            BranchError.initializationFailed(reason: "Test")
        )
        XCTAssertNotEqual(
            BranchError.initializationFailed(reason: "Test1"),
            BranchError.initializationFailed(reason: "Test2")
        )

        XCTAssertEqual(
            BranchError.networkError(statusCode: 500, message: "Error"),
            BranchError.networkError(statusCode: 500, message: "Error")
        )
        XCTAssertNotEqual(
            BranchError.networkError(statusCode: 500, message: "Error"),
            BranchError.networkError(statusCode: 400, message: "Error")
        )
    }

    // MARK: - Description Tests

    func testCustomDescription() {
        let error = BranchError.timeout

        let description = error.description

        XCTAssertTrue(description.contains("BranchError"))
        XCTAssertTrue(description.contains("1007"))
        XCTAssertTrue(description.contains("timed out"))
    }

    // MARK: - Sendable Tests

    func testSendableConformance() async {
        let error = BranchError.networkError(statusCode: 500, message: "Test")

        // Pass error across actor boundary to verify Sendable
        let result = await withCheckedContinuation { continuation in
            Task {
                continuation.resume(returning: error)
            }
        }

        XCTAssertEqual(result, error)
    }
}
