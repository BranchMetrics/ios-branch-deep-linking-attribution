//
//  BranchSceneConnectionOptionsTests.m
//  BranchSDKTests
//
//  Copyright © 2026 Branch, Inc. All rights reserved.
//
//  -[Branch requestDeepLinkDataWithSceneOptions:scene:callback:] is the cold, scene-based
//  counterpart to -requestDeepLinkDataWithUserActivity: and
//  -requestDeepLinkDataWithScene:continueUserActivity:, but unlike those two it only resolves a
//  connectionOptions.userActivities entry whose activityType is NSUserActivityTypeBrowsingWeb. A
//  CSSearchableItemActionType activity (a Spotlight tap) falls through that check unhandled.
//
//  Also covers the three other NSUserActivity entry points
//  (-requestDeepLinkDataWithScene:continueUserActivity:, -requestDeepLinkDataWithUserActivity:,
//  -continueUserActivity:sceneIdentifier:): each enqueues the activity's webpageURL, which is
//  never set for a Spotlight activity, so a Spotlight activity whose identifier is itself a
//  Branch link was enqueued with no URL on every one of the four.
//

#import <XCTest/XCTest.h>
#import <UIKit/UIKit.h>
#import <CoreSpotlight/CoreSpotlight.h>
#import "Branch.h"
#import "BranchConfiguration.h"
#import "BranchConstants.h"
#import "BNCPreferenceHelper.h"
#import "BNCServerInterface.h"
#import "BNCServerRequestQueue.h"
#import "BNCServerResponse.h"
#import "BranchRequestDeepLink.h"

// Test-only reset for the +initialize: reinitialization guard (file-private in Branch.m).
@interface Branch (Test)
+ (void)resetInitializationGuardForTesting;
@end

// Lets a test suspend the queue and inspect what was enqueued before it can hit the network, and
// read the shared queue's branchKey to configure a disposable one the same way.
@interface BNCServerRequestQueue (SceneConnectionOptionsTest)
@property (strong, nonatomic) NSOperationQueue *operationQueue;
@property (copy, nonatomic) NSString *branchKey;
@end

// UISceneConnectionOptions has no public initializer: both +new and -init are NS_UNAVAILABLE
// (UISceneOptions.h). +alloc is not, so an instance can still be made by never sending it -init.
// Both accessors the SDK reads are overridden below, so nothing ever reads the superclass's
// (never-run-init) internal state.
@interface BNCTestSceneConnectionOptions : UISceneConnectionOptions
@property (nonatomic, strong) NSSet<NSUserActivity *> *stubbedUserActivities;
@end

@implementation BNCTestSceneConnectionOptions
- (NSSet<NSUserActivity *> *)userActivities {
    return self.stubbedUserActivities ?: [NSSet set];
}
- (NSSet<UIOpenURLContext *> *)URLContexts {
    return [NSSet set];
}
@end

static NSString * const kSpotlightBranchLinkURL = @"https://example.app.link/spotlight-cold-scene-link";
static NSString * const kSpotlightNonBranchIdentifier = @"spotlight-item-not-a-branch-link";
static NSString * const kBrowsingWebBranchLinkURL = @"https://example.app.link/browsing-web-cold-scene-link";
static NSString * const kThirdActivityType = @"com.branch.test.custom-handoff-activity";

static NSString * const kDeepLinkEndpoint = @"/v3/deeplink";
static NSString * const kOpenEndpoint = @"/v3/events/open";

// An organic (no ~referring_link) /v3/deeplink payload. Used deliberately for the endpoint-level
// test below: if that resolve's own open still reaches the wire, it can only be because
// -attemptToSendOpen took its self.urlString.length > 0 branch (BranchRequestDeepLink.m:280-289),
// which is exactly the mechanism the enqueue-carries-the-link fix feeds.
static NSString * const kOrganicDeepLinkPayloadJSON =
    @"{\"+clicked_branch_link\":false,\"+is_first_session\":false}";

// Records every request posted, in order, and answers /v3/deeplink with the organic payload above;
// every other endpoint gets the session credentials a real open response returns.
@interface BranchSceneConnectionOptionsStubServerInterface : BNCServerInterface
- (NSArray<NSString *> *)postedURLs;
@end

