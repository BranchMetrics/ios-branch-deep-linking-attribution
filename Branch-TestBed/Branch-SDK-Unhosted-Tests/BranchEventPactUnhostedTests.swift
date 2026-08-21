//
//  BranchEventPactTests.swift
//  Branch-SDK-Unhosted-Tests
//
//  Created by Hana Park on 6/29/26.
//  Copyright © 2026 Branch, Inc. All rights reserved.
//
//  PURPOSE: Test PACT contract WITHOUT host app to verify whether
//  host-app lifecycle (automatic install/open) was the root cause
//  of blockers in BranchEventPactTests.swift
//
//  KEY DIFFERENCE from BranchEventPactTests.swift:
//  - Does NOT call [Branch getInstance] or event.logEvent()
//  - Instantiates BNCServerInterface and BranchEventRequest directly
//  - No UIApplication dependency, no automatic install/open
//

import XCTest
import PactSwift

final class BranchEventPactUnhostedTests: XCTestCase {

    nonisolated(unsafe) static var mockService = MockService(
        consumer: "Branch-iOS-SDK-Unhosted",
        provider: "Go-Gateway"
    )

    override func tearDown() {
        super.tearDown()
        BNCServerAPI.sharedInstance().customAPIURL = nil
    }

    func testStandardEvent_WithSKANMapping_NoHostApp() {

        BranchEventPactUnhostedTests.mockService
            .uponReceiving("standard event INITIATE_PURCHASE with SKAN mapping (unhosted)")
            .given(
                ProviderState(
                    description: "app has SKAN mapping for INITIATE_PURCHASE",
                    params: [:]
                )
            )
            .withRequest(
                method: .POST,
                path: "/v2/event/standard",
                query: nil,
                headers: ["Content-Type": "application/json"],
                body: [
                    "branch_sdk_request_unique_id": Matcher.SomethingLike("3A8C711E-81CA-4C50-A4F7-8BD89D994292"),
                    "retryNumber": Matcher.IntegerLike(0),
                    "branch_sdk_request_timestamp": Matcher.IntegerLike(1782320665955),
                    "branch_key": Matcher.SomethingLike("key_live_mbErCMtrzeheAWS0Xagg7hjbwDkaZ6SP"),
                    "skan_postback_index": Matcher.SomethingLike("postback-sequence-index-0"),
                    "metadata": Matcher.SomethingLike(["skan_time_window": "5184000.000000"]),
                    "name": Matcher.SomethingLike("INITIATE_PURCHASE"),
                    "user_data": Matcher.SomethingLike([
                        "sdk_version": "3.14.0",
                        "os": "iOS",
                        "os_version": "26.5",
                        "user_agent": "Mozilla/5.0 (iPhone; CPU iPhone OS 18_7 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Mobile/15E148",
                        "environment": "FULL_APP",
                        "sdk": "ios"
                    ])
                ]
            )
            .willRespondWith(
                status: 200,
                headers: [
                    "Content-Type": "application/json",
                    "X-Branch-App-Id": Matcher.SomethingLike("1234"),
                    "X-Branch-IP": Matcher.SomethingLike("203.0.113.1"),
                    "X-Branch-Request-Id": Matcher.SomethingLike("req-abc-123")
                ],
                body: [
                    "update_conversion_value": Matcher.RegexLike(
                        value: "0",
                        pattern: #"^([0-9]|[1-5][0-9]|6[0-3])$"#
                    ),
                    "coarse_key": Matcher.OneOf(values: ["low", "medium", "high"]),
                    "locked": Matcher.OneOf(values: [true, false]),
                    "ascending_only": Matcher.OneOf(values: [true, false])
                ]
            )

        BranchEventPactUnhostedTests.mockService.run(timeout: 5) { mockServiceURL, done in

            // ✅ Redirect SDK networking to mock service
            BNCServerAPI.sharedInstance().customAPIURL = mockServiceURL

            // ✅ No [Branch getInstance] — direct instantiation only
            let serverInterface = BNCServerInterface()
            serverInterface.preferenceHelper = BNCPreferenceHelper.sharedInstance()
   
            // Convert mockServiceURL to URL and append path
            let fullURL = URL(string: mockServiceURL)!.appendingPathComponent("/v2/event/standard")

            let eventDict: [String: Any] = [
                "branch_sdk_request_unique_id": "3A8C711E-81CA-4C50-A4F7-8BD89D994292",
                "retryNumber": 0,
                "branch_sdk_request_timestamp": 1782320665955,
                "branch_key": "key_live_hcnegAumkH7Kv18M8AOHhfgiohpXq5tB",
                "skan_postback_index": "postback-sequence-index-0",
                "metadata": ["skan_time_window": "5184000.000000"],
                "name": "INITIATE_PURCHASE",
                "user_data": [
                    "sdk_version": "3.14.0",
                    "os": "iOS",
                    "os_version": "26.5",
                    "user_agent": "Mozilla/5.0 (iPhone; CPU iPhone OS 18_7 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Mobile/15E148",
                    "environment": "FULL_APP",
                    "sdk": "ios"
                ]
            ]

            // ✅ Construct request directly — no Branch singleton
            let request = BranchEventRequest(
                serverURL: fullURL,
                eventDictionary: eventDict,
                completion: { response, error in
                    if let error = error {
                        print("❌ Error: \(error)")
                    }
                    if let response = response {
                        print("✅ Response: \(response)")
                    }
                    XCTAssertNil(error, "Should have no error")
                    done()
                }
            )

            print("🔍 Making request to: \(fullURL)")
            print("🔍 Mock service URL: \(mockServiceURL)")

            // ✅ Call network layer directly
            request.make(
                serverInterface,
                key: "key_live_hcnegAumkH7Kv18M8AOHhfgiohpXq5tB",
                callback: { response, error in
                    print("🔍 Callback - Response: \(String(describing: response)), Error: \(String(describing: error))")
                }
            )
        }
    }

}
