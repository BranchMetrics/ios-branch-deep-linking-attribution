//
//  BranchNetworkService.swift
//  Branch iOS SDK - Modern Swift Implementation
//
//  Copyright © 2026 Branch Metrics. All rights reserved.
//  SPDX-License-Identifier: MIT
//

import Foundation

// MARK: - BranchNetworkService Protocol

/// Protocol defining the network operations required by SessionManager.
///
/// This abstraction allows SessionManager to remain decoupled from the
/// underlying network implementation (BNCServerInterface).
@available(iOS 13.0, macOS 10.15, tvOS 13.0, watchOS 6.0, *)
public protocol BranchNetworkService: Sendable {
    /// Perform an install request (first session).
    /// - Parameter requestData: Dictionary of request parameters
    /// - Returns: Server response dictionary
    /// - Throws: Network or API errors
    func performInstall(requestData: [String: Any]) async throws -> [String: Any]

    /// Perform an open request (returning session).
    /// - Parameter requestData: Dictionary of request parameters
    /// - Returns: Server response dictionary
    /// - Throws: Network or API errors
    func performOpen(requestData: [String: Any]) async throws -> [String: Any]

    /// Set user identity.
    /// - Parameters:
    ///   - userId: The user identifier to set
    ///   - sessionId: Current session ID
    ///   - identityId: Current identity ID
    /// - Returns: Server response dictionary
    /// - Throws: Network or API errors
    func setIdentity(userId: String, sessionId: String, identityId: String) async throws -> [String: Any]

    /// Clear user identity (logout).
    /// - Parameters:
    ///   - sessionId: Current session ID
    ///   - identityId: Current identity ID
    /// - Returns: Server response dictionary
    /// - Throws: Network or API errors
    func logout(sessionId: String, identityId: String) async throws -> [String: Any]

    /// Resolve a deep link URL.
    /// - Parameters:
    ///   - url: The deep link URL to resolve
    ///   - sessionId: Current session ID
    /// - Returns: Link data dictionary
    /// - Throws: Network or API errors
    func resolveLink(url: URL, sessionId: String) async throws -> [String: Any]
}

// MARK: - Default Implementation

/// Default network service implementation that bridges to the Objective-C BNCServerInterface.
///
/// Uses dynamic invocation to avoid compile-time dependencies on Objective-C types,
/// which enables SPM compatibility.
///
/// The base URL is determined dynamically from BNCServerAPI to respect configurations
/// set via `Branch.setAPIUrl()`, EU servers, and tracking domains.
@available(iOS 13.0, macOS 10.15, tvOS 13.0, watchOS 6.0, *)
public final class DefaultBranchNetworkService: BranchNetworkService, @unchecked Sendable {
    // MARK: - Properties

    private let logger: any Logging

    // MARK: - Initialization

    public init() {
        logger = BranchLoggerAdapter.shared
    }

    // MARK: - Constants

    /// Constants for URL resolution and selector caching.
    private enum Constants {
        static let defaultURL = "https://api2.branch.io"
        static let sharedSelector = NSSelectorFromString("sharedInstance")
        static let installSelector = NSSelectorFromString("installServiceURL")
        static let branchKeySelector = NSSelectorFromString("branchKey")
    }

    // MARK: - Dynamic URL Resolution

    /// Get the base URL from BNCServerAPI, respecting custom URL configurations.
    ///
    /// This dynamically calls `[BNCServerAPI sharedInstance].installServiceURL` and extracts
    /// the base URL, ensuring we respect:
    /// - Custom API URL set via `Branch.setAPIUrl()`
    /// - EU server configuration
    /// - Tracking domain configuration
    private func getBaseURL() -> String {
        // Try to get installServiceURL from BNCServerAPI and extract base URL
        guard let serverAPIClass = NSClassFromString("BNCServerAPI") as? NSObject.Type else {
            log(.warning, "BNCServerAPI class not found, using default URL")
            return Constants.defaultURL
        }

        guard serverAPIClass.responds(to: Constants.sharedSelector),
              let sharedInstance = serverAPIClass.perform(Constants.sharedSelector)?.takeUnretainedValue() as? NSObject
        else {
            log(.warning, "BNCServerAPI.sharedInstance not available, using default URL")
            return Constants.defaultURL
        }

        // Get installServiceURL which includes the full URL with endpoint
        guard sharedInstance.responds(to: Constants.installSelector),
              let installURL = sharedInstance.perform(Constants.installSelector)?.takeUnretainedValue() as? String
        else {
            log(.warning, "installServiceURL not available, using default URL")
            return Constants.defaultURL
        }

        // Extract base URL by removing the endpoint suffix
        // installServiceURL returns something like "https://api.stage.branch.io/v1/install"
        if let range = installURL.range(of: "/v1/install") {
            let baseURL = String(installURL[..<range.lowerBound])
            log(.debug, "Using configured API base URL: \(baseURL)")
            return baseURL
        }

        log(.warning, "Could not parse installServiceURL, using default URL")
        return Constants.defaultURL
    }

