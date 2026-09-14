//
//  ColdLinkInstalledWireValidationTest.swift
//  TestBed-GPTDriverTests
//
//  C1: a Universal Link into a freshly launched process on a device that
//  already has the app. Establishes that install itself rather than inheriting
//  one from a previous harness invocation.
//
//  Why it does its own install: the first version read the install left behind
//  by the C3 run. That made the scenario depend on the previous xcodebuild
//  invocation having written BNCPreferences before its process was torn down,
//  and on the reinstall migrating the container. Measured over five runs it
//  held four times and failed once, which is the shape of a flake that returns
//  on a loaded runner long after anyone remembers why.
//
//  Launching twice inside one test does not make the write instant, but it
//  removes the reinstall, the container migration and xcodebuild's teardown
//  from between the two launches, and puts the wait under this test's control.
//
//  The capture is the second launch: -[AppDelegate setBranchLogFile] deletes
//  branchlogs.txt on every launch, so the first one leaves nothing behind.
//
//  Like the other L1 drivers, deliberately not a BaseGptDriverTest subclass —
//  L1 must run without MOBILEBOOST_API_KEY.
//

import XCTest

final class ColdLinkInstalledWireValidationTest: XCTestCase {
    /// The link the TestBed already resolves from `requestDeepLinkTouchUpInside:`.
    /// Resolved server-side, so a failure here is more likely the fixture than the SDK.
    private let fixtureLink = "https://bnctestbed.app.link/7HTLJ2jXi3b"

    override func setUpWithError() throws {
        continueAfterFailure = true
    }

    func testColdLinkOnInstalledDeviceEmitsWirePayload() throws {
        let app = XCUIApplication()

        // First launch: no link. This is the install, and it is what leaves the
        // randomized tokens behind for the launch that follows.
        app.launchArguments += ["-uiTest", "1"]
        app.launch()
        XCTAssertTrue(
            app.wait(for: .runningForeground, timeout: 30),
            "TestBed app failed to reach runningForeground on the install launch"
        )
        settle(seconds: 10)
        app.terminate()

        // Second launch: the same app, now installed, entered by a link.
        app.launchArguments += ["-testDeepLinkURL", fixtureLink]
        app.launch()
        XCTAssertTrue(
            app.wait(for: .runningForeground, timeout: 30),
            "TestBed app failed to reach runningForeground on the link launch"
        )
        settle(seconds: 12)
    }

    private func settle(seconds: TimeInterval) {
        let waiter = expectation(description: "settle \(seconds)s")
        DispatchQueue.main.asyncAfter(deadline: .now() + seconds) { waiter.fulfill() }
        wait(for: [waiter], timeout: seconds + 5.0)
    }
}
