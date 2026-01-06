//
//  LinkGenerating.swift
//  Branch iOS SDK - Modern Swift Implementation
//
//  Copyright © 2026 Branch Metrics. All rights reserved.
//  SPDX-License-Identifier: MIT
//

import Foundation

/// Protocol for generating Branch deep links.
///
/// Provides an interface for creating short and long URLs.
///
/// ## Thread Safety
///
/// Implementations must be thread-safe and Sendable.
public protocol LinkGenerating: Sendable {
    /// Create a Branch deep link
    /// - Parameter properties: Link properties including parameters and metadata
    /// - Returns: The generated URL
    /// - Throws: `BranchError` if link generation fails
    func create(with properties: LinkProperties) async throws -> URL

    /// Create a long URL (no server call)
    /// - Parameter properties: Link properties including parameters and metadata
    /// - Returns: The generated long URL
    func createLongURL(with properties: LinkProperties) -> URL
}