@implementation BranchSceneConnectionOptionsStubServerInterface {
    NSMutableArray<NSString *> *_postedURLs;
}

- (instancetype)init {
    if ((self = [super init])) {
        _postedURLs = [NSMutableArray array];
    }
    return self;
}

- (void)postRequest:(NSDictionary *)post
                url:(NSString *)url
                key:(NSString *)key
           callback:(BNCServerCallback)callback {
    @synchronized (self) {
        [_postedURLs addObject:url ?: @""];
    }

    BNCServerResponse *response = [BNCServerResponse new];
    response.statusCode = @200;
    if ([url containsString:kDeepLinkEndpoint]) {
        response.data = @{ BRANCH_RESPONSE_KEY_SESSION_DATA: kOrganicDeepLinkPayloadJSON };
    } else {
        response.data = @{
            BRANCH_RESPONSE_KEY_RANDOMIZED_BUNDLE_TOKEN: @"bundle_token",
            BRANCH_RESPONSE_KEY_RANDOMIZED_DEVICE_TOKEN: @"device_token"
        };
    }

    if (callback) {
        callback(response, nil);
    }
}

- (NSArray<NSString *> *)postedURLs {
    @synchronized (self) {
        return [_postedURLs copy];
    }
}

@end

@interface BranchSceneConnectionOptionsTests : XCTestCase
@property (nonatomic, strong) Branch *branch;
@property (nonatomic, strong) BNCServerRequestQueue *fakeQueue;
@property (nonatomic, copy) NSString *savedSpotlightIdentifier;
// Only the endpoint-level test lets a real queue drain and an open actually run, which writes
// these. Snapshotting them for every test (not only that one) keeps this list in one place and
// costs the other tests nothing, since they never let their queue run at all.
@property (nonatomic, copy) NSString *savedSessionParams;
@property (nonatomic, copy) NSString *savedAttributionLevel;
@property (nonatomic, copy) NSString *savedReferringURL;
@property (nonatomic, copy) NSString *savedBundleToken;
@property (nonatomic, copy) NSString *savedDeviceToken;
@end

@implementation BranchSceneConnectionOptionsTests

- (void)setUp {
    [super setUp];
    // +sharedInstance requires the SDK to be initialized first. Reset the guard so each test can
    // (re)initialize the singleton, then configure it via the canonical entry point.
    [Branch resetInitializationGuardForTesting];
    BranchConfiguration *config = [[BranchConfiguration alloc] initWithKey:@"key_live_hcnegAumkH7Kv18M8AOHhfgiohpXq5tB"];
    self.branch = [Branch initialize:config];

    BNCPreferenceHelper *preferenceHelper = [BNCPreferenceHelper sharedInstance];
    self.savedSpotlightIdentifier = preferenceHelper.spotlightIdentifier;
    self.savedSessionParams = preferenceHelper.sessionParams;
    self.savedAttributionLevel = preferenceHelper.attributionLevel;
    self.savedReferringURL = preferenceHelper.referringURL;
    self.savedBundleToken = preferenceHelper.randomizedBundleToken;
    self.savedDeviceToken = preferenceHelper.randomizedDeviceToken;

    preferenceHelper.spotlightIdentifier = nil;
    preferenceHelper.sessionParams = nil;
    preferenceHelper.referringURL = nil;
    // Deterministic regardless of ambient state: sendOpen is a no-op at level None, and reading
    // isInstall as !randomizedBundleToken would otherwise take the install path on whichever test
    // happens to run first.
    preferenceHelper.attributionLevel = BranchAttributionLevelFull;
    preferenceHelper.randomizedBundleToken = @"scene_connection_options_bundle_token";
    preferenceHelper.randomizedDeviceToken = @"scene_connection_options_device_token";

    // A disposable, permanently-suspended queue. Requests enqueued during a test can be read
    // back without touching the network. Never cancel or resume it -- cancelling a suspended,
    // never-started BNCServerRequestOperation trips an NSOperationQueue consistency check.
    self.fakeQueue = [BNCServerRequestQueue new];
    self.fakeQueue.operationQueue.suspended = YES;
    [self.branch setValue:self.fakeQueue forKey:@"requestQueue"];
}

