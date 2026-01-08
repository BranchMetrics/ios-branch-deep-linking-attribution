//
//  iOSReleaseTestTests.swift
//  iOSReleaseTestTests
//
//  Created by Nidhi Dixit on 1/15/23.
//

import XCTest
@testable import iOSReleaseTest

final class iOSReleaseTestTests: XCTestCase {

    override func setUpWithError() throws {
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }

    override func tearDownWithError() throws {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }

    func testSetTrackingDisabled() throws {

        let sdk = BranchSDKTest()
        
        sdk.disableTracking(status: true)
        let x = sdk.trackingStatus()
        assert( x == true)
        sdk.disableTracking(status: true)
    }

    func testPerformanceExample() throws {
        // This is an example of a performance test case.
        measure {
            // Put the code you want to measure the time of here.
        }
    }

}
