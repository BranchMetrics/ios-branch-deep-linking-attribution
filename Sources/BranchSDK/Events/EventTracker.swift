//
//  EventTracker.swift
//  Branch iOS SDK - Modern Swift Implementation
//
//  Copyright © 2026 Branch Metrics. All rights reserved.
//  SPDX-License-Identifier: MIT
//

import Foundation

/// Actor-based event tracker implementation.
///
/// Provides thread-safe event tracking with batching and retry support.
public actor EventTracker: EventTracking {
    // MARK: Lifecycle

    // MARK: - Initialization

    public init(container: BranchContainer) {
        self.container = container
    }

    // MARK: Public

    // MARK: - EventTracking

    public func track(_ event: BranchEvent) async throws {
        // Validate event
        try validateEvent(event)

        // Add to pending queue
        pendingEvents.append(event)

        // Flush if batch size reached
        if pendingEvents.count >= maxBatchSize {
            await flush()
        }
    }

    public func trackBatch(_ events: [BranchEvent]) async throws {
        for event in events {
            try validateEvent(event)
        }

        pendingEvents.append(contentsOf: events)

        if pendingEvents.count >= maxBatchSize {
            await flush()
        }
    }

    public func flush() async {
        guard !isFlushInProgress, !pendingEvents.isEmpty else {
            return
        }

        isFlushInProgress = true
        defer { isFlushInProgress = false }

        let eventsToSend = Array(pendingEvents.prefix(maxBatchSize))
        pendingEvents.removeFirst(min(maxBatchSize, pendingEvents.count))

        do {
            try await sendEvents(eventsToSend)
            BranchLogger.shared.debug("Successfully sent \(eventsToSend.count) events")
        } catch {
            // Re-queue failed events at the front
            pendingEvents.insert(contentsOf: eventsToSend, at: 0)
            BranchLogger.shared.error("Failed to send events: \(error)")
        }
    }

    // MARK: Private

    private let container: BranchContainer
    private var pendingEvents: [BranchEvent] = []
    private var isFlushInProgress = false

    // MARK: - Configuration

    private let maxBatchSize = 50
    private let flushInterval: TimeInterval = 30

    // MARK: - Private Methods

    private func validateEvent(_ event: BranchEvent) throws {
        if event.eventType == .custom {
            guard let name = event.customEventName, !name.isEmpty else {
                throw BranchError.invalidEvent("Custom event name cannot be empty")
            }
        }
    }

    private func sendEvents(_ events: [BranchEvent]) async throws {
        // TODO: Implement actual API call
        // 1. Serialize events to JSON
        // 2. Make POST request to /v2/event/standard or /v2/event/custom
        // 3. Handle response

        let networkClient = await container.networkClient

        let payload = buildEventPayload(events)
        let data = try JSONSerialization.data(withJSONObject: payload)

        let request = try URLSessionNetworkClient.buildRequest(
            endpoint: "/v2/event/standard",
            method: "POST",
            body: data
        )

        _ = try await networkClient.data(for: request)
    }

    private func buildEventPayload(_ events: [BranchEvent]) -> [String: Any] {
        // TODO: Build proper payload structure
        var payload: [String: Any] = [:]

        if let first = events.first {
            payload["name"] = first.eventType == .custom
                ? first.customEventName
                : first.eventType.rawValue

            if let revenue = first.revenue {
                payload["revenue"] = NSDecimalNumber(decimal: revenue).doubleValue
            }
            if let currency = first.currency {
                payload["currency"] = currency
            }
            if let transactionId = first.transactionId {
                payload["transaction_id"] = transactionId
            }

            if !first.customData.isEmpty {
                payload["custom_data"] = first.customData.mapValues { $0.value }
            }
        }

        return payload
    }
}
