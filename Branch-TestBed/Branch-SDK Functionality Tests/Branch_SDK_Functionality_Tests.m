//
//  Branch_SDK_test.m
//  Branch-SDK test
//
//  Created by Qinwei Gong on 2/19/15.
//  Copyright (c) 2015 Branch Metrics. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <XCTest/XCTest.h>
#import <OCMock/OCMock.h>
#import "Branch.h"
#import "BNCPreferenceHelper.h"
#import "BNCServerInterface.h"
#import "BNCConfig.h"
#import "BNCEncodingUtils.h"
#import "BNCServerRequestQueue.h"

NSString * const TEST_BRANCH_KEY = @"key_live_78801a996de4287481fe73708cc95da2";  //temp
NSString * const TEST_DEVICE_FINGERPRINT_ID = @"94938498586381084";
NSString * const TEST_BROWSER_FINGERPRINT_ID = @"69198153995256641";
NSString * const TEST_IDENTITY_ID = @"95765863201768032";
NSString * const TEST_SESSION_ID = @"97141055400444225";
NSString * const TEST_IDENTITY_LINK = @"https://bnc.lt/i/3N-xr0E-_M";
NSString * const TEST_SHORT_URL = @"https://bnc.lt/l/3PxZVFU-BK";
NSString * const TEST_LOGOUT_IDENTITY_ID = @"98274447349252681";
NSString * const TEST_NEW_IDENTITY_ID = @"85782216939930424";
NSString * const TEST_NEW_SESSION_ID = @"98274447370224207";
NSString * const TEST_NEW_USER_LINK = @"https://bnc.lt/i/2kkbX6k-As";
NSString * const TEST_REFERRAL_CODE = @"LMDLDV";
NSInteger const  TEST_CREDITS = 30;

@interface Branch_SDK_Functionality_Tests : XCTestCase

@property (assign, nonatomic) BOOL hasExceededExpectations;

@end

@implementation Branch_SDK_Functionality_Tests

- (void)test00OpenOrInstall {
    id serverInterfaceMock = OCMClassMock([BranchServerInterface class]);
    
    Branch *branch = [[Branch alloc] initWithInterface:serverInterfaceMock queue:[[BNCServerRequestQueue alloc] init] cache:[[BNCLinkCache alloc] init] key:[OCMArg any]];
    [branch setAppListCheckEnabled:NO];
    
    [BNCPreferenceHelper setCreditCount:NSIntegerMax forBucket:@"default"];
    
    BNCServerResponse *openInstallResponse = [[BNCServerResponse alloc] init];
    openInstallResponse.data = @{
        @"browser_fingerprint_id": TEST_BROWSER_FINGERPRINT_ID,
        @"device_fingerprint_id": TEST_DEVICE_FINGERPRINT_ID,
        @"identity_id": TEST_IDENTITY_ID,
        @"link": TEST_IDENTITY_LINK,
        @"session_id": TEST_SESSION_ID
    };
    
    __block BNCServerCallback openOrInstallCallback;
    id openOrInstallCallbackCheckBlock = [OCMArg checkWithBlock:^BOOL(BNCServerCallback callback) {
        openOrInstallCallback = callback;
        return YES;
    }];
    
    id openOrInstallInvocation = ^(NSInvocation *invocation) {
        openOrInstallCallback(openInstallResponse, nil);
    };

    id openOrInstallUrlCheckBlock = [OCMArg checkWithBlock:^BOOL(NSString *url) {
        return [url rangeOfString:@"open"].location != NSNotFound || [url rangeOfString:@"install"].location != NSNotFound;
    }];
    [[[serverInterfaceMock expect] andDo:openOrInstallInvocation] postRequest:[OCMArg any] url:openOrInstallUrlCheckBlock key:[OCMArg any] callback:openOrInstallCallbackCheckBlock];

    // Fake branch key
    id preferenceHelperMock = OCMClassMock([BNCPreferenceHelper class]);
    [[[preferenceHelperMock stub] andReturn:@"foo"] getBranchKey];
    
    XCTestExpectation *openExpectation = [self expectationWithDescription:@"Test open"];
    [branch initSessionAndRegisterDeepLinkHandler:^(NSDictionary *params, NSError *error) {
        XCTAssertNil(error);
        XCTAssertNotNil([BNCPreferenceHelper getSessionID]);
        XCTAssertEqualObjects([BNCPreferenceHelper getSessionID], TEST_SESSION_ID);
        
        [openExpectation fulfill];
    }];
    
    [self waitForExpectationsWithTimeout:1 handler:NULL];
}