- (void)tearDown {
    [self.branch setValue:[BNCServerRequestQueue getInstance] forKey:@"requestQueue"];
    self.fakeQueue = nil;

    BNCPreferenceHelper *preferenceHelper = [BNCPreferenceHelper sharedInstance];
    preferenceHelper.spotlightIdentifier = self.savedSpotlightIdentifier;
    preferenceHelper.sessionParams = self.savedSessionParams;
    preferenceHelper.attributionLevel = self.savedAttributionLevel;
    preferenceHelper.referringURL = self.savedReferringURL;
    preferenceHelper.randomizedBundleToken = self.savedBundleToken;
    preferenceHelper.randomizedDeviceToken = self.savedDeviceToken;

    // Drains any already-scheduled async block (the endpoint-level test's open callback) against
    // this clean baseline.
    [[NSRunLoop currentRunLoop] runUntilDate:[NSDate dateWithTimeIntervalSinceNow:0.05]];

    self.branch = nil;
    [super tearDown];
}

#pragma mark - Helpers

// The host app's default scene can still be connecting when the first test method in a run
// starts executing, so a single unconditional read of -connectedScenes can race it. Polling
// avoids a spurious precondition failure that has nothing to do with the code under test.
- (UIScene *)waitForConnectedScene {
    NSPredicate *predicate = [NSPredicate predicateWithBlock:^BOOL(id evaluatedObject, NSDictionary *bindings) {
        return [UIApplication sharedApplication].connectedScenes.anyObject != nil;
    }];
    XCTNSPredicateExpectation *expectation = [[XCTNSPredicateExpectation alloc] initWithPredicate:predicate object:self];
    XCTWaiterResult result = [XCTWaiter waitForExpectations:@[expectation] timeout:15.0];
    XCTAssertEqual(result, XCTWaiterResultCompleted, @"Timed out waiting for the test host app to connect a scene.");
    return [UIApplication sharedApplication].connectedScenes.anyObject;
}

// This project loads BNCServerRequestOperation from two images at once, so Class-pointer
// identity is unreliable here; name-based matching is not.
- (NSArray<BNCServerRequest *> *)enqueuedRequestsOfClassNamed:(NSString *)className {
    NSMutableArray<BNCServerRequest *> *requests = [NSMutableArray array];
    for (NSOperation *op in self.fakeQueue.operationQueue.operations) {
        if (![NSStringFromClass([op class]) isEqualToString:@"BNCServerRequestOperation"]) continue;
        BNCServerRequest *request = [op valueForKey:@"request"];
        if ([NSStringFromClass([request class]) isEqualToString:className]) {
            [requests addObject:request];
        }
    }
    return requests;
}

- (NSArray<NSString *> *)postedEndpointsFromURLs:(NSArray<NSString *> *)urls {
    NSMutableArray<NSString *> *endpoints = [NSMutableArray array];
    for (NSString *url in urls) {
        if ([url containsString:kDeepLinkEndpoint]) {
            [endpoints addObject:kDeepLinkEndpoint];
        } else if ([url containsString:kOpenEndpoint]) {
            [endpoints addObject:kOpenEndpoint];
        } else {
            [endpoints addObject:url];
        }
    }
    return endpoints;
}

#pragma mark - Tests

// A Spotlight tap that cold-launches a scene-based app must resolve the same as the warm scene
// path (-requestDeepLinkDataWithScene:continueUserActivity:) and the legacy app-delegate path
// (-requestDeepLinkDataWithUserActivity:) already do for the identical activity. The
// NSUserActivityTypeBrowsingWeb-only check in -requestDeepLinkDataWithSceneOptions:scene:callback:
// means a CSSearchableItemActionType activity is never passed to
// -processUserActivity:sceneIdentifier:filtered:, and nothing is enqueued. Red today.
- (void)testSpotlightActivityWithBranchLinkOnColdSceneConnectEnqueuesExactlyOneDeepLinkRequest {
    UIScene *scene = [self waitForConnectedScene];

    NSUserActivity *activity = [[NSUserActivity alloc] initWithActivityType:CSSearchableItemActionType];
    activity.userInfo = @{ CSSearchableItemActivityIdentifier: kSpotlightBranchLinkURL };

    BNCTestSceneConnectionOptions *options = [BNCTestSceneConnectionOptions alloc]; // no -init; see the class comment above.
    options.stubbedUserActivities = [NSSet setWithObject:activity];

    [self.branch requestDeepLinkDataWithSceneOptions:options scene:scene callback:nil];

    NSArray<BNCServerRequest *> *enqueued = [self enqueuedRequestsOfClassNamed:@"BranchRequestDeepLink"];
    XCTAssertEqual(enqueued.count, (NSUInteger)1,
                  @"A Spotlight activity carrying a Branch link on a cold scene connect must enqueue exactly one deep link request. Enqueued: %@", enqueued);

    BranchRequestDeepLink *resolve = (BranchRequestDeepLink *)enqueued.firstObject;
    XCTAssertEqualObjects(resolve.urlString, kSpotlightBranchLinkURL,
                          @"The enqueued request must carry the Spotlight activity's Branch link.");
}

