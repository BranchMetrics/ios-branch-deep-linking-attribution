//
//  BranchClassTests.m
//  Branch-SDK-Tests
//
//  Created by Nipun Singh on 9/25/23.
//  Copyright © 2023 Branch, Inc. All rights reserved.
//

#import <XCTest/XCTest.h>
#import "Branch.h"
#import "BranchConstants.h"
#import "BNCPasteboard.h"
#import "BNCAppGroupsData.h"
#import "BNCPartnerParameters.h"
#import "BNCServerRequestQueue.h"
#import "BNCServerRequestOperation.h"
#import "BNCServerResponse.h"
#import "BranchRequestOpen.h"
#import "BranchRequestDeepLink.h"

@interface BNCPreferenceHelper(Test)
// Expose internal private method to clear EEA data
- (void)writeObjectToDefaults:(NSString *)key value:(NSObject *)value;
@end


// Expose private session-state internals used to reproduce the in-flight open window.
@interface Branch (SessionReadySettleTest)
- (void)handleInitSuccessAndCallCallback:(BOOL)callCallback sceneIdentifier:(NSString *)sceneIdentifier;
@end

// Expose the EMT-3892 deep-link open deferral internals for regression testing.
@interface Branch (DeepLinkOpenDeferralTest)
@property (nonatomic, assign) BOOL deepLinkOpenPending;
- (BOOL)handleUniversalDeepLink_private:(NSString *)urlString sceneIdentifier:(NSString *)sceneIdentifier;
- (void)cancelDeepLinkOpenFallback;
@end

// Expose the private queue-depth accessor to detect a synchronous enqueue without being
// coupled to leftover install/open state from other tests sharing the Branch singleton.
@interface BNCServerRequestQueue (QueueDepthTest)
- (NSInteger)queueDepth;
@end

// Expose the underlying NSOperationQueue for deterministic, network-free behavioral testing:
// suspend it, drive the SDK's real deep-link/open code paths, inspect exactly what got
// enqueued (class + urlString/linkData) before anything can touch the network, then clear it.
// No HTTP-stub library exists in this suite; this is the cleanest network-free equivalent.
@interface BNCServerRequestQueue (OperationsIntrospectionTest)
@property (strong, nonatomic) NSOperationQueue *operationQueue;
@end

@interface BranchClassTests : XCTestCase
@property (nonatomic, strong) Branch *branch;
// Baseline of the shared singleton state the EMT-3892/3893 behavioral tests mutate,
// captured per-test in -setUp and fully restored in -tearDown. The behavioral tests drive
// the real deep-link/open code paths, which write attributionLevel/referringURL/sessionParams
// on the shared BNCPreferenceHelper and arm an async fallback timer on the shared Branch
// singleton. Without a hermetic tearDown that leaked state (Full attribution left set, a
// still-armed fallback timer firing into a later test) polluted order-dependent pre-existing
// tests in this file. Restoring the captured baseline makes every test self-contained again.
@property (nonatomic, assign) NSTimeInterval savedTimeout;
@property (nonatomic, copy) BranchAttributionLevel savedAttributionLevel;
@end

@implementation BranchClassTests

- (void)setUp {
    [super setUp];
    self.branch = [Branch getInstance];
    BNCPreferenceHelper *preferenceHelper = [BNCPreferenceHelper sharedInstance];
    self.savedTimeout = preferenceHelper.timeout;
    self.savedAttributionLevel = preferenceHelper.attributionLevel;
}

- (void)tearDown {
    // Hermetic reset of everything the behavioral tests touch on the shared singletons, so a
    // failed/early-returning test can never leak state into the next one. Runs regardless of
    // per-test inline cleanup (which is now belt-and-suspenders).
    [self.branch cancelDeepLinkOpenFallback];           // stop any pending async open timer
    self.branch.deepLinkOpenPending = NO;
    [self.branch setValue:nil forKey:@"lastAttributedDeepLinkURL"];
    [self restoreRealRequestQueue];

    BNCPreferenceHelper *preferenceHelper = [BNCPreferenceHelper sharedInstance];
    preferenceHelper.referringURL = nil;
    preferenceHelper.sessionParams = nil;
    preferenceHelper.timeout = self.savedTimeout;
    preferenceHelper.attributionLevel = self.savedAttributionLevel;

    // Let any already-scheduled async block drain against this clean baseline rather than
    // landing mid-way through the next test.
    [[NSRunLoop currentRunLoop] runUntilDate:[NSDate dateWithTimeIntervalSinceNow:0.05]];

    self.branch = nil;
    [super tearDown];
}

