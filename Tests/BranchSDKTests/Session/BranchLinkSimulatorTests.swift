//
//  BranchLinkSimulatorTests.swift
//  BranchSDKTests
//
//  Copyright © 2026 Branch Metrics. All rights reserved.
//  SPDX-License-Identifier: MIT
//

@testable import BranchSDK
import XCTest

// swiftlint:disable type_body_length file_length
@MainActor
final class BranchLinkSimulatorTests: XCTestCase {
    var sut: BranchLinkSimulator!

    override func setUp() async throws {
        // Clean up UserDefaults
        UserDefaults.standard.removeObject(forKey: "branch_has_installed")

        // Get fresh simulator instance
        sut = BranchLinkSimulator.shared

        // Reset state
        sut.disable()
        sut.disableNetworkLogging()
        sut.unregisterAllLinks()
        sut.clearNetworkLogs()

        // Reset SessionManager
        SessionManager.shared.reset()
    }

    override func tearDown() async throws {
        sut.disable()
        sut.disableNetworkLogging()
        sut.unregisterAllLinks()
        sut.clearNetworkLogs()
        sut = nil

        // Clean up UserDefaults
        UserDefaults.standard.removeObject(forKey: "branch_has_installed")
    }

    // MARK: - Enable/Disable Tests

    func testSimulatorStartsDisabled() {
        // Given: Fresh simulator instance
        // Then: Should start disabled
        XCTAssertFalse(sut.isEnabled)
    }

    func testEnableSimulator() {
        // When: Enable simulator
        sut.enable()

        // Wait for isolation queue
        let expectation = self.expectation(description: "enable")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            expectation.fulfill()
        }
        waitForExpectations(timeout: 1.0)

