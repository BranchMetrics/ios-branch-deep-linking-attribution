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

// MARK: - Network Logging Callback

/// Callback type for network request/response logging.
///
/// This allows external observers (like BranchLinkSimulator) to receive
/// network traffic for debugging purposes.
///
/// - Parameters:
///   - url: The request URL
///   - requestBody: The request body as a dictionary
///   - responseBody: The response body as a dictionary (nil if request failed)
///   - statusCode: The HTTP status code (nil if request failed)
///   - error: Any error that occurred (nil if successful)
@available(iOS 13.0, macOS 10.15, tvOS 13.0, watchOS 6.0, *)
public typealias NetworkLogCallback = @Sendable (
    _ url: String,
    _ requestBody: [String: Any],
    _ responseBody: [String: Any]?,
    _ statusCode: Int?,
    _ error: Error?
) -> Void

// MARK: - Network Log Entry (Modern Swift Approach)

/// Represents a single network log entry with all request/response details.
///
/// This struct is `Sendable` and can be safely passed across actor boundaries.
@available(iOS 13.0, macOS 10.15, tvOS 13.0, watchOS 6.0, *)
public struct NetworkLogEntry: Sendable {
    public let id: UUID
    public let timestamp: Date
    public let url: String
    public let requestBody: [String: any Sendable]
    public let responseBody: [String: any Sendable]?
    public let statusCode: Int?
    public let error: String?

    public init(
        url: String,
        requestBody: [String: Any],
        responseBody: [String: Any]?,
        statusCode: Int?,
        error: Error?
    ) {
        id = UUID()
        timestamp = Date()
        self.url = url
        self.requestBody = Self.makeSendable(requestBody)
        self.responseBody = responseBody.map { Self.makeSendable($0) }
        self.statusCode = statusCode
        self.error = error?.localizedDescription
    }

    /// Convert [String: Any] to [String: any Sendable] for actor isolation safety
    private static func makeSendable(_ dict: [String: Any]) -> [String: any Sendable] {
        dict.compactMapValues { makeSendableValue($0) }
    }

    /// Convert any value to a Sendable equivalent
    private static func makeSendableValue(_ value: Any) -> (any Sendable)? {
        switch value {
        case let string as String:
            return string
        case let int as Int:
            return int
        case let double as Double:
            return double
        case let bool as Bool:
            return bool
        case let nsNumber as NSNumber:
            return nsNumber.doubleValue
        case let array as [Any]:
            // Recursively convert array elements
            return array.compactMap { makeSendableValue($0) }
        case let nested as [String: Any]:
            return makeSendable(nested)
        case is NSNull:
            return nil
        default:
            // Fallback: convert to string representation
            return String(describing: value)
        }
    }
}

// MARK: - Branch Network Logger Actor