- (void)testIsUserIdentified {
    [self.branch setIdentity: @"userId"];
    XCTAssertTrue([self.branch isUserIdentified], @"User should be identified");
}

- (void)testDisableAdNetworkCallouts {
    [self.branch disableAdNetworkCallouts:YES];
    XCTAssertTrue([BNCPreferenceHelper sharedInstance].disableAdNetworkCallouts, @"AdNetwork callouts should be disabled");
}

- (void)testSetNetworkTimeout {
    [self.branch setNetworkTimeout:5.0];
    XCTAssertEqual([BNCPreferenceHelper sharedInstance].timeout, 5.0, @"Network timeout should be set to 5.0");
}

//- (void)testSetMaxRetries {
//    [self.branch setMaxRetries:3];
//    XCTAssertEqual([BNCPreferenceHelper sharedInstance].retryCount, 3, @"Max retries should be set to 3");
//}

- (void)testSetRetryInterval {
    [self.branch setRetryInterval:2.0];
    XCTAssertEqual([BNCPreferenceHelper sharedInstance].retryInterval, 2.0, @"Retry interval should be set to 2.0");
}

- (void)testSetRequestMetadataKeyAndValue {
    [self.branch setRequestMetadataKey:@"key" value:@"value"];
    NSDictionary *metadata = [BNCPreferenceHelper sharedInstance].requestMetadataDictionary;
    XCTAssertEqualObjects(metadata[@"key"], @"value");
}

- (void)testSetTrackingDisabled {
    XCTAssertFalse([BNCPreferenceHelper sharedInstance].trackingDisabled);

    [Branch setTrackingDisabled:YES];
    XCTAssertTrue([BNCPreferenceHelper sharedInstance].trackingDisabled);

    [Branch setTrackingDisabled:NO];
    XCTAssertFalse([BNCPreferenceHelper sharedInstance].trackingDisabled);
}

- (void)testCheckPasteboardOnInstall {
    [self.branch checkPasteboardOnInstall];
    BOOL checkOnInstall = [BNCPasteboard sharedInstance].checkOnInstall;
    XCTAssertTrue(checkOnInstall);
}

- (void)testWillShowPasteboardToast_ShouldReturnYes {
    [BNCPreferenceHelper sharedInstance].randomizedBundleToken = nil;
    [BNCPasteboard sharedInstance].checkOnInstall = YES;
    UIPasteboard.generalPasteboard.URL = [NSURL URLWithString:@"https://example.com"];

    BOOL result = [self.branch willShowPasteboardToast];
    XCTAssertTrue(result);
}

- (void)testWillShowPasteboardToast_ShouldReturnNo {
    [BNCPreferenceHelper sharedInstance].randomizedBundleToken = @"some_token";
    [BNCPasteboard sharedInstance].checkOnInstall = NO;

    BOOL result = [self.branch willShowPasteboardToast];
    XCTAssertFalse(result);
}

- (void)testSetAppClipAppGroup {
    NSString *testAppGroup = @"testAppGroup";
    [self.branch setAppClipAppGroup:testAppGroup];
    NSString *actualAppGroup = [BNCAppGroupsData shared].appGroup;

    XCTAssertEqualObjects(testAppGroup, actualAppGroup);
}

- (void)testClearPartnerParameters {
    [self.branch addFacebookPartnerParameterWithName:@"ph" value:@"123456789"];
    [[BNCPartnerParameters shared] clearAllParameters];
       
    NSDictionary *result = [[BNCPartnerParameters shared] parameterJson];
    XCTAssertEqual([result count], 0, @"Parameters should be empty after calling clearAllParameters");
}

- (void)testAddFacebookParameterWithName_Value {
    [self.branch addFacebookPartnerParameterWithName:@"name" value:@"3D4F2BF07DC1BE38B20C653EE9A7E446158F84E525BBB98FEDF721CB5A40A346"];
    
    NSDictionary *result = [[BNCPartnerParameters shared] parameterJson][@"fb"];
    XCTAssertEqualObjects(result[@"name"], @"3D4F2BF07DC1BE38B20C653EE9A7E446158F84E525BBB98FEDF721CB5A40A346", @"Should add parameter for Facebook");
}

- (void)testAddSnapParameterWithName_Value {
    [self.branch addSnapPartnerParameterWithName:@"name" value:@"3D4F2BF07DC1BE38B20C653EE9A7E446158F84E525BBB98FEDF721CB5A40A346"];
    
    NSDictionary *result = [[BNCPartnerParameters shared] parameterJson][@"snap"];
    XCTAssertEqualObjects(result[@"name"], @"3D4F2BF07DC1BE38B20C653EE9A7E446158F84E525BBB98FEDF721CB5A40A346", @"Should add parameter for Snap");
}

