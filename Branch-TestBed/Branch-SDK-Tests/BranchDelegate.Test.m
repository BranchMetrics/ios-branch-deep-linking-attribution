//
//  BranchDelegateTest.m
//  Branch-SDK-Tests
//
//  Created by edward on 11/3/17.
//  Copyright © 2017 Branch, Inc. All rights reserved.
//

#import "BNCTestCase.h"

@interface BranchDelegateTest : BNCTestCase <BranchDelegate>
@property (assign, nonatomic) NSInteger notificationOrder;
@property (strong, nonatomic) XCTestExpectation *branchWillOpenURLExpectation;
@property (strong, nonatomic) XCTestExpectation *branchWillOpenURLNotificationExpectation;
@property (strong, nonatomic) XCTestExpectation *branchDidOpenURLExpectation;
@property (strong, nonatomic) XCTestExpectation *branchDidOpenURLNotificationExpectation;
@property (strong, nonatomic) NSDictionary *deepLinkParams;
@property (assign, nonatomic) BOOL expectFailure;
@end

#pragma mark - BranchDelegateTest

@implementation BranchDelegateTest

+ (void) tearDown {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

// Test that Branch notifications work.
// Test that they 1) work and 2) are sent in the right order.
- (void) testNotificationsSuccess {

    self.expectFailure = NO;
    self.notificationOrder = 0;
    self.branchWillOpenURLExpectation =
        [self expectationWithDescription:@"branchWillOpenURLExpectation"];
    self.branchWillOpenURLNotificationExpectation =
        [self expectationWithDescription:@"branchWillOpenURLNotificationExpectation"];
    self.branchDidOpenURLExpectation =
        [self expectationWithDescription:@"branchDidOpenURLExpectation"];
    self.branchDidOpenURLNotificationExpectation =
        [self expectationWithDescription:@"branchDidOpenURLNotificationExpectation"];

    [[NSNotificationCenter defaultCenter]
        addObserver:self
        selector:@selector(branchWillStartSessionNotification:)
        name:BranchWillStartSessionNotification
        object:nil];

    [[NSNotificationCenter defaultCenter]
        addObserver:self
        selector:@selector(branchDidStartSessionNotification:)
        name:BranchDidStartSessionNotification
        object:nil];

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
    branch.delegate = self;

    BNCServerResponse *openInstallResponse = [[BNCServerResponse alloc] init];
    openInstallResponse.data = @{
        @"data": @"{\"$og_title\":\"Content Title\",\"$identity_id\":\"423237095633725879\",\"~feature\":\"Sharing Feature\",\"$desktop_url\":\"http://branch.io\",\"$canonical_identifier\":\"item/12345\",\"~id\":423243086454504450,\"~campaign\":\"some campaign\",\"+is_first_session\":false,\"~channel\":\"Distribution Channel\",\"$ios_url\":\"https://dev.branch.io/getting-started/sdk-integration-guide/guide/ios/\",\"$exp_date\":0,\"$currency\":\"$\",\"$publicly_indexable\":1,\"$content_type\":\"some type\",\"~creation_source\":3,\"$amount\":1000,\"$og_description\":\"My Content Description\",\"+click_timestamp\":1506983962,\"$og_image_url\":\"https://pbs.twimg.com/profile_images/658759610220703744/IO1HUADP.png\",\"+match_guaranteed\":true,\"+clicked_branch_link\":true,\"deeplink_text\":\"This text was embedded as data in a Branch link with the following characteristics:\\n\\ncanonicalUrl: https://dev.branch.io/getting-started/deep-link-routing/guide/ios/\\n  title: Content Title\\n  contentDescription: My Content Description\\n  imageUrl: https://pbs.twimg.com/profile_images/658759610220703744/IO1HUADP.png\\n\",\"$one_time_use\":false,\"$canonical_url\":\"https://dev.branch.io/getting-started/deep-link-routing/guide/ios/\",\"~referring_link\":\"https://bnctestbed.app.link/izPBY2xCqF\"}",
        @"device_fingerprint_id": @"439892172783867901",
        @"identity_id": @"439892172804841307",
        @"link": @"https://bnctestbed.app.link?%24identity_id=439892172804841307",
        @"session_id": @"443529761084512316",
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
        return [url rangeOfString:@"open"].location != NSNotFound ||
               [url rangeOfString:@"install"].location != NSNotFound;
    }];
    [[[serverInterfaceMock expect]
        andDo:openOrInstallInvocation]
        postRequest:[OCMArg any]
        url:openOrInstallUrlCheckBlock
        key:[OCMArg any]
        callback:openOrInstallCallbackCheckBlock];

    XCTestExpectation *openExpectation = [self expectationWithDescription:@"Test open"];
    [branch initSessionWithLaunchOptions:@{}
        andRegisterDeepLinkHandler:^(NSDictionary *params, NSError *error) {
            // Callback block. Order: 2.
            XCTAssertNil(error);
            XCTAssertEqualObjects(preferenceHelper.sessionID, @"443529761084512316");
            XCTAssertTrue(self.notificationOrder == 2);
            self.notificationOrder++;
            self.deepLinkParams = params;
            [openExpectation fulfill];
        }
    ];

    [self waitForExpectationsWithTimeout:5.0 handler:NULL];
    XCTAssertTrue(self.notificationOrder == 5);
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    branch.delegate = nil;
}