- (void)test01SetIdentity {
    id serverInterfaceMock = OCMClassMock([BranchServerInterface class]);
    [self setupDefaultStubsForServerInterfaceMock:serverInterfaceMock];
    
    Branch *branch = [[Branch alloc] initWithInterface:serverInterfaceMock queue:[[BNCServerRequestQueue alloc] init] cache:[[BNCLinkCache alloc] init] key:[OCMArg any]];
    [branch setAppListCheckEnabled:NO];
    
    // mock logout synchronously
    [BNCPreferenceHelper setIdentityID:@"98274447349252681"];
    [BNCPreferenceHelper setUserURL:@"https://bnc.lt/i/3R7_PIk-77"];
    [BNCPreferenceHelper setUserIdentity:NO_STRING_VALUE];
    [BNCPreferenceHelper setInstallParams:NO_STRING_VALUE];
    [BNCPreferenceHelper setSessionParams:NO_STRING_VALUE];
    [BNCPreferenceHelper clearUserCreditsAndCounts];
    
    BNCServerResponse *setIdentityResponse = [[BNCServerResponse alloc] init];
    setIdentityResponse.data = @{
        @"identity_id": @"98687515069776101",
        @"link_click_id": @"87925296346431956",
        @"link": @"https://bnc.lt/i/3SawKbU-1Z",
        @"referring_data": @"{\"$og_title\":\"Kindred\",\"key1\":\"test_object\",\"key2\":\"here is another object!!\",\"$og_image_url\":\"https://s3-us-west-1.amazonaws.com/branchhost/mosaic_og.png\",\"source\":\"ios\"}"
    };
    
    // Stub setIdentity server call, call callback immediately.
    __block BNCServerCallback setIdentityCallback;
    [[[serverInterfaceMock expect] andDo:^(NSInvocation *invocation) {
        setIdentityCallback(setIdentityResponse, nil);
    }] postRequest:[OCMArg any] url:[BNCPreferenceHelper getAPIURL:@"profile"] key:[OCMArg any] callback:[OCMArg checkWithBlock:^BOOL(BNCServerCallback callback) {
        setIdentityCallback = callback;
        return YES;
    }]];
    
    XCTestExpectation *setIdentityExpectation = [self expectationWithDescription:@"Test setIdentity"];
    __weak Branch *nonRetainedBranch = branch;
    [branch setIdentity:@"test_user_10" withCallback:^(NSDictionary *params, NSError *error) {
        XCTAssertNil(error);
        XCTAssertNotNil(params);
        
        XCTAssertEqualObjects([BNCPreferenceHelper getIdentityID], @"98687515069776101");
        NSDictionary *installParams = [nonRetainedBranch getFirstReferringParams];
        
        XCTAssertEqualObjects(installParams[@"$og_title"], @"Kindred"); //TODO: equal to params?
        XCTAssertEqualObjects(installParams[@"key1"], @"test_object");
        
        [self safelyFulfillExpectation:setIdentityExpectation];
    }];
    
    [self awaitExpectations];
    
    [serverInterfaceMock verify];
}

- (void)test02GetShortURLAsync {
    id serverInterfaceMock = OCMClassMock([BranchServerInterface class]);
    [self setupDefaultStubsForServerInterfaceMock:serverInterfaceMock];
    
    Branch *branch = [[Branch alloc] initWithInterface:serverInterfaceMock queue:[[BNCServerRequestQueue alloc] init] cache:[[BNCLinkCache alloc] init] key:@"key_foo"];
    [branch setAppListCheckEnabled:NO];

    BNCServerResponse *fbLinkResponse = [[BNCServerResponse alloc] init];
    fbLinkResponse.data = @{ @"url": @"https://bnc.lt/l/4BGtJj-03N" };
    
    BNCServerResponse *twLinkResponse = [[BNCServerResponse alloc] init];
    twLinkResponse.data = @{ @"url": @"https://bnc.lt/l/-03N4BGtJj" };
    
    __block BNCServerCallback fbCallback;
    [[[serverInterfaceMock expect] andDo:^(NSInvocation *invocation) {
        fbCallback(fbLinkResponse, nil);
    }] postRequest:[OCMArg any] url:[BNCPreferenceHelper getAPIURL:@"url"] key:[OCMArg any] callback:[OCMArg checkWithBlock:^BOOL(BNCServerCallback callback) {
        fbCallback = callback;
        return YES;
    }]];
    
    [[serverInterfaceMock reject] postRequest:[OCMArg checkWithBlock:^BOOL(NSDictionary *params) {
        return [params[@"channel"] isEqualToString:@"facebook"];
    }] url:[BNCPreferenceHelper getAPIURL:@"url"] key:[OCMArg any] log:YES];
    
    [[[serverInterfaceMock expect] andReturn:twLinkResponse] postRequest:[OCMArg checkWithBlock:^BOOL(NSDictionary *params) {
        return [params[@"channel"] isEqualToString:@"twitter"];
    }] url:[BNCPreferenceHelper getAPIURL:@"url"] key:[OCMArg any] log:YES];
    
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
    
    [serverInterfaceMock verify];
}

