//
//  BranchEventPactTests.swift
//  Branch-SDK-Tests
//
//  Created by Hana Park on 6/22/26.
//  Copyright © 2026 Branch, Inc. All rights reserved.
//

import XCTest
import PactSwift

class BranchEventPactTests: XCTestCase {

    static var mockService = MockService(consumer: "Branch-iOS-SDK", provider: "Go-Gateway")

    // ✅ OPTION 1: Disable automatic install/open BEFORE any tests run
    // This must be called at class setup time, before the host app triggers applicationDidBecomeActive
    override class func setUp() {
        super.setUp()
        Branch.disableNextForeground(forTimeInterval: 999999)
    }

    override func setUpWithError() throws {
        // ✅ OPTION 1 TEST: Skip install/open interactions entirely
        // Since we're calling Branch.disableNextForeground, we should NOT receive install/open
        // If this works, it proves the lifecycle issue is solved

        // DON'T register install/open interactions - we don't expect them!
        // Only register the event interaction in each test method
    }

    func DISABLED_setUpWithError_OLD() throws {
        // OLD CODE: Kept for reference but not executed
        // This was registering install/open which we're trying to eliminate

        // Register install interaction (for fresh simulators)
        BranchEventPactTests.mockService
            .uponReceiving("install request")
            .given(
                ProviderState(
                    description: "fresh install",
                    params: [:]
                )
            )
            .withRequest(
                method: .POST,
                path: "/v1/install",
                query: nil,
                headers: ["Content-Type": "application/json"],
                body: [
                    "os_version": Matcher.SomethingLike("18.3.1"),
                    "ios_bundle_id": Matcher.SomethingLike("io.branch.sdk.Branch-TestBed"),
                    "debug": Matcher.SomethingLike(false),
                    "screen_dpi": Matcher.IntegerLike(3),
                    "country": Matcher.SomethingLike("US"),
                    "is_hardware_id_real": Matcher.SomethingLike(true),
                    "opted_in_status": Matcher.SomethingLike("not_determined"),
                    "ios_team_id": Matcher.SomethingLike("R63EM248DP"),
                    "locale": Matcher.SomethingLike("en_US"),
                    "anon_id": Matcher.SomethingLike("73F99E74-1634-410D-AC66-89A71356CCB1"),
                    "sdk": Matcher.SomethingLike("ios3.14.0"),
                    "operational_metrics": Matcher.SomethingLike([
                        "branch_key_source": "info_plist",
                        "checkPasteboardOnInstall": true,
                        "deferInitForPluginRuntime": false,
                        "linked_frameworks": [
                            "AdSupport": true,
                            "AppAdsOnDeviceConversion": false,
                            "ATTrackingManager": true,
                            "FirebaseCrashlytics": true,
                            "SafariServices": false
                        ]
                    ]),
                    "uri_scheme": Matcher.SomethingLike("branchtest"),
                    "metadata": Matcher.SomethingLike(["skan_time_window": "5184000.000000"]),
                    "environment": Matcher.SomethingLike("FULL_APP"),
                    "connection_type": Matcher.SomethingLike("wifi"),
                    "retryNumber": Matcher.IntegerLike(0),
                    "lastest_update_time": Matcher.IntegerLike(1782341960684),
                    "local_ip": Matcher.SomethingLike("192.168.1.51"),
                    "brand": Matcher.SomethingLike("Apple"),
                    "update": Matcher.IntegerLike(0),
                    "cpu_type": Matcher.SomethingLike("16777228"),
                    "screen_height": Matcher.IntegerLike(2556),
                    "branch_sdk_request_unique_id": Matcher.SomethingLike("C9C2C4F1-336D-4107-999E-5374BAD08139-2026062423"),
                    "model": Matcher.SomethingLike("arm64"),
                    "branch_key": Matcher.SomethingLike("key_live_hcnegAumkH7Kv18M8AOHhfgiohpXq5tB"),
                    "user_agent": Matcher.SomethingLike("Mozilla/5.0 (iPhone; CPU iPhone OS 18_3 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Mobile/15E148"),
                    "first_install_time": Matcher.IntegerLike(1782341999340),
                    "hardware_id": Matcher.SomethingLike("283E9910-30A4-4D84-BDC6-7FC10E23BAA1"),
                    "os": Matcher.SomethingLike("iOS"),
                    "branch_sdk_request_timestamp": Matcher.IntegerLike(1782342007116),
                    "hardware_id_type": Matcher.SomethingLike("vendor_id"),
                    "latest_install_time": Matcher.IntegerLike(1782341999340),
                    "screen_width": Matcher.IntegerLike(1179),
                    "build": Matcher.SomethingLike("25F80"),
                    "language": Matcher.SomethingLike("en"),
                    "ios_vendor_id": Matcher.SomethingLike("283E9910-30A4-4D84-BDC6-7FC10E23BAA1"),
                    "app_version": Matcher.SomethingLike("1.1")
                ]
            )
            .willRespondWith(
                status: 200,
                headers: ["Content-Type": "application/json"],
                body: [
                    "ascending_only": Matcher.OneOf(values: [true, false]),
                    "coarse_key": Matcher.OneOf(values: ["low", "medium", "high"]),
                    "data": Matcher.SomethingLike("{\"+clicked_branch_link\":false,\"+is_first_session\":true}"),
                    "invoke_register_app": Matcher.SomethingLike(true),
                    "link": Matcher.SomethingLike("https://bnctestbed.app.link?%24randomized_bundle_token=632466451366126776"),
                    "locked": Matcher.OneOf(values: [true, false]),
                    "randomized_bundle_token": Matcher.SomethingLike("632466451366126776"),
                    "randomized_device_token": Matcher.SomethingLike("1598371453769175212"),
                    "session_id": Matcher.SomethingLike("1598371453819506880"),
                    "update_conversion_value": Matcher.RegexLike(value: "0", pattern: #"^([0-9]|[1-5][0-9]|6[0-3])$"#)
                ]
            )

        // Register open interaction (for already-installed simulators)
        BranchEventPactTests.mockService
            .uponReceiving("open request")
            .given(
                ProviderState(
                    description: "existing installation",
                    params: [:]
                )
            )
            .withRequest(
                method: .POST,
                path: "/v1/open",
                query: nil,
                headers: ["Content-Type": "application/json"],
                body: [
                    "anon_id": Matcher.SomethingLike("4E37FEB1-E59B-47DB-A6EC-1A047874C63F"),
                    "app_version": Matcher.SomethingLike("1.1"),
                    "branch_key": Matcher.SomethingLike("key_live_hcnegAumkH7Kv18M8AOHhfgiohpXq5tB"),
                    "branch_sdk_request_timestamp": Matcher.IntegerLike(1782338365071),
                    "branch_sdk_request_unique_id": Matcher.SomethingLike("9CCB0229-57FB-49E0-9736-2A3C3F604BAC-2026062421"),
                    "brand": Matcher.SomethingLike("Apple"),
                    "build": Matcher.SomethingLike("25F80"),
                    "connection_type": Matcher.SomethingLike("wifi"),
                    "country": Matcher.SomethingLike("US"),
                    "cpu_type": Matcher.SomethingLike("16777228"),
                    "debug": Matcher.SomethingLike(false),
                    "environment": Matcher.SomethingLike("FULL_APP"),
                    "first_install_time": Matcher.IntegerLike(1782319564379),
                    "hardware_id": Matcher.SomethingLike("95D8360C-AF30-484D-A2E8-193F1E3BA1F9"),
                    "hardware_id_type": Matcher.SomethingLike("vendor_id"),
                    "ios_bundle_id": Matcher.SomethingLike("io.branch.sdk.Branch-TestBed"),
                    "ios_team_id": Matcher.SomethingLike("R63EM248DP"),
                    "ios_vendor_id": Matcher.SomethingLike("95D8360C-AF30-484D-A2E8-193F1E3BA1F9"),
                    "is_hardware_id_real": Matcher.SomethingLike(true),
                    "language": Matcher.SomethingLike("en"),
                    "lastest_update_time": Matcher.IntegerLike(1782338361894),
                    "latest_install_time": Matcher.IntegerLike(1782319564379),
                    "local_ip": Matcher.SomethingLike("192.168.1.51"),
                    "locale": Matcher.SomethingLike("en_US"),
                    "metadata": Matcher.SomethingLike(["skan_time_window": "5184000.000000"]),
                    "model": Matcher.SomethingLike("arm64"),
                    "opted_in_status": Matcher.SomethingLike("not_determined"),
                    "os": Matcher.SomethingLike("iOS"),
                    "os_version": Matcher.SomethingLike("26.5"),
                    "previous_update_time": Matcher.IntegerLike(1782195723641),
                    "retryNumber": Matcher.IntegerLike(0),
                    "screen_dpi": Matcher.IntegerLike(3),
                    "screen_height": Matcher.IntegerLike(2622),
                    "screen_width": Matcher.IntegerLike(1206),
                    "sdk": Matcher.SomethingLike("ios3.14.0"),
                    "skan_postback_index": Matcher.SomethingLike("postback-sequence-index-0"),
                    "update": Matcher.IntegerLike(0),
                    "uri_scheme": Matcher.SomethingLike("branchtest"),
                    "user_agent": Matcher.SomethingLike("Mozilla/5.0 (iPhone; CPU iPhone OS 18_7 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Mobile/15E148")
                ]
            )
            .willRespondWith(
                status: 200,
                headers: ["Content-Type": "application/json"],
                body: [
                    "data": Matcher.SomethingLike("{\"+clicked_branch_link\":false,\"+is_first_session\":false}"),
                    "invoke_register_app": Matcher.SomethingLike(true),
                    "link": Matcher.SomethingLike("https://bnctestbed.app.link?%24randomized_bundle_token=632466451366126776"),
                    "randomized_bundle_token": Matcher.SomethingLike("632466451366126776"),
                    "randomized_device_token": Matcher.SomethingLike("1598371453769175212"),
                    "session_id": Matcher.SomethingLike("1598375599242594313")
                ]
            )
    }

    override func tearDown() {
        super.tearDown()
        BNCServerAPI.sharedInstance().customAPIURL = nil
    }
    
    // MARK: - /v2/event/standard Tests
    func testStandardEvent_WithSKANMapping_Returns200WithAllFields() {

        // #1 - Declare the interaction's expectations
        BranchEventPactTests.mockService
            // #2 - Define the interaction description and provider state for this specific interaction
            .uponReceiving("standard event INITIATE_PURCHASE with SKAN mapping")
            .given(
                ProviderState(
                    description: "app has SKAN mapping for INITIATE_PURCHASE",
                    params: [:]
                )
            )
            // #3 - Declare what our client's request will look like
            .withRequest(
                method: .POST,
                path: "/v2/event/standard",
                query: nil,
                headers: ["Content-Type": "application/json"],
                body: [
                    "branch_sdk_request_unique_id": Matcher.SomethingLike("3A8C711E-81CA-4C50-A4F7-8BD89D994292-2026062417"),
                    "retryNumber": Matcher.IntegerLike(0),
                    "branch_sdk_request_timestamp": Matcher.IntegerLike(1782320665955),
                    "branch_key": Matcher.SomethingLike("key_live_hcnegAumkH7Kv18M8AOHhfgiohpXq5tB"),
                    "skan_postback_index": Matcher.SomethingLike("postback-sequence-index-0"),
                    "metadata": Matcher.SomethingLike(["skan_time_window": "5184000.000000"]),
                    "name": Matcher.SomethingLike("INITIATE_PURCHASE"),
                    "user_data": Matcher.SomethingLike([
                        "sdk_version": "3.14.0",
                        "language": "en",
                        "user_agent": "Mozilla/5.0 (iPhone; CPU iPhone OS 18_7 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Mobile/15E148",
                        "anon_id": "4E37FEB1-E59B-47DB-A6EC-1A047874C63F",
                        "country": "US",
                        "screen_height": 2622,
                        "opted_in_status": "not_determined",
                        "connection_type": "wifi",
                        "app_version": "1.1",
                        "brand": "Apple",
                        "cpu_type": "16777228",
                        "locale": "en_US",
                        "os": "iOS",
                        "local_ip": "192.168.1.51",
                        "screen_width": 1206,
                        "build": "25F80",
                        "environment": "FULL_APP",
                        "idfv": "95D8360C-AF30-484D-A2E8-193F1E3BA1F9",
                        "os_version": "26.5",
                        "model": "arm64",
                        "randomized_device_token": "1598371453769175212",
                        "screen_dpi": 3,
                        "developer_identity": "Bobby Branch",
                        "sdk": "ios"
                    ])
                ]
            )
            // #4 - Declare what the provider should respond with
            .willRespondWith(
                status: 200,
                headers: [
                    "Content-Type": "application/json",
                    "X-Branch-App-Id": Matcher.SomethingLike("1234"),
                    "X-Branch-IP": Matcher.SomethingLike("203.0.113.1"),
                    "X-Branch-Request-Id": Matcher.SomethingLike("req-abc-123")
                ],
                body: [
                    "update_conversion_value": Matcher.RegexLike(value: "0", pattern: #"^([0-9]|[1-5][0-9]|6[0-3])$"#),
                    "coarse_key": Matcher.OneOf(values: ["low", "medium", "high"]),
                    "locked": Matcher.OneOf(values: [true, false]),
                    "ascending_only": Matcher.OneOf(values: [true, false])
                ]
            )

        // Run a Pact test and assert **our** API client makes the request exactly as we promised above
        BranchEventPactTests.mockService.run(timeout: 5) { mockServiceURL, done in

            // #6 - _Redirect_ your API calls to the address MockService runs on - replace base URL, but path should be the same
            BNCServerAPI.sharedInstance().customAPIURL = mockServiceURL

            let event = BranchEvent.standardEvent(.initiatePurchase)

            // #7 - Make the API request.
            event.logEvent { success, error in
                // #8 - Test that **our** API client handles the response as expected.
                XCTAssertTrue(success, "Event should succeed")
                XCTAssertNil(error, "Should have no error")
                
                // #9 - Always run the callback. Run it in your successful and failing assertions!
                // Otherwise your test will time out.
                done()
            }
        }
    }

//    func testStandardEvent_WithoutSKANMapping_Returns200WithEmptyObject() {
//
//            BranchEventPactTests.mockService
//                .uponReceiving("standard event with no SKAN mapping")
//                .given(
//                    ProviderState(
//                        description: "app has no SKAN mapping for RATE",
//                        params: [:]
//                    )
//                )
//                .withRequest(
//                    method: .POST,
//                    path: "/v2/event/standard",
//                    query: nil,
//                    headers: ["Content-Type": "application/json"],
//                    body: [
//                        "branch_sdk_request_unique_id": Matcher.SomethingLike("D4B7D630-7EC4-458F-ABAD-2E76537B4725-2026062405"),
//                        "retryNumber": Matcher.IntegerLike(0),
//                        "branch_sdk_request_timestamp": Matcher.IntegerLike(1782279810623),
//                        "branch_key": Matcher.SomethingLike("key_live_hcnegAumkH7Kv18M8AOHhfgiohpXq5tB"),
//                        "skan_postback_index": Matcher.SomethingLike("postback-sequence-index-0"),
//                        "metadata": Matcher.SomethingLike(["skan_time_window": "5184000.000000"]),
//                        "name": Matcher.SomethingLike("RATE"),
//                        "user_data": Matcher.SomethingLike([
//                            "sdk_version": "3.14.0",
//                            "language": "en",
//                            "user_agent": "Mozilla/5.0 (iPhone; CPU iPhone OS 18_7 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Mobile/15E148",
//                            "anon_id": "4E37FEB1-E59B-47DB-A6EC-1A047874C63F",
//                            "country": "US",
//                            "screen_height": 2622,
//                            "opted_in_status": "not_determined",
//                            "connection_type": "wifi",
//                            "app_version": "1.1",
//                            "brand": "Apple",
//                            "cpu_type": "16777228",
//                            "locale": "en_US",
//                            "os": "iOS",
//                            "local_ip": "192.168.1.51",
//                            "screen_width": 1206,
//                            "build": "25F80",
//                            "environment": "FULL_APP",
//                            "idfv": "95D8360C-AF30-484D-A2E8-193F1E3BA1F9",
//                            "os_version": "26.5",
//                            "model": "arm64",
//                            "randomized_device_token": "1598371453769175212",
//                            "screen_dpi": 3,
//                            "developer_identity": "Bobby Branch",
//                            "sdk": "ios"
//                        ])
//                    ]
//                )
//                .willRespondWith(
//                    status: 200,
//                    headers: [
//                        "Content-Type": "application/json",
//                        "X-Branch-App-Id": Matcher.SomethingLike("1234"),
//                        "X-Branch-IP": Matcher.SomethingLike("203.0.113.1"),
//                        "X-Branch-Request-Id": Matcher.SomethingLike("req-abc-123")
//                    ],
//                    body: [
//                        "locked": Matcher.OneOf(values: [true, false]),
//                        "ascending_only": Matcher.OneOf(values: [true, false])
//                    ]
//                )
//
//            BranchEventPactTests.mockService.run(timeout: 5) { mockServiceURL, done in
//
//                BNCServerAPI.sharedInstance().customAPIURL = mockServiceURL
//
//                let event = BranchEvent.standardEvent(.rate)
//
//                event.logEvent { success, error in
//                    XCTAssertTrue(success)
//                    XCTAssertNil(error)
//                    done()
//                }
//            }
//        }

//        func testStandardEvent_WithInvalidKey_Returns400() {
//
//            BranchEventPactTests.mockService
//                .uponReceiving("request with invalid branch_key")
//                .given(
//                    ProviderState(
//                        description: "invalid branch_key",
//                        params: [:]
//                    )
//                )
//                .withRequest(
//                    method: .POST,
//                    path: "/v2/event/standard",
//                    query: nil,
//                    headers: ["Content-Type": "application/json"],
//                    body: [
//                        "name": "PURCHASE",
//                        "branch_key": "invalid_key",
//                        "user_data": [
//                            "os": "iOS",
//                            "sdk": "ios4.2.0"
//                        ]
//                    ]
//                )
//                .willRespondWith(
//                    status: 400,
//                    body: [
//                        "error": [
//                            "code": Matcher.IntegerLike(400),
//                            "message": Matcher.SomethingLike("Invalid branch_key")
//                        ]
//                    ]
//                )
//
//            BranchEventPactTests.mockService.run(timeout: 5) { mockServiceURL, done in
//
//                BNCServerAPI.sharedInstance().customAPIURL = mockServiceURL
//
//                let event = BranchEvent.standardEvent(.purchase)
//
//                event.logEvent { success, error in
//                    XCTAssertFalse(success)
//                    XCTAssertNotNil(error)
//                    done()
//                }
//            }
//        }

        // MARK: - /v2/event/custom Tests
        // TODO: Mirror the 3 tests above for /v2/event/custom endpoint
        // testCustomEvent_WithSKANMapping_Returns200WithAllFields
        // testCustomEvent_WithoutSKANMapping_Returns200WithEmptyObject
        // testCustomEvent_WithInvalidKey_Returns400
}
