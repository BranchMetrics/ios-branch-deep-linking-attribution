//
//  L1TestSupport.swift
//  iOSReleaseTestUITests
//
//  Shared fixture and helpers for the L1 wire captures.
//

import XCTest

enum L1Fixture {
    /// Branch link the cold-link and multi-scene captures deliver.
    /// TODO(EMT-4495): replace with the fixture link on nipunreleasetest.app.link.
    static let link = "https://nipunreleasetest.app.link/REPLACE_WITH_FIXTURE"
}

extension XCTestCase {
    /// Waits seconds on the main run loop without failing.
    func settle(seconds: TimeInterval) {
        let waiter = expectation(description: "settle \(seconds)s")
        DispatchQueue.main.asyncAfter(deadline: .now() + seconds) { waiter.fulfill() }
        wait(for: [waiter], timeout: seconds + 5.0)
    }

    /// Launches app and asserts it reaches the foreground.
    func launchAndWait(_ app: XCUIApplication, file: StaticString = #filePath, line: UInt = #line) {
        app.launch()
        XCTAssertTrue(
            app.wait(for: .runningForeground, timeout: 30),
            "iOSReleaseTest failed to reach runningForeground state",
            file: file, line: line
        )
    }

    /// Taps "Open Scene 2" and asserts Scene 2 appears. Fails when the device cannot open a second scene.
    func openSecondScene(_ app: XCUIApplication, file: StaticString = #filePath, line: UInt = #line) {
        let button = app.buttons["openScene2"]
        XCTAssertTrue(button.waitForExistence(timeout: 10), "Open Scene 2 button not found", file: file, line: line)
        XCTAssertTrue(button.isEnabled, "Open Scene 2 is disabled; run the multi-scene captures on an iPad", file: file, line: line)
        button.tap()
        XCTAssertTrue(
            app.staticTexts["sceneTitle-scene2"].waitForExistence(timeout: 15),
            "Scene 2 did not appear",
            file: file, line: line
        )
    }
}
