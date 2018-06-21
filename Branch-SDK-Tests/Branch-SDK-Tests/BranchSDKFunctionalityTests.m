//
//  Branch_SDK_test.m
//  Branch-SDK test
//
//  Created by Qinwei Gong on 2/19/15.
//  Copyright (c) 2015 Branch Metrics. All rights reserved.
//

#import "BNCTestCase.h"
#import "Branch.h"

NSString * const TEST_BRANCH_KEY = @"key_live_78801a996de4287481fe73708cc95da2";
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
NSInteger const  TEST_CREDITS = 30;

@interface BranchSDKFunctionalityTests : BNCTestCase
@property (assign, nonatomic) BOOL hasExceededExpectations;
@end

@implementation BranchSDKFunctionalityTests

- (void)test00OpenOrInstall {
    id serverInterfaceMock = OCMClassMock([BNCServerInterface class]);

    BNCPreferenceHelper *preferenceHelper = [BNCPreferenceHelper preferenceHelper];
    Branch.branchKey = @"key_live_foo";
    
    Branch *branch =
        [[Branch alloc]
            initWithInterface:serverInterfaceMock
            queue:[[BNCServerRequestQueue alloc] init]
            cache:[[BNCLinkCache alloc] init]
            preferenceHelper:preferenceHelper
            key:@"key_live_foo"];
    
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
    [[[serverInterfaceMock expect]
        andDo:openOrInstallInvocation]
        postRequest:[OCMArg any]
        url:openOrInstallUrlCheckBlock
        key:[OCMArg any]
        callback:openOrInstallCallbackCheckBlock];
    
    XCTestExpectation *openExpectation = [self expectationWithDescription:@"Test open"];
    [branch initSessionWithLaunchOptions:@{} andRegisterDeepLinkHandler:^(NSDictionary *params, NSError *error) {
        XCTAssertNil(error);
        XCTAssertEqualObjects(preferenceHelper.sessionID, TEST_SESSION_ID);
        [openExpectation fulfill];
    }];
    
    [self waitForExpectationsWithTimeout:2 handler:NULL];
}

- (void)test01SetIdentity {
    id serverInterfaceMock = OCMClassMock([BNCServerInterface class]);
    [self setupDefaultStubsForServerInterfaceMock:serverInterfaceMock];
    
    BNCPreferenceHelper *preferenceHelper = [BNCPreferenceHelper preferenceHelper];
    Branch *branch =
        [[Branch alloc]
            initWithInterface:serverInterfaceMock
            queue:[[BNCServerRequestQueue alloc] init]
            cache:[[BNCLinkCache alloc] init]
            preferenceHelper:preferenceHelper
            key:@"foo"];
    
    // mock logout synchronously
    preferenceHelper.identityID = @"98274447349252681";
    preferenceHelper.userUrl = @"https://bnc.lt/i/3R7_PIk-77";
    preferenceHelper.userIdentity = nil;
    preferenceHelper.installParams = nil;
    preferenceHelper.sessionParams = nil;
    [preferenceHelper clearUserCreditsAndCounts];
    
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
    }] postRequest:[OCMArg any] url:[preferenceHelper getAPIURL:@"profile"] key:[OCMArg any] callback:[OCMArg checkWithBlock:^BOOL(BNCServerCallback callback) {
        setIdentityCallback = callback;
        return YES;
    }]];
    
    XCTestExpectation *setIdentityExpectation = [self expectationWithDescription:@"Test setIdentity"];
    __weak Branch *nonRetainedBranch = branch;
    [branch setIdentity:@"test_user_10" withCallback:^(NSDictionary *params, NSError *error) {
        XCTAssertNil(error);
        XCTAssertNotNil(params);
        
        XCTAssertEqualObjects(preferenceHelper.identityID, @"98687515069776101");
        NSDictionary *installParams = [nonRetainedBranch getFirstReferringParams];
        
        XCTAssertEqualObjects(installParams[@"$og_title"], @"Kindred");
        XCTAssertEqualObjects(installParams[@"key1"], @"test_object");
        
        [self safelyFulfillExpectation:setIdentityExpectation];
    }];
    
    [self awaitExpectations];
    [serverInterfaceMock verify];
}

