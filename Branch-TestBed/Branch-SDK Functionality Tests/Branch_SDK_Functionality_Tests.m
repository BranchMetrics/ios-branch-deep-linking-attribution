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

@interface Branch_SDK_Functionality_Tests : XCTestCase {
    
@private
    __weak Branch *branch;
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

@implementation Branch_SDK_Functionality_Tests

+ (void)setUp {
    [[LSNocilla sharedInstance] start];
    
    stubRequest(@"GET", [BNCPreferenceHelper getAPIURL:[NSString stringWithFormat:@"applist?sdk=ios%@&retryNumber=0", SDK_VERSION]]).andReturn(200);
}

+ (void)tearDown {
    [[LSNocilla sharedInstance] clearStubs];
    [[LSNocilla sharedInstance] stop];
}

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
    
    branch = [Branch getInstance:app_id];
}

- (void)tearDown {
    [super tearDown];
}

- (void)initSession {
    [BNCPreferenceHelper setSessionID:session_id];
    [BNCPreferenceHelper setDeviceFingerprintID:device_fingerprint_id];
    [BNCPreferenceHelper setIdentityID:identity_id];
    [BNCPreferenceHelper setLinkClickID:NO_STRING_VALUE];
    [BNCPreferenceHelper setLinkClickIdentifier:NO_STRING_VALUE];
    [BNCPreferenceHelper setSessionParams:NO_STRING_VALUE];
    [BNCPreferenceHelper setTestDelegate:(id<BNCTestDelegate>)branch];
    [BNCPreferenceHelper simulateInitFinished];
}

- (void)test99Open {
    NSDictionary *responseDict = @{@"browser_fingerprint_id": browser_fingerprint_id,
                                   @"device_fingerprint_id": device_fingerprint_id,
                                   @"identity_id": identity_id,
                                   @"link": identity_link,
                                   @"session_id": session_id
                                   };
    NSData *responseData = [BNCServerInterface encodePostParams:responseDict];
    
    stubRequest(@"POST", [BNCPreferenceHelper getAPIURL:@"open"])
    .andReturn(200)
    .withHeaders(@{@"Content-Type": @"application/json"})
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

- (void)test01GetShortURLAsync {
    [self initSession];
    
    NSString __block *returnURL;
    
    NSDictionary *responseDict = @{@"url": short_link};
    NSData *responseData = [BNCServerInterface encodePostParams:responseDict];
    
    stubRequest(@"POST", [BNCPreferenceHelper getAPIURL:@"url"])
    .andReturn(200)
    .withHeaders(@{@"Content-Type": @"application/json"})
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
        
        NSString *urlFB = [branch getShortURLWithParams:nil andChannel:@"facebook" andFeature:nil];
        XCTAssertEqualObjects(urlFB, url);
        
        if (![[LSNocilla sharedInstance] isStarted]) {
            NSString *urlTT = [branch getShortURLWithParams:nil andChannel:@"twitter" andFeature:nil];
            XCTAssertNotNil(urlTT);
            XCTAssertNotEqualObjects(urlTT, url);
        }
        
        [getShortURLExpectation fulfill];
    }];
    
    [self waitForExpectationsWithTimeout:1 handler:^(NSError *error) {
    }];
}

