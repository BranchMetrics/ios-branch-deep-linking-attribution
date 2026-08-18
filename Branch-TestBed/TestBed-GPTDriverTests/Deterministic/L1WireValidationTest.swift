//
//  L1WireValidationTest.swift
//  TestBed-GPTDriverTests
//
//  Layer 1 wire validation test.
//
//  Launches the Branch-TestBed host app and waits long enough for the SDK
//  initialization to fire `/v1/install`. The AppDelegate's
//  `BranchAdvancedLogCallback` writes each outbound request as
//
//      [BranchLog] Got <URL> Request: <jsonBody>
//
//  into ~/Documents/branchlogs.txt. After the test process exits, the CI
//  script (scripts/run_l1_instrumented.sh) pulls that file out of the
//  simulator's app container with `xcrun simctl get_app_container ... data`
//  and runs scripts/validate_l1_logs.py against it.
//
//  This test deliberately does NOT inherit from BaseGptDriverTest because
//  L1 validation must run without MOBILEBOOST_API_KEY (the API key is only
//  required for AI-driven hybrid tests).
//

import XCTest

final class L1WireValidationTest: XCTestCase {
    override func setUpWithError() throws {
        continueAfterFailure = true
    }

    /// Launches the TestBed and waits for the SDK to fire `/v1/install`.
    ///
    /// Why the explicit wait: Branch's session init posts asynchronously
    /// from a background queue; the AppDelegate callback runs after the
    /// network response (or after a short timeout if offline). 8 seconds
    /// is comfortably above the typical install round-trip on the macOS
    /// runner and well below the workflow's 30-minute timeout.
    func testInstallRequestEmitsWirePayload() throws {
        let app = XCUIApplication()
        app.launchArguments += ["-uiTest", "1"]
        app.launch()

        // Wait for the host app to register as foreground; this is when
        // Branch.initSession runs and `/v1/install` is queued.
        XCTAssertTrue(
            app.wait(for: .runningForeground, timeout: 30),
            "TestBed app failed to reach runningForeground state"
        )

        // Give the SDK enough time to perform the install POST and the
        // AppDelegate callback enough time to write the request line to
        // branchlogs.txt.
        let waitExpectation = expectation(description: "Wait for SDK /v1/install to fire")
        DispatchQueue.main.asyncAfter(deadline: .now() + 8.0) {
            waitExpectation.fulfill()
        }
        wait(for: [waitExpectation], timeout: 12.0)
    }
}