- (void)test02GetShortURLAsync {
    id serverInterfaceMock = OCMClassMock([BNCServerInterface class]);
    [self setupDefaultStubsForServerInterfaceMock:serverInterfaceMock];
    
    BNCPreferenceHelper *preferenceHelper = [BNCPreferenceHelper preferenceHelper];
    Branch *branch =
        [[Branch alloc]
            initWithInterface:serverInterfaceMock
            queue:[[BNCServerRequestQueue alloc] init]
            cache:[[BNCLinkCache alloc] init]
            preferenceHelper:preferenceHelper
            key:@"key_live_foo"];

    BNCServerResponse *fbLinkResponse = [[BNCServerResponse alloc] init];
    fbLinkResponse.statusCode = @200;
    fbLinkResponse.data = @{ @"url": @"https://bnc.lt/l/4BGtJj-03N" };
    
    BNCServerResponse *twLinkResponse = [[BNCServerResponse alloc] init];
    twLinkResponse.statusCode = @200;
    twLinkResponse.data = @{ @"url": @"https://bnc.lt/l/-03N4BGtJj" };
    
    __block BNCServerCallback fbCallback;
    [[[serverInterfaceMock expect]
        andDo:^(NSInvocation *invocation) {
            fbCallback(fbLinkResponse, nil);
        }]
        postRequest:[OCMArg any]
        url:[preferenceHelper getAPIURL:@"url"]
        key:[OCMArg any]
        callback:[OCMArg checkWithBlock:^BOOL(BNCServerCallback callback) {
            fbCallback = callback;
            return YES;
        }]];
    
    [[serverInterfaceMock reject] postRequestSynchronous:[OCMArg checkWithBlock:^BOOL(NSDictionary *params) {
        return [params[@"channel"] isEqualToString:@"facebook"];
    }] url:[preferenceHelper getAPIURL:@"url"] key:[OCMArg any]];
    
    [[[serverInterfaceMock expect] andReturn:twLinkResponse] postRequestSynchronous:[OCMArg checkWithBlock:^BOOL(NSDictionary *params) {
        return [params[@"channel"] isEqualToString:@"twitter"];
    }] url:[preferenceHelper getAPIURL:@"url"] key:[OCMArg any]];
    
    XCTestExpectation *getShortURLExpectation = [self expectationWithDescription:@"Test getShortURL"];
    
    [branch getShortURLWithParams:nil
        andChannel:@"facebook"
        andFeature:nil
        andCallback:^(NSString *url, NSError *error) {
            XCTAssertNil(error);
            XCTAssertNotNil(url);
        
            NSString *returnURL = url;
        
            [branch getShortURLWithParams:nil
                andChannel:@"facebook"
                andFeature:nil
                andCallback:^(NSString *url, NSError *error) {
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
    id serverInterfaceMock = OCMClassMock([BNCServerInterface class]);
    [self setupDefaultStubsForServerInterfaceMock:serverInterfaceMock];
    
    BNCPreferenceHelper *preferenceHelper = [BNCPreferenceHelper preferenceHelper];
    Branch *branch =
        [[Branch alloc]
            initWithInterface:serverInterfaceMock
            queue:[[BNCServerRequestQueue alloc] init]
            cache:[[BNCLinkCache alloc] init]
            preferenceHelper:preferenceHelper
            key:@"key_live_foo"];

    XCTestExpectation *getShortURLExpectation = [self expectationWithDescription:@"Test getShortURL Sync"];
    [branch initSessionWithLaunchOptions:@{} andRegisterDeepLinkHandler:^(NSDictionary *params, NSError *error) {
        BNCServerResponse *fbLinkResponse = [[BNCServerResponse alloc] init];
        fbLinkResponse.statusCode = @200;
        fbLinkResponse.data = @{ @"url": @"https://bnc.lt/l/4BGtJj-03N" };
        
        BNCServerResponse *twLinkResponse = [[BNCServerResponse alloc] init];
        twLinkResponse.statusCode = @200;
        twLinkResponse.data = @{ @"url": @"https://bnc.lt/l/-03N4BGtJj" };
        
        // FB should only be called once
        [[[serverInterfaceMock expect] andReturn:fbLinkResponse] postRequestSynchronous:[OCMArg checkWithBlock:^BOOL(NSDictionary *params) {
            return [params[@"channel"] isEqualToString:@"facebook"];
        }] url:[preferenceHelper getAPIURL:@"url"] key:[OCMArg any]];
        
        [[serverInterfaceMock reject] postRequestSynchronous:[OCMArg checkWithBlock:^BOOL(NSDictionary *params) {
            return [params[@"channel"] isEqualToString:@"facebook"];
        }] url:[preferenceHelper getAPIURL:@"url"] key:[OCMArg any]];
        
        // TW should be allowed still
        [[[serverInterfaceMock expect] andReturn:twLinkResponse] postRequestSynchronous:[OCMArg checkWithBlock:^BOOL(NSDictionary *params) {
            return [params[@"channel"] isEqualToString:@"twitter"];
        }] url:[preferenceHelper getAPIURL:@"url"] key:[OCMArg any]];
        
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
    id serverInterfaceMock = OCMClassMock([BNCServerInterface class]);
    [self setupDefaultStubsForServerInterfaceMock:serverInterfaceMock];
    
    BNCPreferenceHelper *preferenceHelper = [BNCPreferenceHelper preferenceHelper];
    Branch *branch =
        [[Branch alloc]
            initWithInterface:serverInterfaceMock
            queue:[[BNCServerRequestQueue alloc] init]
            cache:[[BNCLinkCache alloc] init]
            preferenceHelper:preferenceHelper
            key:@"key_live_foo"];

    [preferenceHelper setCreditCount:NSIntegerMax forBucket:@"default"];
    
    BNCServerResponse *loadCreditsResponse = [[BNCServerResponse alloc] init];
    loadCreditsResponse.data = @{ @"default": @(NSIntegerMin) };
    
    __block BNCServerCallback loadCreditsCallback;
    [[[serverInterfaceMock expect] andDo:^(NSInvocation *invocation) {
        loadCreditsCallback(loadCreditsResponse, nil);
    }] getRequest:[OCMArg any] url:[preferenceHelper getAPIURL:[NSString stringWithFormat:@"%@/%@", @"credits", preferenceHelper.identityID]] key:[OCMArg any] callback:[OCMArg checkWithBlock:^BOOL(BNCServerCallback callback) {
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
    id serverInterfaceMock = OCMClassMock([BNCServerInterface class]);
    [self setupDefaultStubsForServerInterfaceMock:serverInterfaceMock];
    
    BNCPreferenceHelper *preferenceHelper = [BNCPreferenceHelper preferenceHelper];
    Branch *branch =
        [[Branch alloc]
            initWithInterface:serverInterfaceMock
            queue:[[BNCServerRequestQueue alloc] init]
            cache:[[BNCLinkCache alloc] init]
            preferenceHelper:preferenceHelper
            key:@"key_live_foo"];

    [preferenceHelper setCreditCount:1 forBucket:@"default"];
    
    BNCServerResponse *loadRewardsResponse = [[BNCServerResponse alloc] init];
    loadRewardsResponse.data = @{ @"default": @1 };
    
    __block BNCServerCallback loadRewardsCallback;
    [[[serverInterfaceMock expect]
        andDo:^(NSInvocation *invocation) {
            loadRewardsCallback(loadRewardsResponse, nil);
        }]
        getRequest:[OCMArg any]
        url:[preferenceHelper
        getAPIURL:[NSString stringWithFormat:@"%@/%@", @"credits", preferenceHelper.identityID]]
        key:[OCMArg any]
        callback:[OCMArg checkWithBlock:^BOOL(BNCServerCallback callback) {
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

- (void)test12GetCreditHistory {
    id serverInterfaceMock = OCMClassMock([BNCServerInterface class]);
    [self setupDefaultStubsForServerInterfaceMock:serverInterfaceMock];
    
    BNCPreferenceHelper *preferenceHelper = [BNCPreferenceHelper preferenceHelper];
    Branch *branch =
        [[Branch alloc]
            initWithInterface:serverInterfaceMock
            queue:[[BNCServerRequestQueue alloc] init]
            cache:[[BNCLinkCache alloc] init]
            preferenceHelper:preferenceHelper
            key:@"key_live_foo"];

    [preferenceHelper setCreditCount:1 forBucket:@"default"];
    
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
    [[[serverInterfaceMock expect]
        andDo:^(NSInvocation *invocation) {
            creditHistoryCallback(creditHistoryResponse, nil);
        }]
        postRequest:[OCMArg any]
        url:[preferenceHelper getAPIURL:@"credithistory"]
        key:[OCMArg any]
        callback:[OCMArg checkWithBlock:^BOOL(BNCServerCallback callback) {
            creditHistoryCallback = callback;
            return YES;
        }]];
    
    XCTestExpectation *getCreditHistoryExpectation =
        [self expectationWithDescription:@"Test getCreditHistory"];
    [branch getCreditHistoryWithCallback:^(NSArray *list, NSError *error) {
        XCTAssertNil(error);
        XCTAssertNotNil(list);
        XCTAssertGreaterThan(list.count, 0);
        
        [self safelyFulfillExpectation:getCreditHistoryExpectation];
    }];
    
    [self awaitExpectations];
}

// Test scenario
// * Initialize the session
// * Get a short url.
// * Log out.
// * Get the same url:  should be the same.
- (void)test13GetShortURLAfterLogout {
    id serverInterfaceMock = OCMClassMock([BNCServerInterface class]);
    [self setupDefaultStubsForServerInterfaceMock:serverInterfaceMock];

    BNCPreferenceHelper *preferenceHelper = [BNCPreferenceHelper preferenceHelper];
    Branch *branch =
		[[Branch alloc]
			initWithInterface:serverInterfaceMock
			queue:[[BNCServerRequestQueue alloc] init]
			cache:[[BNCLinkCache alloc] init]
			preferenceHelper:preferenceHelper
			key:@"key_live_foo"];

    // Init session

    XCTestExpectation *initSessionExpectation =
        [self expectationWithDescription:@"Expect Session"];
    
    [branch initSessionWithLaunchOptions:@{}
              andRegisterDeepLinkHandler:^(NSDictionary *params, NSError *error) {
                XCTAssert(!error);
                NSLog(@"Fullfilled 1.");
                [self safelyFulfillExpectation:initSessionExpectation];
              }];

    [self awaitExpectations];

    // Get short URL

    NSString * urlTruthString = @"https://bnc.lt/l/4BGtJj-03N";
    BNCServerResponse *urlResp = [[BNCServerResponse alloc] init];
    urlResp.statusCode = @200;
    urlResp.data = @{ @"url": urlTruthString };

    [[[serverInterfaceMock expect]
        andReturn:urlResp]
            postRequestSynchronous:[OCMArg any]
            url:[preferenceHelper getAPIURL:@"url"]
            key:[OCMArg any]];

    NSString *url1 = [branch getShortURLWithParams:nil andChannel:nil andFeature:nil];
    XCTAssertEqual(urlTruthString, url1);

    // Log out

    BNCServerResponse *logoutResp = [[BNCServerResponse alloc] init];
    logoutResp.data = @{ @"session_id": @"foo", @"identity_id": @"foo", @"link": @"http://foo" };

    __block BNCServerCallback logoutCallback;
    [[[serverInterfaceMock expect]
        andDo:^(NSInvocation *invocation) {
            logoutCallback(logoutResp, nil);
        }]
            postRequest:[OCMArg any]
            url:[preferenceHelper
            getAPIURL:@"logout"]
            key:[OCMArg any]
            callback:[OCMArg
            checkWithBlock:^BOOL(BNCServerCallback callback) {
                logoutCallback = callback;
                return YES;
            }]];

    XCTestExpectation *logoutExpectation =
        [self expectationWithDescription:@"Logout Session"];

    [branch logoutWithCallback:^(BOOL changed, NSError * _Nullable error) {
        XCTAssertNil(error);
        NSLog(@"Fullfilled 2.");
        [self safelyFulfillExpectation:logoutExpectation];
    }];

    self.hasExceededExpectations = NO;
    [self awaitExpectations];

    // Get short URL

    [[[serverInterfaceMock expect]
        andReturn:urlResp]
            postRequestSynchronous:[OCMArg any]
            url:[preferenceHelper getAPIURL:@"url"]
            key:[OCMArg any]];

    NSString *url2 = [branch getShortURLWithParams:nil andChannel:nil andFeature:nil];
    XCTAssertEqualObjects(url1, url2);
}

#pragma mark - Test Utility

- (void)safelyFulfillExpectation:(XCTestExpectation *)expectation {
    if (!self.hasExceededExpectations) {
        [expectation fulfill];
    }
}

- (void)awaitExpectations {
    [self waitForExpectationsWithTimeout:6.0 handler:^(NSError *error) {
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
        return [url rangeOfString:@"open"].location != NSNotFound ||
               [url rangeOfString:@"install"].location != NSNotFound;
    }];
    [[[serverInterfaceMock expect]
        andDo:openOrInstallInvocation]
        postRequest:[OCMArg any]
        url:openOrInstallUrlCheckBlock
        key:[OCMArg any]
        callback:openOrInstallCallbackCheckBlock];
}

@end