    // MARK: - Private Logging Helper

    private func log(
        _ level: LogLevel,
        _ message: @autoclosure () -> String,
        file: String = #file,
        function: String = #function,
        line: Int = #line
    ) {
        logger.log(level, message(), file: file, function: function, line: line)
    }

    // MARK: - BranchNetworkService Implementation

    public func performInstall(requestData: [String: Any]) async throws -> [String: Any] {
        log(.debug, "performInstall - starting request")
        let response = try await performRequest(
            endpoint: "/v1/install",
            requestData: requestData
        )
        log(.debug, "performInstall - completed successfully")
        return response
    }

    public func performOpen(requestData: [String: Any]) async throws -> [String: Any] {
        log(.debug, "performOpen - starting request")
        let response = try await performRequest(
            endpoint: "/v1/open",
            requestData: requestData
        )
        log(.debug, "performOpen - completed successfully")
        return response
    }

    public func setIdentity(userId: String, sessionId: String, identityId: String) async throws -> [String: Any] {
        log(.debug, "setIdentity - starting request for userId: \(userId)")
        var requestData: [String: Any] = [
            "identity": userId,
            "session_id": sessionId,
            "identity_id": identityId,
        ]

        // Get branch key dynamically
        if let branchKey = getBranchKey() {
            requestData["branch_key"] = branchKey
        }

        let response = try await performRequest(
            endpoint: "/v1/profile",
            requestData: requestData
        )
        log(.debug, "setIdentity - completed successfully")
        return response
    }

    public func logout(sessionId: String, identityId: String) async throws -> [String: Any] {
        log(.debug, "logout - starting request for sessionId: \(sessionId)")
        var requestData: [String: Any] = [
            "session_id": sessionId,
            "identity_id": identityId,
        ]

        if let branchKey = getBranchKey() {
            requestData["branch_key"] = branchKey
        }

        let response = try await performRequest(
            endpoint: "/v1/logout",
            requestData: requestData
        )
        log(.debug, "logout - completed successfully")
        return response
    }

    public func resolveLink(url: URL, sessionId: String) async throws -> [String: Any] {
        log(.debug, "resolveLink - starting request for URL: \(url.absoluteString)")
        var requestData: [String: Any] = [
            "url": url.absoluteString,
            "session_id": sessionId,
        ]

        if let branchKey = getBranchKey() {
            requestData["branch_key"] = branchKey
        }

        let response = try await performRequest(
            endpoint: "/v1/url",
            requestData: requestData
        )
        log(.debug, "resolveLink - completed successfully")
        return response
    }

    // MARK: - Private Methods

    /// Get Branch key via dynamic invocation
    private func getBranchKey() -> String? {
        guard let branchClass = NSClassFromString("Branch") as? NSObject.Type else {
            return nil
        }

        guard branchClass.responds(to: Constants.branchKeySelector) else {
            return nil
        }

        return branchClass.perform(Constants.branchKeySelector)?.takeUnretainedValue() as? String
    }

    /// Perform network request using URLSession (pure Swift implementation)
    private func performRequest(
        endpoint: String,
        requestData: [String: Any]
    ) async throws -> [String: Any] {
        // Safely concatenate base URL and endpoint, handling missing slashes
        let baseURL = getBaseURL()
        let fullURL = endpoint.hasPrefix("/") ? baseURL + endpoint : baseURL + "/" + endpoint

        guard let url = URL(string: fullURL) else {
            log(.error, "performRequest - invalid URL: \(fullURL)")
            throw BranchError.networkError("Invalid URL: \(fullURL)")
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        // Add branch key to request if not present
        var mutableRequestData = requestData
        if mutableRequestData["branch_key"] == nil, let branchKey = getBranchKey() {
            mutableRequestData["branch_key"] = branchKey
        }

        // Serialize request body
        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: mutableRequestData)
        } catch {
            log(.error, "performRequest - JSON serialization failed: \(error.localizedDescription)")
            throw error
        }

