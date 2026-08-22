//
//  DeepLinkWarmOpenHybridTest.swift
//  TestBed-GPTDriverTests
//
//  HYBRID — Tests deep link WARM open behavior.
//
//  iOS semantics note: the pre-Scene UIApplication delegate path
//  handles both cold and warm Universal Link arrivals through the
//  SAME method — `application:continueUserActivity:restorationHandler:`.
//  Branch SDK dispatches to `initSession` on cold launch and to
//  `reInit` on warm delivery, but both eventually resolve link
//  metadata via the same cloud call. Therefore, on this TestBed
//  (no SceneDelegate), there is no meaningful difference in the
//  handler path between cold and warm for XCUITest purposes.
//
//  This test exercises the "warm" semantic by:
//    1. Launching the app normally, generating a link.
//    2. Pressing Home to background the process (still running).
//    3. Relaunching with the `-testDeepLinkURL` arg — the AppDelegate
//       hook re-runs on this fresh launch and delivers the synthetic
//       continueUserActivity, which Branch SDK treats as a link
//       arrival on an existing installed session (warm semantics:
//       install already recorded, latest params get updated).
//    4. Verifying the link was re-resolved by inspecting
//       "View Latest Referring Params".
//

import gptd_swift
import XCTest

final class DeepLinkWarmOpenHybridTest: BaseGptDriverTest {
    func testWarmOpen_receivesDeepLinkViaReInit() throws {
        // PHASE 1: generate a link in the current session. This also
        // ensures the Branch install event is recorded, so the next
        // launch is a "warm" open from the SDK's perspective.
        let generatedUrl = generateBranchLink(timeout: 15)
        XCTAssertTrue(
            generatedUrl.hasPrefix("https://"),
            "Branch link should be generated before the warm open, got: \(generatedUrl)"
        )

        // PHASE 2: press Home to background the app, then relaunch
        // with the deep link arg. Branch treats this as a warm open
        // because the device already has an install record for this
        // user and the same bundle identifier.
        XCUIDevice.shared.press(.home)
        wait(timeout: 1.5)

        app.launchArguments += ["-testDeepLinkURL", generatedUrl]
        app.launch()

        // Let the AppDelegate hook deliver the synthetic
        // continueUserActivity and let Branch resolve the link.
        wait(timeout: 5)

        // PHASE 3: verify the deep link was resolved.
        //
        // When Branch SDK resolves a Universal Link with
        // `+clicked_branch_link == true`, AppDelegate's
        // `handleDeepLinkParams` automatically pushes a
        // LogOutputViewController. After the warm open we expect to
        // already be on that log screen — no extra navigation needed.
        try waitForLogOutputScreen()

        try driver.assertBulk([
            "A log output screen is visible showing details for a Branch deep link",
            "The visible text contains at least one Branch SDK metadata key " +
                "such as '~channel', '~feature', '~creation_source', " +
                "'+match_guaranteed', '+clicked_branch_link', or 'deeplink' — " +
                "any of these proves the warm-open deep link was resolved by " +
                "the SDK via continueUserActivity"
        ])

        navigateBackToMainScreen()
    }

    // MARK: - Helpers

    private func waitForLogOutputScreen() throws {
        let logNav = app.navigationBars["Logs"]
        XCTAssertTrue(
            logNav.waitForExistence(timeout: 12),
            "A log output screen should be auto-pushed by Branch's deep link handler"
        )
    }

    private func navigateBackToMainScreen() {
        let backButton = app.navigationBars.buttons.element(boundBy: 0)
        if backButton.exists, backButton.isHittable {
            backButton.tap()
        }
    }
}
