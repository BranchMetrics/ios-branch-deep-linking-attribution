//
//  BranchGetAppListRequestTests.m
//  Branch-TestBed
//
//  Created by Graham Mueller on 6/12/15.
//  Copyright (c) 2015 Branch Metrics. All rights reserved.
//
#import "BranchTest.h"
#import "BranchGetAppListRequest.h"
#import "BranchConstants.h"
#import "BNCPreferenceHelper.h"
#import <OCMock/OCMock.h>
#import "BNCPreferenceHelper.h"
#import "BNCEncodingUtils.h"

@interface BranchGetAppListRequestTests : BranchTest

@end

@implementation BranchGetAppListRequestTests

- (void)testRequestBody {
    BranchGetAppListRequest *request = [[BranchGetAppListRequest alloc] init];
    id serverInterfaceMock = OCMClassMock([BNCServerInterface class]);
    [[serverInterfaceMock expect] getRequest:nil url:[self stringMatchingPattern:BRANCH_REQUEST_ENDPOINT_GET_APP_LIST] key:[OCMArg any] callback:[OCMArg any]];
    
    [request makeRequest:serverInterfaceMock key:nil callback:NULL];
    
    [serverInterfaceMock verify];
}

- (void)testBasicSuccess {
    NSArray * const POTENTIAL_APPS = @[ @"fb://" ];
    BNCServerResponse * const goodResponse = [[BNCServerResponse alloc] init];
    goodResponse.data = @{
        BRANCH_RESPONSE_KEY_POTENTIAL_APPS: POTENTIAL_APPS
    };
    
    XCTestExpectation *requestExpectation = [self expectationWithDescription:@"GetAppList Expectation"];
    BranchGetAppListRequest *request = [[BranchGetAppListRequest alloc] initWithCallback:^(NSArray *list, NSError *error) {
        XCTAssertEqualObjects(list, POTENTIAL_APPS);
        XCTAssertNil(error);

        [self safelyFulfillExpectation:requestExpectation];
    }];
    
    [request processResponse:goodResponse error:nil];
    
    [self awaitExpectations];
}

- (void)testBasicFailure {
    NSError * RESPONSE_ERROR = [NSError errorWithDomain:@"foo" code:1 userInfo:nil];
    
    XCTestExpectation *requestExpectation = [self expectationWithDescription:@"GetAppList Expectation"];
    BranchGetAppListRequest *request = [[BranchGetAppListRequest alloc] initWithCallback:^(NSArray *list, NSError *error) {
        XCTAssertNil(list);
        XCTAssertNotNil(error);
        
        [self safelyFulfillExpectation:requestExpectation];
    }];
    
    [request processResponse:nil error:RESPONSE_ERROR];
    
    [self awaitExpectations];
}

@end