/// Thread-safe network logger using Swift Concurrency.
///
/// This actor provides two ways to observe network logs:
/// 1. **AsyncStream**: Modern reactive approach with automatic buffering
/// 2. **Callback**: Legacy support for simple logging
///
/// Example usage with AsyncStream:
/// ```swift
/// Task {
///     for await entry in BranchNetworkLogger.shared.logStream {
///         print("[\(entry.timestamp)] \(entry.url) -> \(entry.statusCode ?? 0)")
///     }
/// }
/// ```
///
/// Example usage with callback:
/// ```swift
/// await BranchNetworkLogger.shared.setCallback { entry in
///     print("Request: \(entry.url)")
/// }
/// ```
@available(iOS 13.0, macOS 10.15, tvOS 13.0, watchOS 6.0, *)
public actor BranchNetworkLogger {
    // MARK: - Singleton

    /// Shared instance for global access
    public static let shared = BranchNetworkLogger()

    // MARK: - Properties

    /// Buffer for logs received before any observer is attached
    private var pendingLogs: [NetworkLogEntry] = []

    /// Maximum number of pending logs to buffer (prevents memory issues)
    private let maxPendingLogs = 100

    /// Stream continuation for AsyncStream-based observation
    private var streamContinuation: AsyncStream<NetworkLogEntry>.Continuation?

    /// Legacy callback for simple logging
    private var callback: (@Sendable (NetworkLogEntry) -> Void)?

    /// Flag to track if stream has been accessed
    private var streamStarted = false

    // MARK: - Initialization

    private init() {}

    // MARK: - AsyncStream (Modern Approach)

    /// AsyncStream of network log entries.
    ///
    /// This stream buffers entries until an observer attaches, then flushes
    /// all pending logs followed by real-time logs.
    ///
    /// Usage:
    /// ```swift
    /// Task {
    ///     for await entry in BranchNetworkLogger.shared.logStream {
    ///         // Process each log entry
    ///     }
    /// }
    /// ```
    public nonisolated var logStream: AsyncStream<NetworkLogEntry> {
        AsyncStream { continuation in
            Task {
                await self.attachStream(continuation)
            }
        }
    }

    /// Attach a stream continuation and flush pending logs
    private func attachStream(_ continuation: AsyncStream<NetworkLogEntry>.Continuation) {
        streamContinuation = continuation
        streamStarted = true

        // Flush all pending logs to the new stream
        for entry in pendingLogs {
            continuation.yield(entry)
        }
        pendingLogs.removeAll()

        // Handle stream termination
        continuation.onTermination = { @Sendable [weak self] _ in
            Task { [weak self] in
                await self?.detachStream()
            }
        }
    }

    /// Detach stream when observer stops listening
    private func detachStream() {
        streamContinuation = nil
        streamStarted = false
    }

    // MARK: - Callback (Legacy Support)

    /// Set a callback for receiving log entries.
    ///
    /// This is provided for simpler use cases where AsyncStream is overkill.
    /// When set, pending logs are flushed to the callback.
    ///
    /// - Parameter callback: Closure called for each log entry
    public func setCallback(_ callback: @escaping @Sendable (NetworkLogEntry) -> Void) {
        self.callback = callback

        // Flush pending logs to callback
        for entry in pendingLogs {
            callback(entry)
        }
        pendingLogs.removeAll()
    }

    /// Remove the callback
    public func removeCallback() {
        callback = nil
    }

    // MARK: - Logging

    /// Log a network request/response.
    ///
    /// If no observer is attached, the entry is buffered (up to `maxPendingLogs`).
    /// When an observer attaches, buffered entries are flushed.
    ///
    /// - Parameters:
    ///   - url: The request URL
    ///   - requestBody: The request body dictionary
    ///   - responseBody: The response body dictionary (nil if failed)
    ///   - statusCode: HTTP status code (nil if failed)
    ///   - error: Error if request failed
    public func log(
        url: String,
        requestBody: [String: Any],
        responseBody: [String: Any]?,
        statusCode: Int?,
        error: Error?
    ) {
        let entry = NetworkLogEntry(
            url: url,
            requestBody: requestBody,
            responseBody: responseBody,
            statusCode: statusCode,
            error: error
        )

        // Try to deliver to stream
        if let continuation = streamContinuation {
            continuation.yield(entry)
            return
        }

        // Try to deliver to callback
        if let callback = callback {
            callback(entry)
            return
        }

        // Buffer if no observer is attached
        pendingLogs.append(entry)

        // Trim buffer if too large
        if pendingLogs.count > maxPendingLogs {
            pendingLogs.removeFirst(pendingLogs.count - maxPendingLogs)
        }
    }

    // MARK: - Utility

    /// Check if any observer is currently attached
    public var hasObserver: Bool {
        streamContinuation != nil || callback != nil
    }

    /// Get the count of pending (unbuffered) logs
    public var pendingLogCount: Int {
        pendingLogs.count
    }

    /// Clear all pending logs
    public func clearPendingLogs() {
        pendingLogs.removeAll()
    }
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
    // MARK: - Static Logging Callback

    /// Global callback for network logging. Set this to receive all network traffic.
    ///
    /// Example usage in BranchLinkSimulator:
    /// ```swift
    /// DefaultBranchNetworkService.logCallback = { url, request, response, status, error in
    ///     print("Request to \(url): \(request)")
    ///     if let response = response {
    ///         print("Response (\(status ?? 0)): \(response)")
    ///     }
    /// }
    /// ```
    public static var logCallback: NetworkLogCallback?

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
            throw NSError(
                domain: "io.branch.sdk.error",
                code: 1007, // BNCNetworkServiceInterfaceError
                userInfo: [NSLocalizedDescriptionKey: "Invalid URL: \(fullURL)"]
            )
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
            // Log to modern actor-based logger (buffers if no observer)
            await BranchNetworkLogger.shared.log(
                url: fullURL,
                requestBody: mutableRequestData,
                responseBody: nil,
                statusCode: nil,
                error: error
            )
            // Also invoke legacy callback for backwards compatibility
            Self.logCallback?(fullURL, mutableRequestData, nil, nil, error)
            throw NSError(
                domain: "io.branch.sdk.error",
                code: 1007, // BNCNetworkServiceInterfaceError
                userInfo: [NSLocalizedDescriptionKey: error.localizedDescription]
            )
        }

        // Validate response
        guard let httpResponse = response as? HTTPURLResponse else {
            log(.error, "performRequest - invalid response type")
            throw NSError(
                domain: "io.branch.sdk.error",
                code: 1007, // BNCNetworkServiceInterfaceError
                userInfo: [NSLocalizedDescriptionKey: "Invalid response type"]
            )
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
                let parseError = NSError(
                    domain: "io.branch.sdk.error",
                    code: 1007, // BNCNetworkServiceInterfaceError
                    userInfo: [NSLocalizedDescriptionKey: "Invalid JSON response"]
                )
                // Log to modern actor-based logger
                await BranchNetworkLogger.shared.log(
                    url: fullURL,
                    requestBody: mutableRequestData,
                    responseBody: nil,
                    statusCode: httpResponse.statusCode,
                    error: parseError
                )
                // Also invoke legacy callback for backwards compatibility
                Self.logCallback?(fullURL, mutableRequestData, nil, httpResponse.statusCode, parseError)
                throw parseError
            }
            responseData = json
        } else {
            responseData = [:]
        }

        // Log to modern actor-based logger (always logs, buffers if no observer)
        await BranchNetworkLogger.shared.log(
            url: fullURL,
            requestBody: mutableRequestData,
            responseBody: responseData,
            statusCode: httpResponse.statusCode,
            error: nil
        )
        // Also invoke legacy callback for backwards compatibility
        Self.logCallback?(fullURL, mutableRequestData, responseData, httpResponse.statusCode, nil)

        // Check for server errors
        if httpResponse.statusCode >= 400 {
            let errorMessage = responseData["error"] as? String ?? "Server error"
            log(.error, "performRequest - server error \(httpResponse.statusCode): \(errorMessage)")
            throw NSError(
                domain: "io.branch.sdk.error",
                code: httpResponse.statusCode, // Use HTTP status code for server errors
                userInfo: [NSLocalizedDescriptionKey: errorMessage]
            )
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
    public var failureError: Error = NSError(
        domain: "io.branch.sdk.error",
        code: 1007, // BNCNetworkServiceInterfaceError
        userInfo: [NSLocalizedDescriptionKey: "Mock network failure"]
    )

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
