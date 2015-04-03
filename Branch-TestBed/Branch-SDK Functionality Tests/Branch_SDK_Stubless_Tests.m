//
//  Branch_SDK_Stubless_Tests.m
//  Branch-SDK Stubless Tests
//
//  Created by Qinwei Gong on 3/4/15.
//  Copyright (c) 2015 Branch Metrics. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <XCTest/XCTest.h>
#import "Branch.h"
#import "BNCPreferenceHelper.h"
#import "BNCServerInterface.h"
#import "BNCConfig.h"
#import "BNCServerRequestQueue.h"
#import <Nocilla/Nocilla.h>

NSString * const REFERRAL_CODE = @"LMDLDV";

static Branch *branch;

@interface Branch_SDK_Stubless_Tests : XCTestCase

@property (assign, nonatomic) BOOL hasExceededExpectations;

@end

@implementation Branch_SDK_Stubless_Tests

#pragma mark - Setup
+ (void)setUp {
    [[BNCServerRequestQueue getInstance] clearQueue];
    
    [[LSNocilla sharedInstance] start];
    
    stubRequest(@"POST", [BNCPreferenceHelper getAPIURL:@"applist"].regex).andReturn(200);
    stubRequest(@"GET", [BNCPreferenceHelper getAPIURL:@"applist"].regex).andReturn(200);

    NSDictionary *openResponseDict = @{
        @"session_id": @"112263020234678596",
        @"identity_id": @"98687515069776101",
        @"device_fingerprint_id": @"94938498586381084",
        @"browser_fingerprint_id": [NSNull null],
        @"link": @"https://bnc.lt/i/3SawKbU-1Z",
        @"new_identity_id": @"98687515069776101",
        @"identity": @"test_user_10"
    };

    NSData *responseData = [NSJSONSerialization dataWithJSONObject:openResponseDict options:kNilOptions error:nil];
    
    stubRequest(@"POST", [BNCPreferenceHelper getAPIURL:@"open"])
    .andReturn(200)
    .withHeaders(@{@"Content-Type": @"application/json"})
    .withBody(responseData);
    
    branch = [Branch getInstance:@"5668720416392049"];
    [branch initSessionAndRegisterDeepLinkHandler:^(NSDictionary *params, NSError *error) {
        if (error) {
            NSLog(@"An error prevented Branch from initializing: %@", error);
        }
    }];
    
    [NSThread sleepForTimeInterval:1]; // Allow init to complete
}

+ (void)tearDown {
    stubRequest(@"POST", [BNCPreferenceHelper getAPIURL:@"applist"].regex).andReturn(200);
    stubRequest(@"GET", [BNCPreferenceHelper getAPIURL:@"applist"].regex).andReturn(200);

    [[LSNocilla sharedInstance] stop];
}

- (void)setUp {
    self.hasExceededExpectations = NO;
}

- (void)tearDown {
    [[LSNocilla sharedInstance] clearStubs];
}

#pragma mark - Tests

- (void)test00SetIdentity {
    // mock logout synchronously
    [BNCPreferenceHelper setIdentityID:@"98274447349252681"];
    [BNCPreferenceHelper setUserURL:@"https://bnc.lt/i/3R7_PIk-77"];
    [BNCPreferenceHelper setUserIdentity:NO_STRING_VALUE];
    [BNCPreferenceHelper setInstallParams:NO_STRING_VALUE];
    [BNCPreferenceHelper setSessionParams:NO_STRING_VALUE];
    [BNCPreferenceHelper clearUserCreditsAndCounts];

    NSDictionary *setIdentityResponseDict = @{
        @"identity_id": @"98687515069776101",
        @"link_click_id": @"87925296346431956",
        @"link": @"https://bnc.lt/i/3SawKbU-1Z",
        @"referring_data": @"{\"$og_title\":\"Kindred\",\"key1\":\"test_object\",\"key2\":\"here is another object!!\",\"$og_image_url\":\"https://s3-us-west-1.amazonaws.com/branchhost/mosaic_og.png\",\"source\":\"ios\"}"
    };
    
    NSData *responseData = [NSJSONSerialization dataWithJSONObject:setIdentityResponseDict options:kNilOptions error:nil];
    
    stubRequest(@"POST", [BNCPreferenceHelper getAPIURL:@"profile"])
    .andReturn(200)
    .withHeaders(@{@"Content-Type": @"application/json"})
    .withBody(responseData);
    
    XCTestExpectation *setIdentityExpectation = [self expectationWithDescription:@"Test setIdentity"];
    
    NSLog(@"Calling set identity");
    [branch setIdentity:@"test_user_10" withCallback:^(NSDictionary *params, NSError *error) {
        XCTAssertNil(error);
        XCTAssertNotNil(params);
        
        XCTAssertEqualObjects([BNCPreferenceHelper getIdentityID], @"98687515069776101");
        NSDictionary *installParams = [branch getFirstReferringParams];
        
        XCTAssertEqualObjects(installParams[@"$og_title"], @"Kindred"); //TODO: equal to params?
        XCTAssertEqualObjects(installParams[@"key1"], @"test_object");
        
        [self safelyFulfillExpectation:setIdentityExpectation];
    }];
    
    [self awaitExpectations];
}

