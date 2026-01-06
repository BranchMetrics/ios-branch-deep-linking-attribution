//
//  tvOSReleaseTestTests.swift
//  tvOSReleaseTestTests
//
//  Created by Nidhi Dixit on 1/30/23.
//

import XCTest
import Branch

@testable import tvOSReleaseTest

final class tvOSReleaseTestTests: XCTestCase {

    override func setUpWithError() throws {
        // Put setup code here. This method is called before the invocation of each test method in the class.
        Branch.init()
    }

    override func tearDownWithError() throws {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }

    func testSetTrackingDisabled() throws {
        // This is an example of a functional test case.
        // Use XCTAssert and related functions to verify your tests produce the correct results.
        // Any test you write for XCTest can be annotated as throws and async.
        // Mark your test throws to produce an unexpected failure when your test encounters an uncaught error.
        // Mark your test async to allow awaiting for asynchronous code to complete. Check the results with assertions afterwards.
        
        Branch.setTrackingDisabled(true)
        let x = Branch.trackingDisabled()
        assert( x == true)
        Branch.setTrackingDisabled(false)
        print("Test completed.")
    }


    func testPerformanceExample() throws {
        // This is an example of a performance test case.
        self.measure {
            // Put the code you want to measure the time of here.
        }
    }

}