        log(.debug, "performRequest - sending POST to \(endpoint)")

        // Log request data for debugging (only in debug builds)
        #if DEBUG
            if let jsonData = try? JSONSerialization.data(withJSONObject: mutableRequestData, options: .prettyPrinted),
               let jsonString = String(data: jsonData, encoding: .utf8)
            {
                log(.debug, "performRequest - request body:\n\(jsonString)")
            }
        #endif

        // Perform request
        let (data, response): (Data, URLResponse)
        do {
            (data, response) = try await URLSession.shared.data(for: request)
        } catch {
            log(.error, "performRequest - network request failed: \(error.localizedDescription)")
            throw BranchError.networkError(error.localizedDescription)
        }

        // Validate response
        guard let httpResponse = response as? HTTPURLResponse else {
            log(.error, "performRequest - invalid response type")
            throw BranchError.networkError("Invalid response type")
        }

        log(.debug, "performRequest - received HTTP \(httpResponse.statusCode) from \(endpoint)")

        // Log response data for debugging (only in debug builds)
        #if DEBUG
            if let responseString = String(data: data, encoding: .utf8) {
                log(.debug, "performRequest - response body:\n\(responseString)")
            }
        #endif

        // Parse response
        let responseData: [String: Any]
        if !data.isEmpty {
            guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any] else {
                log(.error, "performRequest - invalid JSON response")
                throw BranchError.networkError("Invalid JSON response")
            }
            responseData = json
        } else {
            responseData = [:]
        }

        // Check for server errors
        if httpResponse.statusCode >= 400 {
            let errorMessage = responseData["error"] as? String ?? "Server error"
            log(.error, "performRequest - server error \(httpResponse.statusCode): \(errorMessage)")
            throw BranchError.serverError(statusCode: httpResponse.statusCode, message: errorMessage)
        }

        return responseData
    }
}

// MARK: - Mock Implementation for Testing

/// Mock network service for testing purposes.
///
/// Provides configurable responses, failure simulation, call tracking,
/// and request capture for comprehensive test verification.
@available(iOS 13.0, macOS 10.15, tvOS 13.0, watchOS 6.0, *)
public final class MockBranchNetworkService: BranchNetworkService, @unchecked Sendable {
    // MARK: - Response Configuration

    public var installResponse: [String: Any] = [:]
    public var openResponse: [String: Any] = [:]
    public var identityResponse: [String: Any] = [:]
    public var logoutResponse: [String: Any] = [:]
    public var linkResponse: [String: Any] = [:]

    // MARK: - Failure Simulation

    public var shouldFail: Bool = false
    public var failureError: Error = BranchError.networkError("Mock network failure")

    /// Per-operation failure configuration (overrides shouldFail for specific operations)
    public var installShouldFail: Bool = false
    public var openShouldFail: Bool = false
    public var identityShouldFail: Bool = false
    public var logoutShouldFail: Bool = false
    public var linkShouldFail: Bool = false

    /// Per-operation error configuration
    public var installError: Error?
    public var openError: Error?
    public var identityError: Error?
    public var logoutError: Error?
    public var linkError: Error?

    // MARK: - Unique Session ID Generation

    /// When true, generates unique session_id for each call (default: false for backwards compatibility)
    public var generateUniqueSessionIds: Bool = false

    /// Counter for generating unique session IDs
    private var sessionCounter: Int = 0

    // MARK: - Call Tracking

    /// Number of times performInstall was called
    public private(set) var installCallCount: Int = 0

    /// Number of times performOpen was called
    public private(set) var openCallCount: Int = 0

    /// Number of times setIdentity was called
    public private(set) var identityCallCount: Int = 0

    /// Number of times logout was called
    public private(set) var logoutCallCount: Int = 0

    /// Number of times resolveLink was called
    public private(set) var linkCallCount: Int = 0

    /// Total number of network calls made
    public var totalCallCount: Int {
        installCallCount + openCallCount + identityCallCount + logoutCallCount + linkCallCount
    }

