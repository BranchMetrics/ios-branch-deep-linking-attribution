//
//  BranchNetworkService.swift
//  Branch iOS SDK - Modern Swift Implementation
//
//  Copyright © 2026 Branch Metrics. All rights reserved.
//  SPDX-License-Identifier: MIT
//
//  iOS 12+ compatible using GCD synchronization patterns.
//

import Foundation

// MARK: - BranchNetworkService Protocol

/// Protocol defining the network operations required by SessionManager.
///
/// This abstraction allows SessionManager to remain decoupled from the
/// underlying network implementation (BNCServerInterface).
///
/// All methods use completion handlers for iOS 12 compatibility.
public protocol BranchNetworkService: AnyObject {
    /// Perform an install request (first session).
    /// - Parameters:
    ///   - requestData: Dictionary of request parameters
    ///   - completion: Callback with response dictionary or error
    func performInstall(
        requestData: [String: Any],
        completion: @escaping ([String: Any]?, Error?) -> Void
    )

    /// Perform an open request (returning session).
    /// - Parameters:
    ///   - requestData: Dictionary of request parameters
    ///   - completion: Callback with response dictionary or error
    func performOpen(
        requestData: [String: Any],
        completion: @escaping ([String: Any]?, Error?) -> Void
    )

    /// Set user identity.
    /// - Parameters:
    ///   - userId: The user identifier to set
    ///   - sessionId: Current session ID
    ///   - identityId: Current identity ID
    ///   - completion: Callback with response dictionary or error
    func setIdentity(
        userId: String,
        sessionId: String,
        identityId: String,
        completion: @escaping ([String: Any]?, Error?) -> Void
    )

    /// Clear user identity (logout).
    /// - Parameters:
    ///   - sessionId: Current session ID
    ///   - identityId: Current identity ID
    ///   - completion: Callback with response dictionary or error
    func logout(
        sessionId: String,
        identityId: String,
        completion: @escaping ([String: Any]?, Error?) -> Void
    )

    /// Resolve a deep link URL.
    /// - Parameters:
    ///   - url: The deep link URL to resolve
    ///   - sessionId: Current session ID
    ///   - completion: Callback with link data dictionary or error
    func resolveLink(
        url: URL,
        sessionId: String,
        completion: @escaping ([String: Any]?, Error?) -> Void
    )
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
public typealias NetworkLogCallback = (
    _ url: String,
    _ requestBody: [String: Any],
    _ responseBody: [String: Any]?,
    _ statusCode: Int?,
    _ error: Error?
) -> Void

// MARK: - Network Log Entry

/// Represents a single network log entry with all request/response details.
///
/// This struct captures network traffic for debugging and monitoring.
public struct NetworkLogEntry {
    public let id: UUID
    public let timestamp: Date
    public let url: String
    public let requestBody: [String: Any]
    public let responseBody: [String: Any]?
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
        self.requestBody = requestBody
        self.responseBody = responseBody
        self.statusCode = statusCode
        self.error = error?.localizedDescription
    }
}

// MARK: - Branch Network Logger

/// Thread-safe network logger using GCD synchronization (iOS 12+ compatible).
///
/// This class provides two ways to observe network logs:
/// 1. **Callback**: Simple callback-based observation
/// 2. **NotificationCenter**: For decoupled observation
///
/// Example usage with callback:
/// ```swift
/// BranchNetworkLogger.shared.setCallback { entry in
///     print("Request: \(entry.url)")
/// }
/// ```
///
/// Example usage with NotificationCenter:
/// ```swift
/// NotificationCenter.default.addObserver(
///     forName: BranchNetworkLogger.didLogEntryNotification,
///     object: nil,
///     queue: .main
/// ) { notification in
///     if let entry = notification.userInfo?["entry"] as? NetworkLogEntry {
///         print("Request: \(entry.url)")
///     }
/// }
/// ```
public final class BranchNetworkLogger {
    // MARK: - Notifications

    /// Notification posted when a new log entry is recorded.
    /// The `userInfo` dictionary contains the `NetworkLogEntry` under the key "entry".
    public static let didLogEntryNotification = Notification.Name("BranchNetworkLoggerDidLogEntry")

