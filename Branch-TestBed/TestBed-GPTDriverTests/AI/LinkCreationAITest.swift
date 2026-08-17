//
//  LinkCreationAITest.swift
//  TestBed-GPTDriverTests
//
//  AI approach — 100% GPTDriver.
//
//  Every action and assertion is AI-driven via natural language. The
//  agent reads the screen and performs actions autonomously, without
//  any accessibilityIdentifier or XCUIElement queries.
//
//  Best for: flows where the UI changes frequently, where identifiers
//  are unavailable, or where visual/semantic correctness matters more
//  than structural assertions.
//

import gptd_swift
import XCTest

final class LinkCreationAITest: BaseGptDriverTest {
    func testCreateBranchLink_generatesValidUrl() throws {
        // Ensure we are on the main screen
        try driver.execute(
            "You should see the main screen of the Branch TestBed app with a list " +
                "of buttons. If you are not on the main screen, tap the back button " +
                "(top-left) until you reach it."
        )

        // Tap the button (by natural language, not identifier)
        try driver.execute("Tap on the button labeled 'Create Branch Link'")

        // Wait for the link to appear
        try driver.execute(
            "Wait up to 5 seconds for a URL starting with 'https://' to appear " +
                "in the text field near the top of the screen."
        )

        // Validate multiple conditions at once
        try driver.assertBulk([
            "The text field at the top of the screen contains a URL that starts with 'https://'",
            "The URL shown in the text field contains 'bnctestbed' in the domain"
        ])
    }

    func testCreateBranchLink_urlStartsWithHttps() throws {
        try driver.execute("Tap the 'Create Branch Link' button")
        try driver.execute(
            "Wait a few seconds for the generated link to appear in the " +
                "text field at the top of the screen"
        )
        try driver.assert("The generated URL in the text field starts with 'https://'")
    }
}
