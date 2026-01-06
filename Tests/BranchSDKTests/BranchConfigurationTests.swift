//
//  BranchConfigurationTests.swift
//  Branch iOS SDK - Modern Swift Implementation
//
//  Copyright © 2026 Branch Metrics. All rights reserved.
//  SPDX-License-Identifier: MIT
//

@testable import BranchSDK
import Foundation
import Testing

@Suite("BranchConfiguration Tests")
struct BranchConfigurationTests {
    // MARK: - Initialization Tests

    @Test("Configuration with live key")
    func liveKeyConfiguration() throws {
        let config = BranchConfiguration(apiKey: "key_live_abc123")
        try config.validate()
        #expect(config.apiKey == "key_live_abc123")
        #expect(config.isTestMode == false)
    }

    @Test("Configuration with test key")
    func keyConfiguration() throws {
        let config = BranchConfiguration(apiKey: "key_test_xyz789")
        try config.validate()
        #expect(config.apiKey == "key_test_xyz789")
        #expect(config.isTestMode == true)
    }

    @Test("Empty API key throws error on validation")
    func emptyKeyThrows() {
        let config = BranchConfiguration(apiKey: "")
        #expect(throws: BranchError.self) {
            try config.validate()
        }
    }

    @Test("Invalid API key format throws error on validation")
    func invalidKeyFormatThrows() {
        let config = BranchConfiguration(apiKey: "invalid_key")
        #expect(throws: BranchError.self) {
            try config.validate()
        }
    }

    // MARK: - Builder Pattern Tests

    @Test("Builder pattern creates valid configuration")
    func builderPattern() throws {
        let config = BranchConfiguration(apiKey: "key_live_abc123")
            .withNetworkTimeout(60)
            .withRetryCount(5)
            .withTrackingDisabled(true)
            .withDebugMode(true)

        try config.validate()
        #expect(config.networkTimeout == 60)
        #expect(config.retryCount == 5)
        #expect(config.isTrackingDisabled == true)
        #expect(config.isDebugMode == true)
    }

    @Test("Builder pattern with custom endpoint")
    func customEndpoint() throws {
        let customURL = URL(string: "https://custom.api.example.com")!
        let config = BranchConfiguration(apiKey: "key_live_abc123")
            .withBaseURL(customURL)

        try config.validate()
        #expect(config.baseURL == customURL)
    }

    // MARK: - Default Values Tests

    @Test("Default timeout is 10 seconds")
    func defaultTimeout() {
        let config = BranchConfiguration(apiKey: "key_live_abc123")
        #expect(config.networkTimeout == 10)
    }

    @Test("Default retry count is 3")
    func defaultRetryCount() {
        let config = BranchConfiguration(apiKey: "key_live_abc123")
        #expect(config.retryCount == 3)
    }

    @Test("Tracking is enabled by default")
    func trackingEnabledByDefault() {
        let config = BranchConfiguration(apiKey: "key_live_abc123")
        #expect(config.isTrackingDisabled == false)
    }

    // MARK: - Equatable Tests

    @Test("Configurations with same values are equal")
    func equality() {
        let config1 = BranchConfiguration(apiKey: "key_live_abc123")
        let config2 = BranchConfiguration(apiKey: "key_live_abc123")
        #expect(config1 == config2)
    }

    @Test("Configurations with different keys are not equal")
    func inequality() {
        let config1 = BranchConfiguration(apiKey: "key_live_abc123")
        let config2 = BranchConfiguration(apiKey: "key_live_xyz789")
        #expect(config1 != config2)
    }
}
