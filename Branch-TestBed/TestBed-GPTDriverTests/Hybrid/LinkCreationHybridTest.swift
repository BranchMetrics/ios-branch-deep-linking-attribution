//
//  LinkCreationHybridTest.swift
//  TestBed-GPTDriverTests
//
//  HYBRID approach — XCUITest for actions, GPTDriver AI for validation
//  that XCTest matchers cannot express (multi-condition visual checks,
//  text extraction, semantic assertions).
//
//  Deterministic XCUITest handles taps, scrolls, and simple property
//  assertions. The AI driver validates visual outcomes and extracts
//  dynamic values (e.g. the actual URL text) that standard matchers
//  can't return.
//

import gptd_swift
import XCTest

final class LinkCreationHybridTest: BaseGptDriverTest {
    func testCreateBranchLink_fullValidation() throws {
        let url = generateBranchLink()

        // DETERMINISTIC: cheap structural assertions
        XCTAssertTrue(url.hasPrefix("https://"), "URL should be HTTPS, got: \(url)")
        XCTAssertTrue(url.contains("bnctestbed"), "URL should contain bnctestbed, got: \(url)")

        // AI: visual / contextual checks that XCTest cannot express
        try driver.assertBulk([
            "The generated URL is fully visible in the text field and is not truncated or cut off",
            "The URL text field is not showing an error message",
            "The complete URL is readable and starts with 'https://'"
        ])
    }

    func testCreateBranchLink_extractAndValidateUrl() throws {
        _ = generateBranchLink()

        // AI: extract the actual URL text from the screen. On iOS the textField
        // already exposes its value via XCUIElement.value, but we use extract
        // here to validate that the SDK's extract() path works end-to-end.
        let extracted = try driver.extract(["url_in_branch_link_text_field"])
        let url = (extracted["url_in_branch_link_text_field"] as? String ?? "")
            .trimmingCharacters(in: CharacterSet(charactersIn: "\"").union(.whitespaces))

        XCTAssertFalse(url.isEmpty, "Extracted URL should not be empty, got: '\(url)'")
        XCTAssertTrue(
            url.contains("https://"),
            "Extracted URL should contain https, got: '\(url)'"
        )
        XCTAssertTrue(
            url.contains("bnctestbed"),
            "Extracted URL should contain bnctestbed, got: '\(url)'"
        )
    }
}
