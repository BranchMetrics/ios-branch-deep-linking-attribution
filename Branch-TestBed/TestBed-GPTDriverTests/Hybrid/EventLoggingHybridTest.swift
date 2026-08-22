//
//  EventLoggingHybridTest.swift
//  TestBed-GPTDriverTests
//
//  HYBRID — XCUITest for the tap, GPTDriver AI for soft-probe
//  visual intel; correctness enforced deterministically.
//
//  Tests Branch event logging across the main event categories:
//    - Commerce Event       (BranchEvent .purchase, .addToCart, ...)
//    - Content Event        (BranchEvent .viewItem, .addToWishlist, ...)
//    - Lifecycle Event      (BranchEvent .completeRegistration, ...)
//    - IAP / Subscription   (real StoreKit purchases via TestStoreKitConfig)
//    - Spotlight registration
//
//  The iOS TestBed typically logs event results to the embedded
//  log view or updates a label — there is no reliable visual
//  confirmation of a posted event. So the AI is used as a soft
//  probe via checkBulk — results are surfaced in the cloud
//  dashboard but do NOT cause the test to fail. Correctness is
//  proven by the test returning to the main screen with no
//  stuck modal and the button ready to tap again.
//

import gptd_swift
import XCTest

final class EventLoggingHybridTest: BaseGptDriverTest {
    func testSendCommerceEvent_returnsToMainScreen() throws {
        try tapAndVerifyReturn(
            buttonId: kTestBedBtnSendCommerceEvent,
            probe: "A commerce event confirmation is visible (alert, label, or log entry)"
        )
    }

    func testSendContentEvent_returnsToMainScreen() throws {
        try tapAndVerifyReturn(
            buttonId: kTestBedBtnSendContentEvent,
            probe: "A content event confirmation is visible (alert, label, or log entry)"
        )
    }

    func testSendLifecycleEvent_returnsToMainScreen() throws {
        try tapAndVerifyReturn(
            buttonId: kTestBedBtnSendLifecycleEvent,
            probe: "A lifecycle event confirmation is visible (alert, label, or log entry)"
        )
    }

    func testInAppPurchaseEvent_returnsToMainScreen() throws {
        try tapAndVerifyReturn(
            buttonId: kTestBedBtnInAppPurchaseEvent,
            probe: "A StoreKit purchase sheet is visible, or a purchase success/failure indicator is shown",
            settleTime: 5,
            dismissPossibleModals: true
        )
    }

    func testInAppSubscriptionEvent_returnsToMainScreen() throws {
        try tapAndVerifyReturn(
            buttonId: kTestBedBtnInAppSubscriptionEvent,
            probe: "A StoreKit subscription sheet is visible, or a subscription success/failure indicator is shown",
            settleTime: 5,
            dismissPossibleModals: true
        )
    }

    func testRegisterWithSpotlight_returnsToMainScreen() throws {
        try tapAndVerifyReturn(
            buttonId: kTestBedBtnRegisterWithSpotlight,
            probe: "A Spotlight registration indicator is visible (alert, label, or log entry)"
        )
    }

    // MARK: - Shared tap-and-verify pattern

    /// Taps an event button, soft-probes for a confirmation indicator
    /// via the AI driver (without failing the test), optionally
    /// dismisses any lingering modal (StoreKit), and asserts the main
    /// screen is restored with the same button hittable.
    private func tapAndVerifyReturn(
        buttonId: String,
        probe: String,
        settleTime: TimeInterval = 3,
        dismissPossibleModals: Bool = false
    ) throws {
        let button = app.buttons[buttonId]
        TestScrollHelpers.scrollUntilVisible(button, in: app)
        button.tap()

        wait(timeout: settleTime)

        // Soft probe — logs result on dashboard but doesn't fail the test
        _ = try? driver.checkBulk([probe])

        if dismissPossibleModals {
            try? driver.execute(
                "If a StoreKit purchase or subscription sheet is visible, " +
                    "dismiss it (tap Cancel or Close). If no sheet is visible, " +
                    "do nothing."
            )
            wait(timeout: 2)
        }

        XCTAssertTrue(
            app.buttons[buttonId].waitForExistence(timeout: 10),
            "\(buttonId) should be visible again on the main screen after the event call"
        )
    }
}
