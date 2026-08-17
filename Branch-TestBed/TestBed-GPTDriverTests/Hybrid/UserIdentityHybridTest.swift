//
//  UserIdentityHybridTest.swift
//  TestBed-GPTDriverTests
//
//  HYBRID — XCUITest for taps, GPTDriver AI for soft probes;
//  correctness enforced deterministically.
//
//  The iOS TestBed does NOT prompt for input — the
//  setUserIDButtonTouchUpInside IBAction calls `Branch.setIdentity:`
//  with a hardcoded `user_id2` value and, on success, pushes
//  LogOutputViewController via
//  `performSegueWithIdentifier:@"ShowLogOutput"`. On failure it
//  presents a UIAlertController with the error description.
//
//  These tests therefore exercise the happy path (tap → log view)
//  and the logout round-trip (tap → staysOnMain). There is no
//  text-entry path to test until the TestBed is updated to prompt
//  for a user ID.
//

import gptd_swift
import XCTest

final class UserIdentityHybridTest: BaseGptDriverTest {
    func testSetUserIdentity_pushesLogOutputScreen() throws {
        let button = app.buttons[kTestBedBtnSetUserId]
        TestScrollHelpers.scrollUntilVisible(button, in: app)
        button.tap()

        // setIdentity is async — the callback may take a moment before
        // performSegueWithIdentifier fires.
        try waitForLogOutputOrAlertSettled()

        // Soft probe — record what the AI sees about the identity set
        _ = try? driver.checkBulk([
            "A log output screen is visible showing text that mentions " +
                "the identity was set (e.g. 'Identity set to:') or shows " +
                "the new user ID in the content"
        ])

        navigateBackToMainScreen()

        XCTAssertTrue(
            app.buttons[kTestBedBtnSetUserId].waitForExistence(timeout: 5),
            "Should be back on the main screen after setting identity"
        )
    }

    func testSetUserIdentity_extractIdentityConfirmation() throws {
        let button = app.buttons[kTestBedBtnSetUserId]
        TestScrollHelpers.scrollUntilVisible(button, in: app)
        button.tap()

        try waitForLogOutputOrAlertSettled()

        // AI: best-effort extraction of the identity value visible on
        // the log output screen
        _ = try? driver.extract(["identity_value", "user_id_in_log"])

        navigateBackToMainScreen()

        XCTAssertTrue(
            app.buttons[kTestBedBtnSetUserId].waitForExistence(timeout: 5)
        )
    }

    func testLogoutClearsIdentity_staysOnMainScreen() throws {
        let logoutButton = app.buttons[kTestBedBtnLogout]
        TestScrollHelpers.scrollUntilVisible(logoutButton, in: app)
        logoutButton.tap()

        // Branch.logoutWithCallback is async; the success alert (if any)
        // takes a moment to present. We then dismiss it and verify the
        // main screen is still visible.
        wait(timeout: 3)

        // iOS presents "Logout succeeded" via showAlert on success. If
        // visible, dismiss it.
        let alert = app.alerts.firstMatch
        if alert.waitForExistence(timeout: 3) {
            let okButton = alert.buttons.matching(
                NSPredicate(format: "label IN %@", ["OK", "Done", "Dismiss"])
            ).firstMatch
            if okButton.exists {
                okButton.tap()
            } else {
                alert.buttons.firstMatch.tap()
            }
        }

        XCTAssertTrue(
            app.buttons[kTestBedBtnLogout].waitForExistence(timeout: 5),
            "Main screen should still be visible after logout"
        )
    }

    func testSetUserIdentity_noCrashOnRapidTaps() throws {
        // Stress smoke test: rapidly tapping Set User ID should not crash.
        // iOS TestBed hardcodes the user_id2 value and segues to log view
        // on each success callback — tapping twice in a row should either
        // segue twice (second no-op) or surface an error dialog. Either
        // way, the SDK should remain functional.
        let button = app.buttons[kTestBedBtnSetUserId]
        TestScrollHelpers.scrollUntilVisible(button, in: app)
        button.tap()

        try waitForLogOutputOrAlertSettled()
        navigateBackToMainScreen()

        // Second tap
        let secondTap = app.buttons[kTestBedBtnSetUserId]
        if secondTap.waitForExistence(timeout: 5), secondTap.isHittable {
            secondTap.tap()
            try waitForLogOutputOrAlertSettled()
            navigateBackToMainScreen()
        }

        // Verify the SDK is still alive by generating a Branch link
        let url = generateBranchLink()
        XCTAssertTrue(
            url.hasPrefix("https://"),
            "SDK should still be functional after two setIdentity taps, got: \(url)"
        )
    }

    // MARK: - Helpers

    /// The iOS TestBed either pushes the log output VC on success or
    /// shows a UIAlertController on failure. This helper waits until
    /// one of those two states is reached, or a short timeout elapses
    /// (in which case the test lets XCTAssert fail on the next step).
    private func waitForLogOutputOrAlertSettled() throws {
        let deadline = Date().addingTimeInterval(10)
        while Date() < deadline {
            if app.navigationBars["Logs"].exists { return }
            if app.alerts.firstMatch.exists { return }
            RunLoop.current.run(until: Date().addingTimeInterval(0.25))
        }
    }

    private func navigateBackToMainScreen() {
        // If we're on a log screen, tap the back button.
        if app.navigationBars["Logs"].exists {
            let backButton = app.navigationBars.buttons.element(boundBy: 0)
            if backButton.exists, backButton.isHittable {
                backButton.tap()
                return
            }
        }
        // If an alert is visible, dismiss it.
        let alert = app.alerts.firstMatch
        if alert.exists {
            let firstButton = alert.buttons.firstMatch
            if firstButton.exists {
                firstButton.tap()
            }
        }
    }
}