- (void)testGetFirstReferringBranchUniversalObject_ClickedBranchLink {
    NSString *installParamsString = @"{\"$canonical_identifier\":\"content/12345\",\"$creation_timestamp\":1694557342247,\"$desktop_url\":\"https://example.com/home\",\"$og_description\":\"My Content Description\",\"$og_title\":\"My Content Title\",\"+click_timestamp\":1695749249,\"+clicked_branch_link\":1,\"+is_first_session\":1,\"+match_guaranteed\":1,\"custom\":\"data\",\"key1\":\"value1\",\"~campaign\":\"content 123 launch\",\"~channel\":\"facebook\",\"~creation_source\":3,\"~feature\":\"sharing\",\"~id\":1230269548213984984,\"~referring_link\":\"https://bnctestbed.app.link/uSPHktjO2Cb\"}";
    [[BNCPreferenceHelper sharedInstance] setInstallParams: installParamsString];

    BranchUniversalObject *result = [self.branch getFirstReferringBranchUniversalObject];\
    XCTAssertNotNil(result);
    XCTAssertEqualObjects(result.title, @"My Content Title");
    XCTAssertEqualObjects(result.canonicalIdentifier, @"content/12345");
}

- (void)testGetFirstReferringBranchUniversalObject_NotClickedBranchLink {
    NSString *installParamsString = @"{\"+clicked_branch_link\":false,\"+is_first_session\":true}";
    [[BNCPreferenceHelper sharedInstance] setInstallParams: installParamsString];
        
    BranchUniversalObject *result = [self.branch getFirstReferringBranchUniversalObject];
    XCTAssertNil(result);
}

- (void)testGetFirstReferringBranchLinkProperties_ClickedBranchLink {
    NSString *installParamsString = @"{\"+clicked_branch_link\":1,\"+is_first_session\":1,\"~campaign\":\"content 123 launch\"}";
    [[BNCPreferenceHelper sharedInstance] setInstallParams:installParamsString];

    BranchLinkProperties *result = [self.branch getFirstReferringBranchLinkProperties];
    XCTAssertNotNil(result);
    XCTAssertEqualObjects(result.campaign, @"content 123 launch");
}

- (void)testGetFirstReferringBranchLinkProperties_NotClickedBranchLink {
    NSString *installParamsString = @"{\"+clicked_branch_link\":false,\"+is_first_session\":true}";
    [[BNCPreferenceHelper sharedInstance] setInstallParams:installParamsString];

    BranchLinkProperties *result = [self.branch getFirstReferringBranchLinkProperties];
    XCTAssertNil(result);
}

- (void)testGetFirstReferringParams {
    NSString *installParamsString = @"{\"+clicked_branch_link\":true,\"+is_first_session\":true}";
    [[BNCPreferenceHelper sharedInstance] setInstallParams:installParamsString];

    NSDictionary *result = [self.branch getFirstReferringParams];
    XCTAssertEqualObjects([result objectForKey:@"+clicked_branch_link"], @true);
}

- (void)testGetLatestReferringParams {
    NSString *sessionParamsString = @"{\"+clicked_branch_link\":true,\"+is_first_session\":false}";
    [[BNCPreferenceHelper sharedInstance] setSessionParams:sessionParamsString];

    NSDictionary *result = [self.branch getLatestReferringParams];
    XCTAssertEqualObjects([result objectForKey:@"+clicked_branch_link"], @true);
}

//- (void)testGetLatestReferringParamsSynchronous {
//    NSString *sessionParamsString = @"{\"+clicked_branch_link\":true,\"+is_first_session\":false}";
//    [[BNCPreferenceHelper sharedInstance] setSessionParams:sessionParamsString];
//
//    NSDictionary *result = [self.branch getLatestReferringParamsSynchronous];
//    XCTAssertEqualObjects([result objectForKey:@"+clicked_branch_link"], @true);
//}

- (void)testGetLatestReferringBranchUniversalObject_ClickedBranchLink {
    NSString *sessionParamsString = @"{\"+clicked_branch_link\":1,\"+is_first_session\":false,\"$og_title\":\"My Latest Content\"}";
    [[BNCPreferenceHelper sharedInstance] setSessionParams:sessionParamsString];

    BranchUniversalObject *result = [self.branch getLatestReferringBranchUniversalObject];
    XCTAssertNotNil(result);
    XCTAssertEqualObjects(result.title, @"My Latest Content");
}