- (void)test01GetShortURLAsync {
    NSDictionary *shortUrlFBResponseDict = @{ @"url": @"https://bnc.lt/l/4BGtJj-03N" };
    NSDictionary *shortUrlTWResponseDict = @{ @"url": @"https://bnc.lt/l/-03N4BGtJj" };

    NSData *fbResponseData = [NSJSONSerialization dataWithJSONObject:shortUrlFBResponseDict options:kNilOptions error:nil];
    NSData *twResponseData = [NSJSONSerialization dataWithJSONObject:shortUrlTWResponseDict options:kNilOptions error:nil];
    
    stubRequest(@"POST", [BNCPreferenceHelper getAPIURL:@"url"])
    .withBody(@"\"channel\":\"facebook\"".regex)
    .andReturn(200)
    .withHeaders(@{@"Content-Type": @"application/json"})
    .withBody(fbResponseData);
    
    stubRequest(@"POST", [BNCPreferenceHelper getAPIURL:@"url"])
    .withBody(@"\"channel\":\"twitter\"".regex)
    .andReturn(200)
    .withHeaders(@{@"Content-Type": @"application/json"})
    .withBody(twResponseData);

    XCTestExpectation *getShortURLExpectation = [self expectationWithDescription:@"Test getShortURL"];

    [branch getShortURLWithParams:nil andChannel:@"facebook" andFeature:nil andCallback:^(NSString *url, NSError *error) {
        XCTAssertNil(error);
        XCTAssertNotNil(url);

        NSString *returnURL = url;
        
        [branch getShortURLWithParams:nil andChannel:@"facebook" andFeature:nil andCallback:^(NSString *url, NSError *error) {
            XCTAssertNil(error);
            XCTAssertNotNil(url);
            XCTAssertEqualObjects(url, returnURL);
        }];
        
        NSString *urlFB = [branch getShortURLWithParams:nil andChannel:@"facebook" andFeature:nil];
        XCTAssertEqualObjects(urlFB, url);
        
        NSString *urlTT = [branch getShortURLWithParams:nil andChannel:@"twitter" andFeature:nil];
        XCTAssertNotNil(urlTT);
        XCTAssertNotEqualObjects(urlTT, url);
        
        [self safelyFulfillExpectation:getShortURLExpectation];
    }];
    
    [self awaitExpectations];
}

- (void)test02GetShortURLSync {
    NSString *url1 = [branch getShortURLWithParams:nil andChannel:@"facebook" andFeature:nil];
    XCTAssertNotNil(url1);
    
    NSString *url2 = [branch getShortURLWithParams:nil andChannel:@"facebook" andFeature:nil];
    XCTAssertEqualObjects(url1, url2);
    
    NSString *url3 = [branch getShortURLWithParams:nil andChannel:@"twitter" andFeature:nil];
    XCTAssertNotNil(url3);
    XCTAssertNotEqualObjects(url1, url3);
}

- (void)test03GetRewardsChanged {
    [BNCPreferenceHelper setCreditCount:NSIntegerMax forBucket:@"default"];

    NSDictionary *getRewardsResponseDict = @{
        @"default": @(NSIntegerMin)
    };
    
    NSData *responseData = [NSJSONSerialization dataWithJSONObject:getRewardsResponseDict options:kNilOptions error:nil];

    NSRegularExpression *creditsRegex = [BNCPreferenceHelper getAPIURL:[NSString stringWithFormat:@"credits/%@", [BNCPreferenceHelper getIdentityID]]].regex;
    stubRequest(@"GET", creditsRegex)
    .andReturn(200)
    .withHeaders(@{@"Content-Type": @"application/json"})
    .withBody(responseData);
    
    XCTestExpectation *getRewardExpectation = [self expectationWithDescription:@"Test getReward"];
    
    [branch loadRewardsWithCallback:^(BOOL changed, NSError *error) {
        XCTAssertNil(error);
        XCTAssertTrue(changed);
        
        [self safelyFulfillExpectation:getRewardExpectation];
    }];
    
    [self awaitExpectations];
}

