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
    
    [[LSNocilla sharedInstance] start];
    
    branch = [Branch getInstance:app_id];
    
    credits = 0;
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

- (void)testGetShortURL {
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
        
//        if (![[LSNocilla sharedInstance] isStarted]) {
//            [branch getShortURLWithParams:nil andChannel:@"twitter" andFeature:nil andCallback:^(NSString *url, NSError *error) {
//                XCTAssertNil(error);
//                XCTAssertNotNil(url);
//                if ([[LSNocilla sharedInstance] isStarted]) {
//                    NSLog(@"------------ %@", url);
//                    XCTAssertNotEqualObjects(url, url1);
//                }
//            }];
//        }
        
        [getShortURLExpectation fulfill];
    }];
    
    [self waitForExpectationsWithTimeout:3 handler:^(NSError *error) {
    }];
}

- (void)testGetRewards {
    XCTAssertEqualObjects([BNCPreferenceHelper getSessionID], session_id);
    
    XCTAssert(YES, @"Pass");
}

- (void)performReferral {
    credits += 5;
}

- (void)performRedeem {
    if (credits >= 5) {
        credits -= 5;
    }
}

//- (void)testPerformanceExample {
//    // This is an example of a performance test case.
//    [self measureBlock:^{
//        // Put the code you want to measure the time of here.
//    }];
//}

@end