    // MARK: - Singleton

    /// Shared instance for global access
    public static let shared = BranchNetworkLogger()

    // MARK: - Properties

    /// Serial queue for thread-safe access (iOS 12 compatible pattern)
    private let isolationQueue = DispatchQueue(
        label: "io.branch.networklogger.isolation",
        qos: .utility
    )

    /// Buffer for logs received before any observer is attached
    private var pendingLogs: [NetworkLogEntry] = []

    /// Maximum number of pending logs to buffer (prevents memory issues)
    private let maxPendingLogs = 100

    /// Callback for log entries
    private var callback: ((NetworkLogEntry) -> Void)?

    /// Flag to track if callback is set
    private var hasCallback = false

    // MARK: - Initialization

    private init() {}

    // MARK: - Callback-Based Observation

    /// Set a callback for receiving log entries.
    ///
    /// When set, pending logs are flushed to the callback.
    ///
    /// - Parameter callback: Closure called for each log entry
    public func setCallback(_ callback: @escaping (NetworkLogEntry) -> Void) {
        isolationQueue.async { [weak self] in
            guard let self = self else { return }

            self.callback = callback
            self.hasCallback = true

            // Flush pending logs to callback
            for entry in self.pendingLogs {
                callback(entry)
            }
            self.pendingLogs.removeAll()
        }
    }

    /// Remove the callback
    public func removeCallback() {
        isolationQueue.async { [weak self] in
            self?.callback = nil
            self?.hasCallback = false
        }
    }

    // MARK: - Logging

    /// Log a network request/response entry.
    ///
    /// If no observer is attached, the entry is buffered (up to `maxPendingLogs`).
    /// When an observer attaches, buffered entries are flushed.
    ///
    /// Thread-safe: can be called from any thread.
    ///
    /// - Parameter entry: The log entry to record
    public func log(_ entry: NetworkLogEntry) {
        isolationQueue.async { [weak self] in
            guard let self = self else { return }

            // Try to deliver to callback
            if let callback = self.callback {
                callback(entry)
            } else {
                // Buffer if no observer is attached
                self.pendingLogs.append(entry)

                // Trim buffer if too large
                if self.pendingLogs.count > self.maxPendingLogs {
                    self.pendingLogs.removeFirst(self.pendingLogs.count - self.maxPendingLogs)
                }
            }

            // Always post notification for decoupled observers
            DispatchQueue.main.async {
                NotificationCenter.default.post(
                    name: BranchNetworkLogger.didLogEntryNotification,
                    object: self,
                    userInfo: ["entry": entry]
                )
            }
        }
    }

