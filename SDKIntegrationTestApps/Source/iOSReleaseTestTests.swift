//
//  iOSReleaseTestTests.swift
//  iOSReleaseTestTests
//
//  Created by Nidhi Dixit on 1/15/23.
//

import XCTest
@testable import iOSReleaseTest
import BranchSDK

final class iOSReleaseTestTests: XCTestCase {
    
    private static var testObserver: TestObserver?

    override class func setUp() {
        super.setUp()
        
        // Register the test observer for detailed logging in GitHub Actions
        testObserver = TestObserver()
        XCTestObservationCenter.shared.addTestObserver(testObserver!)
        
        print("[TestSetup] Test observer registered for enhanced GitHub Actions logging")
        
        Branch.setCallbackForTracingRequests { url, request, response, error, serviceURL in
                   // traceQueue.async {
                        print("Tracing Callback Start ********************");
                        print("URL: " + (url ?? ""));
                        if let dict = request as? [AnyHashable: Any] {
                            let stringDict = dict.reduce(into: [String: Any]()) { result, entry in
                                if let key = entry.key as? String {
                                    result[key] = entry.value
                                }
                            }
                            
                            if let data = try? JSONSerialization.data(withJSONObject: stringDict, options: [.prettyPrinted]),
                               let json = String(data: data, encoding: .utf8) {
                                print("Request JSON:\n\(json)")
                            }
                        } else {
                            print("Request JSON: null")
                        }
                        
                        if let dict = response as? [AnyHashable: Any] {
                            let stringDict = dict.reduce(into: [String: Any]()) { result, entry in
                                if let key = entry.key as? String {
                                    result[key] = entry.value
                                }
                            }
                            
                            if let data = try? JSONSerialization.data(withJSONObject: stringDict, options: [.prettyPrinted]),
                               let json = String(data: data, encoding: .utf8) {
                                print("Response JSON:\n\(json)")
                            }
                        } else {
                            print("Response JSON: null")
                        }
                        print("Error: " + (error.debugDescription));
                        print("Request Service URL: " + (serviceURL!));
                    
                        print("Tracing Callback End ********************");
                  //  }
                }
        
        
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

        let expectation = expectation(description: "My asynchronous operation should complete")

        let sdk = BranchSDKTest(){  params, error in
            print(params as? [String: AnyObject] ?? {})
            expectation.fulfill()
        }
        
        print("[Test] Disabling tracking...")
        sdk.disableTracking(status: true)
        
        let trackingStatus = sdk.trackingStatus()
        print("[Test] Tracking status: \(trackingStatus)")
        
        XCTAssertTrue(trackingStatus, "Tracking should be disabled (true)")
        
        print("[Test] Disabling tracking again...")
        sdk.disableTracking(status: true)
        
        waitForExpectations(timeout: 15, handler: nil) // Wait for up to 5 seconds

        
        print("[Test] testSetTrackingDisabled completed")
    }

}