// Test that Branch notifications work with a failure.
// Test that they 1) work and 2) are sent in the right order.
- (void) testNotificationsFailure {

    self.expectFailure = YES;
    self.notificationOrder = 0;
    self.branchWillOpenURLExpectation =
        [self expectationWithDescription:@"branchWillOpenURLExpectation"];
    self.branchWillOpenURLNotificationExpectation =
        [self expectationWithDescription:@"branchWillOpenURLNotificationExpectation"];
    self.branchDidOpenURLExpectation =
        [self expectationWithDescription:@"branchDidOpenURLExpectation"];
    self.branchDidOpenURLNotificationExpectation =
        [self expectationWithDescription:@"branchDidOpenURLNotificationExpectation"];

    [[NSNotificationCenter defaultCenter]
        addObserver:self
        selector:@selector(branchWillStartSessionNotification:)
        name:BranchWillStartSessionNotification
        object:nil];

    [[NSNotificationCenter defaultCenter]
        addObserver:self
        selector:@selector(branchDidStartSessionNotification:)
        name:BranchDidStartSessionNotification
        object:nil];

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
    branch.delegate = self;

    BNCServerResponse *openInstallResponse = [[BNCServerResponse alloc] init];
    openInstallResponse.data = @{ };

    __block BNCServerCallback openOrInstallCallback;
    id openOrInstallCallbackCheckBlock = [OCMArg checkWithBlock:^BOOL(BNCServerCallback callback) {
        openOrInstallCallback = callback;
        return YES;
    }];

    id openOrInstallInvocation = ^(NSInvocation *invocation) {
        NSError *error = [NSError branchErrorWithCode:BNCNetworkServiceInterfaceError];
        openOrInstallCallback(openInstallResponse, error);
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

    XCTestExpectation *openExpectation = [self expectationWithDescription:@"Test open"];
    [branch initSessionWithLaunchOptions:@{}
        andRegisterDeepLinkHandler:^(NSDictionary *params, NSError *error) {
            // Callback block. Order: 2.
            XCTAssertEqualObjects(params, @{});
            XCTAssertNotNil(error);
            XCTAssertTrue(self.notificationOrder == 2);
            self.notificationOrder++;
            self.deepLinkParams = params;
            [openExpectation fulfill];
        }
    ];

    [self waitForExpectationsWithTimeout:5.0 handler:NULL];
    XCTAssertTrue(self.notificationOrder == 5);
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    branch.delegate = nil;
}

#pragma mark - Delegate & Notification Methods

// Delegate method. Order: 0.
- (void) branch:(Branch*)branch willStartSessionWithURL:(NSURL*)url {
    XCTAssertTrue([NSThread isMainThread]);
    XCTAssertTrue(self.notificationOrder == 0);
    self.notificationOrder++;
    [self.branchWillOpenURLExpectation fulfill];
}

// Notification method. Order: 1.
- (void) branchWillStartSessionNotification:(NSNotification*)notification {
    XCTAssertTrue([NSThread isMainThread]);
    XCTAssertTrue(self.notificationOrder == 1);
    self.notificationOrder++;

    NSError *error = notification.userInfo[BranchErrorKey];
    XCTAssertNil(error);

    NSURL *URL = notification.userInfo[BranchURLKey];
    XCTAssertNil(URL);

    BranchUniversalObject *object = notification.userInfo[BranchUniversalObjectKey];
    XCTAssertNil(object);

    BranchLinkProperties *properties = notification.userInfo[BranchLinkPropertiesKey];
    XCTAssertNil(properties);

    [self.branchWillOpenURLNotificationExpectation fulfill];
}

// Delegate method. Order: 3.
- (void) branch:(Branch*)branch
didStartSessionWithURL:(NSURL*)url
     branchLink:(BranchLink*)branchLink {
    XCTAssertTrue([NSThread isMainThread]);
    XCTAssertTrue(self.notificationOrder == 3);
    self.notificationOrder++;
    XCTAssertNotNil(branchLink.universalObject);
    XCTAssertNotNil(branchLink.linkProperties);
    if (self.expectFailure)
        [NSException raise:NSInternalInconsistencyException format:@"Should return an error here."];
    [self.branchDidOpenURLExpectation fulfill];
}

// Delegate method. Order: 3
- (void) branch:(Branch*)branch
failedToStartSessionWithURL:(NSURL*)url
                      error:(NSError*)error {
    XCTAssertTrue([NSThread isMainThread]);
    XCTAssertTrue(self.notificationOrder == 3);
    self.notificationOrder++;
    XCTAssertNotNil(error);
    if (!self.expectFailure)
        [NSException raise:NSInternalInconsistencyException format:@"Shouldn't return an error here."];
    [self.branchDidOpenURLExpectation fulfill];
}

// Notification method. Order: 4
- (void) branchDidStartSessionNotification:(NSNotification*)notification {
    XCTAssertTrue([NSThread isMainThread]);
    XCTAssertTrue(self.notificationOrder == 4);
    self.notificationOrder++;

    NSError *error = notification.userInfo[BranchErrorKey];
    NSURL *URL = notification.userInfo[BranchURLKey];
    BranchUniversalObject *object = notification.userInfo[BranchUniversalObjectKey];
    BranchLinkProperties *properties = notification.userInfo[BranchLinkPropertiesKey];

    if (self.expectFailure) {

        XCTAssertNotNil(error);
        XCTAssertNil(URL);
        XCTAssertNil(object);
        XCTAssertNil(object);

    } else {

        XCTAssertNil(error);
        XCTAssertNotNil(URL);
        XCTAssertNotNil(object);
        XCTAssertNotNil(object);

        NSDictionary *d = [object getDictionaryWithCompleteLinkProperties:properties];
        NSMutableDictionary *truth = [NSMutableDictionary dictionaryWithDictionary:self.deepLinkParams];
        truth[@"~duration"] = @(0);         // ~duration not added because zero value?
        truth[@"$locally_indexable"] = @(0);
        XCTAssertTrue(d.count == truth.count);
        XCTAssertTrue(!d || [d isEqualToDictionary:truth]);
    }

    [self.branchDidOpenURLNotificationExpectation fulfill];
}

@end