- (void)test04GetRewardsUnchanged {
    [BNCPreferenceHelper setCreditCount:1 forBucket:@"default"];
    NSDictionary *getRewardsResponseDict = @{
        @"default": @(1)
    };
    
    NSData *responseData = [NSJSONSerialization dataWithJSONObject:getRewardsResponseDict options:kNilOptions error:nil];

    stubRequest(@"GET", [BNCPreferenceHelper getAPIURL:[NSString stringWithFormat:@"credits/%@", [BNCPreferenceHelper getIdentityID]]].regex)
    .andReturn(200)
    .withHeaders(@{@"Content-Type": @"application/json"})
    .withBody(responseData);
    
    XCTestExpectation *getRewardExpectation = [self expectationWithDescription:@"Test getReward"];
    
    [branch loadRewardsWithCallback:^(BOOL changed, NSError *error) {
        XCTAssertNil(error);
        XCTAssertFalse(changed);

        [self safelyFulfillExpectation:getRewardExpectation];
    }];
    
    [self awaitExpectations];
}

- (void)test05GetReferralCode {
    XCTestExpectation *getReferralCodeExpectation = [self expectationWithDescription:@"Test getReferralCode"];
    NSDictionary *getReferralResponseDict = @{
        @"id": @"85782843459895738",
        @"app_id": @"5668720416392049",
        @"calculation_type": @0,
        @"location": @0,
        @"type": @"credit",
        @"event": @"$redeem_code-LMDLDV",
        @"metadata": @{
            @"bucket": @"default",
            @"amount": @5
        },
        @"filter": [NSNull null],
        @"link_id": [NSNull null],
        @"identity_id": @"98687515069776101",
        @"creation_source": @2,
        @"expiration": [NSNull null],
        @"date": @"2015-01-19T18:00:50.242Z",
        @"referral_code": @"LMDLDV"
    };
    
    NSData *responseData = [NSJSONSerialization dataWithJSONObject:getReferralResponseDict options:kNilOptions error:nil];

    stubRequest(@"POST", [BNCPreferenceHelper getAPIURL:@"referralcode"].regex)
    .andReturn(200)
    .withHeaders(@{@"Content-Type": @"application/json"})
    .withBody(responseData);

    [branch getReferralCodeWithPrefix:@"test" amount:7 expiration:nil bucket:@"default" calculationType:BranchUniqueRewards location:BranchReferringUser andCallback:^(NSDictionary *params, NSError *error) {
        XCTAssertNil(error);
        XCTAssertNotNil(params[@"referral_code"]);
        
        [self safelyFulfillExpectation:getReferralCodeExpectation];
    }];
    
    [self awaitExpectations];
}

// This test depends on test05GetReferralCode
- (void)test06ValidateReferralCode {
    NSDictionary *validateReferralResponseDict = @{
        @"id": @"85782843459895738",
        @"app_id": @"5668720416392049",
        @"calculation_type": @0,
        @"location": @0,
        @"type": @"credit",
        @"event": @"$redeem_code-LMDLDV",
        @"metadata": @{
           @"bucket": @"default",
           @"amount": @5
        },
        @"filter": [NSNull null],
        @"link_id": [NSNull null],
        @"identity_id": @"98687515069776101",
        @"creation_source": @2,
        @"expiration": [NSNull null],
        @"date": @"2015-01-19T18:00:50.242Z",
        @"referral_code": REFERRAL_CODE
    };
    
    NSData *responseData = [NSJSONSerialization dataWithJSONObject:validateReferralResponseDict options:kNilOptions error:nil];
    
    stubRequest(@"POST", [BNCPreferenceHelper getAPIURL:[NSString stringWithFormat:@"referralcode/%@", REFERRAL_CODE]].regex)
    .andReturn(200)
    .withHeaders(@{@"Content-Type": @"application/json"})
    .withBody(responseData);
    
    XCTestExpectation *getReferralCodeExpectation = [self expectationWithDescription:@"Test validateReferralCode"];
    
    [branch validateReferralCode:REFERRAL_CODE andCallback:^(NSDictionary *params, NSError *error) {
        XCTAssertNil(error);
        
        NSString *code = params[@"referral_code"];
        XCTAssertNotNil(code);
        XCTAssertTrue([code isEqualToString:REFERRAL_CODE]);
        XCTAssertEqual([params[@"calculation_type"] integerValue], BranchUnlimitedRewards);
        XCTAssertEqual([params[@"location"] integerValue], BranchReferreeUser);
        XCTAssertEqual([params[@"metadata"][@"amount"] integerValue], 5);

        [self safelyFulfillExpectation:getReferralCodeExpectation];

    }];
    
    [self awaitExpectations];
}

