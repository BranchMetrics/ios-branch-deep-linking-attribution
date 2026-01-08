//
//  BranchError.swift
//  BranchSDK
//
//  Branch iOS SDK - Modern Swift Implementation
//  Copyright © 2026 Branch Metrics. All rights reserved.
//  SPDX-License-Identifier: MIT
//
//  JIRA: EMT-2726
//  Typed error handling for SDK Modernization
//

import Foundation

// MARK: - Branch Error

/// Typed error enum for the Branch SDK.
///
/// Provides strongly-typed errors with associated values for detailed error context.
/// This is the modern Swift equivalent of the Objective-C `BNCErrorCode` enum.
@available(iOS 13.0, tvOS 13.0, *)
public enum BranchError: Error, Sendable, Equatable {
    // MARK: - Initialization Errors

    /// SDK not initialized. Call `initialize()` before using SDK features.
    case notInitialized

    /// SDK is currently initializing. Wait for initialization to complete.
    case initializationInProgress

    /// Initialization failed with the specified reason.
    case initializationFailed(reason: String)

    /// Invalid Branch key provided.
    case invalidBranchKey(String)

    /// Missing required configuration.
    case missingConfiguration(String)

    // MARK: - Network Errors

    /// Network request failed with underlying error.
    case networkError(statusCode: Int?, message: String)

    /// Request timed out.
    case timeout

    /// No network connectivity.
    case noConnectivity

    /// DNS blocking detected (ad blocker).
    case dnsBlocked

    /// VPN blocking detected.
    case vpnBlocked

    /// Server returned an error response.
    case serverError(statusCode: Int, message: String?)

    // MARK: - Deep Link Errors

    /// Invalid URL provided.
    case invalidURL(String?)

    /// No URL provided for deep link handling.
    case noURLProvided

    /// Invalid user activity for deep link handling.
    case invalidUserActivity

    /// Deep link parsing failed.
    case deepLinkParsingFailed(String)

    // MARK: - Session Errors

    /// Invalid state transition attempted.
    case invalidStateTransition(from: String, to: String)

    /// Session expired or invalid.
    case sessionExpired

    /// Duplicate session initialization request.
    case duplicateRequest

    // MARK: - Tracking Errors

    /// Tracking is disabled by user or system.
    case trackingDisabled

    // MARK: - Spotlight Errors

    /// Spotlight indexing not available.
    case spotlightNotAvailable

    /// Invalid Spotlight content identifier.
    case spotlightInvalidIdentifier

    /// Spotlight title is required.
    case spotlightTitleRequired

    // MARK: - QR Code Errors

    /// QR code generation failed.
    case qrCodeGenerationFailed(String)

    // MARK: - General Errors

    /// General SDK error with message.
    case general(String)

    /// Unknown error with description.
    case unknown(String?)
}

// MARK: - LocalizedError Conformance

@available(iOS 13.0, tvOS 13.0, *)
extension BranchError: LocalizedError {
    public var errorDescription: String? {
        switch self {
        case .notInitialized:
            return "Branch SDK not initialized. Call initialize() first."

        case .initializationInProgress:
            return "Branch SDK initialization is already in progress."

        case let .initializationFailed(reason):
            return "Branch SDK initialization failed: \(reason)"

        case let .invalidBranchKey(key):
            return "Invalid Branch key: \(key)"

        case let .missingConfiguration(detail):
            return "Missing required configuration: \(detail)"

        case let .networkError(statusCode, message):
            if let code = statusCode {
                return "Network error (HTTP \(code)): \(message)"
            }
            return "Network error: \(message)"

        case .timeout:
            return "Request timed out."

        case .noConnectivity:
            return "No network connectivity available."

        case .dnsBlocked:
            return "Request blocked by DNS filtering (ad blocker detected)."

        case .vpnBlocked:
            return "Request blocked by VPN filtering."

        case let .serverError(statusCode, message):
            if let msg = message {
                return "Server error (HTTP \(statusCode)): \(msg)"
            }
            return "Server error (HTTP \(statusCode))"

        case let .invalidURL(url):
            if let u = url {
                return "Invalid URL: \(u)"
            }
            return "Invalid URL provided."

        case .noURLProvided:
            return "No URL provided for deep link handling."

        case .invalidUserActivity:
            return "Invalid NSUserActivity for deep link handling."

        case let .deepLinkParsingFailed(reason):
            return "Deep link parsing failed: \(reason)"

        case let .invalidStateTransition(from, to):
            return "Invalid state transition from \(from) to \(to)."

        case .sessionExpired:
            return "Session has expired or is invalid."

        case .duplicateRequest:
            return "Duplicate request detected."

        case .trackingDisabled:
            return "Tracking is disabled by user or system settings."

        case .spotlightNotAvailable:
            return "Spotlight indexing is not available on this device."

        case .spotlightInvalidIdentifier:
            return "Invalid Spotlight content identifier."

        case .spotlightTitleRequired:
            return "Spotlight content requires a title."

        case let .qrCodeGenerationFailed(reason):
            return "QR code generation failed: \(reason)"

        case let .general(message):
            return "Branch SDK error: \(message)"

        case let .unknown(message):
            if let msg = message {
                return "Unknown error: \(msg)"
            }
            return "An unknown error occurred."
        }
    }
}

