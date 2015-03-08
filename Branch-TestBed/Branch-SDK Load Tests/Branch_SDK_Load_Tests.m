//
//  Branch_SDK_Load_Tests.m
//  Branch-TestBed
//
//  Created by Qinwei Gong on 2/23/15.
//  Copyright (c) 2015 Branch Metrics. All rights reserved.
//

#import <XCTest/XCTest.h>
#import "Branch.h"
#import "BNCPreferenceHelper.h"
#import "BNCServerInterface.h"
#import "Nocilla.h"

@interface Branch_SDK_Load_Tests : XCTestCase {
    
@private
    __weak Branch *branch;
}

@end

@implementation Branch_SDK_Load_Tests

- (void)setUp {
    [super setUp];
    
    branch = [Branch getInstance:@"5668720416392049"];
    
    [BNCPreferenceHelper setSessionID:@"97141055400444225"];
    [BNCPreferenceHelper setDeviceFingerprintID:@"94938498586381084"];
    [BNCPreferenceHelper setIdentityID:@"95765863201768032"];
    [BNCPreferenceHelper setLinkClickID:NO_STRING_VALUE];
    [BNCPreferenceHelper setLinkClickIdentifier:NO_STRING_VALUE];
    [BNCPreferenceHelper setSessionParams:NO_STRING_VALUE];
    
    [BNCPreferenceHelper setTestDelegate:(id<BNCTestDelegate>)branch];
    [BNCPreferenceHelper simulateInitFinished];
    
    [[LSNocilla sharedInstance] start];
}

- (void)tearDown {
    [[LSNocilla sharedInstance] clearStubs];
    [[LSNocilla sharedInstance] stop];
    
    [super tearDown];
}

- (void)testLoad {
    NSDictionary *responseDict = @{@"url": @"https://bnc.lt/l/3PxZVFU-BK"};
    NSData *responseData = [BNCServerInterface encodePostParams:responseDict];
    
    stubRequest(@"POST", [BNCPreferenceHelper getAPIURL:@"url"])
    .andReturn(200)
    .withHeaders(@{@"Content-Type": @"application/json"})
    .withBody(responseData);
    
    XCTestExpectation *getShortURLExpectation = [self expectationWithDescription:@"Test getShortURL"];
    
    for (int i = 0; i < 1000; i++) {
        [branch getShortURLWithParams:nil andChannel:[NSString stringWithFormat:@"%d", i] andFeature:nil andCallback:^(NSString *url, NSError *error) {
            XCTAssertNil(error);
            XCTAssertNotNil(url);
        }];
    }
    
    [branch getShortURLWithParams:nil andChannel:nil andFeature:@"feature" andCallback:^(NSString *url, NSError *error) {
        XCTAssertNil(error);
        XCTAssertEqualObjects(url, @"https://bnc.lt/l/3PxZVFU-BK");
        [getShortURLExpectation fulfill];
    }];
    
    [self waitForExpectationsWithTimeout:1 handler:^(NSError *error) {
    }];
}

@end

