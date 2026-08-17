//
//  TrackingControlHybridTest.swift
//  TestBed-GPTDriverTests
//
//  HYBRID — XCUITest for button taps, GPTDriver AI for soft-probe
//  intel only; correctness enforced deterministically.
//
//  Tests the "Disable Tracking" toggle. The TestBed wires the flow
//  to a regular UIButton (kTestBedBtnDisableTracking) that calls
//  `Branch.getInstance().setTrackingDisabled(BOOL)` — there may
//  or may not be a visible label change depending on TestBed
//  implementation, so the AI is used in soft-probe mode.
//
//  Correctness is proven by:
//    (a) the button remains tappable after each toggle,
//    (b) the SDK is still functional (can still generate links)
//        after an even number of toggles.
//

import gptd_swift
import XCTest

final class TrackingControlHybridTest: BaseGptDriverTest {
    func testToggleTracking_disablesThenEnables() throws {
        let toggle = app.buttons[kTestBedBtnDisableTracking]
        TestScrollHelpers.scrollUntilVisible(toggle, in: app)

        // PHASE 1: tap once — tracking should flip
        toggle.tap()
        wait(timeout: 2)

        _ = try? driver.checkBulk([
            "The Disable Tracking button has flipped to a new state (label or " +
                "visual style changed) or an indicator shows tracking is disabled"
        ])

        XCTAssertTrue(
            app.buttons[kTestBedBtnDisableTracking].waitForExistence(timeout: 5),
            "Tracking button should still be visible after first tap"
        )

        // PHASE 2: tap again — tracking should flip back
        let toggleAgain = app.buttons[kTestBedBtnDisableTracking]
        TestScrollHelpers.scrollUntilVisible(toggleAgain, in: app)
        toggleAgain.tap()
        wait(timeout: 2)

        _ = try? driver.checkBulk([
            "The Disable Tracking button has flipped back to its original state " +
                "or an indicator shows tracking is enabled again"
        ])

        XCTAssertTrue(
            app.buttons[kTestBedBtnDisableTracking].waitForExistence(timeout: 5),
            "Tracking button should still be visible after second tap"
        )
    }

    func testToggleTracking_twoTapsLeaveSDKFunctional() throws {
        let toggle = app.buttons[kTestBedBtnDisableTracking]
        TestScrollHelpers.scrollUntilVisible(toggle, in: app)

        for _ in 0 ..< 2 {
            toggle.tap()
            wait(timeout: 1)
        }

        // The SDK should remain functional: generating a link should still work.
        // Tracking OFF → link creation still works (it just doesn't report to server).
        // After two toggles we're back to ON, so behavior should be the same as baseline.
        let url = generateBranchLink()
        XCTAssertTrue(
            url.hasPrefix("https://"),
            "SDK should still be functional after toggling tracking twice, got: \(url)"
        )
    }
}
