//
//  L1WireValidationTest.swift
//  iOSReleaseTestUITests
//
//  install: launches iOSReleaseTest with no link and waits for the launch traffic. The app writes
//  each request to Documents/branchlogs.txt; scripts/run_l1_instrumented.sh pulls the file and
//  scripts/validate_l1_logs.py checks it against the scenario contract.
//
//  Needs no credential: L1 validation must run keyless.
//

import XCTest

final class L1WireValidationTest: XCTestCase {
    override func setUpWithError() throws {
        continueAfterFailure = true
    }

    func testInstallRequestEmitsWirePayload() throws {
        let app = XCUIApplication()
        app.launchArguments += ["-uiTest", "1"]
        launchAndWait(app)
        settle(seconds: 8)
    }
}