// A Spotlight activity whose identifier is not a Branch link still has to be recorded and
// resolved, the same as -requestDeepLinkDataWithScene:continueUserActivity: already does for the
// identical activity (Branch.m:2245-2249): the identifier goes to
// preferenceHelper.spotlightIdentifier and a deferred, nil-URL lookup is enqueued rather than the
// activity being dropped outright. Red today for the same reason as the Branch-link case above:
// the NSUserActivityTypeBrowsingWeb-only check means -processUserActivity: is never called.
- (void)testSpotlightActivityWithNonBranchIdentifierRecordsIdentifierAndEnqueuesNilURLLookup {
    UIScene *scene = [self waitForConnectedScene];

    NSUserActivity *activity = [[NSUserActivity alloc] initWithActivityType:CSSearchableItemActionType];
    activity.userInfo = @{ CSSearchableItemActivityIdentifier: kSpotlightNonBranchIdentifier };

    BNCTestSceneConnectionOptions *options = [BNCTestSceneConnectionOptions alloc]; // no -init; see the class comment above.
    options.stubbedUserActivities = [NSSet setWithObject:activity];

    [self.branch requestDeepLinkDataWithSceneOptions:options scene:scene callback:nil];

    XCTAssertEqualObjects([BNCPreferenceHelper sharedInstance].spotlightIdentifier, kSpotlightNonBranchIdentifier,
                          @"A non-Branch Spotlight identifier on a cold scene connect must still be recorded.");

    NSArray<BNCServerRequest *> *enqueued = [self enqueuedRequestsOfClassNamed:@"BranchRequestDeepLink"];
    XCTAssertEqual(enqueued.count, (NSUInteger)1,
                  @"A non-Branch Spotlight activity on a cold scene connect must still enqueue the deferred, nil-URL lookup. Enqueued: %@", enqueued);

    BranchRequestDeepLink *resolve = (BranchRequestDeepLink *)enqueued.firstObject;
    XCTAssertNil(resolve.urlString,
                @"A non-Branch Spotlight activity carries no URL to resolve, matching -requestDeepLinkDataWithScene:continueUserActivity:'s nil-URL lookup.");
}

// Guard: the case that already works must keep working. A web-browsing activity carrying a
// Branch link is the one activity type -requestDeepLinkDataWithSceneOptions:scene:callback:
// already resolves today, and this must stay true whichever way the Spotlight gap above ends up
// fixed. Green now.
- (void)testWebBrowsingActivityWithBranchLinkOnColdSceneConnectEnqueuesExactlyOneDeepLinkRequest {
    UIScene *scene = [self waitForConnectedScene];

    NSUserActivity *activity = [[NSUserActivity alloc] initWithActivityType:NSUserActivityTypeBrowsingWeb];
    activity.webpageURL = [NSURL URLWithString:kBrowsingWebBranchLinkURL];

    BNCTestSceneConnectionOptions *options = [BNCTestSceneConnectionOptions alloc]; // no -init; see the class comment above.
    options.stubbedUserActivities = [NSSet setWithObject:activity];

    [self.branch requestDeepLinkDataWithSceneOptions:options scene:scene callback:nil];

    NSArray<BNCServerRequest *> *enqueued = [self enqueuedRequestsOfClassNamed:@"BranchRequestDeepLink"];
    XCTAssertEqual(enqueued.count, (NSUInteger)1,
                  @"A web-browsing activity carrying a Branch link on a cold scene connect must enqueue exactly one deep link request. Enqueued: %@", enqueued);

    BranchRequestDeepLink *resolve = (BranchRequestDeepLink *)enqueued.firstObject;
    XCTAssertEqualObjects(resolve.urlString, kBrowsingWebBranchLinkURL,
                          @"The enqueued request must carry the web-browsing activity's Branch link.");
}

