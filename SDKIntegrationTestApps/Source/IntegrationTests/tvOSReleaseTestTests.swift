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

    func testInitSessionAndSetCPPLevel() throws {
        print("[Test] Starting testInitSessionAndSetCPPLevel")

        let expectation = expectation(description: "InitSession should complete.")

        let sdk = BranchSDKTest(){  params, error in
            print(params as? [String: AnyObject] ?? {})
            expectation.fulfill()
        }
        print("Setting CPP Level to none.")
        sdk.setCPPLevel(status: BranchAttributionLevel.none)
        
        let cppLevel = BNCPreferenceHelper.sharedInstance().attributionLevel
        print("[Test] CPP Level: \(String(describing: cppLevel))")
        
        XCTAssertTrue(cppLevel!.isEqual(to: BranchAttributionLevel.none.rawValue) , "Tracking should be disabled (true)")
        
        print("[Test] Disabling tracking again...")
        sdk.setCPPLevel(status: BranchAttributionLevel.full)
        
        waitForExpectations(timeout: 180, handler: nil)
        print("[Test] testInitSessionAndSetCPPLevel completed")
    }

}
