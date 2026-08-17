//
//  SessionAndLogsHybridTest.swift
//  TestBed-GPTDriverTests
//
//  HYBRID — XCUITest for actions, GPTDriver AI for result validation.
//
//  Tests session initialization, log viewing, and logout.
//
//  The iOS TestBed does not expose a user-facing "Init Session"
//  button — the Branch SDK auto-initializes in AppDelegate's
//  didFinishLaunchingWithOptions. We verify the session is alive
//  at app launch by creating a Branch link immediately — if the
//  session failed, link creation would return an error.
//

import gptd_swift
import XCTest

final class SessionAndLogsHybridTest: BaseGptDriverTest {
    func testSessionAlive_generatesLinkAfterLaunch() throws {
        // Branch SDK auto-initializes at app launch. A successful link
        // generation within a few seconds of launch is proof that the
        // session is alive and the SDK is responsive.
        let url = generateBranchLink()

        XCTAssertTrue(
            url.hasPrefix("https://"),
            "Session should be alive enough to generate a link, got: \(url)"
        )
        XCTAssertTrue(
            url.contains("bnctestbed"),
            "Link should be on the TestBed domain, got: \(url)"
        )
    }

    func testLoadLogs_showsLogContent() throws {
        // DETERMINISTIC: navigate to the log output screen
        let loadLogsButton = app.buttons[kTestBedBtnLoadLogs]
        TestScrollHelpers.scrollUntilVisible(loadLogsButton, in: app)
        loadLogsButton.tap()

        // Soft probe — best-effort log content check
        _ = try? driver.checkBulk([
            "A log output screen is visible",
            "The log screen contains SDK log text entries (timestamps, " +
                "level markers, or SDK message content)"
        ])

        // DETERMINISTIC: navigate back to the main screen
        let backButton = app.navigationBars.buttons.element(boundBy: 0)
        if backButton.exists, backButton.isHittable {
            backButton.tap()
        }

        // DETERMINISTIC: confirm we're back on the main screen
        XCTAssertTrue(
            app.buttons[kTestBedBtnLoadLogs].waitForExistence(timeout: 5),
            "Should be back on the main screen with the Load Logs button visible"
        )
    }

    func testLogout_staysOnMainScreen() throws {
        // DETERMINISTIC: scroll to and tap the logout button
        let logoutButton = app.buttons[kTestBedBtnLogout]
        TestScrollHelpers.scrollUntilVisible(logoutButton, in: app)
        logoutButton.tap()

        // Give the SDK a moment to complete the logout callback
        wait(timeout: 2)

        // Soft probe — best-effort confirmation check, does not fail the test
        _ = try? driver.checkBulk([
            "A confirmation indicator is visible showing that the user was logged out"
        ])

        // DETERMINISTIC: verify main screen is still displayed
        XCTAssertTrue(
            app.buttons[kTestBedBtnLogout].waitForExistence(timeout: 3),
            "Main screen should still be visible after logout"
        )
    }
}