- (void)test03GetShortURLSync {
    id serverInterfaceMock = OCMClassMock([BranchServerInterface class]);
    [self setupDefaultStubsForServerInterfaceMock:serverInterfaceMock];
    
    Branch *branch = [[Branch alloc] initWithInterface:serverInterfaceMock queue:[[BNCServerRequestQueue alloc] init] cache:[[BNCLinkCache alloc] init] key:@"key_foo"];
    [branch setAppListCheckEnabled:NO];

    XCTestExpectation *getShortURLExpectation = [self expectationWithDescription:@"Test getShortURL Sync"];
    [branch initSessionAndRegisterDeepLinkHandler:^(NSDictionary *params, NSError *error) {
        BNCServerResponse *fbLinkResponse = [[BNCServerResponse alloc] init];
        fbLinkResponse.data = @{ @"url": @"https://bnc.lt/l/4BGtJj-03N" };
        
        BNCServerResponse *twLinkResponse = [[BNCServerResponse alloc] init];
        twLinkResponse.data = @{ @"url": @"https://bnc.lt/l/-03N4BGtJj" };
        
        // FB should only be called once
        [[[serverInterfaceMock expect] andReturn:fbLinkResponse] postRequest:[OCMArg checkWithBlock:^BOOL(NSDictionary *params) {
            return [params[@"channel"] isEqualToString:@"facebook"];
        }] url:[BNCPreferenceHelper getAPIURL:@"url"] key:[OCMArg any] log:YES];
        
        [[serverInterfaceMock reject] postRequest:[OCMArg checkWithBlock:^BOOL(NSDictionary *params) {
            return [params[@"channel"] isEqualToString:@"facebook"];
        }] url:[BNCPreferenceHelper getAPIURL:@"url"] key:[OCMArg any] log:YES];
        
        // TW should be allowed still
        [[[serverInterfaceMock expect] andReturn:twLinkResponse] postRequest:[OCMArg checkWithBlock:^BOOL(NSDictionary *params) {
            return [params[@"channel"] isEqualToString:@"twitter"];
        }] url:[BNCPreferenceHelper getAPIURL:@"url"] key:[OCMArg any] log:YES];
        
        NSString *url1 = [branch getShortURLWithParams:nil andChannel:@"facebook" andFeature:nil];
        XCTAssertNotNil(url1);
        
        NSString *url2 = [branch getShortURLWithParams:nil andChannel:@"facebook" andFeature:nil];
        XCTAssertEqualObjects(url1, url2);
        
        NSString *url3 = [branch getShortURLWithParams:nil andChannel:@"twitter" andFeature:nil];
        XCTAssertNotNil(url3);
        XCTAssertNotEqualObjects(url1, url3);
        
        [self safelyFulfillExpectation:getShortURLExpectation];
    }];
    
    [self awaitExpectations];
    
    [serverInterfaceMock verify];
}

