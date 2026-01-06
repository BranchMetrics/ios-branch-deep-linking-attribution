//
//  iOSReleaseTestTests.swift
//  iOSReleaseTestTests
//
//  Created by Nidhi Dixit on 1/15/23.
//

import XCTest
import BranchSDK

final class iOSReleaseTestTests: XCTestCase {

    override func setUpWithError() throws {
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }

    override func tearDownWithError() throws {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }

    func testSetTrackingDisabled() throws {
        Branch.getInstance().enableLogging()
        Branch.getInstance().initSession(launchOptions: nil) { (params, error) in
              print(params as? [String: AnyObject] ?? {})
          }
        Branch.setTrackingDisabled(true)
        let x = Branch.trackingDisabled()
        assert( x == true)
        Branch.setTrackingDisabled(false)
    }

    func testPerformanceExample() throws {
        // This is an example of a performance test case.
        measure {
            // Put the code you want to measure the time of here.
        }
    }

}