        // Then: Should be enabled
        XCTAssertTrue(sut.isEnabled)
    }

    func testDisableSimulator() {
        // Given: Enabled simulator
        sut.enable()

        let enableExpectation = expectation(description: "enable")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            enableExpectation.fulfill()
        }
        waitForExpectations(timeout: 1.0)

        // When: Disable simulator
        sut.disable()

        let disableExpectation = expectation(description: "disable")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            disableExpectation.fulfill()
        }
        waitForExpectations(timeout: 1.0)

        // Then: Should be disabled
        XCTAssertFalse(sut.isEnabled)
    }

    // MARK: - Link Registration Tests

    func testRegisterLink() {
        // Given: A simulated link
        let url = URL(string: "https://test.app.link/test123")!
        let linkData = SimulatedLinkData(url: url)
        linkData.params = ["product_id": "12345"]
        linkData.campaign = "test_campaign"

        // When: Register the link
        sut.registerLink(linkData)

        // Wait for isolation queue
        let expectation = self.expectation(description: "register")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            expectation.fulfill()
        }
        waitForExpectations(timeout: 1.0)

        // Then: Link should be registered
        XCTAssertTrue(sut.isLinkRegistered(url))
    }

    func testUnregisterLink() {
        // Given: A registered link
        let url = URL(string: "https://test.app.link/unregister")!
        let linkData = SimulatedLinkData(url: url)
        sut.registerLink(linkData)

        let registerExpectation = expectation(description: "register")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            registerExpectation.fulfill()
        }
        waitForExpectations(timeout: 1.0)

        XCTAssertTrue(sut.isLinkRegistered(url))

        // When: Unregister the link
        sut.unregisterLink(url)

        let unregisterExpectation = expectation(description: "unregister")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            unregisterExpectation.fulfill()
        }
        waitForExpectations(timeout: 1.0)

        // Then: Link should not be registered
        XCTAssertFalse(sut.isLinkRegistered(url))
    }

    func testUnregisterAllLinks() {
        // Given: Multiple registered links
        let url1 = URL(string: "https://test.app.link/link1")!
        let url2 = URL(string: "https://test.app.link/link2")!

        sut.registerLink(SimulatedLinkData(url: url1))
        sut.registerLink(SimulatedLinkData(url: url2))

        let registerExpectation = expectation(description: "register")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            registerExpectation.fulfill()
        }
        waitForExpectations(timeout: 1.0)

        XCTAssertTrue(sut.isLinkRegistered(url1))
        XCTAssertTrue(sut.isLinkRegistered(url2))

        // When: Unregister all links
        sut.unregisterAllLinks()

        let unregisterExpectation = expectation(description: "unregister")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            unregisterExpectation.fulfill()
        }
        waitForExpectations(timeout: 1.0)

        // Then: No links should be registered
        XCTAssertFalse(sut.isLinkRegistered(url1))
        XCTAssertFalse(sut.isLinkRegistered(url2))
    }

    // MARK: - SimulatedLinkData Tests

    func testSimulatedLinkDataBuildParams() {
        // Given: A configured link
        let url = URL(string: "https://test.app.link/build")!
        let linkData = SimulatedLinkData(url: url)
        linkData.params = ["custom_key": "custom_value"]
        linkData.campaign = "summer_sale"
        linkData.channel = "email"
        linkData.feature = "referral"
        linkData.stage = "acquisition"
        linkData.tags = ["promo", "2026"]
        linkData.matchType = .exact
        linkData.clickedBranchLink = true

        // When: Build params
        let params = linkData.buildParams()

        // Then: Should contain all configured values
        XCTAssertEqual(params["custom_key"] as? String, "custom_value")
        XCTAssertEqual(params["~campaign"] as? String, "summer_sale")
        XCTAssertEqual(params["~channel"] as? String, "email")
        XCTAssertEqual(params["~feature"] as? String, "referral")
        XCTAssertEqual(params["~stage"] as? String, "acquisition")
        XCTAssertEqual(params["~tags"] as? [String], ["promo", "2026"])
        XCTAssertEqual(params["+match_type"] as? String, "exact")
        XCTAssertEqual(params["+clicked_branch_link"] as? Bool, true)
        XCTAssertEqual(params["~referring_link"] as? String, url.absoluteString)
    }

    func testLinkMatchTypeStringValue() {
        XCTAssertEqual(LinkMatchType.exact.stringValue, "exact")
        XCTAssertEqual(LinkMatchType.fuzzy.stringValue, "fuzzy")
        XCTAssertEqual(LinkMatchType.deferred.stringValue, "deferred")
    }

    // MARK: - Simulation Tests (when disabled)

    func testSimulateOpenWhenDisabled() {
        // Given: Disabled simulator
        XCTAssertFalse(sut.isEnabled)

        // When: Try to simulate open
        let url = URL(string: "https://test.app.link/disabled")!
        let expectation = self.expectation(description: "simulate")

        sut.simulateOpen(url: url) { session, error in
            // Then: Should fail with error
            XCTAssertNil(session)
            XCTAssertNotNil(error)
            XCTAssertEqual(error?.domain, "io.branch.linksimulator")
            XCTAssertTrue(error?.localizedDescription.contains("not enabled") ?? false)
            expectation.fulfill()
        }

        waitForExpectations(timeout: 2.0)
    }

    // MARK: - Network Logging Tests

    func testNetworkLoggingStartsDisabled() {
        XCTAssertFalse(sut.isNetworkLoggingEnabled)
    }

    func testEnableNetworkLogging() {
        // When: Enable network logging
        sut.enableNetworkLogging()

        // Then: Should be enabled
        XCTAssertTrue(sut.isNetworkLoggingEnabled)
    }

    func testDisableNetworkLogging() {
        // Given: Enabled logging
        sut.enableNetworkLogging()
        XCTAssertTrue(sut.isNetworkLoggingEnabled)

        // When: Disable logging
        sut.disableNetworkLogging()

        // Then: Should be disabled
        XCTAssertFalse(sut.isNetworkLoggingEnabled)
    }

    func testClearNetworkLogs() {
        // Given: Some logs (simulated by adding manually via internal methods)
        sut.enableNetworkLogging()

        // When: Clear logs
        sut.clearNetworkLogs()

        let expectation = self.expectation(description: "clear")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            expectation.fulfill()
        }
        waitForExpectations(timeout: 1.0)

        // Then: Logs should be empty
        XCTAssertTrue(sut.networkLogs.isEmpty)
    }

    // MARK: - NetworkLogEntrySendable Tests

    func testNetworkLogEntrySendableInit() {
        // Given: Log entry parameters
        let id = UUID()
        let timestamp = Date()
        let url = "https://api.branch.io/v1/open"
        let requestBody: [String: Any] = ["branch_key": "test_key"]
        let responseBody: [String: Any] = ["session_id": "123"]
        let statusCode = 200

        // When: Create entry
        let entry = NetworkLogEntrySendable(
            id: id,
            timestamp: timestamp,
            url: url,
            requestBody: requestBody,
            responseBody: responseBody,
            statusCode: statusCode,
            error: nil
        )

        // Then: Should have correct values
        XCTAssertEqual(entry.id, id)
        XCTAssertEqual(entry.timestamp, timestamp)
        XCTAssertEqual(entry.url, url)
        XCTAssertEqual(entry.requestBody["branch_key"] as? String, "test_key")
        XCTAssertEqual(entry.responseBody?["session_id"] as? String, "123")
        XCTAssertEqual(entry.statusCode?.intValue, 200)
        XCTAssertNil(entry.error)
    }

    func testNetworkLogEntrySendableWithError() {
        // Given: Entry with error
        let entry = NetworkLogEntrySendable(
            id: UUID(),
            timestamp: Date(),
            url: "https://api.branch.io/v1/install",
            requestBody: [:],
            responseBody: nil,
            statusCode: nil,
            error: "Network timeout"
        )

        // Then: Should have error
        XCTAssertEqual(entry.error, "Network timeout")
        XCTAssertNil(entry.statusCode)
        XCTAssertNil(entry.responseBody)
    }

    // MARK: - SessionManager Integration Tests

    func testGetSimulatedLinkData() {
        // Given: A registered link
        let url = URL(string: "https://test.app.link/integration")!
        let linkData = SimulatedLinkData(url: url)
        linkData.params = ["product_id": "xyz"]
        linkData.campaign = "integration_test"

        sut.registerLink(linkData)

        let expectation = self.expectation(description: "register")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            expectation.fulfill()
        }
        waitForExpectations(timeout: 1.0)

        // When: Get simulated link data
        let retrievedData = sut.getSimulatedLinkData(for: url)

        // Then: Should return the registered data
        XCTAssertNotNil(retrievedData)
        XCTAssertEqual(retrievedData?.url, url)
        XCTAssertEqual(retrievedData?.campaign, "integration_test")
        XCTAssertEqual(retrievedData?.params["product_id"] as? String, "xyz")
    }

    func testGetSimulatedLinkDataReturnsNilForUnregisteredLink() {
        // Given: An unregistered URL
        let url = URL(string: "https://test.app.link/unregistered")!

        // When: Get simulated link data
        let retrievedData = sut.getSimulatedLinkData(for: url)

        // Then: Should return nil
        XCTAssertNil(retrievedData)
    }

    func testShouldSimulateLinkWhenEnabled() {
        // Given: Enabled simulator with registered link
        let url = URL(string: "https://test.app.link/should-simulate")!
        sut.registerLink(SimulatedLinkData(url: url))
        sut.enable()

        let expectation = self.expectation(description: "setup")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            expectation.fulfill()
        }
        waitForExpectations(timeout: 1.0)

        // When: Check if should simulate
        let shouldSimulate = sut.shouldSimulateLink(url)

        // Then: Should return true
        XCTAssertTrue(shouldSimulate)
    }

    func testShouldSimulateLinkReturnsFalseWhenDisabled() {
        // Given: Disabled simulator with registered link
        let url = URL(string: "https://test.app.link/disabled-check")!
        sut.registerLink(SimulatedLinkData(url: url))

        let expectation = self.expectation(description: "register")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            expectation.fulfill()
        }
        waitForExpectations(timeout: 1.0)

        // Ensure disabled
        XCTAssertFalse(sut.isEnabled)

        // When: Check if should simulate
        let shouldSimulate = sut.shouldSimulateLink(url)

        // Then: Should return false (disabled)
        XCTAssertFalse(shouldSimulate)
    }

    func testShouldSimulateLinkReturnsFalseForUnregisteredLink() {
        // Given: Enabled simulator without registered link
        sut.enable()

        let expectation = self.expectation(description: "enable")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            expectation.fulfill()
        }
        waitForExpectations(timeout: 1.0)

        let url = URL(string: "https://test.app.link/not-registered")!

        // When: Check if should simulate
        let shouldSimulate = sut.shouldSimulateLink(url)

        // Then: Should return false (not registered)
        XCTAssertFalse(shouldSimulate)
    }

    func testBuildSimulatedSession() {
        // Given: Enabled simulator with registered link
        let url = URL(string: "https://test.app.link/session-test")!
        let linkData = SimulatedLinkData(url: url)
        linkData.params = ["product_id": "session-123"]
        linkData.campaign = "session_campaign"
        linkData.channel = "email"
        linkData.matchType = .exact
        linkData.clickedBranchLink = true

        sut.registerLink(linkData)
        sut.enable()

        let expectation = self.expectation(description: "setup")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            expectation.fulfill()
        }
        waitForExpectations(timeout: 1.0)

        // When: Build simulated session
        let session = sut.buildSimulatedSession(for: url, isFirstSession: true)

        // Then: Session should have simulated params
        XCTAssertNotNil(session)
        XCTAssertTrue(session!.id.hasPrefix("simulated-"))
        XCTAssertTrue(session!.isFirstSession)
        XCTAssertEqual(session!.params["product_id"] as? String, "session-123")
        XCTAssertEqual(session!.params["~campaign"] as? String, "session_campaign")
        XCTAssertEqual(session!.params["~channel"] as? String, "email")
        XCTAssertEqual(session!.params["+match_type"] as? String, "exact")
        XCTAssertEqual(session!.params["+clicked_branch_link"] as? Bool, true)
        XCTAssertEqual(session!.params["~referring_link"] as? String, url.absoluteString)
    }

    func testBuildSimulatedSessionReturnsNilForUnregisteredLink() {
        // Given: Enabled simulator without registered link
        sut.enable()

        let expectation = self.expectation(description: "enable")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            expectation.fulfill()
        }
        waitForExpectations(timeout: 1.0)

        let url = URL(string: "https://test.app.link/no-session")!

        // When: Try to build simulated session
        let session = sut.buildSimulatedSession(for: url, isFirstSession: false)

        // Then: Should return nil
        XCTAssertNil(session)
    }

    func testSessionManagerHandlesSimulatedLink() {
        // Given: Enabled simulator with registered link, initialized SessionManager
        let url = URL(string: "https://test.app.link/sm-integration")!
        let linkData = SimulatedLinkData(url: url)
        linkData.params = ["integration": "success"]
        linkData.campaign = "sm_test"
        linkData.simulatedDelay = 0.05 // Fast for tests

        sut.registerLink(linkData)
        sut.enable()

        // Initialize SessionManager first
        let initExpectation = expectation(description: "init")
        SessionManager.shared.initialize { _, _ in
            initExpectation.fulfill()
        }
        waitForExpectations(timeout: 5.0)

        // Wait for simulator to be fully enabled
        let setupExpectation = expectation(description: "setup")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            setupExpectation.fulfill()
        }
        waitForExpectations(timeout: 1.0)

        // When: Handle deep link through SessionManager
        let deepLinkExpectation = expectation(description: "deeplink")
        var resultSession: Session?

        SessionManager.shared.handleDeepLink(url) { session, error in
            resultSession = session
            XCTAssertNil(error)
            deepLinkExpectation.fulfill()
        }

        waitForExpectations(timeout: 3.0)

        // Then: Session should have simulated params
        XCTAssertNotNil(resultSession)
        XCTAssertTrue(resultSession!.id.hasPrefix("simulated-"))
        XCTAssertEqual(resultSession!.params["integration"] as? String, "success")
        XCTAssertEqual(resultSession!.params["~campaign"] as? String, "sm_test")
    }

    func testSimulatedSessionNotificationIncludesSimulatedFlag() {
        // Given: Enabled simulator with registered link
        let url = URL(string: "https://test.app.link/notification-test")!
        let linkData = SimulatedLinkData(url: url)
        linkData.params = ["notify": "test"]
        linkData.simulatedDelay = 0.05

        sut.registerLink(linkData)
        sut.enable()

        // Initialize SessionManager first
        let initExpectation = expectation(description: "init")
        SessionManager.shared.initialize { _, _ in
            initExpectation.fulfill()
        }
        waitForExpectations(timeout: 5.0)

        // Wait for setup
        let setupExpectation = expectation(description: "setup")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            setupExpectation.fulfill()
        }
        waitForExpectations(timeout: 1.0)

        // Set up notification observer
        let notificationExpectation = expectation(description: "notification")
        var receivedSimulatedFlag: Bool?

        let observer = NotificationCenter.default.addObserver(
            forName: Notification.Name("BranchDidStartSessionNotification"),
            object: nil,
            queue: .main
        ) { notification in
            if let simulated = notification.userInfo?["+simulated"] as? Bool {
                receivedSimulatedFlag = simulated
                notificationExpectation.fulfill()
            }
        }

        // When: Handle deep link
        SessionManager.shared.handleDeepLink(url) { _, _ in }

        waitForExpectations(timeout: 3.0)
        NotificationCenter.default.removeObserver(observer)

        // Then: Notification should include simulated flag
        XCTAssertEqual(receivedSimulatedFlag, true)
    }
}