#pragma mark - Tests: the three other NSUserActivity entry points

// The warm scene path already resolves a Spotlight activity (unlike the cold path above before its
// fix), but only bookkeeping-wise: it enqueues activity.webpageURL, nil for every Spotlight
// activity, so a Branch-link identifier was silently dropped here too.
- (void)testSpotlightActivityWithBranchLinkViaWarmSceneContinueUserActivityEnqueuesExactlyOneDeepLinkRequest {
    UIScene *scene = [self waitForConnectedScene];

    NSUserActivity *activity = [[NSUserActivity alloc] initWithActivityType:CSSearchableItemActionType];
    activity.userInfo = @{ CSSearchableItemActivityIdentifier: kSpotlightBranchLinkURL };

    [self.branch requestDeepLinkDataWithScene:scene continueUserActivity:activity];

    NSArray<BNCServerRequest *> *enqueued = [self enqueuedRequestsOfClassNamed:@"BranchRequestDeepLink"];
    XCTAssertEqual(enqueued.count, (NSUInteger)1,
                  @"A Spotlight activity carrying a Branch link via the warm scene path must enqueue exactly one deep link request. Enqueued: %@", enqueued);

    BranchRequestDeepLink *resolve = (BranchRequestDeepLink *)enqueued.firstObject;
    XCTAssertEqualObjects(resolve.urlString, kSpotlightBranchLinkURL,
                          @"The enqueued request must carry the Spotlight activity's Branch link.");
}

// Guard: the warm scene path's existing web-browsing behaviour is unchanged.
- (void)testWebBrowsingActivityViaWarmSceneContinueUserActivityEnqueuesExactlyOneDeepLinkRequest {
    UIScene *scene = [self waitForConnectedScene];

    NSUserActivity *activity = [[NSUserActivity alloc] initWithActivityType:NSUserActivityTypeBrowsingWeb];
    activity.webpageURL = [NSURL URLWithString:kBrowsingWebBranchLinkURL];

    [self.branch requestDeepLinkDataWithScene:scene continueUserActivity:activity];

    NSArray<BNCServerRequest *> *enqueued = [self enqueuedRequestsOfClassNamed:@"BranchRequestDeepLink"];
    XCTAssertEqual(enqueued.count, (NSUInteger)1,
                  @"A web-browsing activity via the warm scene path must enqueue exactly one deep link request. Enqueued: %@", enqueued);

    BranchRequestDeepLink *resolve = (BranchRequestDeepLink *)enqueued.firstObject;
    XCTAssertEqualObjects(resolve.urlString, kBrowsingWebBranchLinkURL,
                          @"The enqueued request must carry the web-browsing activity's Branch link.");
}

// The legacy app-delegate path (application:continueUserActivity:restorationHandler:) has the same
// webpageURL-only gap as the warm scene path above.
- (void)testSpotlightActivityWithBranchLinkViaRequestDeepLinkDataWithUserActivityEnqueuesExactlyOneDeepLinkRequest {
    NSUserActivity *activity = [[NSUserActivity alloc] initWithActivityType:CSSearchableItemActionType];
    activity.userInfo = @{ CSSearchableItemActivityIdentifier: kSpotlightBranchLinkURL };

    [self.branch requestDeepLinkDataWithUserActivity:activity];

    NSArray<BNCServerRequest *> *enqueued = [self enqueuedRequestsOfClassNamed:@"BranchRequestDeepLink"];
    XCTAssertEqual(enqueued.count, (NSUInteger)1,
                  @"A Spotlight activity carrying a Branch link via -requestDeepLinkDataWithUserActivity: must enqueue exactly one deep link request. Enqueued: %@", enqueued);

    BranchRequestDeepLink *resolve = (BranchRequestDeepLink *)enqueued.firstObject;
    XCTAssertEqualObjects(resolve.urlString, kSpotlightBranchLinkURL,
                          @"The enqueued request must carry the Spotlight activity's Branch link.");
}

