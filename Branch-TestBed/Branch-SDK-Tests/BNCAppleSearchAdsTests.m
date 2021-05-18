//
//  BNCAppleSearchAdsTests.m
//  Branch-SDK-Tests
//
//  Created by Ernest Cho on 10/23/19.
//  Copyright © 2019 Branch, Inc. All rights reserved.
//

#import <XCTest/XCTest.h>
#import <UIKit/UIKit.h>
#import <iAd/iAd.h>
#import "BNCAppleSearchAds.h"
#import "BNCAppleAdClient.h"

@interface BNCAppleAdClientMock : NSObject <BNCAppleAdClientProtocol>

@property (nonatomic, assign, readwrite) NSInteger ignoreCount;
@property (nonatomic, assign, readwrite) NSInteger numIgnores;

- (void)requestAttributionDetailsWithBlock:(void (^)(NSDictionary<NSString *,NSObject *> * _Nonnull, NSError * _Nonnull))completionHandler;

@end

@implementation BNCAppleAdClientMock

- (instancetype)init {
    self = [super init];
    if (self) {
        self.numIgnores = 0;
        self.ignoreCount = 0;
    }
    return self;
}

- (void)requestAttributionDetailsWithBlock:(void (^)(NSDictionary<NSString *,NSObject *> * _Nonnull, NSError * _Nonnull))completionHandler {
    if (self.ignoreCount < self.numIgnores) {
        self.ignoreCount++;
        return;
    }

    if (@available(iOS 10, *)) {
        [[ADClient sharedClient] requestAttributionDetailsWithBlock:completionHandler];
    }
}

@end

@interface BNCAppleSearchAds()

// Expose private methods for testing
@property (nonatomic, strong, readwrite) id <BNCAppleAdClientProtocol> adClient;

- (BOOL)isAppleSearchAdSavedToDictionary:(NSDictionary *)appleSearchAdDetails;
- (BOOL)isDateWithinWindow:(NSDate *)installDate;
- (BOOL)isAdClientAvailable;
- (BOOL)isAppleTestData:(NSDictionary *)appleSearchAdDetails;
- (BOOL)isSearchAdsErrorRetryable:(nullable NSError *)error;

- (void)requestAttributionWithMaxAttempts:(NSInteger)maxAttempts completion:(void (^_Nullable)(NSDictionary *__nullable attributionDetails, NSError *__nullable error, NSTimeInterval elapsedSeconds))completion;

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

- (void)testIsSearchAdsErrorRetryable_Nil {
    XCTAssertFalse([self.appleSearchAds isSearchAdsErrorRetryable:nil]);
}

- (void)testIsSearchAdsErrorRetryable_ADClientErrorUnknown {
    NSError *error = [NSError errorWithDomain:@"" code:ADClientErrorUnknown userInfo:nil];
    XCTAssertTrue([self.appleSearchAds isSearchAdsErrorRetryable:error]);
}

- (void)testIsSearchAdsErrorRetryable_ADClientErrorLimitAdTracking {
    NSError *error = [NSError errorWithDomain:@"" code:ADClientErrorLimitAdTracking userInfo:nil];
    XCTAssertFalse([self.appleSearchAds isSearchAdsErrorRetryable:error]);
}

- (void)testIsSearchAdsErrorRetryable_ADClientErrorMissingData {
    NSError *error = [NSError errorWithDomain:@"" code:ADClientErrorMissingData userInfo:nil];
    XCTAssertTrue([self.appleSearchAds isSearchAdsErrorRetryable:error]);
}

- (void)testIsSearchAdsErrorRetryable_ADClientErrorCorruptResponse {
    NSError *error = [NSError errorWithDomain:@"" code:ADClientErrorCorruptResponse userInfo:nil];
    XCTAssertTrue([self.appleSearchAds isSearchAdsErrorRetryable:error]);
}

/*
 Expected payload varies by simulator or test device.  In general, there is a payload of some sort.
 
 This test fails on iOS 10 simulators.  Some iPad simulators never respond.  Some iPhone simulators return an error.
 */
- (void)testRequestAppleSearchAds {
    __block XCTestExpectation *expectation = [self expectationWithDescription:@"AppleSearchAds"];
    
    [self.appleSearchAds requestAttributionWithCompletion:^(NSDictionary * _Nullable attributionDetails, NSError * _Nullable error, NSTimeInterval elapsedSeconds) {
        if (@available(iOS 14.5, *)) {
            // Need ATT permission to use get old Apple Search Ads info
            XCTAssertNotNil(error);
            XCTAssertTrue(elapsedSeconds > 0);
            [expectation fulfill];
            
        } else {
            XCTAssertNil(error);
            XCTAssertTrue(elapsedSeconds > 0);
            
            NSDictionary *tmpDict = [attributionDetails objectForKey:@"Version3.1"];
            XCTAssertNotNil(tmpDict);
            
            NSNumber *tmpBool = [tmpDict objectForKey:@"iad-attribution"];
            XCTAssertNotNil(tmpBool);
            
            [expectation fulfill];
        }
    }];
    
    [self waitForExpectationsWithTimeout:5 handler:^(NSError * _Nullable error) {
        NSLog(@"%@", error);
    }];
}

