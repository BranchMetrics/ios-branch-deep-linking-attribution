//
//  URLSessionNetworkClient.swift
//  Branch iOS SDK - Modern Swift Implementation
//
//  Copyright © 2026 Branch Metrics. All rights reserved.
//  SPDX-License-Identifier: MIT
//

import Foundation

// MARK: - URLSessionNetworkClient

/// URLSession-based implementation of NetworkClient.
///
/// Provides HTTP networking using Apple's URLSession with
/// proper timeout and retry configuration.
public final class URLSessionNetworkClient: NetworkClient, @unchecked Sendable {
    // MARK: Lifecycle

    // MARK: - Initialization

    public init(configuration: BranchConfiguration? = nil) {
        self.configuration = configuration

        let sessionConfig = URLSessionConfiguration.default
        sessionConfig.timeoutIntervalForRequest = configuration?.networkTimeout ?? Self.defaultTimeout
        sessionConfig.timeoutIntervalForResource = (configuration?.networkTimeout ?? Self.defaultTimeout) * 2
        sessionConfig.waitsForConnectivity = true

        // Add default headers
        sessionConfig.httpAdditionalHeaders = [
            "Content-Type": "application/json",
            "Accept": "application/json",
            "User-Agent": Self.userAgent,
        ]

        session = URLSession(configuration: sessionConfig)
    }

    // MARK: Public

    // MARK: - NetworkClient

    public func data(
        for request: URLRequest,
        delegate: (any URLSessionTaskDelegate)?
    ) async throws -> (Data, URLResponse) {
        var mutableRequest = request

        // Add API key header if available
        if let apiKey = configuration?.apiKey {
            mutableRequest.setValue(apiKey, forHTTPHeaderField: "Branch-Key")
        }

        do {
            let (data, response) = try await performDataRequest(mutableRequest, delegate: delegate)

            guard let httpResponse = response as? HTTPURLResponse else {
                throw BranchError.invalidResponse
            }

            // Check for HTTP errors
            switch httpResponse.statusCode {
            case 200 ... 299:
                return (data, response)

            case 400 ... 499:
                let message = Self.extractErrorMessage(from: data)
                throw BranchError.serverError(statusCode: httpResponse.statusCode, message: message)

            case 500 ... 599:
                let message = Self.extractErrorMessage(from: data)
                throw BranchError.serverError(statusCode: httpResponse.statusCode, message: message)

            default:
                throw BranchError.serverError(statusCode: httpResponse.statusCode, message: nil)
            }
        } catch let error as BranchError {
            throw error
        } catch let error as URLError {
            switch error.code {
            case .timedOut:
                throw BranchError.timeout

            case .notConnectedToInternet,
                 .networkConnectionLost:
                throw BranchError.networkError("No internet connection")

            default:
                throw BranchError.networkError(error.localizedDescription)
            }
        } catch {
            throw BranchError.underlying(error)
        }
    }

    // MARK: Private

    // MARK: - Constants

    private static let defaultTimeout: TimeInterval = 30
    private static let defaultRetryCount = 3
    private static let branchAPIHost = "api2.branch.io"

    private static var userAgent: String {
        let sdkVersion = "1.0.0" // TODO: Get from bundle
        let osVersion = ProcessInfo.processInfo.operatingSystemVersionString
        #if os(iOS)
        return "Branch-iOS-SDK/\(sdkVersion) (iOS \(osVersion))"
        #elseif os(macOS)
        return "Branch-macOS-SDK/\(sdkVersion) (macOS \(osVersion))"
        #elseif os(tvOS)
        return "Branch-tvOS-SDK/\(sdkVersion) (tvOS \(osVersion))"
        #elseif os(watchOS)
        return "Branch-watchOS-SDK/\(sdkVersion) (watchOS \(osVersion))"
        #elseif os(visionOS)
        return "Branch-visionOS-SDK/\(sdkVersion) (visionOS \(osVersion))"
        #else
        return "Branch-SDK/\(sdkVersion)"
        #endif
    }

    private let session: URLSession
    private let configuration: BranchConfiguration?

    // MARK: - Private Helpers

    private static func extractErrorMessage(from data: Data) -> String? {
        guard let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            return nil
        }
        return json["error"] as? String ?? json["message"] as? String
    }

    /// Perform the actual data request with platform-appropriate implementation.
    /// Uses native async URLSession on iOS 15+, continuation wrapper on iOS 13-14.
    private func performDataRequest(
        _ request: URLRequest,
        delegate: (any URLSessionTaskDelegate)?
    ) async throws -> (Data, URLResponse) {
        if #available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *) {
            try await session.data(for: request, delegate: delegate)
        } else {
            // Fallback for iOS 13-14: wrap callback-based API in continuation
            try await withCheckedThrowingContinuation { continuation in
                let task = session.dataTask(with: request) { data, response, error in
                    if let error {
                        continuation.resume(throwing: error)
                        return
                    }
                    guard let data, let response else {
                        continuation.resume(throwing: BranchError.invalidResponse)
                        return
                    }
                    continuation.resume(returning: (data, response))
                }
                task.resume()
            }
        }
    }
}

// MARK: - Request Building

public extension URLSessionNetworkClient {
    /// Build a request for a Branch API endpoint
    /// - Parameters:
    ///   - endpoint: The API endpoint path
    ///   - method: HTTP method
    ///   - body: Optional request body
    /// - Returns: Configured URLRequest
    /// - Throws: BranchError.invalidURL if the URL cannot be constructed
    static func buildRequest(
        endpoint: String,
        method: String = "POST",
        body: Data? = nil
    ) throws -> URLRequest {
        var components = URLComponents()
        components.scheme = "https"
        components.host = branchAPIHost
        components.path = endpoint

        guard let url = components.url else {
            throw BranchError.invalidURL("Failed to construct URL for endpoint: \(endpoint)")
        }

        var request = URLRequest(url: url)
        request.httpMethod = method
        request.httpBody = body

        return request
    }
}
