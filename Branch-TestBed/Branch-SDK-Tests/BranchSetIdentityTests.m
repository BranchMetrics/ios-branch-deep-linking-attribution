//
//  BranchSetIdentityRequestTests.m
//  Branch-TestBed
//
//  Created by Graham Mueller on 6/10/15.
//  Copyright (c) 2015 Branch Metrics. All rights reserved.
//

#import "BNCTestCase.h"
#import "BranchConstants.h"
#import "BNCPreferenceHelper.h"
#import "Branch.h"
#import <OCMock/OCMock.h>

static NSString * const IDENTITY_TEST_USER_ID = @"foo_id";

@interface BranchSetIdentityTests : BNCTestCase
@end

@implementation BranchSetIdentityTests

#pragma mark -  setIdentity Tests
- (void)testSetIdentityWithCallback {
    Branch *branch = [Branch getInstance];
    [branch logoutWithCallback:^(BOOL changed, NSError * _Nullable error) {
        BNCPreferenceHelper *preferenceHelper = [BNCPreferenceHelper sharedInstance];

        XCTestExpectation *expectation = [self expectationWithDescription:@"setIdentity callback is called"];
        
        [branch setIdentity:@"testUserIdWithCallback" withCallback:^(NSDictionary *params, NSError *error) {
            XCTAssertEqualObjects(@"testUserIdWithCallback", preferenceHelper.userIdentity);
            [expectation fulfill];
        }];
        
        [self waitForExpectationsWithTimeout:5 handler:nil];
    }];
}

- (void)testSetIdentityWithNilUserId {
    Branch *branch = [Branch getInstance];
    [branch logoutWithCallback:^(BOOL changed, NSError * _Nullable error) {
        BNCPreferenceHelper *preferenceHelper = [BNCPreferenceHelper sharedInstance];

        XCTestExpectation *expectation = [self expectationWithDescription:@"setIdentityWithNil callback is called"];
        
        [branch setIdentity:nil withCallback:^(NSDictionary *params, NSError *error) {
            XCTAssertNil(preferenceHelper.userIdentity);
            [expectation fulfill];
        }];
        
        [self waitForExpectationsWithTimeout:5 handler:nil];
    }];
    

}

- (void)testSetIdentityWithUserId {
    Branch *branch = [Branch getInstance];
    [branch logoutWithCallback:^(BOOL changed, NSError * _Nullable error) {
        BNCPreferenceHelper *preferenceHelper = [BNCPreferenceHelper sharedInstance];

        NSString *testUserId = @"testUserId";
        [branch setIdentity:testUserId withCallback:nil];

        XCTAssertEqualObjects(@"testUserId", preferenceHelper.userIdentity);
    }];

}

@end