- (void)test04GetRewardsChanged {
    id serverInterfaceMock = OCMClassMock([BranchServerInterface class]);
    [self setupDefaultStubsForServerInterfaceMock:serverInterfaceMock];
    
    Branch *branch = [[Branch alloc] initWithInterface:serverInterfaceMock queue:[[BNCServerRequestQueue alloc] init] cache:[[BNCLinkCache alloc] init] key:@"key_foo"];
    [branch setAppListCheckEnabled:NO];

    [BNCPreferenceHelper setCreditCount:NSIntegerMax forBucket:@"default"];
    
    BNCServerResponse *loadCreditsResponse = [[BNCServerResponse alloc] init];
    loadCreditsResponse.data = @{ @"default": @(NSIntegerMin) };
    
    __block BNCServerCallback loadCreditsCallback;
    [[[serverInterfaceMock expect] andDo:^(NSInvocation *invocation) {
        loadCreditsCallback(loadCreditsResponse, nil);
    }] getRequest:[OCMArg any] url:[BNCPreferenceHelper getAPIURL:[NSString stringWithFormat:@"%@/%@", @"credits", [BNCPreferenceHelper getIdentityID]]] key:[OCMArg any] callback:[OCMArg checkWithBlock:^BOOL(BNCServerCallback callback) {
        loadCreditsCallback = callback;
        return YES;
    }]];
    
    XCTestExpectation *getRewardExpectation = [self expectationWithDescription:@"Test getReward"];
    
    [branch loadRewardsWithCallback:^(BOOL changed, NSError *error) {
        XCTAssertNil(error);
        XCTAssertTrue(changed);
        
        [self safelyFulfillExpectation:getRewardExpectation];
    }];
    
    [self awaitExpectations];
}

- (void)test05GetRewardsUnchanged {
    id serverInterfaceMock = OCMClassMock([BranchServerInterface class]);
    [self setupDefaultStubsForServerInterfaceMock:serverInterfaceMock];
    
    Branch *branch = [[Branch alloc] initWithInterface:serverInterfaceMock queue:[[BNCServerRequestQueue alloc] init] cache:[[BNCLinkCache alloc] init] key:@"key_foo"];
    [branch setAppListCheckEnabled:NO];

    [BNCPreferenceHelper setCreditCount:1 forBucket:@"default"];
    
    BNCServerResponse *loadRewardsResponse = [[BNCServerResponse alloc] init];
    loadRewardsResponse.data = @{ @"default": @1 };
    
    __block BNCServerCallback loadRewardsCallback;
    [[[serverInterfaceMock expect] andDo:^(NSInvocation *invocation) {
        loadRewardsCallback(loadRewardsResponse, nil);
    }] getRequest:[OCMArg any] url:[BNCPreferenceHelper getAPIURL:[NSString stringWithFormat:@"%@/%@", @"credits", [BNCPreferenceHelper getIdentityID]]] key:[OCMArg any] callback:[OCMArg checkWithBlock:^BOOL(BNCServerCallback callback) {
        loadRewardsCallback = callback;
        return YES;
    }]];
    
    XCTestExpectation *getRewardExpectation = [self expectationWithDescription:@"Test getReward"];
    
    [branch loadRewardsWithCallback:^(BOOL changed, NSError *error) {
        XCTAssertNil(error);
        XCTAssertFalse(changed);
        
        [self safelyFulfillExpectation:getRewardExpectation];
    }];
    
    [self awaitExpectations];
}

- (void)test06GetReferralCode {
    id serverInterfaceMock = OCMClassMock([BranchServerInterface class]);
    [self setupDefaultStubsForServerInterfaceMock:serverInterfaceMock];
    
    Branch *branch = [[Branch alloc] initWithInterface:serverInterfaceMock queue:[[BNCServerRequestQueue alloc] init] cache:[[BNCLinkCache alloc] init] key:@"key_foo"];
    [branch setAppListCheckEnabled:NO];

    [BNCPreferenceHelper setCreditCount:1 forBucket:@"default"];
    
    BNCServerResponse *referralCodeResponse = [[BNCServerResponse alloc] init];
    referralCodeResponse.data = @{
        @"id": @"85782843459895738",
        @"branch_key": @"key_live_jbgnjxvlhSb6PGH23BhO4hiflcp3y8kx",
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
        @"referral_code": TEST_REFERRAL_CODE
    };
    
    __block BNCServerCallback referralCodeCallback;
    [[[serverInterfaceMock expect] andDo:^(NSInvocation *invocation) {
        referralCodeCallback(referralCodeResponse, nil);
    }] postRequest:[OCMArg any] url:[BNCPreferenceHelper getAPIURL:@"referralcode"] key:[OCMArg any] callback:[OCMArg checkWithBlock:^BOOL(BNCServerCallback callback) {
        referralCodeCallback = callback;
        return YES;
    }]];
    
    XCTestExpectation *getReferralCodeExpectation = [self expectationWithDescription:@"Test getReferralCode"];
    [branch getReferralCodeWithPrefix:@"test" amount:7 expiration:nil bucket:@"default" calculationType:BranchUniqueRewards location:BranchReferringUser andCallback:^(NSDictionary *params, NSError *error) {
        XCTAssertNil(error);
        XCTAssertNotNil(params[@"referral_code"]);
        
        [self safelyFulfillExpectation:getReferralCodeExpectation];
    }];
    
    [self awaitExpectations];
}

