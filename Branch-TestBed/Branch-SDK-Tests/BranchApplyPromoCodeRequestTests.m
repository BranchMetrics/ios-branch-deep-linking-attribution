//
//  BranchApplyPromoCodeRequestTests.m
//  Branch-TestBed
//
//  Created by Graham Mueller on 6/12/15.
//  Copyright (c) 2015 Branch Metrics. All rights reserved.
//

#import "BranchTest.h"
#import "BranchApplyPromoCodeRequest.h"
#import "BNCPreferenceHelper.h"
#import "BranchConstants.h"
#import "BNCError.h"
#import <OCMock/OCMock.h>

@interface BranchApplyPromoCodeRequestTests : BranchTest

@end

@implementation BranchApplyPromoCodeRequestTests

- (void)testRequestBodyWithAllItemsSpecified {
    NSString * const CODE = @"foo_code";
    
    NSDictionary * const expectedParams = @{
        BRANCH_REQUEST_KEY_BRANCH_IDENTITY: [BNCPreferenceHelper getIdentityID],
        BRANCH_REQUEST_KEY_DEVICE_FINGERPRINT_ID: [BNCPreferenceHelper getDeviceFingerprintID],
        BRANCH_REQUEST_KEY_SESSION_ID: [BNCPreferenceHelper getSessionID],
    };
    
    BranchApplyPromoCodeRequest *request = [[BranchApplyPromoCodeRequest alloc] initWithCode:CODE useOld:NO callback:NULL];
    id serverInterfaceMock = OCMClassMock([BNCServerInterface class]);
    [[serverInterfaceMock expect] postRequest:expectedParams url:[OCMArg any] key:[OCMArg any] callback:[OCMArg any]];
    
    [request makeRequest:serverInterfaceMock key:nil callback:NULL];
    
    [serverInterfaceMock verify];
}

- (void)testBasicSuccessWithPromoCode {
    NSString * CODE = @"foo_code";
    NSDictionary * const REFERRAL_RESPONSE_DATA = @{ BRANCH_RESPONSE_KEY_PROMO_CODE: CODE };
    BNCServerResponse *response = [[BNCServerResponse alloc] init];
    response.data = REFERRAL_RESPONSE_DATA;
    
    XCTestExpectation *requestExpecation = [self expectationWithDescription:@"Apply Promo Code Request Expectation"];
    BranchApplyPromoCodeRequest *request = [[BranchApplyPromoCodeRequest alloc] initWithCode:CODE useOld:NO callback:^(NSDictionary *params, NSError *error) {
        XCTAssertEqualObjects(params, REFERRAL_RESPONSE_DATA);
        XCTAssertNil(error);
        [self safelyFulfillExpectation:requestExpecation];
    }];
    
    [request processResponse:response error:nil];
    
    [self awaitExpectations];
}

- (void)testBasicSuccessWithReferralCode {
    NSString * CODE = @"foo_code";
    NSDictionary * const REFERRAL_RESPONSE_DATA = @{ BRANCH_RESPONSE_KEY_REFERRAL_CODE: CODE };
    BNCServerResponse *response = [[BNCServerResponse alloc] init];
    response.data = REFERRAL_RESPONSE_DATA;
    
    XCTestExpectation *requestExpecation = [self expectationWithDescription:@"Apply Promo Code Request Expectation"];
    BranchApplyPromoCodeRequest *request = [[BranchApplyPromoCodeRequest alloc] initWithCode:CODE useOld:YES callback:^(NSDictionary *params, NSError *error) {
        XCTAssertEqualObjects(params, REFERRAL_RESPONSE_DATA);
        XCTAssertNil(error);
        [self safelyFulfillExpectation:requestExpecation];
    }];
    
    [request processResponse:response error:nil];
    
    [self awaitExpectations];
}

- (void)testFailureWithNoCode {
    NSString * CODE = @"foo_code";
    NSDictionary * const RESPONSE_DATA = @{ };
    BNCServerResponse *response = [[BNCServerResponse alloc] init];
    response.data = RESPONSE_DATA;
    
    XCTestExpectation *requestExpecation = [self expectationWithDescription:@"Apply Promo Code Request Expectation"];
    BranchApplyPromoCodeRequest *request = [[BranchApplyPromoCodeRequest alloc] initWithCode:CODE useOld:NO callback:^(NSDictionary *params, NSError *error) {
        XCTAssertEqualObjects(params, RESPONSE_DATA);
        XCTAssertEqualObjects(error.domain, BNCErrorDomain);
        XCTAssertEqual(error.code, BNCInvalidPromoCodeError);
        [self safelyFulfillExpectation:requestExpecation];
    }];
    
    [request processResponse:response error:nil];
    
    [self awaitExpectations];
}

- (void)testBasicFailure {
    NSString * CODE = @"foo_code";
    NSError * const REQUEST_ERROR = [NSError errorWithDomain:@"foo" code:1 userInfo:nil];
    
    XCTestExpectation *requestExpecation = [self expectationWithDescription:@"Apply Promo Code Request Expectation"];
    BranchApplyPromoCodeRequest *request = [[BranchApplyPromoCodeRequest alloc] initWithCode:CODE useOld:NO callback:^(NSDictionary *params, NSError *error) {
        XCTAssertNil(params);
        XCTAssertEqualObjects(error, REQUEST_ERROR);
        [self safelyFulfillExpectation:requestExpecation];
    }];
    
    [request processResponse:nil error:REQUEST_ERROR];
    
    [self awaitExpectations];
}

@end