- (void)testGetLatestReferringBranchLinkProperties_ClickedBranchLink {
    NSString *sessionParamsString = @"{\"+clicked_branch_link\":true,\"+is_first_session\":false,\"~campaign\":\"latest campaign\"}";
    [[BNCPreferenceHelper sharedInstance] setSessionParams:sessionParamsString];

    BranchLinkProperties *result = [self.branch getLatestReferringBranchLinkProperties];
    XCTAssertNotNil(result);
    XCTAssertEqualObjects(result.campaign, @"latest campaign");
}

- (void)testGetShortURL {      
    NSString *shortURL = [self.branch getShortURL];
    XCTAssertNotNil(shortURL, @"URL should not be nil");
    XCTAssertTrue([shortURL hasPrefix:@"https://"], @"URL should start with 'https://'");
}

- (void)testGetLongURLWithParamsAndChannelAndTagsAndFeatureAndStageAndAlias {
    NSDictionary *params = @{@"key": @"value"};
    NSString *channel = @"channel1";
    NSArray *tags = @[@"tag1", @"tag2"];
    NSString *feature = @"feature1";
    NSString *stage = @"stage1";
    NSString *alias = @"alias1";
    
    NSString *generatedURL = [self.branch getLongURLWithParams:params andChannel:channel andTags:tags andFeature:feature andStage:stage andAlias:alias];
    NSString *expectedURL = @"https://bnc.lt/a/key_live_hcnegAumkH7Kv18M8AOHhfgiohpXq5tB?tags=tag1&tags=tag2&alias=alias1&feature=feature1&stage=stage1&source=ios&data=eyJrZXkiOiJ2YWx1ZSJ9";
    
    XCTAssertEqualObjects(generatedURL, expectedURL, @"URL should match the expected format");
}

- (void)testSetDMAParamsForEEA {
    XCTAssertFalse([[BNCPreferenceHelper sharedInstance] eeaRegionInitialized]);
    
    [Branch setDMAParamsForEEA:FALSE AdPersonalizationConsent:TRUE AdUserDataUsageConsent:TRUE];
    XCTAssertTrue([[BNCPreferenceHelper sharedInstance] eeaRegionInitialized]);
    XCTAssertFalse([BNCPreferenceHelper sharedInstance].eeaRegion);
    XCTAssertTrue([BNCPreferenceHelper sharedInstance].adPersonalizationConsent);
    XCTAssertTrue([BNCPreferenceHelper sharedInstance].adUserDataUsageConsent);

    // Manually clear values after testing
    // By design, this API is meant to be set once and always set. However, in a test scenario it needs to be cleared.
    [[BNCPreferenceHelper sharedInstance] writeObjectToDefaults:@"bnc_dma_eea" value:nil];
    [[BNCPreferenceHelper sharedInstance] writeObjectToDefaults:@"bnc_dma_ad_personalization" value:nil];
    [[BNCPreferenceHelper sharedInstance] writeObjectToDefaults:@"bnc_dma_ad_user_data" value:nil];
}

- (void)testSetConsumerProtectionAttributionLevel {
    // Set to Reduced and check
    Branch *branch = [Branch getInstance];
    [branch setConsumerProtectionAttributionLevel:BranchAttributionLevelReduced];
    XCTAssertEqual([BNCPreferenceHelper sharedInstance].attributionLevel, BranchAttributionLevelReduced);
    
    // Set to Minimal and check
    [branch setConsumerProtectionAttributionLevel:BranchAttributionLevelMinimal];
    XCTAssertEqual([BNCPreferenceHelper sharedInstance].attributionLevel, BranchAttributionLevelMinimal);
    
    // Set to None and check
    [branch setConsumerProtectionAttributionLevel:BranchAttributionLevelNone];
    XCTAssertEqual([BNCPreferenceHelper sharedInstance].attributionLevel, BranchAttributionLevelNone);
    
    // Set to Full and check
    [branch setConsumerProtectionAttributionLevel:BranchAttributionLevelFull];
    XCTAssertEqual([BNCPreferenceHelper sharedInstance].attributionLevel, BranchAttributionLevelFull);
    
}



