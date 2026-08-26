//
//  DeepLinkWireValidationTest.swift
//  TestBed-GPTDriverTests
//
//  Drives a deep link resolution so `/v3/deeplink` appears in the capture
//  that scripts/validate_l1_logs.py enforces. Without this driver the
//  endpoint's contract is defined but never exercised.
//
//  WHAT THIS DOES NOT PROVE: that a link delivered BY THE OS — Safari
//  handoff, URI scheme, notification tap — reaches the SDK. Tapping the
//  button is an app-initiated resolution. Delivery across launch states
//  is a separate concern; do not read a green run here as cold-launch
//  coverage of Universal Links.
//
//  The button resolves a hardcoded link (ViewController.m
//  `requestDeepLinkTouchUpInside:`), so this test depends on that link
//  still resolving server-side. A failure here is more likely to be the
//  fixture link than the SDK.
//
//  Runs in its own class, and therefore its own harness invocation with
//  its own OUTPUT_LOG: `-[AppDelegate setBranchLogFile]` deletes
//  branchlogs.txt on every launch, so a second test method relaunching
//  the app would overwrite the previous test's capture.
//
//  Like L1WireValidationTest, this deliberately does NOT inherit from
//  BaseGptDriverTest: it must run without MOBILEBOOST_API_KEY.
//

import XCTest

final class DeepLinkWireValidationTest: XCTestCase {
    /// Pause after launch and after the tap. The first lets session init
    /// finish so the open request is not still in flight; the second lets
    /// `/v3/deeplink` land in branchlogs.txt before the process is torn down.
    private let settleSeconds: TimeInterval = 8.0

    override func setUpWithError() throws {
        continueAfterFailure = true
    }

    /// Launches the TestBed and taps "Request DeepLink", which calls
    /// `requestDeepLinkData:` and posts `/v3/deeplink`.
    ///
    /// Assertions are deliberately minimal — the control exists and is
    /// hittable. Asserting the payload is the validator's job, not the
    /// test's, which is the same split EventAndLinkWireCaptureTest uses.
    func testRequestDeepLinkEmitsWirePayload() throws {
        let app = XCUIApplication()
        app.launchArguments += ["-uiTest", "1"]
        app.launch()

        XCTAssertTrue(
            app.wait(for: .runningForeground, timeout: 30),
            "TestBed app failed to reach runningForeground state"
        )

        settle()

        let button = app.buttons[kTestBedBtnRequestDeepLink]
        TestScrollHelpers.scrollUntilVisible(button, in: app)

        XCTAssertTrue(
            button.exists && button.isHittable,
            "Control '\(kTestBedBtnRequestDeepLink)' not found or not hittable"
        )

        button.tap()
        settle()
    }

    private func settle() {
        let waiter = expectation(description: "settle \(settleSeconds)s")
        DispatchQueue.main.asyncAfter(deadline: .now() + settleSeconds) { waiter.fulfill() }
        wait(for: [waiter], timeout: settleSeconds + 5.0)
    }
}
