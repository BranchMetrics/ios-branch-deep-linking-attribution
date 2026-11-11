//
//  ColdLinkInstalledWireValidationTest.swift
//  iOSReleaseTestUITests
//
//  cold_https: a Universal Link into a freshly launched process on a device that already has the
//  app. The first launch is the install; the second, entered by the link, is the capture, since the
//  app deletes branchlogs.txt on launch.
//
//  Scene 2 is never opened, so state restoration has no second scene to reconnect on the relaunch.
//

import XCTest

final class ColdLinkInstalledWireValidationTest: XCTestCase {
    override func setUpWithError() throws {
        continueAfterFailure = true
    }

    func testColdLinkOnInstalledDeviceEmitsWirePayload() throws {
        let app = XCUIApplication()

        app.launchArguments += ["-uiTest", "1"]
        launchAndWait(app)
        settle(seconds: 20)
        app.terminate()

        app.launchArguments += ["-testDeepLinkURL", L1Fixture.link]
        launchAndWait(app)
        settle(seconds: 12)
    }
}
