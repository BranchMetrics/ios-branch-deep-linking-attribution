//
//  Branch_SDK_test.m
//  Branch-SDK test
//
//  Created by Qinwei Gong on 2/19/15.
//  Copyright (c) 2015 Branch Metrics. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <XCTest/XCTest.h>
#import "Branch.h"
#import "BNCPreferenceHelper.h"
#import "BNCServerInterface.h"
#import "BNCConfig.h"
#import "Nocilla.h"

@interface Branch_SDK_Tests : XCTestCase {
    
@private
    Branch *branch;
    int credits;
    NSString *app_id;
    NSString *device_fingerprint_id;
    NSString *browser_fingerprint_id;
    NSString *identity_id;
    NSString *session_id;
    NSString *identity_link;
    NSString *short_link;
    NSString *logout_identity_id;
    NSString *new_identity_id;
    NSString *new_session_id;
    NSString *new_user_link;
}

@end

@implementation Branch_SDK_Tests

- (void)setUp {
    [super setUp];
    
    app_id = @"5668720416392049";
    device_fingerprint_id = @"94938498586381084";
    browser_fingerprint_id = @"69198153995256641";
    identity_id = @"95765863201768032";
    session_id = @"97141055400444225";
    identity_link = @"https://bnc.lt/i/3N-xr0E-_M";
    short_link = @"https://bnc.lt/l/3PxZVFU-BK";
    credits = 30;
    logout_identity_id = @"98274447349252681";
    new_identity_id = @"85782216939930424";
    new_session_id = @"98274447370224207";
    new_user_link = @"https://bnc.lt/i/2kkbX6k-As";
    
    [[LSNocilla sharedInstance] start];
    
    branch = [Branch getInstance:app_id];
}

- (void)tearDown {
    [[LSNocilla sharedInstance] clearStubs];
    [[LSNocilla sharedInstance] stop];
    
    [super tearDown];
}

- (void)reset {
    [BNCPreferenceHelper setDeviceFingerprintID:NO_STRING_VALUE];
    [BNCPreferenceHelper setSessionID:NO_STRING_VALUE];
    [BNCPreferenceHelper setIdentityID:NO_STRING_VALUE];
}

- (void)testOpen {
    NSDictionary *responseDict = @{@"browser_fingerprint_id": browser_fingerprint_id,
                                   @"device_fingerprint_id": device_fingerprint_id,
                                   @"identity_id": identity_id,
                                   @"link": identity_link,
                                   @"session_id": session_id
                                   };
    NSData *responseData = [BNCServerInterface encodePostParams:responseDict];
    
    stubRequest(@"POST", [BNCPreferenceHelper getAPIURL:@"open"])
    .andReturn(200)
    .withHeaders(@{@"application/json": @"Content-Type"})
    .withBody(responseData);
    
    XCTestExpectation *openExpectation = [self expectationWithDescription:@"Test open"];
    
    [branch initSessionAndRegisterDeepLinkHandler:^(NSDictionary *params, NSError *error) {
        XCTAssertNil(error);
        XCTAssertNotNil([BNCPreferenceHelper getSessionID]);
        if ([[LSNocilla sharedInstance] isStarted]) {
            XCTAssertEqualObjects([BNCPreferenceHelper getSessionID], session_id);
        } else {
            XCTAssertNotEqualObjects([BNCPreferenceHelper getSessionID], NO_STRING_VALUE);
        }

        [openExpectation fulfill];
    }];
    
    [self waitForExpectationsWithTimeout:1 handler:^(NSError *error) {
    }];
}

- (void)testGetShortURLAsync {
    [self testOpen];
    
    NSString __block *returnURL;
    
    NSDictionary *responseDict = @{@"url": short_link};
    NSData *responseData = [BNCServerInterface encodePostParams:responseDict];
    
    stubRequest(@"POST", [BNCPreferenceHelper getAPIURL:@"url"])
    .andReturn(200)
    .withHeaders(@{@"application/json": @"Content-Type"})
    .withBody(responseData);
    
    XCTestExpectation *getShortURLExpectation = [self expectationWithDescription:@"Test getShortURL"];
    
    [branch getShortURLWithParams:nil andChannel:@"facebook" andFeature:nil andCallback:^(NSString *url, NSError *error) {
        XCTAssertNil(error);
        XCTAssertNotNil(url);
        if ([[LSNocilla sharedInstance] isStarted]) {
            XCTAssertEqualObjects(url, short_link);
        }
        returnURL = url;
        
        [branch getShortURLWithParams:nil andChannel:@"facebook" andFeature:nil andCallback:^(NSString *url, NSError *error) {
            XCTAssertNil(error);
            XCTAssertNotNil(url);
            if ([[LSNocilla sharedInstance] isStarted]) {
                XCTAssertEqualObjects(url, returnURL);
            }
        }];
        
        [getShortURLExpectation fulfill];
    }];
    
    [self waitForExpectationsWithTimeout:1 handler:^(NSError *error) {
    }];
}

- (void)testGetShortURLSync {
    [self testOpen];
    
    NSDictionary *responseDict = @{@"url": short_link};
    NSData *responseData = [BNCServerInterface encodePostParams:responseDict];
    
    stubRequest(@"POST", [BNCPreferenceHelper getAPIURL:@"url"])
    .andReturn(200)
    .withHeaders(@{@"application/json": @"Content-Type"})
    .withBody(responseData);
    
    NSString *url1 = [branch getShortURLWithParams:nil andChannel:@"facebook" andFeature:nil];
    XCTAssertNotNil(url1);
    if ([[LSNocilla sharedInstance] isStarted]) {
        XCTAssertEqualObjects(url1, short_link);
    }
    
    NSString *url2 = [branch getShortURLWithParams:nil andChannel:@"facebook" andFeature:nil];
    XCTAssertEqualObjects(url1, url2);
    
    if (![[LSNocilla sharedInstance] isStarted]) {
        NSString *url3 = [branch getShortURLWithParams:nil andChannel:@"twitter" andFeature:nil];
        XCTAssertNotNil(url3);
        XCTAssertNotEqualObjects(url1, url3);
    }
}

