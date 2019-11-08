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

// verifies AdClient loaded via reflection is the sharedClient
- (void)testAdClientLoadsViaReflection {
    XCTAssertTrue([ADClient sharedClient] == [BNCAppleAdClient new].adClient);
}

- (void)testErrorOnFailureToLoad {
    // simulate failure to load by setting adClient to nil
    BNCAppleAdClient *adClient = [BNCAppleAdClient new];
    adClient.adClient = nil;
    
    __block XCTestExpectation *expectation = [self expectationWithDescription:@""];
    
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
