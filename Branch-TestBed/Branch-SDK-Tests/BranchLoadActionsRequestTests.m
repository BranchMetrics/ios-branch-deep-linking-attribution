//
//  BranchLoadActionsRequestTests.m
//  Branch-TestBed
//
//  Created by Graham Mueller on 6/12/15.
//  Copyright (c) 2015 Branch Metrics. All rights reserved.
//

#import "BranchTest.h"
#import "BranchLoadActionsRequest.h"
#import "BranchConstants.h"
#import "BNCPreferenceHelper.h"
#import <OCMock/OCMock.h>

@interface BranchLoadActionsRequestTests : BranchTest

@end

@implementation BranchLoadActionsRequestTests

- (void)testRequestBody {
    BranchLoadActionsRequest *request = [[BranchLoadActionsRequest alloc] init];
    id serverInterfaceMock = OCMClassMock([BNCServerInterface class]);
    [[serverInterfaceMock expect] getRequest:nil url:[self stringMatchingPattern:BRANCH_REQUEST_ENDPOINT_LOAD_ACTIONS] key:[OCMArg any] callback:[OCMArg any]];
    
    [request makeRequest:serverInterfaceMock key:nil callback:NULL];
    
    [serverInterfaceMock verify];
}

- (void)testSuccessWithUpdatedValues {
    NSString * const ACTION_KEY = @"buy";
    NSInteger const OLD_TOTAL_VALUE = 25;
    NSInteger const NEW_TOTAL_VALUE = 100;
    NSInteger const OLD_UNIQUE_VALUE = 25;
    NSInteger const NEW_UNIQUE_VALUE = 25;

    NSDictionary * const ACTION_DICT = @{
        ACTION_KEY: @{
            BRANCH_RESPONSE_KEY_ACTION_COUNT_TOTAL: @(NEW_TOTAL_VALUE),
            BRANCH_RESPONSE_KEY_ACTION_COUNT_UNIQUE: @(NEW_UNIQUE_VALUE),
        }
    };
    
    BNCServerResponse *response = [[BNCServerResponse alloc] init];
    response.data = ACTION_DICT;
    
    [BNCPreferenceHelper setActionTotalCount:ACTION_KEY withCount:OLD_TOTAL_VALUE];
    [BNCPreferenceHelper setActionUniqueCount:ACTION_KEY withCount:OLD_UNIQUE_VALUE];
    
    XCTestExpectation *requestCallbackExpectation = [self expectationWithDescription:@"Request Callback Expectation"];
    BranchLoadActionsRequest *request = [[BranchLoadActionsRequest alloc] initWithCallback:^(BOOL changed, NSError *error) {
        XCTAssertTrue(changed);
        XCTAssertNil(error);
        
        [self safelyFulfillExpectation:requestCallbackExpectation];
    }];
    
    [request processResponse:response error:nil];
    
    [self awaitExpectations];
    XCTAssertEqual([BNCPreferenceHelper getActionTotalCount:ACTION_KEY], NEW_TOTAL_VALUE);
    XCTAssertEqual([BNCPreferenceHelper getActionUniqueCount:ACTION_KEY], NEW_UNIQUE_VALUE);
}

- (void)testSuccessWithSameValues {
    NSString * const ACTION_KEY = @"buy";
    NSInteger const OLD_TOTAL_VALUE = 25;
    NSInteger const NEW_TOTAL_VALUE = 25;
    NSInteger const OLD_UNIQUE_VALUE = 25;
    NSInteger const NEW_UNIQUE_VALUE = 25;
    
    NSDictionary * const ACTION_DICT = @{
        ACTION_KEY: @{
            BRANCH_RESPONSE_KEY_ACTION_COUNT_TOTAL: @(NEW_TOTAL_VALUE),
            BRANCH_RESPONSE_KEY_ACTION_COUNT_UNIQUE: @(NEW_UNIQUE_VALUE),
        }
    };
    
    BNCServerResponse *response = [[BNCServerResponse alloc] init];
    response.data = ACTION_DICT;
    
    [BNCPreferenceHelper setActionTotalCount:ACTION_KEY withCount:OLD_TOTAL_VALUE];
    [BNCPreferenceHelper setActionUniqueCount:ACTION_KEY withCount:OLD_UNIQUE_VALUE];
    
    XCTestExpectation *requestCallbackExpectation = [self expectationWithDescription:@"Request Callback Expectation"];
    BranchLoadActionsRequest *request = [[BranchLoadActionsRequest alloc] initWithCallback:^(BOOL changed, NSError *error) {
        XCTAssertFalse(changed);
        XCTAssertNil(error);
        
        [self safelyFulfillExpectation:requestCallbackExpectation];
    }];
    
    [request processResponse:response error:nil];
    
    [self awaitExpectations];
    XCTAssertEqual([BNCPreferenceHelper getActionTotalCount:ACTION_KEY], OLD_TOTAL_VALUE);
    XCTAssertEqual([BNCPreferenceHelper getActionUniqueCount:ACTION_KEY], OLD_UNIQUE_VALUE);
}

- (void)testRequestWithError {
    NSString * const ACTION_KEY = @"buy";
    NSInteger const OLD_TOTAL_VALUE = 25;
    NSInteger const OLD_UNIQUE_VALUE = 25;
    NSError * const REQUEST_ERROR = [NSError errorWithDomain:@"foo" code:1 userInfo:nil];
    
    [BNCPreferenceHelper setActionTotalCount:ACTION_KEY withCount:OLD_TOTAL_VALUE];
    [BNCPreferenceHelper setActionUniqueCount:ACTION_KEY withCount:OLD_UNIQUE_VALUE];
    
    XCTestExpectation *requestCallbackExpectation = [self expectationWithDescription:@"Request Callback Expectation"];
    BranchLoadActionsRequest *request = [[BranchLoadActionsRequest alloc] initWithCallback:^(BOOL changed, NSError *error) {
        XCTAssertFalse(changed);
        XCTAssertNotNil(error);
        
        [self safelyFulfillExpectation:requestCallbackExpectation];
    }];
    
    [request processResponse:nil error:REQUEST_ERROR];
    
    [self awaitExpectations];
    XCTAssertEqual([BNCPreferenceHelper getActionTotalCount:ACTION_KEY], OLD_TOTAL_VALUE);
    XCTAssertEqual([BNCPreferenceHelper getActionUniqueCount:ACTION_KEY], OLD_UNIQUE_VALUE);
}

@end