- (void)testSetIdentity {
    [self testOpen];

    [BNCPreferenceHelper setSessionID:new_session_id];
    [BNCPreferenceHelper setIdentityID:logout_identity_id];
    [BNCPreferenceHelper setUserURL:@"https://bnc.lt/i/3R7_PIk-77"];
    
    [BNCPreferenceHelper setUserIdentity:NO_STRING_VALUE];
    [BNCPreferenceHelper setInstallParams:NO_STRING_VALUE];
    [BNCPreferenceHelper setSessionParams:NO_STRING_VALUE];
    [BNCPreferenceHelper clearUserCreditsAndCounts];
    
    NSDictionary *responseDict = @{@"identity_id": new_identity_id,
                                   @"link": new_user_link,
                                   @"link_click_id": @"87925296346431956",
                                   @"referring_data": @"{ \"$og_title\":\"Kindred\",\"key\":\"test_object\" }"
                                   };
    NSData *responseData = [BNCServerInterface encodePostParams:responseDict];
    
    stubRequest(@"POST", [BNCPreferenceHelper getAPIURL:@"profile"])
    .andReturn(200)
    .withHeaders(@{@"application/json": @"Content-Type"})
    .withBody(responseData);
    
    XCTestExpectation *setIdentityExpectation = [self expectationWithDescription:@"Test setIdentity"];

    [branch setIdentity:@"test_user_10" withCallback:^(NSDictionary *params, NSError *error) {
        XCTAssertNil(error);
        XCTAssertNotNil(params);
        
        XCTAssertEqualObjects([BNCPreferenceHelper getIdentityID], new_identity_id);
        XCTAssertEqualObjects([BNCPreferenceHelper getUserURL], new_user_link);
        NSDictionary *installParams = [branch getFirstReferringParams];
        
        XCTAssertEqualObjects(installParams[@"$og_title"], @"Kindred");
        XCTAssertEqualObjects(installParams[@"key"], @"test_object");
        
        [setIdentityExpectation fulfill];
    }];
    
    [self waitForExpectationsWithTimeout:3 handler:^(NSError *error) {
    }];
}

- (void)logout {
    NSDictionary *responseDict = @{@"identity_id": logout_identity_id,
                                   @"link": @"https://bnc.lt/i/3R7_PIk-77",
                                   @"session_id": new_session_id
                                   };
    NSData *responseData = [BNCServerInterface encodePostParams:responseDict];
    
    stubRequest(@"POST", [BNCPreferenceHelper getAPIURL:@"logout"])
    .andReturn(200)
    .withHeaders(@{@"application/json": @"Content-Type"})
    .withBody(responseData);
    
    [branch logout];
}

- (void)testGetRewardsChanged {
    [self testOpen];
    
    [BNCPreferenceHelper setCreditCount:0 forBucket:@"default"];

    NSDictionary *responseDict = @{@"default": [NSNumber numberWithInt:credits]};
    NSData *responseData = [BNCServerInterface encodePostParams:responseDict];
    
    stubRequest(@"GET", [BNCPreferenceHelper getAPIURL:[NSString stringWithFormat:@"%@%@?sdk=ios%@", @"credits/", [BNCPreferenceHelper getIdentityID], SDK_VERSION]])
    .andReturn(200)
    .withHeaders(@{@"application/json": @"Content-Type"})
    .withBody(responseData);
    
    XCTestExpectation *getRewardExpectation = [self expectationWithDescription:@"Test getReward"];
    
    [branch loadRewardsWithCallback:^(BOOL changed, NSError *error) {
        XCTAssertNil(error);
        if ([[LSNocilla sharedInstance] isStarted]) {
            XCTAssertTrue(changed);
        }
        
        [getRewardExpectation fulfill];
    }];
    
    [self waitForExpectationsWithTimeout:1 handler:^(NSError *error) {
    }];
}

- (void)testGetRewardsUnchanged {
    [self testOpen];
    
    [BNCPreferenceHelper setCreditCount:credits forBucket:@"default"];
    
    NSDictionary *responseDict = @{@"default": [NSNumber numberWithInt:credits]};
    NSData *responseData = [BNCServerInterface encodePostParams:responseDict];
    
    stubRequest(@"GET", [BNCPreferenceHelper getAPIURL:[NSString stringWithFormat:@"%@%@?sdk=ios%@", @"credits/", [BNCPreferenceHelper getIdentityID], SDK_VERSION]])
    .andReturn(200)
    .withHeaders(@{@"application/json": @"Content-Type"})
    .withBody(responseData);
    
    XCTestExpectation *getRewardExpectation = [self expectationWithDescription:@"Test getReward"];
    
    [branch loadRewardsWithCallback:^(BOOL changed, NSError *error) {
        XCTAssertNil(error);
        if ([[LSNocilla sharedInstance] isStarted]) {
            XCTAssertFalse(changed);
        }
        
        [getRewardExpectation fulfill];
    }];
    
    [self waitForExpectationsWithTimeout:1 handler:^(NSError *error) {
    }];
}



//- (void)testPerformanceExample {
//    // This is an example of a performance test case.
//    [self measureBlock:^{
//        // Put the code you want to measure the time of here.
//    }];
//}

@end