// Regression test for the in-flight auto open window: a handler registered via
// initSession while an open is in flight (status Initializing == 1) must still
// be invoked when the open settles silently (callCallback:NO), which is how the
// automatic sendOpen completes its requests.
- (void)testInitSessionCallbackRegisteredWhileOpenInFlightIsInvoked {
    // Force the state an in-flight automatic open leaves us in.
    [self.branch setValue:@(1) forKey:@"initializationStatus"];

    XCTestExpectation *expectation = [self expectationWithDescription:@"init callback invoked after silent settle"];
    __block BOOL alreadyFulfilled = NO;
    [self.branch initSessionWithLaunchOptions:@{} andRegisterDeepLinkHandler:^(NSDictionary *params, NSError *error) {
        if (!alreadyFulfilled) {
            alreadyFulfilled = YES;
            [expectation fulfill];
        }
    }];

    // Let the isolation queue process the registration before the open settles.
    [NSThread sleepForTimeInterval:0.5];

    // Simulate the in-flight automatic open settling the session silently.
    [self.branch handleInitSuccessAndCallCallback:NO sceneIdentifier:nil];

    [self waitForExpectationsWithTimeout:5.0 handler:nil];

    // Reset session state so this test does not leak into others.
    [self.branch setValue:@(0) forKey:@"initializationStatus"];
}

// EMT-3892 regression: a Branch deep-link (universal link) open must defer the launch
// open until requestDeepLinkData resolves it, not synchronously enqueue an unattributed
// generic open. See Branch.m deferLaunchOpenPendingDeepLinkResolution.
- (void)testUniversalDeepLinkDefersLaunchOpenPendingResolution {
    BNCServerRequestQueue *requestQueue = [self.branch valueForKey:@"requestQueue"];
    NSInteger queueDepthBeforeDeepLink = [requestQueue queueDepth];

    BOOL isBranchLink = [self.branch handleUniversalDeepLink_private:@"https://example.app.link/abc123" sceneIdentifier:nil];
    XCTAssertTrue(isBranchLink, @"example.app.link should be recognized as a Branch link.");

    // Delta-based (not absolute) so this isn't coupled to install/open state left behind by
    // other tests sharing the Branch singleton and its request queue.
    XCTAssertEqual([requestQueue queueDepth], queueDepthBeforeDeepLink, @"The launch open must be deferred, not enqueued synchronously before deep-link resolution.");
    XCTAssertTrue(self.branch.deepLinkOpenPending, @"Deep link resolution should be marked pending after a universal link open.");

    // Cancel the bounded fallback so it doesn't fire a real network open later in the suite.
    [self.branch cancelDeepLinkOpenFallback];
    XCTAssertFalse(self.branch.deepLinkOpenPending, @"Cancelling the fallback should clear the pending flag.");
}

#pragma mark - EMT-3892/3893 behavioral evidence helpers

// Swaps in a disposable, permanently-suspended BNCServerRequestQueue so a scenario's
// enqueued requests can be inspected deterministically (class + urlString/linkData)
// without ever touching the network and without depending on / polluting the shared
// singleton queue other tests use. No HTTP-stub library exists in this suite; this is the
// cleanest network-free equivalent. Always pair with -restoreRealRequestQueue.
//
// Note: we deliberately never cancel/resume this fake queue. BNCServerRequestOperation's
// -cancel sets isFinished directly when a suspended (never-started) operation is
// cancelled, which trips an NSOperationQueue internal consistency check ("went
// isFinished=YES without being started by the queue it is in") and crashed the test host
// during development of this test. Simply discarding the whole disposable queue (and its
// never-started operations) avoids that pre-existing, out-of-scope edge case entirely.
- (BNCServerRequestQueue *)installFakeRequestQueue {
    BNCServerRequestQueue *fakeQueue = [BNCServerRequestQueue new];
    fakeQueue.operationQueue.suspended = YES;
    [self.branch setValue:fakeQueue forKey:@"requestQueue"];
    return fakeQueue;
}

- (void)restoreRealRequestQueue {
    [self.branch setValue:[BNCServerRequestQueue getInstance] forKey:@"requestQueue"];
}

// All BNCServerRequestOperation-wrapped requests currently sitting in `queue`, as untyped
// KVC handles (`.request`, and on that the request's own `urlString`/`linkData`). This
// project links BranchSDK in a way that loads some classes (confirmed: at least
// BNCServerRequestOperation) from two different images at once — `isKindOfClass:`/typed
// casts against a class the test target also references directly are unreliable (the
// object's real class and the test file's compile-time class symbol can be two distinct
// Class objects with the same name). `-valueForKey:` and `NSStringFromClass` dispatch by
// selector/name instead of Class-pointer identity, sidestepping that entirely — the same
// "queue-introspection pattern" already used via `queueDepth` elsewhere in this file.
- (NSArray<NSOperation *> *)requestOperationsIn:(BNCServerRequestQueue *)queue {
    NSMutableArray<NSOperation *> *ops = [NSMutableArray array];
    for (NSOperation *op in queue.operationQueue.operations) {
        if ([NSStringFromClass([op class]) isEqualToString:@"BNCServerRequestOperation"]) {
            [ops addObject:op];
        }
    }
    return ops;
}

