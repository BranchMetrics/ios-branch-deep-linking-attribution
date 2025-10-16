//
//  iOSReleaseTestTests.swift
//  iOSReleaseTestTests
//
//  Created by Nidhi Dixit on 1/15/23.
//

import XCTest
@testable import iOSReleaseTest

final class iOSReleaseTestTests: XCTestCase {
    
    private static var testObserver: TestObserver?

    override class func setUp() {
        super.setUp()
        
        // Register the test observer for detailed logging in GitHub Actions
        testObserver = TestObserver()
        XCTestObservationCenter.shared.addTestObserver(testObserver!)
        
        print("[TestSetup] Test observer registered for enhanced GitHub Actions logging")
        
    }
    
    override class func tearDown() {
        // Remove the test observer
        if let observer = testObserver {
            XCTestObservationCenter.shared.removeTestObserver(observer)
            testObserver = nil
        }
        
        super.tearDown()
    }

    override func setUpWithError() throws {
        // Put setup code here. This method is called before the invocation of each test method in the class.
        print("[Setup] Setting up test: \(self.name)")
    }

    override func tearDownWithError() throws {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        print("[Teardown] Cleaning up test: \(self.name)")
    }
    
    func testDummy() throws {
        print("[Test] Running dummy test")
        XCTAssertTrue(true, "Dummy test should always pass")
        print("[Test] Dummy test completed")
    }

    func testSetTrackingDisabled() throws {
        print("[Test] Starting testSetTrackingDisabled")

        let sdk = BranchSDKTest()
        
        print("[Test] Disabling tracking...")
        sdk.disableTracking(status: true)
        
        let trackingStatus = sdk.trackingStatus()
        print("[Test] Tracking status: \(trackingStatus)")
        
        XCTAssertTrue(trackingStatus, "Tracking should be disabled (true)")
        
        print("[Test] Disabling tracking again...")
        sdk.disableTracking(status: true)
        
        print("[Test] testSetTrackingDisabled completed successfully")
    }

    func testPerformanceExample() throws {
        print("[Test] Starting performance test *********************")
        measure {
            print("[Performance] Measuring performance...********************")
            let sdk = BranchSDKTest()
            sdk.disableTracking(status: false)
            _ = sdk.trackingStatus()
        }
        
        print("[Test] Performance test completed")
    }

}