// This test depends on test05GetReferralCode
- (void)test07ApplyReferralCode {
    NSDictionary *applyReferralResponseDict = @{
        @"id": @"85782843459895738",
        @"app_id": @"5668720416392049",
        @"calculation_type": @0,
        @"location": @0,
        @"type": @"credit",
        @"event": @"$redeem_code-LMDLDV",
        @"metadata": @{
            @"bucket": @"default",
            @"amount": @5
        },
        @"filter": [NSNull null],
        @"link_id": [NSNull null],
        @"identity_id": @"98687515069776101",
        @"creation_source": @2,
        @"expiration": [NSNull null],
        @"date": @"2015-01-19T18:00:50.242Z",
        @"referral_code": REFERRAL_CODE
    };
    
    NSData *responseData = [NSJSONSerialization dataWithJSONObject:applyReferralResponseDict options:kNilOptions error:nil];
    
    stubRequest(@"POST", [BNCPreferenceHelper getAPIURL:[NSString stringWithFormat:@"applycode/%@", REFERRAL_CODE]].regex)
    .andReturn(200)
    .withHeaders(@{@"Content-Type": @"application/json"})
    .withBody(responseData);
    
    XCTestExpectation *getReferralCodeExpectation = [self expectationWithDescription:@"Test applyReferralCode"];

    [branch applyReferralCode:REFERRAL_CODE andCallback:^(NSDictionary *params, NSError *error) {
        XCTAssertNil(error);
        
        NSString *code = params[@"referral_code"];
        XCTAssertNotNil(code);
        XCTAssertTrue([code isEqualToString:REFERRAL_CODE]);
        XCTAssertEqual([params[@"calculation_type"] integerValue], BranchUnlimitedRewards);
        XCTAssertEqual([params[@"location"] integerValue], BranchReferreeUser);
        XCTAssertEqual([params[@"metadata"][@"amount"] integerValue], 5);
        
        [self safelyFulfillExpectation:getReferralCodeExpectation];
    }];
    
    [self awaitExpectations];
}

- (void)test08GetCreditHistory {
    NSArray *creditHistoryResponseArray = @[
        @{
            @"transaction": @{
                @"id": @"112281771218838351",
                @"bucket": @"default",
                @"type": @0,
                @"amount": @5,
                @"date": @"2015-04-02T20:58:06.946Z"
            },
            @"referrer": @"test_user_10",
            @"referree": [NSNull null]
        }
    ];
    
    NSData *responseData = [NSJSONSerialization dataWithJSONObject:creditHistoryResponseArray options:kNilOptions error:nil];
    
    stubRequest(@"POST", [BNCPreferenceHelper getAPIURL:@"credithistory"].regex)
    .andReturn(200)
    .withHeaders(@{@"Content-Type": @"application/json"})
    .withBody(responseData);

    XCTestExpectation *getCreditHistoryExpectation = [self expectationWithDescription:@"Test getCreditHistory"];
    
    [branch getCreditHistoryWithCallback:^(NSArray *list, NSError *error) {
        XCTAssertNil(error);
        XCTAssertNotNil(list);
        XCTAssertGreaterThan(list.count, 0);
        
        [self safelyFulfillExpectation:getCreditHistoryExpectation];
    }];
    
    [self awaitExpectations];
}

#pragma mark - Test Util
- (void)safelyFulfillExpectation:(XCTestExpectation *)expectation {
    if (!self.hasExceededExpectations) {
        [expectation fulfill];
    }
}

- (void)awaitExpectations {
    [self waitForExpectationsWithTimeout:1 handler:^(NSError *error) {
        self.hasExceededExpectations = YES;
    }];
}

@end

