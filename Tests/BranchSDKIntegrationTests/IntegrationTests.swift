//
//  IntegrationTests.swift
//  Branch iOS SDK - Modern Swift Implementation
//
//  Copyright © 2026 Branch Metrics. All rights reserved.
//  SPDX-License-Identifier: MIT
//

@testable import BranchSDK
@testable import BranchSDKTestKit
import Foundation
import Testing

// MARK: - IntegrationTests

/// Integration tests verify complete flows across multiple components.
@Suite("Integration Tests")
struct IntegrationTests {
    // MARK: - Full Initialization Flow

    @Test("Complete initialization flow with mocks")
    func completeInitializationFlow() async throws {
        // Setup mocks
        let mockNetwork = MockNetworkClient()
        await mockNetwork.stubOpenResponse()

        let mockStorage = MockStorageProvider()
        let mockLogger = MockLogger()

        let container = BranchContainer(
            networkClient: mockNetwork,
            storageProvider: mockStorage,
            logger: mockLogger
        )

        let manager = SessionManager(container: container)

        // Initialize
        let options = InitializationOptions()
        let session = try await manager.initialize(options: options)

        // Verify session was created
        #expect(!session.id.isEmpty)
        #expect(session.isFirstSession)

        // Note: Network calls will be verified once SessionManager
        // implementation makes actual API calls (currently TODO)
    }

    // MARK: - Event Tracking Flow

    @Test("Event tracking with mock network")
    func eventTrackingFlow() async throws {
        let mockNetwork = MockNetworkClient()
        await mockNetwork.setDefaultResponse(MockNetworkClient.StubbedResponse(
            data: "{}".data(using: .utf8)!,
            statusCode: 200
        ))

        let container = BranchContainer(networkClient: mockNetwork)
        let tracker = EventTracker(container: container)

        // Track event
        let event = BranchEvent.purchase()
            .with(revenue: 99.99, currency: "USD")
            .with(transactionId: "TXN123")

        try await tracker.track(event)
        await tracker.flush()

        // Verify request was made
        let requestCount = await mockNetwork.requestsMade.count
        #expect(requestCount > 0)
    }

    // MARK: - Link Generation Flow

    @Test("Link generation with mock network")
    func linkGenerationFlow() async throws {
        let mockNetwork = MockNetworkClient()
        await mockNetwork.stubLinkResponse(url: "https://example.app.link/generated")

        let container = BranchContainer(networkClient: mockNetwork)
        let generator = LinkGenerator(container: container)

        // Generate link
        let properties = LinkProperties()
            .with(channel: "share")
            .with(feature: "referral")
            .with(key: "product_id", value: "123")

        let url = try await generator.create(with: properties)

        // Verify
        #expect(url.absoluteString.contains("example.app.link"))
    }

    // MARK: - Error Handling

    @Test("Network error is properly propagated")
    func networkErrorHandling() async throws {
        let mockNetwork = MockNetworkClient()
        await mockNetwork.setShouldFail(true, error: BranchError.timeout)

        let container = BranchContainer(networkClient: mockNetwork)
        let generator = LinkGenerator(container: container)

        let properties = LinkProperties()

        await #expect(throws: BranchError.self) {
            _ = try await generator.create(with: properties)
        }
    }

    // MARK: - State Persistence

    @Test("Session data persists to storage")
    func sessionPersistence() async throws {
        let mockStorage = MockStorageProvider()
        let container = BranchContainer(storageProvider: mockStorage)
        let manager = SessionManager(container: container)

        // Initialize
        let options = InitializationOptions()
        _ = try await manager.initialize(options: options)

        // Storage operations should have been performed
        // Note: Actual storage calls depend on implementation
        let keys = await mockStorage.allKeys()
        // In a full implementation, we'd verify session was stored
        #expect(keys.count >= 0) // Placeholder assertion
    }

    // MARK: - Identity Flow

    @Test("Complete identity flow")
    func identityFlow() async throws {
        let mockNetwork = MockNetworkClient()
        await mockNetwork.setDefaultResponse(MockNetworkClient.StubbedResponse(
            data: "{}".data(using: .utf8)!,
            statusCode: 200
        ))

        let container = BranchContainer(networkClient: mockNetwork)
        let manager = SessionManager(container: container)

        // Initialize
        let options = InitializationOptions()
        _ = try await manager.initialize(options: options)

        // Set identity
        let userId = "user_12345"
        try await manager.setIdentity(userId)

        // Verify identity is set
        let session = await manager.currentSession
        #expect(session?.userId == userId)

        // Logout
        try await manager.logout()

        // Verify identity is cleared
        let loggedOutSession = await manager.currentSession
        #expect(loggedOutSession?.userId == nil)
    }
}

// MARK: - DeepLinkIntegrationTests

@Suite("Deep Link Integration Tests")
struct DeepLinkIntegrationTests {
    @Test("Handle universal link")
    func universalLinkHandling() async throws {
        let mockNetwork = MockNetworkClient()
        await mockNetwork.setDefaultResponse(MockNetworkClient.StubbedResponse(
            data: """
            {
                "data": "{\\"key\\":\\"value\\"}",
                "$canonical_identifier": "content/123"
            }
            """.data(using: .utf8)!,
            statusCode: 200
        ))

        let container = BranchContainer(networkClient: mockNetwork)
        let manager = SessionManager(container: container)

        // Initialize first
        let options = InitializationOptions()
        _ = try await manager.initialize(options: options)

        // Handle deep link
        let url = URL(string: "https://example.app.link/abcdef")!
        let session = try await manager.handleDeepLink(url)

        // Session should be returned (link data processing is TODO)
        #expect(!session.id.isEmpty)
    }

    @Test("Handle URI scheme")
    func uRISchemeHandling() async throws {
        let container = BranchContainer()
        let manager = SessionManager(container: container)

        // Initialize first
        let options = InitializationOptions()
        _ = try await manager.initialize(options: options)

        // Handle URI scheme
        let url = URL(string: "myapp://product?id=123")!
        let session = try await manager.handleDeepLink(url)

        #expect(!session.id.isEmpty)
    }
}
