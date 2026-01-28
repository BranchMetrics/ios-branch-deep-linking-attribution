//
//  BranchError.swift
//  Branch iOS SDK - Modern Swift Implementation
//
//  Copyright © 2026 Branch Metrics. All rights reserved.
//  SPDX-License-Identifier: MIT
//

import Foundation

// MARK: - BranchError

/// Errors that can occur during Branch SDK operations.
///
/// All errors are strongly typed for better error handling and debugging.
public enum BranchError: Error, Sendable, Equatable {
    // MARK: - Configuration Errors

    /// Invalid SDK configuration
    case invalidConfiguration(String)

    /// SDK not initialized
    case notInitialized

    /// SDK already initialized
    case alreadyInitialized

    // MARK: - Network Errors

    /// Network request failed
    case networkError(String)

    /// Network request timed out
    case timeout

    /// Server returned an error
    case serverError(statusCode: Int, message: String?)

    /// Invalid response from server
    case invalidResponse

    // MARK: - State Errors

    /// Invalid state transition
    case invalidStateTransition(from: String, to: String)

    /// Operation requires initialized session
    case sessionRequired

    // MARK: - Link Errors

    /// Invalid URL provided
    case invalidURL(String)

    /// No URL provided when required
    case noURLProvided

    /// Link creation failed
    case linkCreationFailed(String)

    // MARK: - User Activity Errors

    /// Invalid user activity
    case invalidUserActivity

    // MARK: - Identity Errors

    /// Invalid identity
    case invalidIdentity(String)

    // MARK: - Event Errors

    /// Invalid event
    case invalidEvent(String)

    /// Event tracking failed
    case eventTrackingFailed(String)

    // MARK: - Storage Errors

    /// Storage operation failed
    case storageError(String)

    // MARK: - General Errors

    /// Unknown error
    case unknown(String)

    /// Underlying system error
    case underlying(any Error)
}

// MARK: LocalizedError

extension BranchError: LocalizedError {
    public var errorDescription: String? {
        switch self {
        case let .invalidConfiguration(message):
            return "Invalid configuration: \(message)"
        case .notInitialized:
            return "Branch SDK is not initialized. Call Branch.shared.initialize() first."
        case .alreadyInitialized:
            return "Branch SDK is already initialized."
        case let .networkError(message):
            return "Network error: \(message)"
        case .timeout:
            return "Network request timed out"
        case let .serverError(statusCode, message):
            if let message {
                return "Server error (\(statusCode)): \(message)"
            }
            return "Server error: HTTP \(statusCode)"
        case .invalidResponse:
            return "Invalid response from server"
        case let .invalidStateTransition(from, to):
            return "Invalid state transition from \(from) to \(to)"
        case .sessionRequired:
            return "This operation requires an initialized session"
        case let .invalidURL(url):
            return "Invalid URL: \(url)"
        case .noURLProvided:
            return "No URL provided"
        case let .linkCreationFailed(message):
            return "Failed to create link: \(message)"
        case .invalidUserActivity:
            return "Invalid user activity"
        case let .invalidIdentity(message):
            return "Invalid identity: \(message)"
        case let .invalidEvent(message):
            return "Invalid event: \(message)"
        case let .eventTrackingFailed(message):
            return "Failed to track event: \(message)"
        case let .storageError(message):
            return "Storage error: \(message)"
        case let .unknown(message):
            return "Unknown error: \(message)"
        case let .underlying(error):
            return "Underlying error: \(error.localizedDescription)"
        }
    }
}

// MARK: CustomNSError

extension BranchError: CustomNSError {
    public static var errorDomain: String {
        "io.branch.sdk"
    }

    public var errorCode: Int {
        switch self {
        case .invalidConfiguration: 1001
        case .notInitialized: 1002
        case .alreadyInitialized: 1003
        case .networkError: 2001
        case .timeout: 2002
        case .serverError: 2003
        case .invalidResponse: 2004
        case .invalidStateTransition: 3001
        case .sessionRequired: 3002
        case .invalidURL: 4001
        case .noURLProvided: 4002
        case .linkCreationFailed: 4003
        case .invalidUserActivity: 4004
        case .invalidIdentity: 5001
        case .invalidEvent: 6001
        case .eventTrackingFailed: 6002
        case .storageError: 7001
        case .unknown: 9001
        case .underlying: 9002
        }
    }

    public var errorUserInfo: [String: Any] {
        [NSLocalizedDescriptionKey: errorDescription ?? "Unknown error"]
    }
}

// MARK: - Equatable

public extension BranchError {
    static func == (lhs: BranchError, rhs: BranchError) -> Bool {
        lhs.errorCode == rhs.errorCode && lhs.errorDescription == rhs.errorDescription
    }
}
