//
//  BranchInstallParamsTests.h
//  Branch-TestBed
//
//  Created by Graham Mueller on 7/17/15.
//  Copyright (c) 2015 Branch Metrics. All rights reserved.
//
//  TODO MERGE THESE WHEN THE TESTING BRANCH IS MERGED

#import "BranchTest.h"
#import "BranchOpenRequest.h"
#import "BranchInstallRequest.h"
#import "BNCPreferenceHelper.h"

@interface BranchInstallParamsTests : BranchTest

@end

@implementation BranchInstallParamsTests

- (void)setUp {
    [super setUp];
    
    BNCPreferenceHelper *preferenceHelper = [BNCPreferenceHelper preferenceHelper];
    preferenceHelper.installParams = nil;
    preferenceHelper.identityID = nil;
}

- (void)testInstallWhenReferrableAndNullData {
    BNCPreferenceHelper *preferenceHelper = [BNCPreferenceHelper preferenceHelper];
    preferenceHelper.isReferrable = YES;
    
    XCTestExpectation *expectation = [self expectationWithDescription:@"ReferrableInstall"];
    BranchInstallRequest *request = [[BranchInstallRequest alloc] initWithCallback:^(BOOL changed, NSError *error) {
        XCTAssertNil(error);
        XCTAssertNil(preferenceHelper.installParams);
        
        [self safelyFulfillExpectation:expectation];
    }];
    
    BNCServerResponse *response = [[BNCServerResponse alloc] init];
    response.data = @{};
    [request processResponse:response error:nil];
    
    [self awaitExpectations];
}

- (void)testInstallWhenReferrableAndNonNullData {
    BNCPreferenceHelper *preferenceHelper = [BNCPreferenceHelper preferenceHelper];
    preferenceHelper.isReferrable = YES;
    
    NSString * const INSTALL_PARAMS = @"{\"foo\":\"bar\"}";
    
    XCTestExpectation *expectation = [self expectationWithDescription:@"Request Expectation"];
    BranchInstallRequest *request = [[BranchInstallRequest alloc] initWithCallback:^(BOOL changed, NSError *error) {
        XCTAssertNil(error);
        XCTAssertEqualObjects(preferenceHelper.installParams, INSTALL_PARAMS);
        
        [self safelyFulfillExpectation:expectation];
    }];
    
    BNCServerResponse *response = [[BNCServerResponse alloc] init];
    response.data = @{ @"data": INSTALL_PARAMS };
    [request processResponse:response error:nil];
    
    [self awaitExpectations];
}

- (void)testInstallWhenNotReferrable {
    BNCPreferenceHelper *preferenceHelper = [BNCPreferenceHelper preferenceHelper];
    preferenceHelper.isReferrable = NO;
    
    NSString * const INSTALL_PARAMS = @"{\"foo\":\"bar\"}";
    
    XCTestExpectation *expectation = [self expectationWithDescription:@"Request Expectation"];
    BranchInstallRequest *request = [[BranchInstallRequest alloc] initWithCallback:^(BOOL changed, NSError *error) {
        XCTAssertNil(error);
        XCTAssertNil(preferenceHelper.installParams);
        
        [self safelyFulfillExpectation:expectation];
    }];
    
    BNCServerResponse *response = [[BNCServerResponse alloc] init];
    response.data = @{ @"data": INSTALL_PARAMS };
    [request processResponse:response error:nil];
    
    [self awaitExpectations];
}

- (void)testOpenWhenReferrableAndNoInstallParamsAndNonNullData {
    BNCPreferenceHelper *preferenceHelper = [BNCPreferenceHelper preferenceHelper];
    preferenceHelper.isReferrable = YES;
    
    NSString * const OPEN_PARAMS = @"{\"foo\":\"bar\"}";
    
    XCTestExpectation *expectation = [self expectationWithDescription:@"Request Expectation"];
    BranchOpenRequest *request = [[BranchOpenRequest alloc] initWithCallback:^(BOOL changed, NSError *error) {
        XCTAssertNil(error);
        XCTAssertEqualObjects(preferenceHelper.installParams, OPEN_PARAMS);
        
        [self safelyFulfillExpectation:expectation];
    }];
    
    BNCServerResponse *response = [[BNCServerResponse alloc] init];
    response.data = @{ @"data": OPEN_PARAMS };
    [request processResponse:response error:nil];
    
    [self awaitExpectations];
}

- (void)testOpenWhenReferrableAndNoInstallParamsAndNullData {
    BNCPreferenceHelper *preferenceHelper = [BNCPreferenceHelper preferenceHelper];
    preferenceHelper.isReferrable = YES;
    
    XCTestExpectation *expectation = [self expectationWithDescription:@"Request Expectation"];
    BranchOpenRequest *request = [[BranchOpenRequest alloc] initWithCallback:^(BOOL changed, NSError *error) {
        XCTAssertNil(error);
        XCTAssertNil(preferenceHelper.installParams);
        
        [self safelyFulfillExpectation:expectation];
    }];
    
    BNCServerResponse *response = [[BNCServerResponse alloc] init];
    response.data = @{ };
    [request processResponse:response error:nil];
    
    [self awaitExpectations];
}

- (void)testOpenWhenReferrableAndInstallParams {
    BNCPreferenceHelper *preferenceHelper = [BNCPreferenceHelper preferenceHelper];
    preferenceHelper.isReferrable = YES;
    
    NSString * const INSTALL_PARAMS = @"{\"foo\":\"bar\"}";
    NSString * const OPEN_PARAMS = @"{\"bar\":\"foo\"}";

    preferenceHelper.installParams = INSTALL_PARAMS;
    
    XCTestExpectation *expectation = [self expectationWithDescription:@"Request Expectation"];
    BranchOpenRequest *request = [[BranchOpenRequest alloc] initWithCallback:^(BOOL changed, NSError *error) {
        XCTAssertNil(error);
        XCTAssertEqualObjects(preferenceHelper.installParams, INSTALL_PARAMS);
        
        [self safelyFulfillExpectation:expectation];
    }];
    
    BNCServerResponse *response = [[BNCServerResponse alloc] init];
    response.data = @{ @"data": OPEN_PARAMS };
    [request processResponse:response error:nil];
    
    [self awaitExpectations];
}

- (void)testOpenWhenNotReferrable {
    BNCPreferenceHelper *preferenceHelper = [BNCPreferenceHelper preferenceHelper];
    preferenceHelper.isReferrable = NO;
    
    NSString * const OPEN_PARAMS = @"{\"foo\":\"bar\"}";
    
    XCTestExpectation *expectation = [self expectationWithDescription:@"Request Expectation"];
    BranchOpenRequest *request = [[BranchOpenRequest alloc] initWithCallback:^(BOOL changed, NSError *error) {
        XCTAssertNil(error);
        XCTAssertNil(preferenceHelper.installParams);
        
        [self safelyFulfillExpectation:expectation];
    }];
    
    BNCServerResponse *response = [[BNCServerResponse alloc] init];
    response.data = @{ @"data": OPEN_PARAMS };
    [request processResponse:response error:nil];
    
    [self awaitExpectations];
}

@end
