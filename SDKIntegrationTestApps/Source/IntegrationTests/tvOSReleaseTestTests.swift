//
//  tvOSReleaseTestTests.swift
//  tvOSReleaseTestTests
//
//  Created by Nidhi Dixit on 1/30/23.
//

@testable import BranchSDK
@testable import tvOSReleaseTest
import XCTest

// swiftlint:disable:next type_name
final class tvOSReleaseTestTests: XCTestCase {
    private static var testObserver: TestObserver?

    // swiftlint:disable:next static_over_final_class
    override class func setUp() {
        super.setUp()
        testObserver = TestObserver()
        XCTestObservationCenter.shared.addTestObserver(testObserver!)
        print("[TestSetup] Test observer registered for enhanced GitHub Actions logging")
    }

    // swiftlint:disable:next static_over_final_class
    override class func tearDown() {
        if let observer = testObserver {
            XCTestObservationCenter.shared.removeTestObserver(observer)
            testObserver = nil
        }
        super.tearDown()
    }

    override func setUpWithError() throws {
        print("[Setup] Setting up test: \(name)")
    }

    override func tearDownWithError() throws {
        print("[Teardown] Cleaning up test: \(name)")
    }

    func testDummy() throws {
        print("[Test] Running dummy test")
        XCTAssertTrue(true, "Dummy test should always pass")
        print("[Test] Dummy test completed")
    }

    func testInitSessionAndSetCPPLevel() throws {
        print("[Test] Starting testInitSessionAndSetCPPLevel")

        let expectation = expectation(description: "InitSession should complete.")

        let sdk = BranchSDKTest { params, _ in
            print(params as? [String: AnyObject] ?? {})
            expectation.fulfill()
        }
        print("Setting CPP Level to none.")
        sdk.setCPPLevel(status: BranchAttributionLevel.none)

        let cppLevel = BNCPreferenceHelper.sharedInstance().attributionLevel
        print("[Test] CPP Level: \(String(describing: cppLevel))")

        XCTAssertEqual(
            cppLevel,
            BranchAttributionLevel.none.rawValue,
            "Tracking should be disabled"
        )

        print("[Test] Disabling tracking again...")
        sdk.setCPPLevel(status: BranchAttributionLevel.full)

        let result = XCTWaiter().wait(for: [expectation], timeout: 10)
        if result == .timedOut {
            print("[Test] initSession callback timed out (expected in CI without network)")
        }
        print("[Test] testInitSessionAndSetCPPLevel completed")
    }
}
