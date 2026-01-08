//
//  InitializationOptionsTests.swift
//  BranchSwiftSDKTests
//
//  Branch iOS SDK - Modern Swift Implementation
//  Copyright © 2026 Branch Metrics. All rights reserved.
//  SPDX-License-Identifier: MIT
//
//  JIRA: EMT-2737
//  Unit tests for InitializationOptions
//

import XCTest

@testable import BranchSwiftSDK

@available(iOS 13.0, tvOS 13.0, *)
final class InitializationOptionsTests: XCTestCase {
    // MARK: - Default Initialization Tests

    func testDefaultInitialization() {
        let options = InitializationOptions()

        XCTAssertNil(options.launchURL)
        XCTAssertNil(options.launchOptions)
        XCTAssertNil(options.userActivity)
        XCTAssertFalse(options.checkPasteboardOnInstall)
        XCTAssertFalse(options.deferInitForPluginRuntime)
        XCTAssertNil(options.referringURL)
        XCTAssertFalse(options.isSceneBasedLaunch)
        XCTAssertNil(options.customMetadata)
    }

    // MARK: - Builder Method Tests

    func testWithURL() {
        let url = URL(string: "https://example.app.link/test")!

        let options = InitializationOptions()
            .withURL(url)

        XCTAssertEqual(options.launchURL, url)
        // Other defaults unchanged
        XCTAssertNil(options.launchOptions)
        XCTAssertFalse(options.checkPasteboardOnInstall)
    }

    func testWithURLNil() {
        let url = URL(string: "https://example.app.link/test")!

        let options = InitializationOptions()
            .withURL(url)
            .withURL(nil)

        XCTAssertNil(options.launchURL)
    }

    func testWithLaunchOptions() {
        let launchOptions: [String: Any] = [
            "UIApplicationLaunchOptionsURLKey": "test-url",
            "UIApplicationLaunchOptionsSourceApplicationKey": "com.test.app",
        ]

        let options = InitializationOptions()
            .withLaunchOptions(launchOptions)

        XCTAssertNotNil(options.launchOptions)
        XCTAssertEqual(
            options.launchOptions?["UIApplicationLaunchOptionsURLKey"] as? String,
            "test-url"
        )
    }

    func testWithUserActivity() {
        let activity = NSUserActivity(activityType: NSUserActivityTypeBrowsingWeb)
        activity.webpageURL = URL(string: "https://example.app.link/test")

        let options = InitializationOptions()
            .withUserActivity(activity)

        XCTAssertNotNil(options.userActivity)
        XCTAssertEqual(
            options.userActivity?.webpageURL?.absoluteString,
            "https://example.app.link/test"
        )
    }

    func testCheckPasteboardOnInstall() {
        let optionsEnabled = InitializationOptions()
            .checkPasteboardOnInstall(true)

        let optionsDisabled = InitializationOptions()
            .checkPasteboardOnInstall(false)

        XCTAssertTrue(optionsEnabled.checkPasteboardOnInstall)
        XCTAssertFalse(optionsDisabled.checkPasteboardOnInstall)
    }

    func testDeferInitForPluginRuntime() {
        let optionsEnabled = InitializationOptions()
            .deferInitForPluginRuntime(true)

        let optionsDisabled = InitializationOptions()
            .deferInitForPluginRuntime(false)

        XCTAssertTrue(optionsEnabled.deferInitForPluginRuntime)
        XCTAssertFalse(optionsDisabled.deferInitForPluginRuntime)
    }

    func testWithReferringURL() {
        let url = URL(string: "https://referring.app.link/source")!

        let options = InitializationOptions()
            .withReferringURL(url)

        XCTAssertEqual(options.referringURL, url)
    }

    func testAsSceneBasedLaunch() {
        let options = InitializationOptions()
            .asSceneBasedLaunch(true)

        XCTAssertTrue(options.isSceneBasedLaunch)
    }

    func testWithCustomMetadata() {
        let metadata: [String: String] = [
            "custom_key": "custom_value",
            "analytics_id": "12345",
        ]

        let options = InitializationOptions()
            .withCustomMetadata(metadata)

        XCTAssertEqual(options.customMetadata?["custom_key"], "custom_value")
        XCTAssertEqual(options.customMetadata?["analytics_id"], "12345")
    }

    // MARK: - Builder Chaining Tests

    func testBuilderChaining() {
        let url = URL(string: "https://example.app.link/test")!
        let referringURL = URL(string: "https://referring.link")!
        let launchOptions: [String: Any] = ["key": "value"]
        let metadata = ["meta": "data"]

        let options = InitializationOptions()
            .withURL(url)
            .withLaunchOptions(launchOptions)
            .checkPasteboardOnInstall(true)
            .deferInitForPluginRuntime(true)
            .withReferringURL(referringURL)
            .asSceneBasedLaunch(true)
            .withCustomMetadata(metadata)

        XCTAssertEqual(options.launchURL, url)
        XCTAssertNotNil(options.launchOptions)
        XCTAssertTrue(options.checkPasteboardOnInstall)
        XCTAssertTrue(options.deferInitForPluginRuntime)
        XCTAssertEqual(options.referringURL, referringURL)
        XCTAssertTrue(options.isSceneBasedLaunch)
        XCTAssertEqual(options.customMetadata?["meta"], "data")
    }