// Deterministically waits for the bounded fallback (deferLaunchOpenPendingDeepLinkResolution's
// timer) to actually enqueue an open into `queue`, instead of a fixed wall-clock sleep. Uses
// XCTNSPredicateExpectation, which polls the predicate and resolves the instant it becomes
// true — so this is as fast as the real event AND has a generous ceiling for slow/loaded CI,
// eliminating the flakiness of racing a tight fixed-duration sleep against an async GCD timer.
- (void)waitForFallbackOpenIn:(BNCServerRequestQueue *)queue timeout:(NSTimeInterval)timeout {
    NSPredicate *fallbackEnqueued = [NSPredicate predicateWithBlock:^BOOL(id evaluatedObject, NSDictionary *bindings) {
        return [self requestOperationsIn:queue].count > 0;
    }];
    XCTNSPredicateExpectation *expectation = [[XCTNSPredicateExpectation alloc] initWithPredicate:fallbackEnqueued object:self];
    XCTWaiterResult result = [XCTWaiter waitForExpectations:@[expectation] timeout:timeout];
    XCTAssertEqual(result, XCTWaiterResultCompleted, @"The bounded fallback did not enqueue an open within %.1fs.", timeout);
}

// A stub deep-link resolution response carrying a resolved, clicked Branch link — what
// BranchRequestDeepLink.processResponse: would receive from a real /v3/deeplink round trip.
- (BNCServerResponse *)stubDeepLinkResponseForLink:(NSString *)linkURL {
    BNCServerResponse *response = [BNCServerResponse new];
    response.statusCode = @200;
    response.data = @{
        BRANCH_RESPONSE_KEY_SESSION_DATA: @{
            BRANCH_RESPONSE_KEY_CLICKED_BRANCH_LINK: @1,
            BRANCH_RESPONSE_KEY_BRANCH_REFERRING_LINK: linkURL
        }
    };
    return response;
}

// A stub plain-open response carrying no link click — what a generic /v3/events/open would
// receive when there is nothing to attribute.
- (BNCServerResponse *)stubGenericOpenResponse {
    BNCServerResponse *response = [BNCServerResponse new];
    response.statusCode = @200;
    response.data = @{
        BRANCH_RESPONSE_KEY_SESSION_DATA: @{
            BRANCH_RESPONSE_KEY_CLICKED_BRANCH_LINK: @0
        }
    };
    return response;
}

#pragma mark - EMT-3892/3893 behavioral evidence

// Behavior 1: deep link + requestDeepLinkData resolving emits exactly ONE open request for
// the session, and it carries the resolved link — not an unattributed launch open plus a
// duplicate attributed one. No HTTP stub library exists in this suite, so the deep-link
// server round trip is simulated directly on a BranchRequestDeepLink instance (mirrors what
// requestDeepLinkData: does internally once its network call returns).
- (void)testDeepLinkResolutionEmitsExactlyOneAttributedOpenCarryingTheLink {
    NSString *linkURL = @"https://example.app.link/behavioral-resolved";
    BNCPreferenceHelper *preferenceHelper = [BNCPreferenceHelper sharedInstance];
    preferenceHelper.attributionLevel = BranchAttributionLevelFull; // deterministic regardless of ambient state

    BNCServerRequestQueue *fakeQueue = [self installFakeRequestQueue];

    // 1) App receives the deep link: SDK defers the launch open (EMT-3892).
    [self.branch handleUniversalDeepLink_private:linkURL sceneIdentifier:nil];
    XCTAssertEqual([self requestOperationsIn:fakeQueue].count, 0u,
                    @"Nothing should be enqueued yet — the open is deferred pending resolution.");

    // 2) App calls requestDeepLinkData(...), which (a) cancels the bounded fallback and
    // (b) resolves the link. We simulate step (b)'s network response directly.
    [self.branch cancelDeepLinkOpenFallback];

    BranchRequestDeepLink *deepLinkRequest = [[BranchRequestDeepLink alloc] initWithCallback:nil];
    deepLinkRequest.urlString = linkURL;
    deepLinkRequest.uri = linkURL;
    [deepLinkRequest processResponse:[self stubDeepLinkResponseForLink:linkURL] error:nil];

    // Exactly one open — the single ATTRIBUTED open sent by
    // BranchRequestDeepLink.processResponse: (sendOpen:), not a second/duplicate one.
    NSArray<NSOperation *> *ops = [self requestOperationsIn:fakeQueue];
    XCTAssertEqual(ops.count, 1u, @"Exactly one open request must be emitted for a resolved deep link — no duplicate.");

    if (ops.count == 1) {
        id request = [ops.firstObject valueForKey:@"request"];
        XCTAssertEqualObjects(NSStringFromClass([request class]), @"BranchRequestOpen");
        // The attributed open carries the resolved link via linkData (-> link_data on the
        // wire, see BranchRequestOpen.makeRequest:), not urlString. Documented explicitly
        // because it differs from the factory-level universal_link_url path.
        NSDictionary *linkData = [request valueForKey:@"linkData"];
        XCTAssertNotNil(linkData, @"The attributed open must carry the resolved link's data.");
        NSDictionary *carriedSessionData = linkData[BRANCH_RESPONSE_KEY_SESSION_DATA];
        XCTAssertEqualObjects(carriedSessionData[BRANCH_RESPONSE_KEY_BRANCH_REFERRING_LINK], linkURL,
                               @"The carried link data must be the resolved link, not stale/empty.");
    }

    [self restoreRealRequestQueue];
}