- (void)test02GetShortURLSync {
    [self initSession];
    
    NSDictionary *responseDict = @{@"url": short_link};
    NSData *responseData = [BNCServerInterface encodePostParams:responseDict];
    
    stubRequest(@"POST", [BNCPreferenceHelper getAPIURL:@"url"])
    .andReturn(200)
    .withHeaders(@{@"Content-Type": @"application/json"})
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

- (void)test03GetRewardsChanged {
    [self initSession];
    
    [BNCPreferenceHelper setCreditCount:0 forBucket:@"default"];
    
    NSDictionary *responseDict = @{@"default": [NSNumber numberWithInt:credits]};
    NSData *responseData = [BNCServerInterface encodePostParams:responseDict];
    
    stubRequest(@"GET", [BNCPreferenceHelper getAPIURL:[NSString stringWithFormat:@"%@/%@?sdk=ios%@&retryNumber=0&app_id=%@", @"credits", [BNCPreferenceHelper getIdentityID], SDK_VERSION, app_id]])
    .andReturn(200)
    .withHeaders(@{@"Content-Type": @"application/json"})
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

- (void)test04GetRewardsUnchanged {
    [self initSession];
    
    [BNCPreferenceHelper setCreditCount:credits forBucket:@"default"];
    
    NSDictionary *responseDict = @{@"default": [NSNumber numberWithInt:credits]};
    NSData *responseData = [BNCServerInterface encodePostParams:responseDict];
    
    stubRequest(@"GET", [BNCPreferenceHelper getAPIURL:[NSString stringWithFormat:@"%@/%@?sdk=ios%@&retryNumber=0&app_id=%@", @"credits", [BNCPreferenceHelper getIdentityID], SDK_VERSION, app_id]])
    .andReturn(200)
    .withHeaders(@{@"Content-Type": @"application/json"})
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

- (void)test05GetReferralCode {
    [self initSession];
    
    NSDictionary *responseDict = @{@"referral_code": @"testRC",
                                   @"calculation_type": @1,
                                   @"event": @"$redeem_code-testRC",
                                   @"location": @2,
                                   @"metadata": @{@"amount": @7,
                                                  @"bucket": @"default"
                                                  }
                                   };
    NSData *responseData = [BNCServerInterface encodePostParams:responseDict];
    
    stubRequest(@"POST", [BNCPreferenceHelper getAPIURL:@"referralcode"])
    .andReturn(200)
    .withHeaders(@{@"Content-Type": @"application/json"})
    .withBody(responseData);
    
    XCTestExpectation *getReferralCodeExpectation = [self expectationWithDescription:@"Test getReferralCode"];
    
    [branch getReferralCodeWithPrefix:@"test" amount:7 expiration:nil bucket:@"default" calculationType:BranchUniqueRewards location:BranchReferringUser andCallback:^(NSDictionary *params, NSError *error) {
        XCTAssertNil(error);
        
        NSString *code = params[@"referral_code"];
        XCTAssertNotNil(code);
        XCTAssertTrue([code hasPrefix:@"test"]);
        XCTAssertEqual([params[@"calculation_type"] integerValue], BranchUniqueRewards);
        XCTAssertEqual([params[@"location"] integerValue], BranchReferringUser);
        XCTAssertEqual([params[@"metadata"][@"amount"] integerValue], 7);
        
        [getReferralCodeExpectation fulfill];
    }];
    
    [self waitForExpectationsWithTimeout:1 handler:^(NSError *error) {
    }];
}

- (void)test06ValidateReferralCode {
    [self initSession];
    
    NSDictionary *responseDict = @{@"referral_code": @"testRC",
                                   @"calculation_type": @1,
                                   @"event": @"$redeem_code-testRC",
                                   @"location": @2,
                                   @"metadata": @{@"amount": @7,
                                                  @"bucket": @"default"
                                                  }
                                   };
    NSData *responseData = [BNCServerInterface encodePostParams:responseDict];
    
    stubRequest(@"POST", [BNCPreferenceHelper getAPIURL:[NSString stringWithFormat:@"%@/%@", @"referralcode", @"testRC"]])
    .andReturn(200)
    .withHeaders(@{@"Content-Type": @"application/json"})
    .withBody(responseData);
    
    XCTestExpectation *getReferralCodeExpectation = [self expectationWithDescription:@"Test validateReferralCode"];
    
    [branch validateReferralCode:@"testRC" andCallback:^(NSDictionary *params, NSError *error) {
        XCTAssertNil(error);
        
        NSString *code = params[@"referral_code"];
        XCTAssertNotNil(code);
        XCTAssertTrue([code isEqualToString:@"testRC"]);
        XCTAssertEqual([params[@"calculation_type"] integerValue], BranchUniqueRewards);
        XCTAssertEqual([params[@"location"] integerValue], BranchReferringUser);
        XCTAssertEqual([params[@"metadata"][@"amount"] integerValue], 7);
        
        [getReferralCodeExpectation fulfill];
    }];
    
    [self waitForExpectationsWithTimeout:1 handler:^(NSError *error) {
    }];
}

- (void)test07ApplyReferralCode {
    [self initSession];
    
    NSDictionary *responseDict = @{@"referral_code": @"testRC",
                                   @"calculation_type": @1,
                                   @"event": @"$redeem_code-testRC",
                                   @"location": @2,
                                   @"metadata": @{@"amount": @7,
                                                  @"bucket": @"default"
                                                  }
                                   };
    NSData *responseData = [BNCServerInterface encodePostParams:responseDict];
    
    stubRequest(@"POST", [BNCPreferenceHelper getAPIURL:[NSString stringWithFormat:@"%@/%@", @"applycode", @"testRC"]])
    .andReturn(200)
    .withHeaders(@{@"Content-Type": @"application/json"})
    .withBody(responseData);
    
    XCTestExpectation *getReferralCodeExpectation = [self expectationWithDescription:@"Test applyReferralCode"];
    
    [branch applyReferralCode:@"testRC" andCallback:^(NSDictionary *params, NSError *error) {
        XCTAssertNil(error);
        
        NSString *code = params[@"referral_code"];
        XCTAssertNotNil(code);
        XCTAssertTrue([code isEqualToString:@"testRC"]);
        XCTAssertEqual([params[@"calculation_type"] integerValue], BranchUniqueRewards);
        XCTAssertEqual([params[@"location"] integerValue], BranchReferringUser);
        XCTAssertEqual([params[@"metadata"][@"amount"] integerValue], 7);
        
        [getReferralCodeExpectation fulfill];
    }];
    
    [self waitForExpectationsWithTimeout:1 handler:^(NSError *error) {
    }];
}

- (void)test08GetCreditHistory {
    [self initSession];
    
    NSArray *responseArray = @[
                               @{@"referree": @"<null>",
                                 @"referrer": @"user_1",
                                 @"transaction": @{@"amount": @7,
                                                   @"bucket": @"default",
                                                   @"date": @"2015-02-23T19:14:40.880Z",
                                                   @"id": @"98485002198582256",
                                                   @"type": @0
                                                   }
                                 },
                               @{@"referree": @"<null>",
                                 @"referrer": @"user_2",
                                 @"transaction": @{@"amount": @8,
                                                   @"bucket": @"default",
                                                   @"date": @"2015-02-23T19:13:32.798Z",
                                                   @"id": @"98484716641976809",
                                                   @"type": @0
                                                   }
                                 }
                               ];
    NSError *err = nil;
    NSData *responseData = [NSJSONSerialization dataWithJSONObject:responseArray options:NSJSONWritingPrettyPrinted error:&err];
    
    stubRequest(@"POST", [BNCPreferenceHelper getAPIURL:@"credithistory"])
    .andReturn(200)
    .withHeaders(@{@"Content-Type": @"application/json"})
    .withBody(responseData);
    
    XCTestExpectation *getCreditHistoryExpectation = [self expectationWithDescription:@"Test getCreditHistory"];
    
    [branch getCreditHistoryWithCallback:^(NSArray *list, NSError *error) {
        XCTAssertNil(error);
        XCTAssertNotNil(list);
        XCTAssertEqual(list.count, 2);
        
        NSDictionary *xact = list[0];
        XCTAssertEqualObjects(xact[@"referrer"], @"user_1");
        XCTAssertEqualObjects(xact[@"transaction"][@"id"], @"98485002198582256");
        XCTAssertEqualObjects(xact[@"transaction"][@"amount"], @7);
        
        xact = list[1];
        XCTAssertEqualObjects(xact[@"referrer"], @"user_2");
        XCTAssertEqualObjects(xact[@"transaction"][@"id"], @"98484716641976809");
        XCTAssertEqualObjects(xact[@"transaction"][@"amount"], @8);
        
        [getCreditHistoryExpectation fulfill];
    }];
    
    [self waitForExpectationsWithTimeout:1 handler:^(NSError *error) {
    }];
}

- (void)test09SetIdentity {
    [self initSession];
    
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
    .withHeaders(@{@"Content-Type": @"application/json"})
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
    
    [self waitForExpectationsWithTimeout:1 handler:^(NSError *error) {
    }];
}

@end