- (void)test07ValidateReferralCode {
    id serverInterfaceMock = OCMClassMock([BranchServerInterface class]);
    [self setupDefaultStubsForServerInterfaceMock:serverInterfaceMock];
    
    Branch *branch = [[Branch alloc] initWithInterface:serverInterfaceMock queue:[[BNCServerRequestQueue alloc] init] cache:[[BNCLinkCache alloc] init] key:@"key_foo"];
    [branch setAppListCheckEnabled:NO];

    [BNCPreferenceHelper setCreditCount:1 forBucket:@"default"];
    
    BNCServerResponse *validateCodeResponse = [[BNCServerResponse alloc] init];
    validateCodeResponse.data = @{
        @"id": @"85782843459895738",
        @"branch_key": @"key_live_jbgnjxvlhSb6PGH23BhO4hiflcp3y8kx",
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
        @"referral_code": TEST_REFERRAL_CODE
    };

    __block BNCServerCallback validateCodeCallback;
    [[[serverInterfaceMock expect] andDo:^(NSInvocation *invocation) {
        validateCodeCallback(validateCodeResponse, nil);
    }] postRequest:[OCMArg any] url:[BNCPreferenceHelper getAPIURL:@"referralcode/LMDLDV"] key:[OCMArg any] callback:[OCMArg checkWithBlock:^BOOL(BNCServerCallback callback) {
        validateCodeCallback = callback;
        return YES;
    }]];
    
    XCTestExpectation *validateCodeExpectation = [self expectationWithDescription:@"Test validateReferralCode"];
    [branch validateReferralCode:TEST_REFERRAL_CODE andCallback:^(NSDictionary *params, NSError *error) {
        XCTAssertNil(error);
        
        NSString *code = params[@"referral_code"];
        XCTAssertNotNil(code);
        XCTAssertTrue([code isEqualToString:TEST_REFERRAL_CODE]);
        XCTAssertEqual([params[@"calculation_type"] integerValue], BranchUnlimitedRewards);
        XCTAssertEqual([params[@"location"] integerValue], BranchReferreeUser);
        XCTAssertEqual([params[@"metadata"][@"amount"] integerValue], 5);
        
        [self safelyFulfillExpectation:validateCodeExpectation];
    }];
    
    [self awaitExpectations];
}

- (void)test08ApplyReferralCode {
    id serverInterfaceMock = OCMClassMock([BranchServerInterface class]);
    [self setupDefaultStubsForServerInterfaceMock:serverInterfaceMock];
    
    Branch *branch = [[Branch alloc] initWithInterface:serverInterfaceMock queue:[[BNCServerRequestQueue alloc] init] cache:[[BNCLinkCache alloc] init] key:@"key_foo"];
    [branch setAppListCheckEnabled:NO];

    [BNCPreferenceHelper setCreditCount:1 forBucket:@"default"];
    
    BNCServerResponse *applyCodeResponse = [[BNCServerResponse alloc] init];
    applyCodeResponse.data = @{
        @"id": @"85782843459895738",
        @"branch_key": @"key_live_jbgnjxvlhSb6PGH23BhO4hiflcp3y8kx",
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
        @"referral_code": TEST_REFERRAL_CODE
    };

    __block BNCServerCallback applyCodeCallback;
    [[[serverInterfaceMock expect] andDo:^(NSInvocation *invocation) {
        applyCodeCallback(applyCodeResponse, nil);
    }] postRequest:[OCMArg any] url:[BNCPreferenceHelper getAPIURL:@"applycode/LMDLDV"] key:[OCMArg any] callback:[OCMArg checkWithBlock:^BOOL(BNCServerCallback callback) {
        applyCodeCallback = callback;
        return YES;
    }]];
    
    XCTestExpectation *applyCodeExpectation = [self expectationWithDescription:@"Test applyReferralCode"];
    [branch applyReferralCode:TEST_REFERRAL_CODE andCallback:^(NSDictionary *params, NSError *error) {
        XCTAssertNil(error);
        
        NSString *code = params[@"referral_code"];
        XCTAssertNotNil(code);
        XCTAssertTrue([code isEqualToString:TEST_REFERRAL_CODE]);
        XCTAssertEqual([params[@"calculation_type"] integerValue], BranchUnlimitedRewards);
        XCTAssertEqual([params[@"location"] integerValue], BranchReferreeUser);
        XCTAssertEqual([params[@"metadata"][@"amount"] integerValue], 5);
        
        [self safelyFulfillExpectation:applyCodeExpectation];
    }];
    
    [self awaitExpectations];
}