// Behavior 2: deep link received, requestDeepLinkData never called → after the bounded
// fallback window, exactly ONE generic (unattributed) open is emitted so the open isn't
// lost. preferenceHelper.timeout is temporarily lowered so the test doesn't wait out the
// real ~5.5s default.
- (void)testDeepLinkFallbackFiresExactlyOneUnattributedOpenWhenNeverResolved {
    NSString *linkURL = @"https://example.app.link/behavioral-never-resolved";
    BNCPreferenceHelper *preferenceHelper = [BNCPreferenceHelper sharedInstance];
    preferenceHelper.attributionLevel = BranchAttributionLevelFull;
    NSTimeInterval originalTimeout = preferenceHelper.timeout;
    preferenceHelper.timeout = 0.2; // deterministic, fast fallback window for this test only

    BNCServerRequestQueue *fakeQueue = [self installFakeRequestQueue];

    [self.branch handleUniversalDeepLink_private:linkURL sceneIdentifier:nil];
    XCTAssertTrue(self.branch.deepLinkOpenPending);

    // Do NOT call requestDeepLinkData. Wait for the fallback to actually enqueue the open —
    // not a fixed wall-clock sleep, which raced under load (observed flaky: sometimes the
    // 0.2s-configured fallback hadn't fired by a fixed 0.6s deadline). A polling predicate
    // expectation resolves as soon as the real event happens, with a generous ceiling.
    [self waitForFallbackOpenIn:fakeQueue timeout:5.0];

    XCTAssertFalse(self.branch.deepLinkOpenPending, @"The fallback should have fired and cleared the pending flag.");

    NSArray<NSOperation *> *ops = [self requestOperationsIn:fakeQueue];
    XCTAssertEqual(ops.count, 1u, @"Exactly one open must be emitted by the fallback — the deep link open must not be lost.");

    if (ops.count == 1) {
        id request = [ops.firstObject valueForKey:@"request"];
        XCTAssertEqualObjects(NSStringFromClass([request class]), @"BranchRequestOpen");
        XCTAssertNil([request valueForKey:@"urlString"], @"The fallback open must be unattributed: no urlString.");
        XCTAssertNil([request valueForKey:@"linkData"], @"The fallback open must be unattributed: no linkData.");
    }

    [self restoreRealRequestQueue];
    preferenceHelper.timeout = originalTimeout;
}

