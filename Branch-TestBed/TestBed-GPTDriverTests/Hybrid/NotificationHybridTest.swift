//
//  NotificationHybridTest.swift
//  TestBed-GPTDriverTests
//
//  HYBRID — Tests push / local notification delivery carrying a
//  Branch deep link.
//

import gptd_swift
import XCTest

final class NotificationHybridTest: BaseGptDriverTest {
    override func setUpWithError() throws {
        try super.setUpWithError()
        // Skip cleanly when the host-app `btn_notification_send` is not
        // wired — otherwise the warm-up below (and the test body) fail on
        // a missing button instead of reporting a skip.
        try XCTSkipUnless(
            app.buttons[kTestBedBtnNotificationSend].exists,
            "Host-app button btn_notification_send is not wired"
        )
        warmUpNotificationPermission()
    }

    /// Acquire iOS notification permission upfront so the test body's
    /// deterministic SpringBoard banner query is not racing the
    /// `UNUserNotificationCenter.requestAuthorization` dialog.
    ///
    /// `Branch-TestBed/ViewController.m::scheduleNotificationWithURL:` calls
    /// `requestAuthorization` lazily inside the send-notification button
    /// handler. On a cold simulator the resulting "Would Like to Send You
    /// Notifications" alert is queued and only manifests on a later
    /// SpringBoard touch — well after the test body's 15s wait for the
    /// banner has already timed out — and the first scheduled notification
    /// is silently dropped because the authorization callback ran with
    /// `granted == NO` at the moment `addNotificationRequest:` would have
    /// fired.
    ///
    /// We fire a dry tap on the send-notification button here to surface
    /// the dialog, tap "Allow" directly on SpringBoard, and then wait out
    /// the resulting phantom Branch banner (scheduled with a 5s trigger
    /// inside the auth completion handler) so it cannot collide with the
    /// real banner the test body produces. On warm sims (permission
    /// granted in a prior run) the dialog never appears and only the
    /// phantom banner from the dry tap needs to age out.
    private func warmUpNotificationPermission() {
        let button = app.buttons[kTestBedBtnNotificationSend]
        TestScrollHelpers.scrollUntilVisible(button, in: app)
        button.tap()

        let springboard = XCUIApplication(bundleIdentifier: "com.apple.springboard")
        let allowButton = springboard.buttons["Allow"]
        if allowButton.waitForExistence(timeout: 5) {
            allowButton.tap()
        }

        // Phantom Branch banner from the dry tap appears ~5s after the
        // authorization grant. Wait for it; if it shows, let SpringBoard
        // auto-dismiss it (~6-8s) so it does not race the test body.
        let bannerPredicate = NSPredicate(
            format: "identifier == 'NotificationShortLookView' OR identifier == 'NotificationCell' " +
                "OR label CONTAINS[c] 'Branch Test Notification'"
        )
        let phantomBanner = springboard.descendants(matching: .any)
            .matching(bannerPredicate).firstMatch
        if phantomBanner.waitForExistence(timeout: 12) {
            wait(timeout: 10)
        }
    }

    func testSendNotification_createsNotificationWithBranchLink() throws {
        let button = app.buttons[kTestBedBtnNotificationSend]
        TestScrollHelpers.scrollUntilVisible(button, in: app)
        button.tap()

        // 1. DETERMINISTIC STEP:
        // Target the iOS SpringBoard to catch the banner BEFORE XCUITest's
        // interruption monitor forces a wait for it to disappear.
        let springboard = XCUIApplication(bundleIdentifier: "com.apple.springboard")

        // Try multiple banner identifiers / label matchers — exact accessibility id
        // varies between iOS versions. On iOS 18.4 the banner may not register as
        // "NotificationShortLookView"; fall back to a label-contains query.
        let bannerPredicate = NSPredicate(
            format: "identifier == 'NotificationShortLookView' OR identifier == 'NotificationCell' " +
                "OR label CONTAINS[c] 'Branch Test Notification'"
        )
        let banner = springboard.descendants(matching: .any).matching(bannerPredicate).firstMatch

        var tapped = false
        if banner.waitForExistence(timeout: 15) {
            // Coordinate-based center tap — more robust than .tap() because
            // notification banners sometimes have non-tappable edges.
            banner.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5)).tap()
            tapped = true
        }

        if !tapped {
            // 2. AI FALLBACK:
            // If the deterministic tap missed the banner, use AI to open
            // Notification Center and tap the notification by title.
            try driver.execute(
                """
                Slide down 60% from the system time on top of the screen.
                This should open Notification Center.
                Then find the notification titled "Branch Test Notification" and tap it.
                """
            )
        }

        // Give it time to handle the deep link and push the view
        let logNav = app.navigationBars["Logs"]
        XCTAssertTrue(logNav.waitForExistence(timeout: 15),
                      "Tapping the notification should have triggered a deep link and pushed the Logs screen")

        // AI VALIDATION: Verify the content of the logs
        // The Logs screen renders "Successfully Deeplinked:\n\n<text>\nSession Details:\n\n<dict>"
        // where <dict> includes Branch link parameters. Accept any one of several
        // markers to keep this resilient across SDK versions / link payloads.
        try driver.assert(
            "The screen contains Branch session or deep-link information. " +
                "Look for ANY of these markers: 'Successfully Deeplinked', " +
                "'Session Details', '+clicked_branch_link', '~channel', '~feature', " +
                "'~campaign', '+match_guaranteed', or a JSON/dictionary-like block " +
                "with key=value pairs."
        )

        // Cleanup
        if logNav.exists {
            let backButton = app.navigationBars.buttons.element(boundBy: 0)
            if backButton.exists { backButton.tap() }
        }
    }
}