    // MARK: - Request Capture

    /// Captured install request data (most recent)
    public private(set) var lastInstallRequest: [String: Any]?

    /// Captured open request data (most recent)
    public private(set) var lastOpenRequest: [String: Any]?

    /// Captured identity parameters (most recent)
    public private(set) var lastIdentityUserId: String?

    /// Captured logout parameters (most recent)
    public private(set) var lastLogoutSessionId: String?

    /// Captured link URL (most recent)
    public private(set) var lastLinkURL: URL?

    /// All captured install requests
    public private(set) var allInstallRequests: [[String: Any]] = []

    /// All captured open requests
    public private(set) var allOpenRequests: [[String: Any]] = []

    // MARK: - Timing Configuration

    /// Simulated network delay in nanoseconds (default: 10ms)
    public var simulatedDelay: UInt64 = 10_000_000

    // MARK: - Initialization

    public init() {}

    /// Convenience initializer with standard test responses
    public static func withStandardResponses() -> MockBranchNetworkService {
        let mock = MockBranchNetworkService()
        mock.installResponse = [
            "session_id": "test-session-123",
            "identity_id": "test-identity-456",
            "device_fingerprint_id": "test-fingerprint-789",
        ]
        mock.openResponse = mock.installResponse
        mock.identityResponse = ["success": true]
        mock.logoutResponse = ["success": true]
        mock.linkResponse = [
            "+clicked_branch_link": true,
            "~referring_link": "https://test.app.link/deeplink123",
        ]
        return mock
    }

    // MARK: - Reset

    /// Reset all call counts and captured requests
    public func resetCallTracking() {
        installCallCount = 0
        openCallCount = 0
        identityCallCount = 0
        logoutCallCount = 0
        linkCallCount = 0
        lastInstallRequest = nil
        lastOpenRequest = nil
        lastIdentityUserId = nil
        lastLogoutSessionId = nil
        lastLinkURL = nil
        allInstallRequests = []
        allOpenRequests = []
        sessionCounter = 0
    }

    // MARK: - BranchNetworkService Implementation

    public func performInstall(requestData: [String: Any]) async throws -> [String: Any] {
        installCallCount += 1
        lastInstallRequest = requestData
        allInstallRequests.append(requestData)
        try await simulateNetworkCall(operationShouldFail: installShouldFail, operationError: installError)
        return withUniqueSessionId(installResponse)
    }

    public func performOpen(requestData: [String: Any]) async throws -> [String: Any] {
        openCallCount += 1
        lastOpenRequest = requestData
        allOpenRequests.append(requestData)
        try await simulateNetworkCall(operationShouldFail: openShouldFail, operationError: openError)
        return withUniqueSessionId(openResponse)
    }

    public func setIdentity(userId: String, sessionId _: String, identityId _: String) async throws -> [String: Any] {
        identityCallCount += 1
        lastIdentityUserId = userId
        try await simulateNetworkCall(operationShouldFail: identityShouldFail, operationError: identityError)
        return identityResponse
    }

    public func logout(sessionId: String, identityId _: String) async throws -> [String: Any] {
        logoutCallCount += 1
        lastLogoutSessionId = sessionId
        try await simulateNetworkCall(operationShouldFail: logoutShouldFail, operationError: logoutError)
        return logoutResponse
    }

    public func resolveLink(url: URL, sessionId _: String) async throws -> [String: Any] {
        linkCallCount += 1
        lastLinkURL = url
        try await simulateNetworkCall(operationShouldFail: linkShouldFail, operationError: linkError)
        return linkResponse
    }

    // MARK: - Private Methods

    /// Optionally modifies response to include unique session_id
    private func withUniqueSessionId(_ response: [String: Any]) -> [String: Any] {
        guard generateUniqueSessionIds else { return response }
        var modified = response
        sessionCounter += 1
        modified["session_id"] = "test-session-\(sessionCounter)"
        return modified
    }

    private func simulateNetworkCall(operationShouldFail: Bool = false, operationError: Error? = nil) async throws {
        if simulatedDelay > 0 {
            try await Task.sleep(nanoseconds: simulatedDelay)
        }

        // Per-operation failure takes precedence
        if operationShouldFail {
            throw operationError ?? failureError
        }

        // Global failure check
        if shouldFail {
            throw failureError
        }
    }
}
