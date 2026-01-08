//
//  EventTracking.swift
//  Branch iOS SDK - Modern Swift Implementation
//
//  Copyright © 2026 Branch Metrics. All rights reserved.
//  SPDX-License-Identifier: MIT
//

import Foundation

/// Protocol for tracking events.
///
/// Provides an interface for tracking standard and custom events.
///
/// ## Thread Safety
///
/// Implementations must be thread-safe and Sendable.
public protocol EventTracking: Sendable {
    /// Track an event
    /// - Parameter event: The event to track
    /// - Throws: `BranchError` if tracking fails
    func track(_ event: BranchEvent) async throws

    /// Track multiple events in batch
    /// - Parameter events: The events to track
    /// - Throws: `BranchError` if tracking fails
    func trackBatch(_ events: [BranchEvent]) async throws

    /// Flush any pending events
    func flush() async
}