- (void)test09GetCreditHistory {
    id serverInterfaceMock = OCMClassMock([BranchServerInterface class]);
    [self setupDefaultStubsForServerInterfaceMock:serverInterfaceMock];
    
    Branch *branch = [[Branch alloc] initWithInterface:serverInterfaceMock queue:[[BNCServerRequestQueue alloc] init] cache:[[BNCLinkCache alloc] init] key:@"key_foo"];
    [branch setAppListCheckEnabled:NO];

    [BNCPreferenceHelper setCreditCount:1 forBucket:@"default"];
    
    BNCServerResponse *creditHistoryResponse = [[BNCServerResponse alloc] init];
    creditHistoryResponse.data = @[
        [@{
            @"transaction": @{
                @"id": @"112281771218838351",
                @"bucket": @"default",
                @"type": @0,
                @"amount": @5,
                @"date": @"2015-04-02T20:58:06.946Z"
            },
            @"referrer": @"test_user_10",
            @"referree": [NSNull null]
        } mutableCopy]
    ];
    
    __block BNCServerCallback creditHistoryCallback;
    [[[serverInterfaceMock expect] andDo:^(NSInvocation *invocation) {
        creditHistoryCallback(creditHistoryResponse, nil);
    }] postRequest:[OCMArg any] url:[BNCPreferenceHelper getAPIURL:@"credithistory"] key:[OCMArg any] callback:[OCMArg checkWithBlock:^BOOL(BNCServerCallback callback) {
        creditHistoryCallback = callback;
        return YES;
    }]];
    
    XCTestExpectation *getCreditHistoryExpectation = [self expectationWithDescription:@"Test getCreditHistory"];
    [branch getCreditHistoryWithCallback:^(NSArray *list, NSError *error) {
        XCTAssertNil(error);
        XCTAssertNotNil(list);
        XCTAssertGreaterThan(list.count, 0);
        
        [self safelyFulfillExpectation:getCreditHistoryExpectation];
    }];
    
    [self awaitExpectations];
}

#pragma mark - Test Utility

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

- (void)setupDefaultStubsForServerInterfaceMock:(id)serverInterfaceMock {
    BNCServerResponse *openInstallResponse = [[BNCServerResponse alloc] init];
    openInstallResponse.data = @{
        @"session_id": TEST_SESSION_ID,
        @"identity_id": TEST_IDENTITY_ID,
        @"device_fingerprint_id": TEST_DEVICE_FINGERPRINT_ID,
        @"browser_fingerprint_id": TEST_BROWSER_FINGERPRINT_ID,
        @"link": TEST_IDENTITY_LINK,
        @"new_identity_id": TEST_NEW_IDENTITY_ID
    };
    
    // Stub open / install
    __block BNCServerCallback openOrInstallCallback;
    id openOrInstallCallbackCheckBlock = [OCMArg checkWithBlock:^BOOL(BNCServerCallback callback) {
        openOrInstallCallback = callback;
        return YES;
    }];
    
    id openOrInstallInvocation = ^(NSInvocation *invocation) {
        openOrInstallCallback(openInstallResponse, nil);
    };
    
    id openOrInstallUrlCheckBlock = [OCMArg checkWithBlock:^BOOL(NSString *url) {
        return [url rangeOfString:@"open"].location != NSNotFound || [url rangeOfString:@"install"].location != NSNotFound;
    }];
    [[[serverInterfaceMock expect] andDo:openOrInstallInvocation] postRequest:[OCMArg any] url:openOrInstallUrlCheckBlock key:[OCMArg any] callback:openOrInstallCallbackCheckBlock];
    
    // Fake branch key
    id preferenceHelperMock = OCMClassMock([BNCPreferenceHelper class]);
    [[[preferenceHelperMock stub] andReturn:@"foo"] getBranchKey];
}

@end