// MARK: - Error Code Mapping

@available(iOS 13.0, tvOS 13.0, *)
public extension BranchError {
    /// Maps the error to a numeric code compatible with legacy Objective-C error codes.
    var errorCode: Int {
        switch self {
        case .notInitialized, .initializationInProgress, .initializationFailed:
            return 1000 // BNCInitError
        case .duplicateRequest:
            return 1001 // BNCDuplicateResourceError
        case .invalidBranchKey, .missingConfiguration, .invalidURL, .noURLProvided, .invalidUserActivity:
            return 1003 // BNCBadRequestError
        case .serverError:
            return 1004 // BNCServerProblemError
        case .networkError, .timeout, .noConnectivity:
            return 1007 // BNCNetworkServiceInterfaceError
        case .spotlightNotAvailable:
            return 1010 // BNCSpotlightNotAvailableError
        case .spotlightTitleRequired:
            return 1011 // BNCSpotlightTitleError
        case .spotlightInvalidIdentifier:
            return 1013 // BNCSpotlightIdentifierError
        case .trackingDisabled:
            return 1015 // BNCTrackingDisabledError
        case .dnsBlocked:
            return 1017 // BNCDNSAdBlockerError
        case .vpnBlocked:
            return 1018 // BNCVPNAdBlockerError
        case .general, .unknown, .deepLinkParsingFailed, .invalidStateTransition, .sessionExpired, .qrCodeGenerationFailed:
            return 1016 // BNCGeneralError
        }
    }

    /// Creates a BranchError from a legacy Objective-C NSError.
    static func from(nsError: NSError) -> BranchError {
        let message = nsError.localizedDescription

        switch nsError.code {
        case 1000:
            return .initializationFailed(reason: message)
        case 1001:
            return .duplicateRequest
        case 1003:
            return .general(message)
        case 1004:
            return .serverError(statusCode: 500, message: message)
        case 1007:
            return .networkError(statusCode: nil, message: message)
        case 1010:
            return .spotlightNotAvailable
        case 1011:
            return .spotlightTitleRequired
        case 1013:
            return .spotlightInvalidIdentifier
        case 1015:
            return .trackingDisabled
        case 1017:
            return .dnsBlocked
        case 1018:
            return .vpnBlocked
        default:
            return .unknown(nsError.localizedDescription)
        }
    }

    /// Converts to NSError for Objective-C interoperability.
    func toNSError() -> NSError {
        NSError(
            domain: "io.branch.sdk.error",
            code: errorCode,
            userInfo: [NSLocalizedDescriptionKey: errorDescription ?? "Unknown Branch error"]
        )
    }
}

// MARK: - Debug Description

@available(iOS 13.0, tvOS 13.0, *)
extension BranchError: CustomStringConvertible {
    public var description: String {
        "BranchError(code: \(errorCode), message: \(errorDescription ?? "nil"))"
    }
}
