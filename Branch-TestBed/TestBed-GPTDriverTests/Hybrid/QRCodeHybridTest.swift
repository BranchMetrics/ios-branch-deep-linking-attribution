//
//  QRCodeHybridTest.swift
//  TestBed-GPTDriverTests
//
//  HYBRID — XCUITest for the tap, GPTDriver AI for the visual
//  assertion on the generated QR code image.
//
//  The "Create QR Code" button triggers an async Branch call that
//  returns image data presented in a modal (UIAlertController-like
//  presentation). XCUITest cannot inspect the pixels of the image,
//  so AI is used to validate that a real QR pattern is visible —
//  not a blank or error image.
//

import gptd_swift
import XCTest

final class QRCodeHybridTest: BaseGptDriverTest {
    func testCreateQRCode_displaysImageInDialog() throws {
        // DETERMINISTIC: scroll to and tap the Create QR Code button
        let qrButton = app.buttons[kTestBedBtnCreateQRCode]
        TestScrollHelpers.scrollUntilVisible(qrButton, in: app)
        qrButton.tap()

        // AI: wait for async QR generation and validate the modal
        try driver.assertBulk([
            "A modal or alert with a QR code image is visible on the screen",
            "The visible area contains a rendered QR code image, not a blank or loading placeholder",
            "There is a dismiss / close / done button available on the modal"
        ])

        // AI: close the modal
        try driver.execute("Tap the button that closes or dismisses the QR code modal")

        // AI: verify we returned to the TestBed main screen
        try driver.assert(
            "The main screen of the Branch TestBed app is visible again, " +
                "showing buttons like 'Create Branch Link' and 'Create QR Code'"
        )
    }

    func testCreateQRCode_imageIsNotBlank() throws {
        let qrButton = app.buttons[kTestBedBtnCreateQRCode]
        TestScrollHelpers.scrollUntilVisible(qrButton, in: app)
        qrButton.tap()

        // AI: validate that the QR image has real content
        try driver.assert(
            "A modal is visible with a QR code image. The image contains a " +
                "QR code pattern (dark modules on a light background), indicating " +
                "a real QR code was generated — not a blank, solid, or error image."
        )

        // AI: close the modal
        try driver.execute("Dismiss the QR code modal")
    }
}
