//
//  MockNetworkClient.swift
//  Branch iOS SDK - Modern Swift Implementation
//
//  Copyright © 2026 Branch Metrics. All rights reserved.
//  SPDX-License-Identifier: MIT
//

import BranchSDK
import Foundation

// MARK: - MockNetworkClient

/// Mock network client for testing.
///
/// Allows you to configure responses and verify requests without
/// making actual network calls.
///
/// ## Example
///
/// ```swift
/// let mock = MockNetworkClient()
/// await mock.stubResponse(for: "/v1/open", response: openResponseData)
///
/// // Use in tests
/// await Branch.shared.initialize(...)
///
/// let requests = await mock.requestsMade
/// XCTAssertTrue(requests.contains { $0.url?.path == "/v1/open" })
/// ```
public actor MockNetworkClient: NetworkClient {
    // MARK: Lifecycle

    // MARK: - Initialization

    public init() {}

    // MARK: Public

    // MARK: - Types

    public struct RecordedRequest: Sendable {
        // MARK: Lifecycle

        public init(request: URLRequest, timestamp: Date = Date()) {
            self.request = request
            self.timestamp = timestamp
        }

        // MARK: Public

        public let request: URLRequest
        public let timestamp: Date
    }

    public struct StubbedResponse: Sendable {
        // MARK: Lifecycle

        public init(data: Data, statusCode: Int = 200, headers: [String: String] = [:]) {
            self.data = data
            self.statusCode = statusCode
            self.headers = headers
        }

        // MARK: Public

        public let data: Data
        public let statusCode: Int
        public let headers: [String: String]
    }

    /// All requests that have been made
    public var requestsMade: [RecordedRequest] {
        _requestsMade
    }

    // MARK: - Configuration

    /// Stub a response for a specific endpoint path
    public func stubResponse(for path: String, response: StubbedResponse) {
        _stubbedResponses[path] = response
    }

    /// Stub a JSON response for a specific endpoint path
    public func stubResponse(for path: String, json: [String: Any], statusCode: Int = 200) {
        let data = (try? JSONSerialization.data(withJSONObject: json)) ?? Data()
        stubResponse(for: path, response: StubbedResponse(data: data, statusCode: statusCode))
    }

    /// Set the default response for unstubbed endpoints
    public func setDefaultResponse(_ response: StubbedResponse) {
        _defaultResponse = response
    }

    /// Configure the mock to fail all requests
    public func setShouldFail(_ shouldFail: Bool, error: (any Error)? = nil) {
        _shouldFail = shouldFail
        _failureError = error
    }

    /// Set artificial delay for requests
    public func setRequestDelay(_ delay: TimeInterval) {
        _requestDelay = delay
    }

    /// Clear all recorded requests
    public func clearRequests() {
        _requestsMade.removeAll()
    }

    /// Reset all configuration
    public func reset() {
        _requestsMade.removeAll()
        _stubbedResponses.removeAll()
        _defaultResponse = nil
        _shouldFail = false
        _failureError = nil
        _requestDelay = 0
    }

    // MARK: - NetworkClient

    public func data(
        for request: URLRequest,
        delegate _: (any URLSessionTaskDelegate)?
    ) async throws -> (Data, URLResponse) {
        // Record request
        _requestsMade.append(RecordedRequest(request: request))

        let shouldFail = _shouldFail
        let failureError = _failureError
        let delay = _requestDelay
        let path = request.url?.path ?? ""
        let stubbedResponse = _stubbedResponses[path]
        let defaultResponse = _defaultResponse

        // Apply delay if configured
        if delay > 0 {
            try await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
        }

        // Check for failure mode
        if shouldFail {
            throw failureError ?? BranchError.networkError("Mock network failure")
        }

        // Find response
        guard let response = stubbedResponse ?? defaultResponse else {
            throw BranchError.networkError("No stub configured for path: \(path)")
        }

        // Build HTTP response
        let url = request.url ?? URL(string: "https://api2.branch.io")!
        let httpResponse = HTTPURLResponse(
            url: url,
            statusCode: response.statusCode,
            httpVersion: "HTTP/1.1",
            headerFields: response.headers
        )!

        return (response.data, httpResponse)
    }

    // MARK: Private

    private var _requestsMade: [RecordedRequest] = []
    private var _stubbedResponses: [String: StubbedResponse] = [:]
    private var _defaultResponse: StubbedResponse?
    private var _shouldFail: Bool = false
    private var _failureError: (any Error)?
    private var _requestDelay: TimeInterval = 0
}

// MARK: - Convenience Extensions

public extension MockNetworkClient {
    /// Stub a successful open response
    func stubOpenResponse(
        sessionId: String = "mock_session_id",
        identityId: String = "mock_identity_id",
        deviceFingerprintId: String = "mock_device_fingerprint"
    ) {
        let json: [String: Any] = [
            "session_id": sessionId,
            "identity_id": identityId,
            "device_fingerprint_id": deviceFingerprintId,
            "link": "https://example.app.link/test",
            "data": "{}",
        ]
        stubResponse(for: "/v1/open", json: json)
    }

    /// Stub a successful install response
    func stubInstallResponse(
        sessionId: String = "mock_session_id",
        identityId: String = "mock_identity_id",
        deviceFingerprintId: String = "mock_device_fingerprint"
    ) {
        let json: [String: Any] = [
            "session_id": sessionId,
            "identity_id": identityId,
            "device_fingerprint_id": deviceFingerprintId,
            "link": "https://example.app.link/install",
            "data": "{}",
        ]
        stubResponse(for: "/v1/install", json: json)
    }

    /// Stub a successful link creation response
    func stubLinkResponse(url: String = "https://example.app.link/abcdef") {
        stubResponse(for: "/v1/url", json: ["url": url])
    }

    /// Stub a server error response
    func stubServerError(path: String, statusCode: Int = 500, message: String = "Internal Server Error") {
        let json: [String: Any] = ["error": ["code": statusCode, "message": message]]
        stubResponse(for: path, response: StubbedResponse(
            data: (try? JSONSerialization.data(withJSONObject: json)) ?? Data(),
            statusCode: statusCode
        ))
    }
}
