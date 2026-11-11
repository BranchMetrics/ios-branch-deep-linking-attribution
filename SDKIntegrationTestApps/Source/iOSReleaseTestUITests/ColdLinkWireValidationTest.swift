//
//  ColdLinkWireValidationTest.swift
//  iOSReleaseTestUITests
//
//  cold_firstInstall: a Universal Link delivered into a freshly launched process with no prior
//  install. The `-testDeepLinkURL` hook in SceneDelegate registers Scene 1's callback without the
//  no-link lookup and delivers the link with requestDeepLinkData(scene:userActivity:), so the
//  launch sends one /v3/deeplink.
//
//  Does not prove that the OS delivers the link: the delivery is synthetic.
//
//  Runs in its own class for its own capture, since the app deletes branchlogs.txt on launch.
//

import XCTest

final class ColdLinkWireValidationTest: XCTestCase {
    override func setUpWithError() throws {
        continueAfterFailure = true
    }

    func testColdLinkEmitsWirePayload() throws {
        let app = XCUIApplication()
        app.launchArguments += ["-uiTest", "1", "-testDeepLinkURL", L1Fixture.link]
        launchAndWait(app)
        settle(seconds: 15)
    }
}
