//
//  BNCAppleSearchAdsTests.m
//  Branch-SDK-Tests
//
//  Created by Ernest Cho on 10/23/19.
//  Copyright © 2019 Branch, Inc. All rights reserved.
//

#import <XCTest/XCTest.h>
#import "BNCAppleSearchAds.h"

@interface BNCAppleSearchAds()

- (BOOL)isAppleSearchAdSavedToDictionary:(NSDictionary *)appleSearchAdDetails;
- (BOOL)isDateWithinWindow:(NSDate *)installDate;
- (BOOL)isAdClientAvailable;

// if AdClient is not available, this is a noop.  The completion is not called.
- (void)requestAttributionWithCompletion:(void (^_Nullable)(NSDictionary *__nullable attributionDetails, NSError *__nullable error, NSTimeInterval elapsedSeconds))completion;

@end

@interface BNCAppleSearchAdsTests : XCTestCase

@end

@implementation BNCAppleSearchAdsTests

- (void)setUp {

}

- (void)tearDown {

}

- (void)testExample {
    BNCAppleSearchAds *tmp = [BNCAppleSearchAds new];
}

@end