// Guard: -requestDeepLinkDataWithUserActivity:'s existing web-browsing behaviour is unchanged.
- (void)testWebBrowsingActivityViaRequestDeepLinkDataWithUserActivityEnqueuesExactlyOneDeepLinkRequest {
    NSUserActivity *activity = [[NSUserActivity alloc] initWithActivityType:NSUserActivityTypeBrowsingWeb];
    activity.webpageURL = [NSURL URLWithString:kBrowsingWebBranchLinkURL];

    [self.branch requestDeepLinkDataWithUserActivity:activity];

    NSArray<BNCServerRequest *> *enqueued = [self enqueuedRequestsOfClassNamed:@"BranchRequestDeepLink"];
    XCTAssertEqual(enqueued.count, (NSUInteger)1,
                  @"A web-browsing activity via -requestDeepLinkDataWithUserActivity: must enqueue exactly one deep link request. Enqueued: %@", enqueued);

    BranchRequestDeepLink *resolve = (BranchRequestDeepLink *)enqueued.firstObject;
    XCTAssertEqualObjects(resolve.urlString, kBrowsingWebBranchLinkURL,
                          @"The enqueued request must carry the web-browsing activity's Branch link.");
}

// -continueUserActivity:sceneIdentifier: (the tvOS scene branch and the public BOOL-returning
// entry point) has the same webpageURL-only gap as the other three.
- (void)testSpotlightActivityWithBranchLinkViaContinueUserActivitySceneIdentifierEnqueuesExactlyOneDeepLinkRequest {
    NSUserActivity *activity = [[NSUserActivity alloc] initWithActivityType:CSSearchableItemActionType];
    activity.userInfo = @{ CSSearchableItemActivityIdentifier: kSpotlightBranchLinkURL };

    [self.branch continueUserActivity:activity sceneIdentifier:nil];

    NSArray<BNCServerRequest *> *enqueued = [self enqueuedRequestsOfClassNamed:@"BranchRequestDeepLink"];
    XCTAssertEqual(enqueued.count, (NSUInteger)1,
                  @"A Spotlight activity carrying a Branch link via -continueUserActivity:sceneIdentifier: must enqueue exactly one deep link request. Enqueued: %@", enqueued);

    BranchRequestDeepLink *resolve = (BranchRequestDeepLink *)enqueued.firstObject;
    XCTAssertEqualObjects(resolve.urlString, kSpotlightBranchLinkURL,
                          @"The enqueued request must carry the Spotlight activity's Branch link.");
}

// Guard: -continueUserActivity:sceneIdentifier:'s existing web-browsing behaviour is unchanged.
- (void)testWebBrowsingActivityViaContinueUserActivitySceneIdentifierEnqueuesExactlyOneDeepLinkRequest {
    NSUserActivity *activity = [[NSUserActivity alloc] initWithActivityType:NSUserActivityTypeBrowsingWeb];
    activity.webpageURL = [NSURL URLWithString:kBrowsingWebBranchLinkURL];

    [self.branch continueUserActivity:activity sceneIdentifier:nil];

    NSArray<BNCServerRequest *> *enqueued = [self enqueuedRequestsOfClassNamed:@"BranchRequestDeepLink"];
    XCTAssertEqual(enqueued.count, (NSUInteger)1,
                  @"A web-browsing activity via -continueUserActivity:sceneIdentifier: must enqueue exactly one deep link request. Enqueued: %@", enqueued);

    BranchRequestDeepLink *resolve = (BranchRequestDeepLink *)enqueued.firstObject;
    XCTAssertEqualObjects(resolve.urlString, kBrowsingWebBranchLinkURL,
                          @"The enqueued request must carry the web-browsing activity's Branch link.");
}

#pragma mark - Tests: endpoint level and a third activity type