// Behavior 3 (EMT-3893, SDK layer only): once the attributed open's own response settles,
// referringURL is cleared, so a subsequent open with no new link does not carry the
// previous link forward. Does NOT prove/disprove server-side stickiness (out of scope).
- (void)testResolvedLinkDoesNotStickToSubsequentOpen {
    NSString *linkURL = @"https://example.app.link/behavioral-sticky-check";
    BNCPreferenceHelper *preferenceHelper = [BNCPreferenceHelper sharedInstance];
    preferenceHelper.attributionLevel = BranchAttributionLevelFull;

    [self.branch handleUniversalDeepLink_private:linkURL sceneIdentifier:nil];
    [self.branch cancelDeepLinkOpenFallback];
    XCTAssertEqualObjects(preferenceHelper.referringURL, linkURL);

    // The attributed open's own response settling is what clears referringURL today. Use an
    // isolated request instance (nil callback) so this assertion-only step doesn't also
    // trigger the production completion path's async main-queue side effects on the shared
    // Branch singleton.
    BranchRequestOpen *attributedOpenRequest = [[BranchRequestOpen alloc] initWithCallback:nil];
    attributedOpenRequest.urlString = nil;
    attributedOpenRequest.linkData = [self stubDeepLinkResponseForLink:linkURL].data;
    [attributedOpenRequest processResponse:[self stubGenericOpenResponse] error:nil];
    XCTAssertNil(preferenceHelper.referringURL,
                 @"EMT-3893 (SDK layer): referringURL must be cleared once the attributed open settles, not held sticky.");

    // A subsequent open with no new link (e.g. organic foreground) must not carry the
    // previous link forward.
    BNCServerRequestQueue *fakeQueue = [self installFakeRequestQueue];

    [self.branch sendOpen];

    NSArray<NSOperation *> *ops = [self requestOperationsIn:fakeQueue];
    XCTAssertEqual(ops.count, 1u);
    if (ops.count == 1) {
        id request = [ops.firstObject valueForKey:@"request"];
        XCTAssertNil([request valueForKey:@"urlString"], @"A subsequent organic open must not carry the previous link's URL.");
        XCTAssertNil([request valueForKey:@"linkData"], @"A subsequent organic open must not carry the previous link's data.");
    }

    [self restoreRealRequestQueue];
}

// Behavior 4 (ordering risk, FIXED): requestDeepLinkData resolving a link BEFORE
// handleUniversalDeepLink_private is invoked for that same link. This can legitimately
// happen (e.g. a host app resolving from scene-connection options before UIKit separately
// delivers the universal link). Regression test for the fix: handleUniversalDeepLink_private
// now recognizes (via lastAttributedDeepLinkURL) that this exact link was already attributed
// by the earlier resolution and does not re-arm the deferred-open fallback, so only ONE open
// total is ever emitted — previously this double-emitted (1 attributed + 1 unattributed
// fallback).
- (void)testRequestDeepLinkDataBeforeUniversalDeepLinkEmitsExactlyOneOpen {
    NSString *linkURL = @"https://example.app.link/behavioral-ordering-edge";
    BNCPreferenceHelper *preferenceHelper = [BNCPreferenceHelper sharedInstance];
    preferenceHelper.attributionLevel = BranchAttributionLevelFull;
    NSTimeInterval originalTimeout = preferenceHelper.timeout;
    preferenceHelper.timeout = 0.2;

    BNCServerRequestQueue *fakeQueue = [self installFakeRequestQueue];

    // 1) requestDeepLinkData resolves FIRST — the attributed open fires on its own.
    [self.branch cancelDeepLinkOpenFallback];
    BranchRequestDeepLink *deepLinkRequest = [[BranchRequestDeepLink alloc] initWithCallback:nil];
    deepLinkRequest.urlString = linkURL;
    [deepLinkRequest processResponse:[self stubDeepLinkResponseForLink:linkURL] error:nil];

    NSArray<NSOperation *> *afterResolution = [self requestOperationsIn:fakeQueue];
    XCTAssertEqual(afterResolution.count, 1u, @"The early resolution alone must still emit exactly one attributed open.");

    // 2) handleUniversalDeepLink_private fires AFTER, for the same (already-attributed)
    // link. The fix: it must recognize that and skip arming the deferred-open fallback.
    [self.branch handleUniversalDeepLink_private:linkURL sceneIdentifier:nil];
    XCTAssertFalse(self.branch.deepLinkOpenPending,
                    @"A link already attributed via an earlier resolution must not re-arm the deferred-open fallback.");

    // Deterministically prove no SECOND open ever appears — an inverted expectation, not a
    // blind sleep: it only fails if a second open actually shows up within the window, so
    // there is no false-negative risk from finishing "too fast".
    NSPredicate *secondOpenEnqueued = [NSPredicate predicateWithBlock:^BOOL(id evaluatedObject, NSDictionary *bindings) {
        return [self requestOperationsIn:fakeQueue].count > 1;
    }];
    XCTNSPredicateExpectation *noSecondOpen = [[XCTNSPredicateExpectation alloc] initWithPredicate:secondOpenEnqueued object:self];
    noSecondOpen.inverted = YES;
    [self waitForExpectations:@[noSecondOpen] timeout:0.5];

    NSArray<NSOperation *> *afterSecondCall = [self requestOperationsIn:fakeQueue];
    XCTAssertEqual(afterSecondCall.count, 1u,
                    @"EMT-3892 ordering fix: resolving before handleUniversalDeepLink_private must still emit exactly ONE open total, not a duplicate.");

    [self restoreRealRequestQueue];
    preferenceHelper.timeout = originalTimeout;
}

@end
