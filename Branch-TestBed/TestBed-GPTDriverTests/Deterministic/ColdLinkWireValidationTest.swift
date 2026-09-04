//
//  ColdLinkWireValidationTest.swift
//  TestBed-GPTDriverTests
//
//  Drives a Universal Link into a freshly launched process so the capture
//  holds the link-open sequence rather than an organic one.
//
//  The link is delivered by the AppDelegate's `-testDeepLinkURL` hook, which
//  wraps it in an NSUserActivity and calls `application:continueUserActivity:`
//  1.5s after launch. That is the same entry point Safari handoff uses and the
//  SDK cannot distinguish the two.
//
//  WHAT THIS DOES NOT PROVE: that the OS delivers the link. Real Universal Link
//  handoff needs a signed build carrying `com.apple.developer.associated-domains`,
//  which CI cannot produce. The process is cold; the delivery is synthetic and
//  arrives after launch.
//
//  Runs in its own class for its own capture: `-[AppDelegate setBranchLogFile]`
//  deletes branchlogs.txt on every launch, so a second method relaunching the
//  app would overwrite this one's log.
//
//  Like the other L1 drivers, deliberately not a BaseGptDriverTest subclass —
//  L1 must run without MOBILEBOOST_API_KEY.
//

import XCTest

final class ColdLinkWireValidationTest: XCTestCase {
    /// The link the TestBed already resolves from `requestDeepLinkTouchUpInside:`.
    /// Resolved server-side, so a failure here is more likely the fixture than the SDK.
    private let fixtureLink = "https://bnctestbed.app.link/7HTLJ2jXi3b"

    /// Covers the hook's 1.5s delay plus the resolve and attribution round trips.
    private let settleSeconds: TimeInterval = 12.0

    override func setUpWithError() throws {
        continueAfterFailure = true
    }

    func testColdLinkEmitsWirePayload() throws {
        let app = XCUIApplication()
        app.launchArguments += ["-uiTest", "1", "-testDeepLinkURL", fixtureLink]
        app.launch()

        XCTAssertTrue(
            app.wait(for: .runningForeground, timeout: 30),
            "TestBed app failed to reach runningForeground state"
        )

        let waiter = expectation(description: "settle \(settleSeconds)s")
        DispatchQueue.main.asyncAfter(deadline: .now() + settleSeconds) { waiter.fulfill() }
        wait(for: [waiter], timeout: settleSeconds + 5.0)
    }
}
