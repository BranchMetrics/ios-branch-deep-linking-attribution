//
//  BaseGptDriverTest.swift
//  TestBed-GPTDriverTests
//
//  Base class for MobileBoost hybrid tests.
//
//  Initializes GptDriver in NATIVE XCUITest mode (no Appium server
//  required). The API key is read from (in order):
//    1. `MOBILEBOOST_API_KEY` process environment variable
//    2. `MOBILEBOOST_API_KEY` in the test bundle's Info.plist, which
//       is fed at build time by `Config/MobileBoost.xcconfig`
//       including (optionally) `Config/MobileBoost.local.xcconfig`
//       (gitignored).
//

import gptd_swift
import XCTest

class BaseGptDriverTest: XCTestCase {
    var app: XCUIApplication!
    var driver: GptDriver!

    override func setUpWithError() throws {
        continueAfterFailure = false

        app = XCUIApplication()
        app.launchArguments += ["-uiTest", "1"]
        app.launch()

        let apiKey = Self.resolveApiKey()
        precondition(
            !apiKey.isEmpty,
            "MOBILEBOOST_API_KEY is not configured. Copy " +
                "Branch-TestBed/TestBed-GPTDriverTests/Config/MobileBoost.local.xcconfig.example " +
                "to MobileBoost.local.xcconfig and paste your key, or set " +
                "the MOBILEBOOST_API_KEY environment variable."
        )

        driver = GptDriver(apiKey: apiKey, nativeApp: app)
    }

    override func tearDownWithError() throws {
        guard let driver = driver else { return }
        let passed = (testRun?.failureCount ?? 0) == 0
        if passed {
            try? driver.setSessionSucceeded()
        } else {
            try? driver.setSessionFailed()
        }
    }

    // MARK: - Shared helpers

    /// Generates a Branch short link via the "Create Branch Link" button and
    /// waits until the main text field is populated with a valid HTTPS URL,
    /// or the timeout elapses. Returns the final text-field value (or empty
    /// string if nothing appeared).
    @discardableResult
    func generateBranchLink(timeout: TimeInterval = 10) -> String {
        app.buttons[kTestBedBtnCreateBranchLink].tap()

        let field = app.textFields[kTestBedTxtBranchLink]
        _ = field.waitForExistence(timeout: 5)

        let deadline = Date().addingTimeInterval(timeout)
        while Date() < deadline {
            let value = (field.value as? String) ?? ""
            if value.hasPrefix("https://") { return value }
            RunLoop.current.run(until: Date().addingTimeInterval(0.25))
        }
        return (field.value as? String) ?? ""
    }

    /// Polls a text field until its value looks like a real Branch link,
    /// without tapping anything. Useful for tests that trigger link
    /// generation indirectly.
    func waitForLinkInField(_ field: XCUIElement, timeout: TimeInterval = 10) -> String {
        let deadline = Date().addingTimeInterval(timeout)
        while Date() < deadline {
            let value = (field.value as? String) ?? ""
            if value.hasPrefix("https://") { return value }
            RunLoop.current.run(until: Date().addingTimeInterval(0.25))
        }
        return (field.value as? String) ?? ""
    }

    /// Replaces Thread.sleep with a more deterministic wait using XCTWaiter.
    /// This avoids blocking the main thread and is generally preferred in XCUITest.
    func wait(timeout: TimeInterval) {
        let exp = XCTestExpectation(description: "Deterministic wait for \(timeout)s")
        XCTWaiter().wait(for: [exp], timeout: timeout)
    }

    // MARK: - Private

    private static func resolveApiKey() -> String {
        let envKey = ProcessInfo.processInfo.environment["MOBILEBOOST_API_KEY"] ?? ""
        if !envKey.isEmpty { return envKey }

        let plistKey = (Bundle(for: BaseGptDriverTest.self)
            .infoDictionary?["MOBILEBOOST_API_KEY"] as? String) ?? ""
        if !plistKey.isEmpty, plistKey != "$(MOBILEBOOST_API_KEY)" { return plistKey }

        return ""
    }
}