// Closes the loop from enqueue to the wire: a Spotlight activity's Branch link, once enqueued
// with the fix above, reaches the resolve's own open via -attemptToSendOpen's
// self.urlString.length > 0 branch (BranchRequestDeepLink.m:280-289) -- proved here by answering
// /v3/deeplink with an ORGANIC payload (no ~referring_link) and still seeing exactly one open.
// Mirrors how BranchLifecycleOpenResolveTests.m:528-551 drives a real queue against a stub
// transport and asserts on postedEndpoints, adapted for a resolve that chains its own open
// directly rather than one queued behind a lifecycle foreground.
- (void)testSpotlightActivityWithBranchLinkOnColdSceneConnectPostsDeepLinkThenOpen {
    UIScene *scene = [self waitForConnectedScene];

    NSUserActivity *activity = [[NSUserActivity alloc] initWithActivityType:CSSearchableItemActionType];
    activity.userInfo = @{ CSSearchableItemActivityIdentifier: kSpotlightBranchLinkURL };

    BNCTestSceneConnectionOptions *options = [BNCTestSceneConnectionOptions alloc]; // no -init; see the class comment above.
    options.stubbedUserActivities = [NSSet setWithObject:activity];

    BranchSceneConnectionOptionsStubServerInterface *stub = [BranchSceneConnectionOptionsStubServerInterface new];
    BNCServerRequestQueue *drainingQueue = [BNCServerRequestQueue new];
    [drainingQueue configureWithServerInterface:stub
                                       branchKey:[BNCServerRequestQueue getInstance].branchKey
                                preferenceHelper:[BNCPreferenceHelper sharedInstance]];
    // Suspended until the activity is handed in, so the interleaving is deterministic.
    drainingQueue.operationQueue.suspended = YES;
    [self.branch setValue:drainingQueue forKey:@"requestQueue"];

    [self.branch requestDeepLinkDataWithSceneOptions:options scene:scene callback:nil];

    drainingQueue.operationQueue.suspended = NO;
    NSPredicate *predicate = [NSPredicate predicateWithBlock:^BOOL(id evaluatedObject, NSDictionary *bindings) {
        return drainingQueue.operationQueue.operations.count == 0;
    }];
    XCTNSPredicateExpectation *expectation = [[XCTNSPredicateExpectation alloc] initWithPredicate:predicate object:self];
    XCTWaiterResult result = [XCTWaiter waitForExpectations:@[expectation] timeout:15.0];
    XCTAssertEqual(result, XCTWaiterResultCompleted, @"Timed out waiting for the request queue to drain.");
    // -attemptToSendOpen enqueues the open from inside -processResponse:, before the resolve
    // itself finishes, so the queue never dips to empty between the resolve leaving and the open
    // arriving; a second, short spin is still worth taking to let its posted URL land.
    [[NSRunLoop currentRunLoop] runUntilDate:[NSDate dateWithTimeIntervalSinceNow:0.1]];

    XCTAssertEqualObjects([self postedEndpointsFromURLs:[stub postedURLs]], (@[kDeepLinkEndpoint, kOpenEndpoint]),
                          @"A Spotlight activity's Branch link must resolve, then send exactly one attributed open, in that order. Posted: %@", [stub postedURLs]);
}

// A third activity type, neither web-browsing nor Spotlight, must not crash and must still
// enqueue the existing deferred, nil-URL lookup: the same behaviour the other three entry points
// already have for anything -processUserActivity: does not recognise.
- (void)testThirdActivityTypeOnColdSceneConnectEnqueuesNilURLLookupWithoutCrashing {
    UIScene *scene = [self waitForConnectedScene];

    NSUserActivity *activity = [[NSUserActivity alloc] initWithActivityType:kThirdActivityType];

    BNCTestSceneConnectionOptions *options = [BNCTestSceneConnectionOptions alloc]; // no -init; see the class comment above.
    options.stubbedUserActivities = [NSSet setWithObject:activity];

    [self.branch requestDeepLinkDataWithSceneOptions:options scene:scene callback:nil];

    NSArray<BNCServerRequest *> *enqueued = [self enqueuedRequestsOfClassNamed:@"BranchRequestDeepLink"];
    XCTAssertEqual(enqueued.count, (NSUInteger)1,
                  @"A third activity type on a cold scene connect must still enqueue the deferred, nil-URL lookup. Enqueued: %@", enqueued);

    BranchRequestDeepLink *resolve = (BranchRequestDeepLink *)enqueued.firstObject;
    XCTAssertNil(resolve.urlString,
                @"A third activity type carries neither a webpage URL nor a Spotlight identifier to resolve.");
}

@end
