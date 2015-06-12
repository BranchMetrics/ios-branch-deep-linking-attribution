//
//  BranchGetReferralCodeRequestTests.m
//  Branch-TestBed
//
//  Created by Graham Mueller on 6/12/15.
//  Copyright (c) 2015 Branch Metrics. All rights reserved.
//

#import "BranchTest.h"
#import "BranchGetReferralCodeRequest.h"
#import "BNCPreferenceHelper.h"
#import "BranchConstants.h"
#import "BNCError.h"
#import <OCMock/OCMock.h>

@interface BranchGetReferralCodeRequestTests : BranchTest

@end

@implementation BranchGetReferralCodeRequestTests

- (void)testRequestBodyWithAllItemsSpecified {
    NSString * const BUCKET = @"foo_bucket";
    NSInteger const AMOUNT = 5;
    NSString * const PREFIX = @"foo_prefix";
    NSDate * const EXPIRATION = [NSDate date];

    NSDictionary * const expectedParams = @{
        BRANCH_REQUEST_KEY_BUCKET: BUCKET,
        BRANCH_REQUEST_KEY_AMOUNT: @(AMOUNT),
        BRANCH_REQUEST_KEY_BRANCH_IDENTITY: [BNCPreferenceHelper getIdentityID],
        BRANCH_REQUEST_KEY_DEVICE_FINGERPRINT_ID: [BNCPreferenceHelper getDeviceFingerprintID],
        BRANCH_REQUEST_KEY_SESSION_ID: [BNCPreferenceHelper getSessionID],
        BRANCH_REQUEST_KEY_REFERRAL_CALCULATION_TYPE: @(BranchUniqueRewards),
        BRANCH_REQUEST_KEY_REFERRAL_REWARD_LOCATION: @(BranchReferringUser),
        BRANCH_REQUEST_KEY_REFERRAL_TYPE: @"credit",
        BRANCH_REQUEST_KEY_REFERRAL_CREATION_SOURCE: @2,
        BRANCH_REQUEST_KEY_REFERRAL_PREFIX: PREFIX,
        BRANCH_REQUEST_KEY_REFERRAL_EXPIRATION: EXPIRATION
    };
    
    BranchGetReferralCodeRequest *request = [[BranchGetReferralCodeRequest alloc] initWithCalcType:BranchUniqueRewards location:BranchReferringUser amount:AMOUNT bucket:BUCKET prefix:PREFIX expiration:EXPIRATION callback:NULL];
    id serverInterfaceMock = OCMClassMock([BNCServerInterface class]);
    [[serverInterfaceMock expect] postRequest:expectedParams url:[OCMArg any] key:[OCMArg any] callback:[OCMArg any]];
    
    [request makeRequest:serverInterfaceMock key:nil callback:NULL];
    
    [serverInterfaceMock verify];
}

- (void)testRequestBodyWithItemsMissing {
    NSString * const BUCKET = @"foo_bucket";
    NSInteger const AMOUNT = 5;
    
    NSDictionary * const expectedParams = @{
        BRANCH_REQUEST_KEY_BUCKET: BUCKET,
        BRANCH_REQUEST_KEY_AMOUNT: @(AMOUNT),
        BRANCH_REQUEST_KEY_BRANCH_IDENTITY: [BNCPreferenceHelper getIdentityID],
        BRANCH_REQUEST_KEY_DEVICE_FINGERPRINT_ID: [BNCPreferenceHelper getDeviceFingerprintID],
        BRANCH_REQUEST_KEY_SESSION_ID: [BNCPreferenceHelper getSessionID],
        BRANCH_REQUEST_KEY_REFERRAL_CALCULATION_TYPE: @(BranchUniqueRewards),
        BRANCH_REQUEST_KEY_REFERRAL_REWARD_LOCATION: @(BranchReferringUser),
        BRANCH_REQUEST_KEY_REFERRAL_TYPE: @"credit",
        BRANCH_REQUEST_KEY_REFERRAL_CREATION_SOURCE: @2
    };
    
    BranchGetReferralCodeRequest *request = [[BranchGetReferralCodeRequest alloc] initWithCalcType:BranchUniqueRewards location:BranchReferringUser amount:AMOUNT bucket:BUCKET prefix:nil expiration:nil callback:NULL];
    id serverInterfaceMock = OCMClassMock([BNCServerInterface class]);
    [[serverInterfaceMock expect] postRequest:expectedParams url:[OCMArg any] key:[OCMArg any] callback:[OCMArg any]];
    
    [request makeRequest:serverInterfaceMock key:nil callback:NULL];
    
    [serverInterfaceMock verify];
}

- (void)testBasicSuccess {
    NSDictionary * const REFERRAL_RESPONSE_DATA = @{ BRANCH_RESPONSE_KEY_REFERRAL_CODE: @"foo" };
    BNCServerResponse *response = [[BNCServerResponse alloc] init];
    response.data = REFERRAL_RESPONSE_DATA;
    
    XCTestExpectation *requestExpecation = [self expectationWithDescription:@"Get Referral Code Request Expectation"];
    BranchGetReferralCodeRequest *request = [[BranchGetReferralCodeRequest alloc] initWithCalcType:0 location:0 amount:0 bucket:nil prefix:nil expiration:nil callback:^(NSDictionary *params, NSError *error) {
        XCTAssertEqualObjects(params, REFERRAL_RESPONSE_DATA);
        XCTAssertNil(error);
        [self safelyFulfillExpectation:requestExpecation];
    }];
    
    [request processResponse:response error:nil];
    
    [self awaitExpectations];
}

- (void)testFailureWithNoCode {
    NSDictionary * const RESPONSE_DATA = @{ };
    BNCServerResponse *response = [[BNCServerResponse alloc] init];
    response.data = RESPONSE_DATA;
    
    XCTestExpectation *requestExpecation = [self expectationWithDescription:@"Get Referral Code Request Expectation"];
    BranchGetReferralCodeRequest *request = [[BranchGetReferralCodeRequest alloc] initWithCalcType:0 location:0 amount:0 bucket:nil prefix:nil expiration:nil callback:^(NSDictionary *params, NSError *error) {
        XCTAssertEqualObjects(params, RESPONSE_DATA);
        XCTAssertEqualObjects(error.domain, BNCErrorDomain);
        XCTAssertEqual(error.code, BNCInvalidReferralCodeError);
        [self safelyFulfillExpectation:requestExpecation];
    }];
    
    [request processResponse:response error:nil];
    
    [self awaitExpectations];
}

- (void)testBasicFailure {
    NSError * const REQUEST_ERROR = [NSError errorWithDomain:@"foo" code:1 userInfo:nil];
    
    XCTestExpectation *requestExpecation = [self expectationWithDescription:@"Get Referral Code Request Expectation"];
    BranchGetReferralCodeRequest *request = [[BranchGetReferralCodeRequest alloc] initWithCalcType:0 location:0 amount:0 bucket:nil prefix:nil expiration:nil callback:^(NSDictionary *params, NSError *error) {
        XCTAssertNil(params);
        XCTAssertEqualObjects(error, REQUEST_ERROR);
        [self safelyFulfillExpectation:requestExpecation];
    }];
    
    [request processResponse:nil error:REQUEST_ERROR];
    
    [self awaitExpectations];
}

@end