    func testBuilderImmutability() {
        let options1 = InitializationOptions()
        let options2 = options1.withURL(URL(string: "https://test.com")!)

        // Original options should be unchanged
        XCTAssertNil(options1.launchURL)
        XCTAssertNotNil(options2.launchURL)
    }

    // MARK: - Factory Method Tests

    func testAppLaunchFactory() {
        let launchOptions: [String: Any] = [
            "UIApplicationLaunchOptionsURLKey": "test",
        ]

        let options = InitializationOptions.appLaunch(options: launchOptions)

        XCTAssertNotNil(options.launchOptions)
        XCTAssertNil(options.launchURL)
        XCTAssertFalse(options.isSceneBasedLaunch)
    }

    func testAppLaunchFactoryWithNilOptions() {
        let options = InitializationOptions.appLaunch(options: nil)

        XCTAssertNil(options.launchOptions)
    }

    func testUniversalLinkFactory() {
        let activity = NSUserActivity(activityType: NSUserActivityTypeBrowsingWeb)
        activity.webpageURL = URL(string: "https://example.app.link/universal")

        let options = InitializationOptions.universalLink(activity: activity)

        XCTAssertNotNil(options.userActivity)
        XCTAssertEqual(
            options.launchURL?.absoluteString,
            "https://example.app.link/universal"
        )
    }

    func testDeepLinkFactory() {
        let url = URL(string: "myapp://deep/link?param=value")!

        let options = InitializationOptions.deepLink(url: url)

        XCTAssertEqual(options.launchURL, url)
        XCTAssertNil(options.userActivity)
    }

    func testSceneLaunchFactory() {
        let connectionOptions: [String: Any] = ["scene_key": "scene_value"]
        let activity = NSUserActivity(activityType: NSUserActivityTypeBrowsingWeb)

        let options = InitializationOptions.sceneLaunch(
            connectionOptions: connectionOptions,
            userActivity: activity
        )

        XCTAssertNotNil(options.launchOptions)
        XCTAssertNotNil(options.userActivity)
        XCTAssertTrue(options.isSceneBasedLaunch)
    }

    func testSceneLaunchFactoryWithoutUserActivity() {
        let connectionOptions: [String: Any] = ["key": "value"]

        let options = InitializationOptions.sceneLaunch(
            connectionOptions: connectionOptions,
            userActivity: nil
        )

        XCTAssertNotNil(options.launchOptions)
        XCTAssertNil(options.userActivity)
        XCTAssertTrue(options.isSceneBasedLaunch)
    }

    // MARK: - Equatable Tests

    func testEquatableWithSameValues() {
        let url = URL(string: "https://test.com")!
        let metadata = ["key": "value"]

        let options1 = InitializationOptions()
            .withURL(url)
            .checkPasteboardOnInstall(true)
            .withCustomMetadata(metadata)

        let options2 = InitializationOptions()
            .withURL(url)
            .checkPasteboardOnInstall(true)
            .withCustomMetadata(metadata)

        XCTAssertEqual(options1, options2)
    }

    func testEquatableWithDifferentURLs() {
        let options1 = InitializationOptions()
            .withURL(URL(string: "https://test1.com")!)

        let options2 = InitializationOptions()
            .withURL(URL(string: "https://test2.com")!)

        XCTAssertNotEqual(options1, options2)
    }

    func testEquatableWithDifferentBooleans() {
        let options1 = InitializationOptions()
            .checkPasteboardOnInstall(true)

        let options2 = InitializationOptions()
            .checkPasteboardOnInstall(false)

        XCTAssertNotEqual(options1, options2)
    }

    func testEquatableWithDifferentMetadata() {
        let options1 = InitializationOptions()
            .withCustomMetadata(["key": "value1"])

        let options2 = InitializationOptions()
            .withCustomMetadata(["key": "value2"])

        XCTAssertNotEqual(options1, options2)
    }

    // MARK: - Description Tests

    func testDescription() {
        let url = URL(string: "https://test.app.link")!

        let options = InitializationOptions()
            .withURL(url)
            .checkPasteboardOnInstall(true)
            .asSceneBasedLaunch(true)

        let description = options.description

        XCTAssertTrue(description.contains("InitializationOptions"))
        XCTAssertTrue(description.contains("https://test.app.link"))
        XCTAssertTrue(description.contains("checkPasteboardOnInstall: true"))
        XCTAssertTrue(description.contains("isSceneBasedLaunch: true"))
    }

    func testDescriptionWithNilURL() {
        let options = InitializationOptions()

        let description = options.description

        XCTAssertTrue(description.contains("launchURL: nil"))
    }

    // MARK: - Sendable Tests

    func testSendableConformance() async {
        let options = InitializationOptions()
            .withURL(URL(string: "https://test.com")!)
            .checkPasteboardOnInstall(true)

        // Pass options across actor boundary to verify Sendable
        let result = await withCheckedContinuation { continuation in
            Task {
                continuation.resume(returning: options)
            }
        }

        XCTAssertEqual(result, options)
    }
}
