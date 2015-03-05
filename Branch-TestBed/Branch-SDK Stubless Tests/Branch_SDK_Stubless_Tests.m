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

static NSString *referralCode = nil;
static ReferralCodeCalculation referralCodeCalculationType = BranchUnlimitedRewards;
static ReferralCodeLocation referralCodeLocation = BranchReferreeUser;
static int referralCodeAmount = 0;
static NSInteger credits = 0;

@interface Branch_SDK_Stubless_Tests : XCTestCase {
    
@private
    __weak Branch *branch;
    NSString *app_id;
//    NSString *device_fingerprint_id;
//    NSString *browser_fingerprint_id;
//    NSString *identity_id;
//    NSString *session_id;
//    NSString *identity_link;
//    NSString *short_link;
    NSString *logout_identity_id;
//    NSString *new_identity_id;
//    NSString *new_session_id;
//    NSString *new_user_link;
}

@end

@implementation Branch_SDK_Stubless_Tests

- (void)setUp {
    [super setUp];
    
    app_id = @"5668720416392049";
//    device_fingerprint_id = @"94938498586381084";
//    browser_fingerprint_id = @"69198153995256641";
//    identity_id = @"95765863201768032";
//    session_id = @"97141055400444225";
//    identity_link = @"https://bnc.lt/i/3N-xr0E-_M";
//    short_link = @"https://bnc.lt/l/3PxZVFU-BK";
//    credits = 30;
    logout_identity_id = @"98274447349252681";
//    new_identity_id = @"85782216939930424";
//    new_session_id = @"98274447370224207";
//    new_user_link = @"https://bnc.lt/i/2kkbX6k-As";
    
    branch = [Branch getInstance:app_id];
    [self initSession];
}

- (void)tearDown {
    [super tearDown];
}

- (void)reset {
    [BNCPreferenceHelper setDeviceFingerprintID:NO_STRING_VALUE];
    [BNCPreferenceHelper setSessionID:NO_STRING_VALUE];
    [BNCPreferenceHelper setIdentityID:NO_STRING_VALUE];
}

- (void)initSession {
    XCTestExpectation *openExpectation = [self expectationWithDescription:@"Test open"];
    
    [branch initSessionAndRegisterDeepLinkHandler:^(NSDictionary *params, NSError *error) {
        XCTAssertNil(error);
        XCTAssertNotNil([BNCPreferenceHelper getSessionID]);
        XCTAssertNotEqualObjects([BNCPreferenceHelper getSessionID], NO_STRING_VALUE);
        
        [openExpectation fulfill];
    }];
    
    [self waitForExpectationsWithTimeout:1 handler:^(NSError *error) {
    }];
}

- (void)test00SetIdentity {
    // mock logout synchronously
    [BNCPreferenceHelper setIdentityID:logout_identity_id];
    [BNCPreferenceHelper setUserURL:@"https://bnc.lt/i/3R7_PIk-77"];
    [BNCPreferenceHelper setUserIdentity:NO_STRING_VALUE];
    [BNCPreferenceHelper setInstallParams:NO_STRING_VALUE];
    [BNCPreferenceHelper setSessionParams:NO_STRING_VALUE];
    [BNCPreferenceHelper clearUserCreditsAndCounts];
    
    XCTestExpectation *setIdentityExpectation = [self expectationWithDescription:@"Test setIdentity"];
    
    [branch setIdentity:@"test_user_10" withCallback:^(NSDictionary *params, NSError *error) {
        XCTAssertNil(error);
        XCTAssertNotNil(params);
        
        XCTAssertEqualObjects([BNCPreferenceHelper getIdentityID], @"98687515069776101");
        NSDictionary *installParams = [branch getFirstReferringParams];
        
        XCTAssertEqualObjects(installParams[@"$og_title"], @"Kindred");
        XCTAssertEqualObjects(installParams[@"key1"], @"test_object");
        
        [setIdentityExpectation fulfill];
    }];
    
    [self waitForExpectationsWithTimeout:1 handler:^(NSError *error) {
    }];
}

