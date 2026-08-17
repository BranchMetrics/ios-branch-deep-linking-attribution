//
//  LinkCreationDeterministicTest.swift
//  TestBed-GPTDriverTests
//
//  DETERMINISTIC approach — 100% XCUITest, no AI assertions.
//
//  All actions and assertions use accessibilityIdentifier + standard
//  XCTAssert matchers. GPTDriver is only used for session lifecycle
//  (success/failure reporting is handled by BaseGptDriverTest's
//  tearDownWithError).
//

import XCTest

final class LinkCreationDeterministicTest: BaseGptDriverTest {
    func testCreateBranchLink_generatesValidUrl() throws {
        let url = generateBranchLink()
        XCTAssertFalse(url.isEmpty, "Generated URL should not be empty")
        XCTAssertTrue(
            url.contains("bnctestbed"),
            "TestBed runs in test mode so domain should contain 'bnctestbed', got: \(url)"
        )
    }

    func testCreateBranchLink_urlStartsWithHttps() throws {
        let url = generateBranchLink()
        XCTAssertTrue(
            url.hasPrefix("https://"),
            "Generated URL should start with https://, got: \(url)"
        )
    }
}