// min attempts = 1, so this should ignore the max attempts
- (void)testRequestAppleSearchAdsWithRetry_0 {
    __block XCTestExpectation *expectation = [self expectationWithDescription:@"AppleSearchAds"];
    
    [self.appleSearchAds requestAttributionWithMaxAttempts:0 completion:^(NSDictionary * _Nullable attributionDetails, NSError * _Nullable error, NSTimeInterval elapsedSeconds) {
        if (@available(iOS 14.5, *)) {
            // Need ATT permission to use get old Apple Search Ads info
            XCTAssertNotNil(error);
            XCTAssert([@"The app is not authorized for ad tracking" isEqualToString:error.localizedDescription]);
            XCTAssertTrue(elapsedSeconds > 0);
            [expectation fulfill];
            
        } else {
            XCTAssertNil(error);
            XCTAssertTrue(elapsedSeconds > 0);
            
            NSDictionary *tmpDict = [attributionDetails objectForKey:@"Version3.1"];
            XCTAssertNotNil(tmpDict);
            
            NSNumber *tmpBool = [tmpDict objectForKey:@"iad-attribution"];
            XCTAssertNotNil(tmpBool);
            
            [expectation fulfill];
        }
    }];
    
    [self waitForExpectationsWithTimeout:5 handler:^(NSError * _Nullable error) {
        NSLog(@"%@", error);
    }];
}

// should work as a basic pass through
- (void)testRequestAppleSearchAdsWithRetry_1 {
    __block XCTestExpectation *expectation = [self expectationWithDescription:@"AppleSearchAds"];
    
    [self.appleSearchAds requestAttributionWithMaxAttempts:1 completion:^(NSDictionary * _Nullable attributionDetails, NSError * _Nullable error, NSTimeInterval elapsedSeconds) {
        if (@available(iOS 14.5, *)) {
            // Need ATT permission to use get old Apple Search Ads info
            XCTAssertNotNil(error);
            XCTAssert([@"The app is not authorized for ad tracking" isEqualToString:error.localizedDescription]);
            XCTAssertTrue(elapsedSeconds > 0);
            [expectation fulfill];
            
        } else {
            XCTAssertNil(error);
            XCTAssertTrue(elapsedSeconds > 0);
            
            NSDictionary *tmpDict = [attributionDetails objectForKey:@"Version3.1"];
            XCTAssertNotNil(tmpDict);
            
            NSNumber *tmpBool = [tmpDict objectForKey:@"iad-attribution"];
            XCTAssertNotNil(tmpBool);
            
            [expectation fulfill];
        }
    }];
    
    [self waitForExpectationsWithTimeout:5 handler:^(NSError * _Nullable error) {
        NSLog(@"%@", error);
    }];
}

- (void)testRequestAppleSearchAdsWithRetry_NoResponse {
    __block XCTestExpectation *expectation = [self expectationWithDescription:@"AppleSearchAds"];

    // Mock the adClient to never respond
    self.appleSearchAds.adClient = nil;
    
    [self.appleSearchAds requestAttributionWithMaxAttempts:1 completion:^(NSDictionary * _Nullable attributionDetails, NSError * _Nullable error, NSTimeInterval elapsedSeconds) {
        XCTAssertNotNil(error);
        XCTAssertTrue(elapsedSeconds > 0);
        XCTAssertNil(attributionDetails);
        
        [expectation fulfill];
    }];
    
    [self waitForExpectationsWithTimeout:5 handler:^(NSError * _Nullable error) {
        NSLog(@"%@", error);
    }];
}

- (void)testRequestAppleSearchAdsWithRetry_3 {
    __block XCTestExpectation *expectation = [self expectationWithDescription:@"AppleSearchAds"];

    // Mock the adClient to ignore 2 times
    __block BNCAppleAdClientMock *mock = [BNCAppleAdClientMock new];
    mock.ignoreCount = 2;
    self.appleSearchAds.adClient = mock;
    
    [self.appleSearchAds requestAttributionWithMaxAttempts:3 completion:^(NSDictionary * _Nullable attributionDetails, NSError * _Nullable error, NSTimeInterval elapsedSeconds) {
        if (@available(iOS 14.5, *)) {
            // Need ATT permission to use get old Apple Search Ads info
            XCTAssertNotNil(error);
            XCTAssert([@"The app is not authorized for ad tracking" isEqualToString:error.localizedDescription]);
            XCTAssertTrue(elapsedSeconds > 0);
            
            // verifies things were ignored
            XCTAssert(mock.ignoreCount == 2);
            
            [expectation fulfill];
            
        } else {
            XCTAssertNil(error);
            XCTAssertTrue(elapsedSeconds > 0);
            
            NSDictionary *tmpDict = [attributionDetails objectForKey:@"Version3.1"];
            XCTAssertNotNil(tmpDict);
            
            NSNumber *tmpBool = [tmpDict objectForKey:@"iad-attribution"];
            XCTAssertNotNil(tmpBool);
            
            // verifies things were ignored
            XCTAssert(mock.ignoreCount == 2);
                    
            [expectation fulfill];
        }
    }];
    
    [self waitForExpectationsWithTimeout:5 handler:^(NSError * _Nullable error) {
        NSLog(@"%@", error);
    }];
}

@end
