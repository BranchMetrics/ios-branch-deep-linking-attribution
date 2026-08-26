//
//  EventAndLinkWireCaptureTest.swift
//  TestBed-GPTDriverTests
//
//  Wire-capture driver for EMT-4022 (event / link endpoint schema survey).
//
//  This test exists to DRIVE the app deterministically, not to assert
//  behaviour. It taps the link-creation control and the five event
//  controls with a fixed pause between them, so that an external
//  `xcrun simctl spawn <udid> log stream` capture can attribute each
//  outbound request to the control that produced it, by timestamp.
//
//  The assertions are deliberately minimal and honest: each control
//  exists and is hittable. Nothing here asserts that a request was
//  made, which endpoint it hit, or what it contained — that is the
//  job of the log analysis this test feeds.
//
//  Like L1WireValidationTest, this deliberately does NOT inherit from
//  BaseGptDriverTest: it must run without MOBILEBOOST_API_KEY, since
//  wire capture is a measurement task and not an AI-driven test.
//
//  Three of the six controls open a UIAlertControllerStyleActionSheet
//  rather than firing a request directly (commerce / content /
//  lifecycle). For those, the sheet option is selected too — tapping
//  the button alone produces no wire traffic and would leave a modal
//  sheet blocking every subsequent tap.
//

import XCTest

final class EventAndLinkWireCaptureTest: XCTestCase {
    /// Pause after each tap. Long enough that requests from different
    /// controls land in distinct timestamp clusters in the log capture.
    private let settleSeconds: TimeInterval = 8.0

    private var app: XCUIApplication!

    override func setUpWithError() throws {
        // Keep driving even if one control fails to appear — a partial
        // capture of five controls is more useful than none, and the
        // failure is still reported.
        continueAfterFailure = true
    }

    func testDriveEventAndLinkControlsForWireCapture() throws {
        app = XCUIApplication()
        app.launch()

        XCTAssertTrue(
            app.wait(for: .runningForeground, timeout: 30),
            "TestBed app failed to reach runningForeground state"
        )

        // Let session init settle so `/v1/install` (or `/v1/open`) is
        // clearly separated from the first control-driven request.
        mark("launch-settled")
        sleep(seconds: settleSeconds)

        tapControl(kTestBedBtnCreateBranchLink, label: "create-branch-link")
        sleep(seconds: settleSeconds)

        tapControl(kTestBedBtnSendCommerceEvent, label: "send-commerce-event")
        chooseSheetOption("Add To Cart")
        sleep(seconds: settleSeconds)
        dismissAlertIfPresent()

        tapControl(kTestBedBtnSendContentEvent, label: "send-content-event")
        chooseSheetOption("View Item")
        sleep(seconds: settleSeconds)
        dismissAlertIfPresent()

        tapControl(kTestBedBtnSendLifecycleEvent, label: "send-lifecycle-event")
        chooseSheetOption("Complete Registration")
        sleep(seconds: settleSeconds)
        dismissAlertIfPresent()

        tapControl(kTestBedBtnInAppPurchaseEvent, label: "in-app-purchase-event")
        sleep(seconds: settleSeconds)
        dismissAlertIfPresent()

        tapControl(kTestBedBtnInAppSubscriptionEvent, label: "in-app-subscription-event")
        sleep(seconds: settleSeconds)
        dismissAlertIfPresent()

        mark("run-complete")
    }

    // MARK: - Driving helpers

    /// Scrolls the control into view, records a timestamped marker, and taps it.
    /// Asserts only existence and hittability.
    private func tapControl(_ identifier: String, label: String) {
        let button = app.buttons[identifier]
        TestScrollHelpers.scrollUntilVisible(button, in: app)

        guard button.exists, button.isHittable else {
            XCTFail("Control '\(identifier)' (\(label)) not found or not hittable")
            return
        }

        mark("tap \(label) id=\(identifier)")
        button.tap()
    }

    /// Selects an option from the action sheet a control presented.
    /// Not every control presents one, so a missing sheet is reported
    /// rather than failed — the tap itself is what the capture needs.
    private func chooseSheetOption(_ title: String) {
        let option = app.sheets.buttons[title].firstMatch
        if option.waitForExistence(timeout: 5), option.isHittable {
            mark("sheet-option \(title)")
            option.tap()
            return
        }

        // Fall back to a plain alert presentation (iPad-style or if the
        // sheet style changes), then give up loudly.
        let alertOption = app.alerts.buttons[title].firstMatch
        if alertOption.exists, alertOption.isHittable {
            mark("alert-option \(title)")
            alertOption.tap()
            return
        }

        mark("sheet-option-missing \(title)")
    }

    /// Dismisses the "Successfully logged…" confirmation alert if one is up,
    /// so the next control is reachable.
    private func dismissAlertIfPresent() {
        let okButton = app.alerts.buttons["OK"].firstMatch
        if okButton.exists, okButton.isHittable {
            okButton.tap()
        }
    }

    // MARK: - Correlation helpers

    /// Emits a timestamped marker from the test runner process. Capturing
    /// the runner alongside the host app puts markers and requests on one
    /// clock, which is how each request gets attributed to a control.
    private func mark(_ text: String) {
        NSLog("[WIRECAP] %@", text)
    }

    private func sleep(seconds: TimeInterval) {
        let waiter = expectation(description: "settle \(seconds)s")
        DispatchQueue.main.asyncAfter(deadline: .now() + seconds) { waiter.fulfill() }
        wait(for: [waiter], timeout: seconds + 5.0)
    }
}
