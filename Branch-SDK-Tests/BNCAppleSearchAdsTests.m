//
//  BNCAppleSearchAdsTests.m
//  Branch-SDK-Tests
//
//  Created by Ernest Cho on 10/23/19.
//  Copyright © 2019 Branch, Inc. All rights reserved.
//

#import <XCTest/XCTest.h>
#import "BNCAppleSearchAds.h"

// expose private methods for unit testing
@interface BNCAppleSearchAds()

- (BOOL)isAppleSearchAdSavedToDictionary:(NSDictionary *)appleSearchAdDetails;
- (BOOL)isDateWithinWindow:(NSDate *)installDate;
- (BOOL)isAdClientAvailable;
- (BOOL)isAppleTestData:(NSDictionary *)appleSearchAdDetails;

- (void)requestAttributionWithCompletion:(void (^_Nullable)(NSDictionary *__nullable attributionDetails, NSError *__nullable error, NSTimeInterval elapsedSeconds))completion;

@end

@interface BNCAppleSearchAdsTests : XCTestCase

@property (nonatomic, strong, readwrite) BNCAppleSearchAds *appleSearchAds;

@end

@implementation BNCAppleSearchAdsTests

- (void)setUp {
    self.appleSearchAds = [[BNCAppleSearchAds alloc] init];
}

- (void)tearDown {

}

- (void)testAdClientIsAvailable {
    XCTAssertTrue([self.appleSearchAds isAdClientAvailable]);
}

- (void)testDateIsWithinWindow_DistantPast {
    XCTAssertFalse([self.appleSearchAds isDateWithinWindow:[NSDate distantPast]]);
}

- (void)testDateIsWithinWindow_DistantFuture {
    XCTAssertFalse([self.appleSearchAds isDateWithinWindow:[NSDate distantFuture]]);
}

- (void)testDateIsWithinWindow_Now {
    XCTAssertTrue([self.appleSearchAds isDateWithinWindow:[NSDate date]]);
}

- (void)testIsAppleSearchAdSavedToDictionary_Nil {
    XCTAssertFalse([self.appleSearchAds isAppleSearchAdSavedToDictionary:nil]);
}

- (void)testIsAppleSearchAdSavedToDictionary_Empty {
    XCTAssertFalse([self.appleSearchAds isAppleSearchAdSavedToDictionary:@{}]);
}

- (void)testIsAppleSearchAdSavedToDictionary_NO {
    XCTAssertFalse([self.appleSearchAds isAppleSearchAdSavedToDictionary:@{ @"Version3.1" : @{ @"iad-attribution": @(NO) } }]);
}

- (void)testIsAppleSearchAdSavedToDictionary_YES {
    XCTAssertTrue([self.appleSearchAds isAppleSearchAdSavedToDictionary:@{ @"Version3.1" : @{ @"iad-attribution": @(YES) } }]);
}

/*
 Expected test data from Apple.
 
 "Version3.1" =     {
     "iad-adgroup-id" = 1234567890;
     "iad-adgroup-name" = AdGroupName;
     "iad-attribution" = true;
     "iad-campaign-id" = 1234567890;
     "iad-campaign-name" = CampaignName;
     "iad-click-date" = "2019-10-24T00:14:36Z";
     "iad-conversion-date" = "2019-10-24T00:14:36Z";
     "iad-conversion-type" = Download;
     "iad-country-or-region" = US;
     "iad-creativeset-id" = 1234567890;
     "iad-creativeset-name" = CreativeSetName;
     "iad-keyword" = Keyword;
     "iad-keyword-id" = KeywordID;
     "iad-keyword-matchtype" = Broad;
     "iad-lineitem-id" = 1234567890;
     "iad-lineitem-name" = LineName;
     "iad-org-id" = 1234567890;
     "iad-org-name" = OrgName;
     "iad-purchase-date" = "2019-10-24T00:14:36Z";
 };
 */
- (void)testIsTestData_YES {
    NSDictionary *testDataIndicators = @{
        @"Version3.1" : @{
            @"iad-adgroup-id" : @"1234567890",
            @"iad-adgroup-name" : @"AdGroupName",
            @"iad-campaign-id" : @"1234567890",
            @"iad-campaign-name" : @"CampaignName",
            @"iad-org-id" : @"1234567890",
            @"iad-org-name" : @"OrgName"
        }
    };
    
    XCTAssertTrue([self.appleSearchAds isAppleTestData:testDataIndicators]);
}

- (void)testIsTestData_NO {
    NSDictionary *testDataIndicators = @{
        @"Version3.1" : @{
            @"iad-adgroup-id" : @"100",
            @"iad-adgroup-name" : @"AdGroupName",
            @"iad-campaign-id" : @"1234567890",
            @"iad-campaign-name" : @"CampaignName",
            @"iad-org-id" : @"1234567890",
            @"iad-org-name" : @"OrgName"
        }
    };
    
    XCTAssertFalse([self.appleSearchAds isAppleTestData:testDataIndicators]);
}

/*
 Expected payload varies by simulator or test device.  In general, there is a payload of some sort.
 
 This test fails on iOS 10 simulators.  iPad simulators never respond.  iPhone simulators return an error.
 */
- (void)testRequestAppleSearchAds {
    __block XCTestExpectation *expectation = [self expectationWithDescription:@"AppleSearchAds"];
    
    [self.appleSearchAds requestAttributionWithCompletion:^(NSDictionary * _Nullable attributionDetails, NSError * _Nullable error, NSTimeInterval elapsedSeconds) {
        XCTAssertNil(error);
        XCTAssertTrue(elapsedSeconds > 0);
        
        NSDictionary *tmpDict = [attributionDetails objectForKey:@"Version3.1"];
        XCTAssertNotNil(tmpDict);
        
        NSNumber *tmpBool = [tmpDict objectForKey:@"iad-attribution"];
        XCTAssertNotNil(tmpBool);
        
        [expectation fulfill];
    }];
    
    [self waitForExpectationsWithTimeout:5 handler:^(NSError * _Nullable error) {
        NSLog(@"%@", error);
    }];
}

@end
