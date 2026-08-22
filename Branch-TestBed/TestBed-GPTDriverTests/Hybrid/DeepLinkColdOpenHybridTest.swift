//
//  DeepLinkColdOpenHybridTest.swift
//  TestBed-GPTDriverTests
//
//  HYBRID — Tests deep link COLD open (fresh app launch with a
//  Branch Universal Link delivered at startup, exactly as if the
//  user had just tapped a link in Safari/Mail).
//
//  iOS simulator constraint:
//  Universal Link handoff via Safari requires code-signed builds
//  with the `com.apple.developer.associated-domains` entitlement
//  embedded in the signature. Tests run unsigned via
//  `CODE_SIGNING_ALLOWED=NO`, so the `swcutil` daemon never
//  associates the app with `bnctestbed.test-app.link` and Safari
//  does not hand off.
//
//  Solution: the TestBed AppDelegate has a `#if DEBUG` hook in
//  `application:didFinishLaunchingWithOptions:` that reads a
//  `-testDeepLinkURL` launch argument and, if present, delivers
//  the URL via a synthetic NSUserActivity /
//  `application:continueUserActivity:` call after Branch
//  finishes its initial session setup. The resolution path is
//  IDENTICAL to a real Safari Universal Link handoff — the
//  Branch SDK cannot distinguish the two.
//

import gptd_swift
import XCTest

final class DeepLinkColdOpenHybridTest: BaseGptDriverTest {
    func testColdOpen_receivesDeepLinkParams() throws {
        // PHASE 1: generate a real Branch link in the existing session
        let generatedUrl = generateBranchLink(timeout: 15)
        XCTAssertTrue(
            generatedUrl.hasPrefix("https://"),
            "Branch link should be generated before the cold open, got: \(generatedUrl)"
        )

        // PHASE 2: terminate and relaunch with the deep link URL baked
        // into launch arguments. Reusing the same XCUIApplication
        // instance keeps the GptDriver's nativeApp reference valid.
        // The AppDelegate `#if DEBUG` hook picks the arg up and
        // delivers a synthetic continueUserActivity after ~1.5s —
        // enough for Branch.initSessionWithLaunchOptions to register
        // its deep link handler.
        app.terminate()
        app.launchArguments += ["-testDeepLinkURL", generatedUrl]
        app.launch()

        // Give the AppDelegate hook its 1.5s delay plus Branch SDK
        // round-trip time to resolve the link metadata.
        wait(timeout: 5)

        // PHASE 3: verify the deep link was resolved.
        //
        // When Branch SDK resolves a Universal Link with
        // `+clicked_branch_link == true`, AppDelegate's
        // `handleDeepLinkParams` automatically pushes a
        // LogOutputViewController showing the link details. So after
        // the cold open we expect to ALREADY be on the log output
        // screen — no need to tap "View Latest Referring Params".
        try waitForLogOutputScreen()

        try driver.assertBulk([
            "A log output screen is visible showing details for a Branch deep link",
            "The visible text contains at least one Branch SDK metadata key " +
                "such as '~channel', '~feature', '~creation_source', " +
                "'+match_guaranteed', '+clicked_branch_link', or 'deeplink' — " +
                "any of these proves the deep link was resolved by the SDK " +
                "via the continueUserActivity path"
        ])

        navigateBackToMainScreen()
    }

    // MARK: - Helpers

    private func waitForLogOutputScreen() throws {
        // The auto-pushed LogOutputViewController has navigation title "Logs".
        let logNav = app.navigationBars["Logs"]
        XCTAssertTrue(
            logNav.waitForExistence(timeout: 12),
            "A log output screen should be auto-pushed by Branch's deep link " +
                "handler after the synthetic continueUserActivity is delivered"
        )
    }

    private func navigateBackToMainScreen() {
        let backButton = app.navigationBars.buttons.element(boundBy: 0)
        if backButton.exists, backButton.isHittable {
            backButton.tap()
        }
    }
}
