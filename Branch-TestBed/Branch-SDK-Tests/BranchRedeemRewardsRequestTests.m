//
//  BranchRedeemRewardsRequestTests.m
//  Branch-TestBed
//
//  Created by Graham Mueller on 6/12/15.
//  Copyright (c) 2015 Branch Metrics. All rights reserved.
//

#import "BNCTestCase.h"
#import "BranchRedeemRewardsRequest.h"
#import "BranchConstants.h"
#import "BNCPreferenceHelper.h"
#import <OCMock/OCMock.h>

@interface BranchRedeemRewardsRequestTests : BNCTestCase

@end

@implementation BranchRedeemRewardsRequestTests

- (void)testRequestBody {
    NSString * const BUCKET = @"foo_bucket";
    NSInteger const AMOUNT = 5;

    BNCPreferenceHelper *preferenceHelper = [BNCPreferenceHelper preferenceHelper];
    NSMutableDictionary * const expectedParams = NSMutableDictionary.new;
    expectedParams[BRANCH_REQUEST_KEY_BUCKET] = BUCKET;
    expectedParams[BRANCH_REQUEST_KEY_AMOUNT] = @(AMOUNT);
    expectedParams[BRANCH_REQUEST_KEY_BRANCH_IDENTITY] = preferenceHelper.identityID;
    expectedParams[BRANCH_REQUEST_KEY_DEVICE_FINGERPRINT_ID] = preferenceHelper.deviceFingerprintID;
    expectedParams[BRANCH_REQUEST_KEY_SESSION_ID] = preferenceHelper.sessionID;
    
    BranchRedeemRewardsRequest *request = [[BranchRedeemRewardsRequest alloc] initWithAmount:AMOUNT bucket:BUCKET callback:NULL];
    id serverInterfaceMock = OCMClassMock([BNCServerInterface class]);
    [[serverInterfaceMock expect] postRequest:expectedParams url:[self stringMatchingPattern:BRANCH_REQUEST_ENDPOINT_REDEEM_REWARDS] key:[OCMArg any] callback:[OCMArg any]];
    
    [request makeRequest:serverInterfaceMock key:nil callback:NULL];
    
    [serverInterfaceMock verify];
}

- (void)testBasicSuccess {
    NSInteger const STARTING_AMOUNT = 100;
    NSInteger const REDEEM_AMOUNT = 5;
    NSString * const BUCKET = @"foo_bucket";
    
    [[BNCPreferenceHelper preferenceHelper] setCreditCount:STARTING_AMOUNT forBucket:BUCKET];
    
    XCTestExpectation *requestExpectation = [self expectationWithDescription:@"Redeem Request Expectation"];
    BranchRedeemRewardsRequest *request = [[BranchRedeemRewardsRequest alloc] initWithAmount:REDEEM_AMOUNT bucket:BUCKET callback:^(BOOL success, NSError *error) {
        XCTAssertTrue(success);
        XCTAssertNil(error);
        
        [self safelyFulfillExpectation:requestExpectation];
    }];
    
    [request processResponse:[[BNCServerResponse alloc] init] error:nil];
    
    [self awaitExpectations];
    XCTAssertEqual([[BNCPreferenceHelper preferenceHelper] getCreditCountForBucket:BUCKET], STARTING_AMOUNT - REDEEM_AMOUNT);
}

- (void)testBasicFailure {
    NSInteger const STARTING_AMOUNT = 100;
    NSInteger const REDEEM_AMOUNT = 5;
    NSString * const BUCKET = @"foo_bucket";
    NSError * REQUEST_ERROR = [NSError errorWithDomain:@"foo" code:1 userInfo:nil];
    
    [[BNCPreferenceHelper preferenceHelper] setCreditCount:STARTING_AMOUNT forBucket:BUCKET];
    
    XCTestExpectation *requestExpectation = [self expectationWithDescription:@"Redeem Request Expectation"];
    BranchRedeemRewardsRequest *request = [[BranchRedeemRewardsRequest alloc] initWithAmount:REDEEM_AMOUNT bucket:BUCKET callback:^(BOOL success, NSError *error) {
        XCTAssertFalse(success);
        XCTAssertNotNil(error);
        
        [self safelyFulfillExpectation:requestExpectation];
    }];
    
    [request processResponse:nil error:REQUEST_ERROR];
    
    [self awaitExpectations];
    XCTAssertEqual([[BNCPreferenceHelper preferenceHelper] getCreditCountForBucket:BUCKET], STARTING_AMOUNT);
}

@end
