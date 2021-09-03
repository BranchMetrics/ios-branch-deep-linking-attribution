//
//  BNCAppleAdClientTests.m
//  Branch-SDK-Tests
//
//  Created by Ernest Cho on 11/7/19.
//  Copyright © 2019 Branch, Inc. All rights reserved.
//

#import <XCTest/XCTest.h>
#import <iAd/iAd.h>
#import "BNCAppleAdClient.h"

// expose private property for testing
@interface BNCAppleAdClient()

@property (nonatomic, strong, readwrite) id adClient;

@end

@interface BNCAppleAdClientTests : XCTestCase

@end

@implementation BNCAppleAdClientTests

- (void)setUp {
    // Put setup code here. This method is called before the invocation of each test method in the class.
}

- (void)tearDown {
    // Put teardown code here. This method is called after the invocation of each test method in the class.
}

- (void)testAdClientLoadsViaReflection {
    XCTAssertNotNil([BNCAppleAdClient new].adClient);
    XCTAssertTrue([[BNCAppleAdClient new].adClient isKindOfClass:ADClient.class]);
}

/*
Expected payload varies by simulator or test device.  In general, there is a payload of some sort.

This test fails on iOS 10 simulators.  Some iPad simulators never respond.  Some iPhone simulators return an error.
*/
- (void)testRequestAttribution {
    __block XCTestExpectation *expectation = [self expectationWithDescription:@"BNCAppleAdClient"];
    
    BNCAppleAdClient *adClient = [BNCAppleAdClient new];
    [adClient requestAttributionDetailsWithBlock:^(NSDictionary<NSString *,NSObject *> * _Nonnull attributionDetails, NSError * _Nonnull error) {
    
        if (@available(iOS 14.5, *)) {
            // Need ATT permission to use get old Apple Search Ads info
            XCTAssertNotNil(error);
            XCTAssert([@"The app is not authorized for ad tracking" isEqualToString:error.localizedDescription]);
            [expectation fulfill];
            
        } else {
            XCTAssertNil(error);
            
            id tmp = [attributionDetails objectForKey:@"Version3.1"];
            if ([tmp isKindOfClass:NSDictionary.class]) {
                NSDictionary *tmpDict = (NSDictionary *)tmp;
                XCTAssertNotNil(tmpDict);
                       
                NSNumber *tmpBool = [tmpDict objectForKey:@"iad-attribution"];
                XCTAssertNotNil(tmpBool);
            } else {
                XCTFail(@"Did not find Search Ads attribution");
            }
            
            [expectation fulfill];
        }
    }];
    
    [self waitForExpectationsWithTimeout:5 handler:^(NSError * _Nullable error) {
        NSLog(@"%@", error);
    }];
}

- (void)testRequestAttribution_Error {
    
    // simulate failure to load by setting adClient to nil
    BNCAppleAdClient *adClient = [BNCAppleAdClient new];
    adClient.adClient = nil;
    
    __block XCTestExpectation *expectation = [self expectationWithDescription:@"BNCAppleAdClient"];
    
    [adClient requestAttributionDetailsWithBlock:^(NSDictionary<NSString *,NSObject *> * _Nonnull attributionDetails, NSError * _Nonnull error) {
        XCTAssertNotNil(error);
        XCTAssertTrue([error.localizedFailureReason containsString:@"ADClient is not available"]);
        
        [expectation fulfill];
    }];
    
    [self waitForExpectationsWithTimeout:5 handler:^(NSError * _Nullable error) {
        NSLog(@"%@", error);
    }];
}

@end
