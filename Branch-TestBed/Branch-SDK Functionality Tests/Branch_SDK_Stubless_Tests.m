//
//  Branch_SDK_Stubless_Tests.m
//  Branch-SDK Stubless Tests
//
//  Created by Qinwei Gong on 3/4/15.
//  Copyright (c) 2015 Branch Metrics. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <XCTest/XCTest.h>
#import <OCMock/OCMock.h>
#import "Branch.h"
#import "BNCPreferenceHelper.h"
#import "BNCServerInterface.h"
#import "BNCConfig.h"
#import "BNCServerRequestQueue.h"

NSString * const TEST_REFERRAL_CODE = @"LMDLDV";

@interface Branch_SDK_Stubless_Tests : XCTestCase

@property (assign, nonatomic) BOOL hasExceededExpectations;

@end

@implementation Branch_SDK_Stubless_Tests

#pragma mark - Tests

- (void)test00SetIdentity {
    id serverInterfaceMock = OCMClassMock([BranchServerInterface class]);
    [self setupDefaultStubsForServerInterfaceMock:serverInterfaceMock];

    Branch *branch = [[Branch alloc] initWithInterface:serverInterfaceMock queue:[[BNCServerRequestQueue alloc] init] cache:[[BNCLinkCache alloc] init]];

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
    }] identifyUser:[OCMArg any] callback:[OCMArg checkWithBlock:^BOOL(BNCServerCallback callback) {
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

- (void)test01GetShortURLAsync {
    id serverInterfaceMock = OCMClassMock([BranchServerInterface class]);
    [self setupDefaultStubsForServerInterfaceMock:serverInterfaceMock];
    
    Branch *branch = [[Branch alloc] initWithInterface:serverInterfaceMock queue:[[BNCServerRequestQueue alloc] init] cache:[[BNCLinkCache alloc] init]];

    BNCServerResponse *fbLinkResponse = [[BNCServerResponse alloc] init];
    fbLinkResponse.data = @{ @"url": @"https://bnc.lt/l/4BGtJj-03N" };

    BNCServerResponse *twLinkResponse = [[BNCServerResponse alloc] init];
    twLinkResponse.data = @{ @"url": @"https://bnc.lt/l/-03N4BGtJj" };
    
    __block BNCServerCallback fbCallback;
    [[[serverInterfaceMock expect] andDo:^(NSInvocation *invocation) {
        fbCallback(fbLinkResponse, nil);
    }] createCustomUrl:[OCMArg any] callback:[OCMArg checkWithBlock:^BOOL(BNCServerCallback callback) {
        fbCallback = callback;
        return YES;
    }]];
    
    [[serverInterfaceMock reject] createCustomUrl:[OCMArg checkWithBlock:^BOOL(BNCServerRequest *request) {
        return [request.postData[@"channel"] isEqualToString:@"facebook"];
    }]];
    
    [[[serverInterfaceMock expect] andReturn:twLinkResponse] createCustomUrl:[OCMArg checkWithBlock:^BOOL(BNCServerRequest *request) {
        return [request.postData[@"channel"] isEqualToString:@"twitter"];
    }]];

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

- (void)test02GetShortURLSync {
    id serverInterfaceMock = OCMClassMock([BranchServerInterface class]);
    [self setupDefaultStubsForServerInterfaceMock:serverInterfaceMock];
    
    Branch *branch = [[Branch alloc] initWithInterface:serverInterfaceMock queue:[[BNCServerRequestQueue alloc] init] cache:[[BNCLinkCache alloc] init]];
    
    XCTestExpectation *getShortURLExpectation = [self expectationWithDescription:@"Test getShortURL Sync"];
    [branch initSessionAndRegisterDeepLinkHandler:^(NSDictionary *params, NSError *error) {
        BNCServerResponse *fbLinkResponse = [[BNCServerResponse alloc] init];
        fbLinkResponse.data = @{ @"url": @"https://bnc.lt/l/4BGtJj-03N" };
        
        BNCServerResponse *twLinkResponse = [[BNCServerResponse alloc] init];
        twLinkResponse.data = @{ @"url": @"https://bnc.lt/l/-03N4BGtJj" };
        
        // FB should only be called once
        [[[serverInterfaceMock expect] andReturn:fbLinkResponse] createCustomUrl:[OCMArg checkWithBlock:^BOOL(BNCServerRequest *request) {
            return [request.postData[@"channel"] isEqualToString:@"facebook"];
        }]];
        
        [[serverInterfaceMock reject] createCustomUrl:[OCMArg checkWithBlock:^BOOL(BNCServerRequest *request) {
            return [request.postData[@"channel"] isEqualToString:@"facebook"];
        }]];
        
        // TW should be allowed still
        [[[serverInterfaceMock expect] andReturn:twLinkResponse] createCustomUrl:[OCMArg checkWithBlock:^BOOL(BNCServerRequest *request) {
            return [request.postData[@"channel"] isEqualToString:@"twitter"];
        }]];
        
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

- (void)test03GetRewardsChanged {
    id serverInterfaceMock = OCMClassMock([BranchServerInterface class]);
    [self setupDefaultStubsForServerInterfaceMock:serverInterfaceMock];
    
    Branch *branch = [[Branch alloc] initWithInterface:serverInterfaceMock queue:[[BNCServerRequestQueue alloc] init] cache:[[BNCLinkCache alloc] init]];

    [BNCPreferenceHelper setCreditCount:NSIntegerMax forBucket:@"default"];

    BNCServerResponse *loadCreditsResponse = [[BNCServerResponse alloc] init];
    loadCreditsResponse.data = @{
        @"default": @(NSIntegerMin)
    };
    
    __block BNCServerCallback loadCreditsCallback;
    [[[serverInterfaceMock expect] andDo:^(NSInvocation *invocation) {
        loadCreditsCallback(loadCreditsResponse, nil);
    }] getRewardsWithCallback:[OCMArg checkWithBlock:^BOOL(BNCServerCallback callback) {
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

- (void)test04GetRewardsUnchanged {
    id serverInterfaceMock = OCMClassMock([BranchServerInterface class]);
    [self setupDefaultStubsForServerInterfaceMock:serverInterfaceMock];
    
    Branch *branch = [[Branch alloc] initWithInterface:serverInterfaceMock queue:[[BNCServerRequestQueue alloc] init] cache:[[BNCLinkCache alloc] init]];

    [BNCPreferenceHelper setCreditCount:1 forBucket:@"default"];

    BNCServerResponse *loadRewardsResponse = [[BNCServerResponse alloc] init];
    loadRewardsResponse.data = @{
        @"default": @(1)
    };

    __block BNCServerCallback loadRewardsCallback;
    [[[serverInterfaceMock expect] andDo:^(NSInvocation *invocation) {
        loadRewardsCallback(loadRewardsResponse, nil);
    }] getRewardsWithCallback:[OCMArg checkWithBlock:^BOOL(BNCServerCallback callback) {
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

- (void)test05GetReferralCode {
    id serverInterfaceMock = OCMClassMock([BranchServerInterface class]);
    [self setupDefaultStubsForServerInterfaceMock:serverInterfaceMock];
    
    Branch *branch = [[Branch alloc] initWithInterface:serverInterfaceMock queue:[[BNCServerRequestQueue alloc] init] cache:[[BNCLinkCache alloc] init]];
    
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
    }] getReferralCode:[OCMArg any] callback:[OCMArg checkWithBlock:^BOOL(BNCServerCallback callback) {
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

- (void)test06ValidateReferralCode {
    id serverInterfaceMock = OCMClassMock([BranchServerInterface class]);
    [self setupDefaultStubsForServerInterfaceMock:serverInterfaceMock];
    
    Branch *branch = [[Branch alloc] initWithInterface:serverInterfaceMock queue:[[BNCServerRequestQueue alloc] init] cache:[[BNCLinkCache alloc] init]];
    
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
    }] validateReferralCode:[OCMArg any] callback:[OCMArg checkWithBlock:^BOOL(BNCServerCallback callback) {
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

- (void)test07ApplyReferralCode {
    id serverInterfaceMock = OCMClassMock([BranchServerInterface class]);
    [self setupDefaultStubsForServerInterfaceMock:serverInterfaceMock];
    
    Branch *branch = [[Branch alloc] initWithInterface:serverInterfaceMock queue:[[BNCServerRequestQueue alloc] init] cache:[[BNCLinkCache alloc] init]];
    
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
    }] applyReferralCode:[OCMArg any] callback:[OCMArg checkWithBlock:^BOOL(BNCServerCallback callback) {
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

- (void)test08GetCreditHistory {
    id serverInterfaceMock = OCMClassMock([BranchServerInterface class]);
    [self setupDefaultStubsForServerInterfaceMock:serverInterfaceMock];
    
    Branch *branch = [[Branch alloc] initWithInterface:serverInterfaceMock queue:[[BNCServerRequestQueue alloc] init] cache:[[BNCLinkCache alloc] init]];
    
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
    }] getCreditHistory:[OCMArg any] callback:[OCMArg checkWithBlock:^BOOL(BNCServerCallback callback) {
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

- (void)setupDefaultStubsForServerInterfaceMock:(id)serverInterfaceMock {
    BNCServerResponse *openInstallResponse = [[BNCServerResponse alloc] init];
    openInstallResponse.data = @{
        @"session_id": @"112263020234678596",
        @"identity_id": @"98687515069776101",
        @"device_fingerprint_id": @"94938498586381084",
        @"browser_fingerprint_id": [NSNull null],
        @"link": @"https://bnc.lt/i/3SawKbU-1Z",
        @"new_identity_id": @"98687515069776101",
        @"identity": @"test_user_10"
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
    
    // Stub app list calls
    __block BNCServerCallback appListCallback;
    id appListCallbackCheckBlock = [OCMArg checkWithBlock:^BOOL(BNCServerCallback callback) {
        callback([[BNCServerResponse alloc] init], nil);
        return YES;
    }];
    
    id appListInvocation = ^(NSInvocation *invocation) {
        appListCallback(openInstallResponse, nil);
    };
    
    [[[serverInterfaceMock stub] andDo:openOrInstallInvocation] registerInstall:NO callback:openOrInstallCallbackCheckBlock];
    [[[serverInterfaceMock stub] andDo:openOrInstallInvocation] registerOpen:NO callback:openOrInstallCallbackCheckBlock];
    [[[serverInterfaceMock stub] andDo:appListInvocation] uploadListOfApps:[OCMArg any] callback:appListCallbackCheckBlock];
    [[[serverInterfaceMock stub] andDo:appListInvocation] retrieveAppsToCheckWithCallback:appListCallbackCheckBlock];
    
    // Fake branch key
    id preferenceHelperMock = OCMClassMock([BNCPreferenceHelper class]);
    [[[preferenceHelperMock stub] andReturn:@"foo"] getBranchKey];
}

@end

