//
//  BNCServerInterfaceTests.m
//  Branch-SDK-Unhosted-Tests
//
//  Created by Ernest Cho on 7/16/19.
//  Copyright © 2019 Branch, Inc. All rights reserved.
//

#import <XCTest/XCTest.h>
#import "BNCServerInterface.h"

// expose private method
@interface BNCServerInterface()
- (BOOL) isV2APIURL:(NSString *)urlstring baseURL:(NSString *)baseURL;
@end

@interface BNCServerInterfaceTests : XCTestCase

@end

@implementation BNCServerInterfaceTests

- (void)setUp {
    // Put setup code here. This method is called before the invocation of each test method in the class.
}

- (void)tearDown {
    // Put teardown code here. This method is called after the invocation of each test method in the class.
}

- (void)testIsV2Endpoint_Nil {
    BNCServerInterface *service = [BNCServerInterface new];
    NSString *testURL = nil;
    XCTAssertFalse([service isV2APIURL:testURL baseURL:@"api2.branch.io"]);
}

- (void)testIsV2Endpoint_EmptyString {
    BNCServerInterface *service = [BNCServerInterface new];
    NSString *testURL = @"";
    XCTAssertFalse([service isV2APIURL:testURL baseURL:@"api2.branch.io"]);
}

- (void)testIsV2Endpoint_V1Endpoint {
    BNCServerInterface *service = [BNCServerInterface new];
    NSString *testURL = @"https://api2.branch.io/v1/";
    XCTAssertFalse([service isV2APIURL:testURL baseURL:@"api2.branch.io"]);
}

- (void)testIsV2Endpoint_V2Endpoint {
    BNCServerInterface *service = [BNCServerInterface new];
    NSString *testURL = @"https://api2.branch.io/v2/";
    XCTAssertTrue([service isV2APIURL:testURL baseURL:@"api2.branch.io"]);
}

- (void)testIsV2Endpoint_CustomBaseURLWithStandardV2Endpoint {
    BNCServerInterface *service = [BNCServerInterface new];
    NSString *testURL = @"https://api2.branch.io/v2/";
    XCTAssertFalse([service isV2APIURL:testURL baseURL:@"www.custom.com"]);
}

- (void)testIsV2Endpoint_CustomBaseURLWithCustomV2Endpoint {
    BNCServerInterface *service = [BNCServerInterface new];
    NSString *testURL = @"https://www.custom.com/v2/";
    XCTAssertTrue([service isV2APIURL:testURL baseURL:@"www.custom.com"]);
}

@end
