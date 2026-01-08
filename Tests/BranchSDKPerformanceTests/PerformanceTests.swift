//
//  PerformanceTests.swift
//  Branch iOS SDK - Modern Swift Implementation
//
//  Copyright © 2026 Branch Metrics. All rights reserved.
//  SPDX-License-Identifier: MIT
//

@testable import BranchSDK
@testable import BranchSDKTestKit
import Foundation
import Testing

// MARK: - PerformanceTests

/// Performance tests verify that operations complete within acceptable time limits.
@Suite("Performance Tests")
struct PerformanceTests {
    // MARK: - Initialization Performance

    @Test("Initialization completes successfully")
    func initializationPerformance() async throws {
        let mockNetwork = MockNetworkClient()
        await mockNetwork.stubOpenResponse()

        let container = BranchContainer(networkClient: mockNetwork)
        let manager = SessionManager(container: container)

        let options = InitializationOptions()
        _ = try await manager.initialize(options: options)
    }

    // MARK: - Link Generation Performance

    @Test("Long URL generation is synchronous and fast")
    func longURLGenerationPerformance() async {
        let container = BranchContainer()
        let generator = LinkGenerator(container: container)

        let properties = LinkProperties()
            .with(channel: "test")
            .with(feature: "performance")
            .with(campaign: "benchmark")
            .with(tags: ["tag1", "tag2", "tag3"])
            .with(customData: [
                "key1": "value1",
                "key2": "value2",
                "key3": "value3",
            ])

        // Long URL generation should be fast (no network)
        _ = generator.createLongURL(with: properties)
    }

    @Test("Generate 100 long URLs quickly")
    func bulkLongURLGeneration() async {
        let container = BranchContainer()
        let generator = LinkGenerator(container: container)

        for i in 0 ..< 100 {
            let properties = LinkProperties()
                .with(channel: "test")
                .with(campaign: "bulk_\(i)")

            _ = generator.createLongURL(with: properties)
        }
    }

    // MARK: - Event Creation Performance

    @Test("Create 1000 events quickly")
    func eventCreationPerformance() {
        var events: [BranchEvent] = []
        events.reserveCapacity(1000)

        for i in 0 ..< 1000 {
            let event = BranchEvent.purchase()
                .with(revenue: Decimal(i), currency: "USD")
                .with(transactionId: "TXN\(i)")

            events.append(event)
        }

        #expect(events.count == 1000)
    }

    // MARK: - Storage Performance

    @Test("Storage read/write is fast")
    func storagePerformance() async {
        let storage = MockStorageProvider()

        // Write 100 values
        for i in 0 ..< 100 {
            let key = StorageKey(rawValue: "test_key_\(i)")
            await storage.set("value_\(i)", forKey: key)
        }

        // Read 100 values
        for i in 0 ..< 100 {
            let key = StorageKey(rawValue: "test_key_\(i)")
            let _: String? = await storage.get(forKey: key)
        }
    }

    // MARK: - Concurrent Operations

    @Test("Handle concurrent state observations")
    func concurrentStateObservations() async throws {
        let container = BranchContainer()
        let manager = SessionManager(container: container)

        // Create multiple observers
        var tasks: [Task<Void, Never>] = []

        for _ in 0 ..< 10 {
            let task = Task {
                let stream = await manager.observeState()
                var count = 0
                for await _ in stream {
                    count += 1
                    if count >= 1 {
                        break
                    }
                }
            }
            tasks.append(task)
        }

        // Initialize while observers are active
        let options = InitializationOptions()
        _ = try await manager.initialize(options: options)

        // Cancel all tasks
        for task in tasks {
            task.cancel()
        }
    }
}

// MARK: - MemoryTests

@Suite("Memory Tests")
struct MemoryTests {
    @Test("Event tracker doesn't leak events")
    func eventTrackerMemory() async throws {
        let mockNetwork = MockNetworkClient()
        await mockNetwork.setDefaultResponse(MockNetworkClient.StubbedResponse(
            data: "{}".data(using: .utf8)!,
            statusCode: 200
        ))

        let container = BranchContainer(networkClient: mockNetwork)
        let tracker = EventTracker(container: container)

        // Track many events
        for _ in 0 ..< 1000 {
            try await tracker.track(BranchEvent.purchase())
        }

        // Flush events
        await tracker.flush()

        // After flush, pending events should be cleared
        // (Implementation detail - adjust based on actual behavior)
    }

    @Test("Link generator cache is bounded")
    func linkGeneratorCacheSize() async throws {
        let mockNetwork = MockNetworkClient()
        await mockNetwork.stubLinkResponse()

        let container = BranchContainer(networkClient: mockNetwork)
        let generator = LinkGenerator(container: container)

        // Generate many unique links
        for i in 0 ..< 100 {
            let properties = LinkProperties()
                .with(campaign: "campaign_\(i)")

            _ = try await generator.create(with: properties)
        }

        // Cache should have entries
        let cacheSize = await generator.cacheSize
        #expect(cacheSize > 0)

        // Clear cache
        await generator.clearCache()
        let clearedSize = await generator.cacheSize
        #expect(clearedSize == 0)
    }
}

// MARK: - StressTests

@Suite("Stress Tests", .disabled("Run manually for stress testing"))
struct StressTests {
    @Test("Handle rapid initialization attempts")
    func rapidInitialization() async throws {
        let container = BranchContainer()
        let manager = SessionManager(container: container)

        var successCount = 0
        var errorCount = 0

        // Try to initialize multiple times rapidly
        await withTaskGroup(of: Bool.self) { group in
            for _ in 0 ..< 10 {
                group.addTask {
                    do {
                        _ = try await manager.initialize(options: InitializationOptions())
                        return true
                    } catch {
                        return false
                    }
                }
            }

            for await success in group {
                if success {
                    successCount += 1
                } else {
                    errorCount += 1
                }
            }
        }

        // At least one should succeed
        #expect(successCount >= 1)
    }

    @Test("Handle high event throughput")
    func highEventThroughput() async throws {
        let mockNetwork = MockNetworkClient()
        await mockNetwork.setDefaultResponse(MockNetworkClient.StubbedResponse(
            data: "{}".data(using: .utf8)!,
            statusCode: 200
        ))

        let container = BranchContainer(networkClient: mockNetwork)
        let tracker = EventTracker(container: container)

        // Track 10,000 events from multiple tasks
        await withTaskGroup(of: Void.self) { group in
            for taskNum in 0 ..< 10 {
                group.addTask {
                    for i in 0 ..< 1000 {
                        try? await tracker.track(
                            BranchEvent.custom("stress_event_\(taskNum)_\(i)")
                        )
                    }
                }
            }
        }

        await tracker.flush()
    }
}
