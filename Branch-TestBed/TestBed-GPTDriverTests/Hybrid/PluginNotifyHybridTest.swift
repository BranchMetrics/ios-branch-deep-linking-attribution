//
//  PluginNotifyHybridTest.swift
//  TestBed-GPTDriverTests
//
//  HYBRID — Tests the `Branch.notifyNativeToInit()` plugin entry
//  point used by React Native / Flutter wrappers to signal that
//  the native SDK should complete its initialization.
//

import gptd_swift
import XCTest

final class PluginNotifyHybridTest: BaseGptDriverTest {
    func testPluginNotifyInit_sdkRemainsFunctional() throws {
        let button = app.buttons[kTestBedBtnPluginNotifyInit]
        TestScrollHelpers.scrollUntilVisible(button, in: app)
        button.tap()

        // Wait for the alert to appear
        let alert = app.alerts.firstMatch
        XCTAssertTrue(alert.waitForExistence(timeout: 5), "An alert should appear after calling notifyNativeToInit")

        // AI: Dismiss the alert
        try driver.execute("Dismiss the alert that says 'notifyNativeToInit called'")

        // Verify the SDK is still functional by generating a Branch link
        let url = generateBranchLink()
        XCTAssertTrue(
            url.hasPrefix("https://"),
            "SDK should still be functional after calling notifyNativeToInit, got: \(url)"
        )
    }
}