- (void)test01GetShortURLAsync {
    NSString __block *returnURL;

    XCTestExpectation *getShortURLExpectation = [self expectationWithDescription:@"Test getShortURL"];
    
    [branch getShortURLWithParams:nil andChannel:@"facebook" andFeature:nil andCallback:^(NSString *url, NSError *error) {
        XCTAssertNil(error);
        XCTAssertNotNil(url);

        returnURL = url;
        
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
        
        [getShortURLExpectation fulfill];
    }];
    
    [self waitForExpectationsWithTimeout:1 handler:^(NSError *error) {
    }];
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

// Assumption: there's only one "default" bucket for this identity
- (void)test03GetRewardsChanged {
    [BNCPreferenceHelper setCreditCount:9999999 forBucket:@"default"];
    
    XCTestExpectation *getRewardExpectation = [self expectationWithDescription:@"Test getReward"];
    
    [branch loadRewardsWithCallback:^(BOOL changed, NSError *error) {
        XCTAssertNil(error);
        XCTAssertTrue(changed);
        credits = [BNCPreferenceHelper getCreditCountForBucket:@"default"];
        
        [getRewardExpectation fulfill];
    }];
    
    [self waitForExpectationsWithTimeout:1 handler:^(NSError *error) {
    }];
}

// Assumption: there's only one "default" bucket for this identity
// This test depends on test03GetRewardsChanged
- (void)test04GetRewardsUnchanged {
    [BNCPreferenceHelper setCreditCount:credits forBucket:@"default"];
    
    XCTestExpectation *getRewardExpectation = [self expectationWithDescription:@"Test getReward"];
    
    [branch loadRewardsWithCallback:^(BOOL changed, NSError *error) {
        XCTAssertNil(error);
        XCTAssertFalse(changed);
        
        [getRewardExpectation fulfill];
    }];
    
    [self waitForExpectationsWithTimeout:1 handler:^(NSError *error) {
    }];
}

- (void)test05GetReferralCode {
    XCTestExpectation *getReferralCodeExpectation = [self expectationWithDescription:@"Test getReferralCode"];
    
    [branch getReferralCodeWithPrefix:@"test" amount:7 expiration:nil bucket:@"default" calculationType:BranchUniqueRewards location:BranchReferringUser andCallback:^(NSDictionary *params, NSError *error) {
        XCTAssertNil(error);
        
        referralCode = params[@"referral_code"];
        XCTAssertNotNil(referralCode);
        
        referralCodeCalculationType = (ReferralCodeCalculation)[params[@"calculation_type"] integerValue];
        referralCodeLocation = (ReferralCodeLocation)[params[@"location"] integerValue];
        referralCodeAmount = (int)[params[@"metadata"][@"amount"] integerValue];
        
        [getReferralCodeExpectation fulfill];
    }];
    
    [self waitForExpectationsWithTimeout:1 handler:^(NSError *error) {
    }];
}

// This test depends on test05GetReferralCode
- (void)test06ValidateReferralCode {
    XCTestExpectation *getReferralCodeExpectation = [self expectationWithDescription:@"Test validateReferralCode"];
    
    [branch validateReferralCode:referralCode andCallback:^(NSDictionary *params, NSError *error) {
        XCTAssertNil(error);
        
        NSString *code = params[@"referral_code"];
        XCTAssertNotNil(code);
        XCTAssertTrue([code isEqualToString:referralCode]);
        XCTAssertEqual([params[@"calculation_type"] integerValue], referralCodeCalculationType);
        XCTAssertEqual([params[@"location"] integerValue], referralCodeLocation);
        XCTAssertEqual([params[@"metadata"][@"amount"] integerValue], referralCodeAmount);
        
        [getReferralCodeExpectation fulfill];
    }];
    
    [self waitForExpectationsWithTimeout:1 handler:^(NSError *error) {
    }];
}

// This test depends on test05GetReferralCode
- (void)test07ApplyReferralCode {
    XCTestExpectation *getReferralCodeExpectation = [self expectationWithDescription:@"Test applyReferralCode"];
    
    [branch applyReferralCode:referralCode andCallback:^(NSDictionary *params, NSError *error) {
        XCTAssertNil(error);
        
        NSString *code = params[@"referral_code"];
        XCTAssertNotNil(code);
        XCTAssertTrue([code isEqualToString:referralCode]);
        XCTAssertEqual([params[@"calculation_type"] integerValue], referralCodeCalculationType);
        XCTAssertEqual([params[@"location"] integerValue], referralCodeLocation);
        XCTAssertEqual([params[@"metadata"][@"amount"] integerValue], referralCodeAmount);
        
        [getReferralCodeExpectation fulfill];
    }];
    
    [self waitForExpectationsWithTimeout:1 handler:^(NSError *error) {
    }];
}

- (void)test08GetCreditHistory {
    XCTestExpectation *getCreditHistoryExpectation = [self expectationWithDescription:@"Test getCreditHistory"];
    
    [branch getCreditHistoryWithCallback:^(NSArray *list, NSError *error) {
        XCTAssertNil(error);
        XCTAssertNotNil(list);
        XCTAssertGreaterThan(list.count, 0);
        
        [getCreditHistoryExpectation fulfill];
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