    /// Convenience method to log raw components.
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
        log(entry)
    }

    // MARK: - Utility

    /// Check if any observer is currently attached (thread-safe read)
    public var hasObserver: Bool {
        var result = false
        isolationQueue.sync {
            result = hasCallback
        }
        return result
    }

    /// Get the count of pending (unbuffered) logs (thread-safe read)
    public var pendingLogCount: Int {
        var result = 0
        isolationQueue.sync {
            result = pendingLogs.count
        }
        return result
    }

    /// Clear all pending logs
    public func clearPendingLogs() {
        isolationQueue.async { [weak self] in
            self?.pendingLogs.removeAll()
        }
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
public final class DefaultBranchNetworkService: BranchNetworkService {
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

    /// Serial queue for network operations
    private let networkQueue = DispatchQueue(
        label: "io.branch.networkservice.network",
        qos: .userInitiated
    )

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

    public func performInstall(
        requestData: [String: Any],
        completion: @escaping ([String: Any]?, Error?) -> Void
    ) {
        log(.debug, "performInstall - starting request")
        performRequest(endpoint: "/v1/install", requestData: requestData) { [weak self] response, error in
            if error == nil {
                self?.log(.debug, "performInstall - completed successfully")
            }
            completion(response, error)
        }
    }

    public func performOpen(
        requestData: [String: Any],
        completion: @escaping ([String: Any]?, Error?) -> Void
    ) {
        log(.debug, "performOpen - starting request")
        performRequest(endpoint: "/v1/open", requestData: requestData) { [weak self] response, error in
            if error == nil {
                self?.log(.debug, "performOpen - completed successfully")
            }
            completion(response, error)
        }
    }

    public func setIdentity(
        userId: String,
        sessionId: String,
        identityId: String,
        completion: @escaping ([String: Any]?, Error?) -> Void
    ) {
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

        performRequest(endpoint: "/v1/profile", requestData: requestData) { [weak self] response, error in
            if error == nil {
                self?.log(.debug, "setIdentity - completed successfully")
            }
            completion(response, error)
        }
    }

    public func logout(
        sessionId: String,
        identityId: String,
        completion: @escaping ([String: Any]?, Error?) -> Void
    ) {
        log(.debug, "logout - starting request for sessionId: \(sessionId)")
        var requestData: [String: Any] = [
            "session_id": sessionId,
            "identity_id": identityId,
        ]

        if let branchKey = getBranchKey() {
            requestData["branch_key"] = branchKey
        }

        performRequest(endpoint: "/v1/logout", requestData: requestData) { [weak self] response, error in
            if error == nil {
                self?.log(.debug, "logout - completed successfully")
            }
            completion(response, error)
        }
    }

    public func resolveLink(
        url: URL,
        sessionId: String,
        completion: @escaping ([String: Any]?, Error?) -> Void
    ) {
        log(.debug, "resolveLink - starting request for URL: \(url.absoluteString)")
        var requestData: [String: Any] = [
            "url": url.absoluteString,
            "session_id": sessionId,
        ]

        if let branchKey = getBranchKey() {
            requestData["branch_key"] = branchKey
        }

        performRequest(endpoint: "/v1/url", requestData: requestData) { [weak self] response, error in
            if error == nil {
                self?.log(.debug, "resolveLink - completed successfully")
            }
            completion(response, error)
        }
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

    /// Perform network request using URLSession with completion handler (iOS 12 compatible)
    private func performRequest(
        endpoint: String,
        requestData: [String: Any],
        completion: @escaping ([String: Any]?, Error?) -> Void
    ) {
        // Safely concatenate base URL and endpoint, handling missing slashes
        let baseURL = getBaseURL()
        let fullURL = endpoint.hasPrefix("/") ? baseURL + endpoint : baseURL + "/" + endpoint

        guard let url = URL(string: fullURL) else {
            log(.error, "performRequest - invalid URL: \(fullURL)")
            let error = NSError(
                domain: "io.branch.sdk.error",
                code: 1007, // BNCNetworkServiceInterfaceError
                userInfo: [NSLocalizedDescriptionKey: "Invalid URL: \(fullURL)"]
            )
            completion(nil, error)
            return
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
            completion(nil, error)
            return
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

        // Perform request using completion-based API (iOS 12 compatible)
        let task = URLSession.shared.dataTask(with: request) { [weak self] data, response, error in
            guard let self = self else {
                completion(nil, NSError(
                    domain: "io.branch.sdk.error",
                    code: 1007,
                    userInfo: [NSLocalizedDescriptionKey: "Service deallocated"]
                ))
                return
            }

            // Handle network error
            if let error = error {
                self.log(.error, "performRequest - network request failed: \(error.localizedDescription)")

                // Log to network logger (non-blocking)
                self.networkQueue.async {
                    let entry = NetworkLogEntry(
                        url: fullURL,
                        requestBody: mutableRequestData,
                        responseBody: nil,
                        statusCode: nil,
                        error: error
                    )
                    BranchNetworkLogger.shared.log(entry)
                }

                // Also invoke legacy callback for backwards compatibility
                Self.logCallback?(fullURL, mutableRequestData, nil, nil, error)

                let nsError = NSError(
                    domain: "io.branch.sdk.error",
                    code: 1007, // BNCNetworkServiceInterfaceError
                    userInfo: [NSLocalizedDescriptionKey: error.localizedDescription]
                )
                completion(nil, nsError)
                return
            }

            // Validate response
            guard let httpResponse = response as? HTTPURLResponse else {
                self.log(.error, "performRequest - invalid response type")
                let invalidResponseError = NSError(
                    domain: "io.branch.sdk.error",
                    code: 1007, // BNCNetworkServiceInterfaceError
                    userInfo: [NSLocalizedDescriptionKey: "Invalid response type"]
                )
                completion(nil, invalidResponseError)
                return
            }

            self.log(.debug, "performRequest - received HTTP \(httpResponse.statusCode) from \(endpoint)")

            // Log response data for debugging (only in debug builds)
            #if DEBUG
                if let data = data, let responseString = String(data: data, encoding: .utf8) {
                    self.log(.debug, "performRequest - response body:\n\(responseString)")
                }
            #endif

            // Parse response
            let responseData: [String: Any]
            if let data = data, !data.isEmpty {
                guard let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {
                    self.log(.error, "performRequest - invalid JSON response")
                    let parseError = NSError(
                        domain: "io.branch.sdk.error",
                        code: 1007, // BNCNetworkServiceInterfaceError
                        userInfo: [NSLocalizedDescriptionKey: "Invalid JSON response"]
                    )

                    // Log to network logger (non-blocking)
                    self.networkQueue.async {
                        let parseEntry = NetworkLogEntry(
                            url: fullURL,
                            requestBody: mutableRequestData,
                            responseBody: nil,
                            statusCode: httpResponse.statusCode,
                            error: parseError
                        )
                        BranchNetworkLogger.shared.log(parseEntry)
                    }

                    // Also invoke legacy callback for backwards compatibility
                    Self.logCallback?(fullURL, mutableRequestData, nil, httpResponse.statusCode, parseError)

                    completion(nil, parseError)
                    return
                }
                responseData = json
            } else {
                responseData = [:]
            }

            // Log to network logger (non-blocking)
            self.networkQueue.async {
                let successEntry = NetworkLogEntry(
                    url: fullURL,
                    requestBody: mutableRequestData,
                    responseBody: responseData,
                    statusCode: httpResponse.statusCode,
                    error: nil
                )
                BranchNetworkLogger.shared.log(successEntry)
            }

            // Also invoke legacy callback for backwards compatibility
            Self.logCallback?(fullURL, mutableRequestData, responseData, httpResponse.statusCode, nil)

            // Check for server errors
            if httpResponse.statusCode >= 400 {
                let errorMessage = responseData["error"] as? String ?? "Server error"
                self.log(.error, "performRequest - server error \(httpResponse.statusCode): \(errorMessage)")
                let serverError = NSError(
                    domain: "io.branch.sdk.error",
                    code: httpResponse.statusCode, // Use HTTP status code for server errors
                    userInfo: [NSLocalizedDescriptionKey: errorMessage]
                )
                completion(nil, serverError)
                return
            }

            completion(responseData, nil)
        }
        task.resume()
    }
}

// MARK: - Mock Implementation for Testing

/// Mock network service for testing purposes.
///
/// Provides configurable responses, failure simulation, call tracking,
/// and request capture for comprehensive test verification.
public final class MockBranchNetworkService: BranchNetworkService {
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

    /// Lock for thread-safe counter access
    private let counterLock = NSLock()

    // MARK: - Call Tracking

    /// Thread-safe call tracking using lock
    private let trackingLock = NSLock()

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
        trackingLock.lock()
        defer { trackingLock.unlock() }
        return installCallCount + openCallCount + identityCallCount + logoutCallCount + linkCallCount
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

    /// Simulated network delay in seconds (default: 0.01s / 10ms)
    public var simulatedDelay: TimeInterval = 0.01

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
        trackingLock.lock()
        defer { trackingLock.unlock() }

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

        counterLock.lock()
        sessionCounter = 0
        counterLock.unlock()
    }

    // MARK: - BranchNetworkService Implementation

    public func performInstall(
        requestData: [String: Any],
        completion: @escaping ([String: Any]?, Error?) -> Void
    ) {
        trackingLock.lock()
        installCallCount += 1
        lastInstallRequest = requestData
        allInstallRequests.append(requestData)
        trackingLock.unlock()

        simulateNetworkCall(
            operationShouldFail: installShouldFail,
            operationError: installError
        ) { [weak self] error in
            if let error = error {
                completion(nil, error)
            } else {
                completion(self?.withUniqueSessionId(self?.installResponse ?? [:]), nil)
            }
        }
    }

    public func performOpen(
        requestData: [String: Any],
        completion: @escaping ([String: Any]?, Error?) -> Void
    ) {
        trackingLock.lock()
        openCallCount += 1
        lastOpenRequest = requestData
        allOpenRequests.append(requestData)
        trackingLock.unlock()

        simulateNetworkCall(
            operationShouldFail: openShouldFail,
            operationError: openError
        ) { [weak self] error in
            if let error = error {
                completion(nil, error)
            } else {
                completion(self?.withUniqueSessionId(self?.openResponse ?? [:]), nil)
            }
        }
    }

    public func setIdentity(
        userId: String,
        sessionId: String,
        identityId: String,
        completion: @escaping ([String: Any]?, Error?) -> Void
    ) {
        _ = sessionId // Suppress unused parameter warning
        _ = identityId

        trackingLock.lock()
        identityCallCount += 1
        lastIdentityUserId = userId
        trackingLock.unlock()

        simulateNetworkCall(
            operationShouldFail: identityShouldFail,
            operationError: identityError
        ) { [weak self] error in
            if let error = error {
                completion(nil, error)
            } else {
                completion(self?.identityResponse, nil)
            }
        }
    }

    public func logout(
        sessionId: String,
        identityId: String,
        completion: @escaping ([String: Any]?, Error?) -> Void
    ) {
        _ = identityId // Suppress unused parameter warning

        trackingLock.lock()
        logoutCallCount += 1
        lastLogoutSessionId = sessionId
        trackingLock.unlock()

        simulateNetworkCall(
            operationShouldFail: logoutShouldFail,
            operationError: logoutError
        ) { [weak self] error in
            if let error = error {
                completion(nil, error)
            } else {
                completion(self?.logoutResponse, nil)
            }
        }
    }

    public func resolveLink(
        url: URL,
        sessionId: String,
        completion: @escaping ([String: Any]?, Error?) -> Void
    ) {
        _ = sessionId // Suppress unused parameter warning

        trackingLock.lock()
        linkCallCount += 1
        lastLinkURL = url
        trackingLock.unlock()

        simulateNetworkCall(
            operationShouldFail: linkShouldFail,
            operationError: linkError
        ) { [weak self] error in
            if let error = error {
                completion(nil, error)
            } else {
                completion(self?.linkResponse, nil)
            }
        }
    }

    // MARK: - Private Methods

    /// Optionally modifies response to include unique session_id
    private func withUniqueSessionId(_ response: [String: Any]) -> [String: Any] {
        guard generateUniqueSessionIds else { return response }

        counterLock.lock()
        sessionCounter += 1
        let counter = sessionCounter
        counterLock.unlock()

        var modified = response
        modified["session_id"] = "test-session-\(counter)"
        return modified
    }

    private func simulateNetworkCall(
        operationShouldFail: Bool = false,
        operationError: Error? = nil,
        completion: @escaping (Error?) -> Void
    ) {
        // Simulate network delay using GCD (iOS 12 compatible)
        let delay = simulatedDelay > 0 ? simulatedDelay : 0.001

        DispatchQueue.global(qos: .userInitiated).asyncAfter(deadline: .now() + delay) { [weak self] in
            guard let self = self else {
                completion(NSError(
                    domain: "io.branch.sdk.error",
                    code: 1007,
                    userInfo: [NSLocalizedDescriptionKey: "Mock deallocated"]
                ))
                return
            }

            // Per-operation failure takes precedence
            if operationShouldFail {
                completion(operationError ?? self.failureError)
                return
            }

            // Global failure check
            if self.shouldFail {
                completion(self.failureError)
                return
            }

            completion(nil)
        }
    }
}
