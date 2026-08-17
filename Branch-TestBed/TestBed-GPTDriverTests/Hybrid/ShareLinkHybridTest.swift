//
//  ShareLinkHybridTest.swift
//  TestBed-GPTDriverTests
//
//  HYBRID — XCUITest for the tap, GPTDriver AI for validating the
//  native iOS share sheet (UIActivityViewController), which
//  XCUITest cannot easily introspect in detail.
//
//  The TestBed has TWO share buttons:
//    - "Share Branch Link" (kTestBedBtnShareLink) — basic
//      UIActivityViewController with the Branch link.
//    - "Share Link with LPLinkMetadata" (kTestBedBtnShareLinkWithMetadata)
//      — same, decorated with rich LinkPresentation metadata.
//  Both present a native iOS share sheet; the differences are
//  only visible in the rich preview card at the top of the sheet.
//

import gptd_swift
import XCTest

final class ShareLinkHybridTest: BaseGptDriverTest {
    func testShareBranchLink_opensShareSheet() throws {
        // DETERMINISTIC: first generate a link so there's something to share
        _ = generateBranchLink()

        // DETERMINISTIC: tap "Share Link"
        let shareButton = app.buttons[kTestBedBtnShareLink]
        TestScrollHelpers.scrollUntilVisible(shareButton, in: app)
        shareButton.tap()

        // AI: validate the iOS share sheet appeared
        try driver.assertBulk([
            "A native iOS share sheet is visible on screen",
            "The share sheet shows a list of sharing destinations (AirDrop, Messages, Mail, etc.) or app icons"
        ])

        // AI: dismiss the share sheet and return to the main screen
        try driver.execute(
            "Dismiss the share sheet (swipe down from the top of the sheet or tap Cancel) " +
                "so the TestBed main screen is visible again"
        )

        // DETERMINISTIC: verify we're back on the main screen
        XCTAssertTrue(
            app.buttons[kTestBedBtnShareLink].waitForExistence(timeout: 5),
            "Share button should be visible again on the main screen"
        )
    }

    func testShareLinkWithMetadata_opensShareSheetWithRichPreview() throws {
        _ = generateBranchLink()

        // DETERMINISTIC: tap "Share Link with LPLinkMetadata"
        let shareMetaButton = app.buttons[kTestBedBtnShareLinkWithMetadata]
        TestScrollHelpers.scrollUntilVisible(shareMetaButton, in: app)
        shareMetaButton.tap()

        // AI: validate the share sheet with rich preview card
        try driver.assert(
            "A native iOS share sheet is visible, showing a rich preview card " +
                "at the top of the sheet (with title, image, or subtitle text) " +
                "from the LinkPresentation metadata, followed by a list of " +
                "sharing destinations."
        )

        // AI: dismiss
        try driver.execute("Dismiss the share sheet and return to the TestBed main screen")
    }

    func testShareBranchLink_containsShareContent() throws {
        _ = generateBranchLink()

        let shareButton = app.buttons[kTestBedBtnShareLink]
        TestScrollHelpers.scrollUntilVisible(shareButton, in: app)
        shareButton.tap()

        // AI: best-effort extraction of what the share sheet exposes
        _ = try? driver.extract(["share_subject_or_title", "share_url_or_message"])

        // AI: verify at minimum that something shareable is on screen
        try driver.assert(
            "The share sheet is visible and contains the Branch link to share — " +
                "either visible in a preview or implied by the destinations shown"
        )

        // AI: dismiss
        try driver.execute("Dismiss the share sheet")
    }
}
