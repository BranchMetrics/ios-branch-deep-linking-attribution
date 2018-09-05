//
//  BranchLoadRewardsRequestTests.m
//  Branch-TestBed
//
//  Created by Graham Mueller on 6/12/15.
//  Copyright (c) 2015 Branch Metrics. All rights reserved.
//

#import "BNCTestCase.h"
#import "BranchLoadRewardsRequest.h"
#import "BranchConstants.h"
#import "BNCPreferenceHelper.h"
#import "BNCDebug.h"
#import <OCMock/OCMock.h>

@interface BranchLoadRewardsRequestTests : BNCTestCase
@end

@implementation BranchLoadRewardsRequestTests

- (void)testRequestBody {

    id serverInterfaceMock = OCMClassMock([BNCServerInterface class]);
    [[serverInterfaceMock expect]
        getRequest:nil
        url:[self stringMatchingPattern:BRANCH_REQUEST_ENDPOINT_LOAD_REWARDS]
        key:[OCMArg any]
        callback:[OCMArg any]];
    
    BranchLoadRewardsRequest *request = [[BranchLoadRewardsRequest alloc] init];
    [request makeRequest:serverInterfaceMock key:nil callback:NULL];
    [serverInterfaceMock verify];
}

- (void)testSuccessWithUpdatedValues {
    NSString * const BUCKET = @"default";
    NSInteger const OLD_REWARD_VALUE = 25;
    NSInteger const NEW_REWARD_VALUE = 100;

    [[BNCPreferenceHelper preferenceHelper] setCreditCount:OLD_REWARD_VALUE forBucket:BUCKET];

    XCTestExpectation *requestCallbackExpectation = [self expectationWithDescription:@"Request Callback Expectation"];
    BranchLoadRewardsRequest *request =
        [[BranchLoadRewardsRequest alloc]
            initWithCallback:^(BOOL changed, NSError *error) {
                XCTAssertTrue(changed);
                XCTAssertNil(error);
                [self safelyFulfillExpectation:requestCallbackExpectation];
            }];
    BNCServerResponse *response = [[BNCServerResponse alloc] init];
    response.data = @{
        BUCKET: @(NEW_REWARD_VALUE)
    };
    [request processResponse:response error:nil];
    
    [self awaitExpectations];
    XCTAssertEqual(
        [[BNCPreferenceHelper preferenceHelper] getCreditCountForBucket:BUCKET],
        NEW_REWARD_VALUE
    );
}

- (void)testSuccessWithSameValues {
    NSString * const BUCKET = @"default";
    NSInteger const OLD_REWARD_VALUE = 25;
    NSInteger const NEW_REWARD_VALUE = 25;

    [[BNCPreferenceHelper preferenceHelper] setCreditCount:OLD_REWARD_VALUE forBucket:BUCKET];

    XCTestExpectation *requestCallbackExpectation =
        [self expectationWithDescription:@"Request Callback Expectation"];

    BranchLoadRewardsRequest *request =
        [[BranchLoadRewardsRequest alloc]
            initWithCallback:^(BOOL changed, NSError *error) {
                if (changed) {
                    BNCDebugBreakpoint();
                }
                XCTAssertFalse(changed);
                XCTAssertNil(error);
                [self safelyFulfillExpectation:requestCallbackExpectation];
            }];
    BNCServerResponse *response = [[BNCServerResponse alloc] init];
    response.data = @{
        BUCKET: @(NEW_REWARD_VALUE)
    };
    [request processResponse:response error:nil];

    [self awaitExpectations];
    [[BNCPreferenceHelper preferenceHelper] synchronize];
    XCTAssertEqual(
        [[BNCPreferenceHelper preferenceHelper] getCreditCountForBucket:BUCKET],
        NEW_REWARD_VALUE
    );
}

- (void)testRequestWithError {
    NSString * const BUCKET = @"default";
    NSInteger const OLD_REWARD_VALUE = 25;
    NSError * const REQUEST_ERROR = [NSError errorWithDomain:@"foo" code:1 userInfo:nil];
    
    [[BNCPreferenceHelper preferenceHelper] setCreditCount:OLD_REWARD_VALUE forBucket:BUCKET];
    
    XCTestExpectation *requestCallbackExpectation =
        [self expectationWithDescription:@"Request Callback Expectation"];

    BranchLoadRewardsRequest *request =
        [[BranchLoadRewardsRequest alloc]
            initWithCallback:^(BOOL changed, NSError *error) {
                XCTAssertFalse(changed);
                XCTAssertNotNil(error);
                [self safelyFulfillExpectation:requestCallbackExpectation];
            }];
    
    [request processResponse:nil error:REQUEST_ERROR];
    
    [self awaitExpectations];
    XCTAssertEqual(
        [[BNCPreferenceHelper preferenceHelper] getCreditCountForBucket:BUCKET],
        OLD_REWARD_VALUE
    );
}

@end
