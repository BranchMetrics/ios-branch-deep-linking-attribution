//
//  BrowserExperienceHybridTest.swift
//  TestBed-GPTDriverTests
//
//  HYBRID — Tests the native iOS browser experience: a user taps a
//  Branch Universal Link in Safari, iOS hands off to the TestBed,
//  and the SDK resolves the deep link metadata.
//
//  iOS simulator constraint:
//  Universal Link handoff requires code-signed builds, which tests
//  do not have. We therefore simulate the Safari handoff via the
//  AppDelegate `-testDeepLinkURL` launch-argument hook, which
//  delivers a synthetic NSUserActivity of type
//  NSUserActivityTypeBrowsingWeb — the exact same activity type
//  Safari uses for a real Universal Link tap. From the Branch SDK's
//  perspective there is no difference between this and a real
//  Safari handoff.
//
//  This test is semantically close to `DeepLinkColdOpenHybridTest`
//  but is framed from the browser's perspective and focuses on the
//  "link was resolved via a web-browsing user activity" aspect.
//

import gptd_swift
import XCTest

final class BrowserExperienceHybridTest: BaseGptDriverTest {
    func testSafariHandoff_opensTestBedFromUniversalLink() throws {
        // PHASE 1: generate a Branch Universal Link to hand off
        let generatedUrl = generateBranchLink(timeout: 15)
        XCTAssertTrue(
            generatedUrl.hasPrefix("https://"),
            "Branch link should be generated before the handoff, got: \(generatedUrl)"
        )

        // PHASE 2: simulate the Safari handoff by relaunching with the
        // `-testDeepLinkURL` arg. The AppDelegate hook creates an
        // NSUserActivity of type NSUserActivityTypeBrowsingWeb (the
        // iOS-standard activity type for "user arrived from a web
        // browser") and delivers it to application:continueUserActivity:
        // — byte-for-byte identical to what Safari would send.
        app.terminate()
        app.launchArguments += ["-testDeepLinkURL", generatedUrl]
        app.launch()

        wait(timeout: 5)

        // PHASE 3: verify the synthetic Safari handoff was processed.
        //
        // The Branch SDK auto-pushes a LogOutputViewController when it
        // resolves a Universal Link with `+clicked_branch_link == true`
        // (see AppDelegate.handleDeepLinkParams). After the synthetic
        // handoff we expect to be on that log screen with the link
        // metadata visible.
        try waitForLogOutputScreen()

        try driver.assertBulk([
            "A log output screen is visible showing details for a Branch deep link",
            "The visible text contains at least one Branch SDK metadata key " +
                "such as '~channel', '~feature', '~creation_source', " +
                "'+match_guaranteed', '+clicked_branch_link', or 'deeplink' — " +
                "any of these proves the SDK resolved a link that arrived via " +
                "a web-browsing user activity (NSUserActivityTypeBrowsingWeb)"
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
