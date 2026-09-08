//
//  tvOSReleaseTestTests.swift
//  tvOSReleaseTestTests
//
//  Created by Nidhi Dixit on 1/30/23.
//

import XCTest
@testable import tvOSReleaseTest
@testable import BranchSDK

final class tvOSReleaseTestTests: XCTestCase {

    private static var testObserver: TestObserver?

    override class func setUp() {
        super.setUp()
        testObserver = TestObserver()
        XCTestObservationCenter.shared.addTestObserver(testObserver!)
        print("[TestSetup] Test observer registered for enhanced GitHub Actions logging")
    }

    override class func tearDown() {
        if let observer = testObserver {
            XCTestObservationCenter.shared.removeTestObserver(observer)
            testObserver = nil
        }
        super.tearDown()
    }

    override func setUpWithError() throws {
        print("[Setup] Setting up test: \(self.name)")
    }

    override func tearDownWithError() throws {
        print("[Teardown] Cleaning up test: \(self.name)")
    }

    func testDummy() throws {
        print("[Test] Running dummy test")
        XCTAssertTrue(true, "Dummy test should always pass")
        print("[Test] Dummy test completed")
    }

    func testRequestDeepLinkDataAndSetCPPLevel() throws {
        print("[Test] Starting testRequestDeepLinkDataAndSetCPPLevel")

        Branch.enableLogging(at: .verbose, withCallback: { message, logLevel, error in
            print(message)
            if let error = error {
                print(error)
            }
        })
        let expectation = expectation(description: "InitSession should complete.")
        // +sharedInstance requires the SDK to be initialized first.
        Branch.initialize(BranchConfiguration(key: "key_live_ok7NoVhyIh1llbtOW6sfHpbnxBlJjiDp"))
        Branch.sharedInstance()?.setConsumerProtectionAttributionLevel(BranchAttributionLevel.none)
        Branch.sharedInstance()?.setConsumerProtectionAttributionLevel(BranchAttributionLevel.full, resetSession:false)
        let sdk = BranchSDKTest() { params, error in
            print(params as? [String: AnyObject] ?? [:])
            print("RequestDeepLinkData called.")
            expectation.fulfill()
        }

        waitForExpectations(timeout: 90, handler: nil)

        print("Setting CPP Level to none.")
        sdk.setCPPLevel(status: BranchAttributionLevel.none)

        let cppLevel = BNCPreferenceHelper.sharedInstance().attributionLevel
        XCTAssertNotNil(cppLevel, "CPP level should not be nil")
        XCTAssertEqual(cppLevel as? String, BranchAttributionLevel.none.rawValue, "CPP level should be none")

        print("[Test] testRequestDeepLinkDataAndSetCPPLevel completed")
    }

}
