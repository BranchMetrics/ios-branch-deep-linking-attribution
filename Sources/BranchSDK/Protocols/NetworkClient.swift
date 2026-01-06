//
//  NetworkClient.swift
//  Branch iOS SDK - Modern Swift Implementation
//
//  Copyright © 2026 Branch Metrics. All rights reserved.
//  SPDX-License-Identifier: MIT
//

import Foundation

// MARK: - NetworkClient

/// Protocol for network operations.
///
/// Abstracts URLSession for testability and allows for custom networking implementations.
///
/// ## Thread Safety
///
/// Implementations must be thread-safe and Sendable.
public protocol NetworkClient: Sendable {
    /// Perform an HTTP request
    /// - Parameter request: The request to perform
    /// - Returns: A tuple of data and response
    /// - Throws: Network-related errors
    func data(for request: URLRequest) async throws -> (Data, URLResponse)

    /// Perform an HTTP request with custom delegate
    /// - Parameters:
    ///   - request: The request to perform
    ///   - delegate: Optional delegate for progress tracking
    /// - Returns: A tuple of data and response
    func data(
        for request: URLRequest,
        delegate: (any URLSessionTaskDelegate)?
    ) async throws -> (Data, URLResponse)
}

// MARK: - Default Implementation

public extension NetworkClient {
    func data(for request: URLRequest) async throws -> (Data, URLResponse) {
        try await data(for: request, delegate: nil)
    }
}
