//
//  MockEventTracker.swift
//  Branch iOS SDK - Modern Swift Implementation
//
//  Copyright © 2026 Branch Metrics. All rights reserved.
//  SPDX-License-Identifier: MIT
//

import BranchSDK
import Foundation

/// Mock event tracker for testing.
///
/// Records all tracked events for verification in tests.
public actor MockEventTracker: EventTracking {
    // MARK: Lifecycle

    // MARK: - Initialization

    public init() {}

    // MARK: Public

    /// Whether tracking should fail
    public var shouldFailTracking = false

    /// Error to throw when tracking fails
    public var trackingError: Error?

    // MARK: - Public Access

    /// All events that have been tracked
    public var trackedEvents: [BranchEvent] {
        _trackedEvents
    }

    /// All batches that have been flushed
    public var flushedEvents: [[BranchEvent]] {
        _flushedEvents
    }

    /// Get the last tracked event
    public var lastTrackedEvent: BranchEvent? {
        _trackedEvents.last
    }

    // MARK: - EventTracking

    public func track(_ event: BranchEvent) async throws {
        if shouldFailTracking {
            throw trackingError ?? BranchError.eventTrackingFailed("Mock tracking failure")
        }
        _trackedEvents.append(event)
    }

    public func trackBatch(_ events: [BranchEvent]) async throws {
        if shouldFailTracking {
            throw trackingError ?? BranchError.eventTrackingFailed("Mock tracking failure")
        }
        _trackedEvents.append(contentsOf: events)
    }

    public func flush() async {
        if !_trackedEvents.isEmpty {
            _flushedEvents.append(_trackedEvents)
            _trackedEvents.removeAll()
        }
    }

    // MARK: - Test Helpers

    /// Check if a specific event type was tracked
    public func hasTrackedEvent(ofType type: BranchEvent.EventType) -> Bool {
        _trackedEvents.contains { $0.eventType == type }
    }

    /// Get all events of a specific type
    public func events(ofType type: BranchEvent.EventType) -> [BranchEvent] {
        _trackedEvents.filter { $0.eventType == type }
    }

    /// Clear all tracked events
    public func clearEvents() {
        _trackedEvents.removeAll()
        _flushedEvents.removeAll()
    }

    /// Reset all state
    public func reset() {
        _trackedEvents.removeAll()
        _flushedEvents.removeAll()
        shouldFailTracking = false
        trackingError = nil
    }

    // MARK: Private

    private var _trackedEvents: [BranchEvent] = []
    private var _flushedEvents: [[BranchEvent]] = []
}
