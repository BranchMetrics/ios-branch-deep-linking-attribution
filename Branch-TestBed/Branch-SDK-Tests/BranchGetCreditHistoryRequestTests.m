//
//  BranchGetCreditHistoryRequestTests.m
//  Branch-TestBed
//
//  Created by Graham Mueller on 6/12/15.
//  Copyright (c) 2015 Branch Metrics. All rights reserved.
//
#import "BNCTestCase.h"
#import "BranchCreditHistoryRequest.h"
#import "BranchConstants.h"
#import "BNCPreferenceHelper.h"
#import <OCMock/OCMock.h>

@interface BranchGetCreditHistoryRequestTests : BNCTestCase
@end

@implementation BranchGetCreditHistoryRequestTests

- (void)testRequestBodyWithItemsSpecified {
    NSString * const BUCKET = @"foo_bucket";
    NSString * const CREDIT_TRANSACTION_ID = @"foo_transaction_id";
    NSInteger const LENGTH = 5;
    
    BNCPreferenceHelper *preferenceHelper = [BNCPreferenceHelper preferenceHelper];
    NSMutableDictionary * const expectedParams = NSMutableDictionary.new;
    expectedParams[BRANCH_REQUEST_KEY_BRANCH_IDENTITY] = preferenceHelper.identityID;
    expectedParams[BRANCH_REQUEST_KEY_DEVICE_FINGERPRINT_ID] = preferenceHelper.deviceFingerprintID;
    expectedParams[BRANCH_REQUEST_KEY_SESSION_ID] = preferenceHelper.sessionID;
    expectedParams[BRANCH_REQUEST_KEY_STARTING_TRANSACTION_ID] = CREDIT_TRANSACTION_ID;
    expectedParams[BRANCH_REQUEST_KEY_BUCKET] = BUCKET;
    expectedParams[BRANCH_REQUEST_KEY_LENGTH] = @(LENGTH);
    expectedParams[BRANCH_REQUEST_KEY_DIRECTION] = @"desc";

    BranchCreditHistoryRequest *request = [[BranchCreditHistoryRequest alloc] initWithBucket:BUCKET creditTransactionId:CREDIT_TRANSACTION_ID length:LENGTH order:BranchMostRecentFirst callback:NULL];
    id serverInterfaceMock = OCMClassMock([BNCServerInterface class]);
    [[serverInterfaceMock expect] postRequest:expectedParams url:[self stringMatchingPattern:BRANCH_REQUEST_ENDPOINT_CREDIT_HISTORY] key:[OCMArg any] callback:[OCMArg any]];
    
    [request makeRequest:serverInterfaceMock key:nil callback:NULL];
    
    [serverInterfaceMock verify];
}

- (void)testRequestBodyWithItemsMissing {
    NSInteger const LENGTH = 5;

    BNCPreferenceHelper *preferenceHelper = [BNCPreferenceHelper preferenceHelper];
    NSMutableDictionary * const expectedParams = NSMutableDictionary.new;
    expectedParams[BRANCH_REQUEST_KEY_BRANCH_IDENTITY] = preferenceHelper.identityID;
    expectedParams[BRANCH_REQUEST_KEY_DEVICE_FINGERPRINT_ID] = preferenceHelper.deviceFingerprintID;
    expectedParams[BRANCH_REQUEST_KEY_SESSION_ID] = preferenceHelper.sessionID;
    expectedParams[BRANCH_REQUEST_KEY_LENGTH] = @(LENGTH);
    expectedParams[BRANCH_REQUEST_KEY_DIRECTION] = @"asc";

    BranchCreditHistoryRequest *request = [[BranchCreditHistoryRequest alloc] initWithBucket:nil creditTransactionId:nil length:LENGTH order:BranchLeastRecentFirst callback:NULL];
    id serverInterfaceMock = OCMClassMock([BNCServerInterface class]);
    [[serverInterfaceMock expect] postRequest:expectedParams url:[OCMArg any] key:[OCMArg any] callback:[OCMArg any]];
    
    [request makeRequest:serverInterfaceMock key:nil callback:NULL];
    
    [serverInterfaceMock verify];
}

- (void)testBasicSuccess {
    NSArray * const RESPONSE_ARRAY = @[
        [@{
            BRANCH_RESPONSE_KEY_REFERRER: @"foo",
            BRANCH_RESPONSE_KEY_REFERREE: @"bar"
        } mutableCopy],
        [@{
            BRANCH_RESPONSE_KEY_REFERRER: @"foo",
            BRANCH_RESPONSE_KEY_REFERREE: [NSNull null]
        } mutableCopy],
        [@{
            BRANCH_RESPONSE_KEY_REFERRER: [NSNull null],
            BRANCH_RESPONSE_KEY_REFERREE: @"bar"
        } mutableCopy]
    ];
    
    NSArray * const EXPECTED_CALLBACK_ARRAY = @[
        @{
            BRANCH_RESPONSE_KEY_REFERRER: @"foo",
            BRANCH_RESPONSE_KEY_REFERREE: @"bar"
        },
        @{
            BRANCH_RESPONSE_KEY_REFERRER: @"foo"
        },
        @{
            BRANCH_RESPONSE_KEY_REFERREE: @"bar"
        }
    ];
    
    BNCServerResponse *response = [[BNCServerResponse alloc] init];
    response.data = RESPONSE_ARRAY;
    
    XCTestExpectation *requestExpectation = [self expectationWithDescription:@"Credit History Request Expectation"];
    BranchCreditHistoryRequest *request = [[BranchCreditHistoryRequest alloc] initWithBucket:nil creditTransactionId:nil length:0 order:0 callback:^(NSArray *list, NSError *error) {
        XCTAssertEqualObjects(list, EXPECTED_CALLBACK_ARRAY);
        XCTAssertNil(error);
        
        [self safelyFulfillExpectation:requestExpectation];
    }];
    
    [request processResponse:response error:nil];
    
    [self awaitExpectations];
}

- (void)testBasicFailure {
    NSError * const error = [NSError errorWithDomain:@"foo" code:1 userInfo:nil];
    
    XCTestExpectation *requestExpectation = [self expectationWithDescription:@"Credit History Request Expectation"];
    BranchCreditHistoryRequest *request = [[BranchCreditHistoryRequest alloc] initWithBucket:nil creditTransactionId:nil length:0 order:0 callback:^(NSArray *list, NSError *error) {
        XCTAssertNil(list);
        XCTAssertNotNil(error);
        
        [self safelyFulfillExpectation:requestExpectation];
    }];
    
    [request processResponse:nil error:error];
    
    [self awaitExpectations];
}

@end
