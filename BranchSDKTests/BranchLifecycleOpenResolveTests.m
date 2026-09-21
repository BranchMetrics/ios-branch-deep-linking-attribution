//
//  BranchLifecycleOpenResolveTests.m
//  BranchSDKTests
//
//  Copyright © 2026 Branch, Inc. All rights reserved.
//
//  How many /v3/events/open a foreground sends around a /v3/deeplink resolve, against a real
//  BNCServerRequestQueue with the transport stubbed. The outcome turns on whether the resolve is
//  still queued when -applicationDidBecomeActive reads the queue.
//

#import <XCTest/XCTest.h>
#import <UIKit/UIKit.h>
#import "Branch.h"
#import "BranchConfiguration.h"
#import "BranchConstants.h"
#import "BNCPreferenceHelper.h"
#import "BNCServerInterface.h"
#import "BNCServerRequestQueue.h"
#import "BNCServerResponse.h"
#import "BranchOpenRequest.h"
#import "BranchRequestOpen.h"
#import "BranchRequestDeepLink.h"

@interface Branch (LifecycleOpenResolveTest)
+ (void)resetInitializationGuardForTesting;
+ (BOOL)automaticOpenTrackingDisabled;
- (void)applicationDidBecomeActive;
- (void)applicationWillResignActive;
@end

@interface BNCServerRequestQueue (LifecycleOpenResolveTest)
@property (strong, nonatomic) NSOperationQueue *operationQueue;
@property (copy, nonatomic) NSString *branchKey;
@end

static NSString * const kDeepLinkEndpoint = @"/v3/deeplink";
static NSString * const kOpenEndpoint = @"/v3/events/open";

static NSString * const kResolvedLinkURL = @"https://example.app.link/lifecycle-open-resolve";

// A resolve chains its own open only when the response carries ~referring_link. These two
// payloads are the only difference between the two tests below.
static NSString * const kLinkPayloadJSON =
    @"{\"+clicked_branch_link\":true,\"+is_first_session\":false,"
     "\"$canonical_identifier\":\"content/4362\",\"~campaign\":\"lifecycle open\","
     "\"~referring_link\":\"https://example.app.link/lifecycle-open-resolve\"}";
static NSString * const kOrganicPayloadJSON =
    @"{\"+clicked_branch_link\":false,\"+is_first_session\":false}";

static NSString * const kRecordURLKey = @"url";
static NSString * const kRecordBodyKey = @"body";

typedef NS_ENUM(NSInteger, BranchResolveStubMode) {
    BranchResolveStubModeLinkPayload,
    BranchResolveStubModeOrganicPayload
};

#pragma mark - Stub transport

/// Records every request the SDK posted, in execution order, and answers /v3/deeplink according
/// to -deepLinkMode. Every other endpoint gets the session credentials a real open returns.
@interface BranchResolveStubServerInterface : BNCServerInterface
@property (assign, atomic) BranchResolveStubMode deepLinkMode;
/// Each entry is @{ kRecordURLKey: NSString, kRecordBodyKey: NSDictionary }.
- (NSArray<NSDictionary *> *)postedRequests;
@end

@implementation BranchResolveStubServerInterface {
    NSMutableArray<NSDictionary *> *_postedRequests;
}

- (instancetype)init {
    if ((self = [super init])) {
        _postedRequests = [NSMutableArray array];
        _deepLinkMode = BranchResolveStubModeOrganicPayload;
    }
    return self;
}

- (void)postRequest:(NSDictionary *)post
                url:(NSString *)url
                key:(NSString *)key
           callback:(BNCServerCallback)callback {
    @synchronized (self) {
        [_postedRequests addObject:@{ kRecordURLKey: url ?: @"", kRecordBodyKey: post ?: @{} }];
    }

    BNCServerResponse *response = [BNCServerResponse new];
    response.statusCode = @200;

    if ([url containsString:kDeepLinkEndpoint]) {
        switch (self.deepLinkMode) {
            case BranchResolveStubModeLinkPayload:
                response.data = @{ BRANCH_RESPONSE_KEY_SESSION_DATA: kLinkPayloadJSON };
                break;
            case BranchResolveStubModeOrganicPayload:
                response.data = @{ BRANCH_RESPONSE_KEY_SESSION_DATA: kOrganicPayloadJSON };
                break;
        }
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

- (NSArray<NSDictionary *> *)postedRequests {
    @synchronized (self) {
        return [_postedRequests copy];
    }
}

@end

#pragma mark - Tests

@interface BranchLifecycleOpenResolveTests : XCTestCase
@property (nonatomic, strong) Branch *branch;
@property (nonatomic, strong) BranchResolveStubServerInterface *stub;
@property (nonatomic, strong) BNCServerRequestQueue *testQueue;
@property (nonatomic, copy) NSString *savedSessionParams;
@property (nonatomic, copy) NSString *savedAttributionLevel;
@property (nonatomic, copy) NSString *savedReferringURL;
@property (nonatomic, copy) NSString *savedBundleToken;
@property (nonatomic, copy) NSString *savedDeviceToken;
// A resolve that chains nothing runs -clearLinkIdentifiers:, which wipes all seven of these.
@property (nonatomic, copy) NSString *savedLinkClickIdentifier;
@property (nonatomic, copy) NSString *savedSpotlightIdentifier;
@property (nonatomic, copy) NSString *savedUniversalLinkURL;
@property (nonatomic, copy) NSString *savedExternalIntentURI;
@property (nonatomic, copy) NSString *savedInitialReferrer;
@property (nonatomic, copy) NSString *savedUXType;
@property (nonatomic, strong) NSDate *savedURLLoadMs;
@end

@implementation BranchLifecycleOpenResolveTests

- (void)setUp {
    [super setUp];
    // +sharedInstance is nil until the SDK is initialized, and the guard allows that once.
    [Branch resetInitializationGuardForTesting];
    BranchConfiguration *config = [[BranchConfiguration alloc] initWithKey:@"key_live_hcnegAumkH7Kv18M8AOHhfgiohpXq5tB"];
    self.branch = [Branch initialize:config];

    // Branch observes the real UIApplication notifications, and its handlers are the two methods
    // these tests drive by hand. A genuine foreground mid-test enqueues an open indistinguishable
    // from the one under test.
    [self detachLifecycleObservers];

    BNCPreferenceHelper *preferenceHelper = [BNCPreferenceHelper sharedInstance];
    self.savedSessionParams = preferenceHelper.sessionParams;
    self.savedAttributionLevel = preferenceHelper.attributionLevel;
    self.savedReferringURL = preferenceHelper.referringURL;
    self.savedBundleToken = preferenceHelper.randomizedBundleToken;
    self.savedDeviceToken = preferenceHelper.randomizedDeviceToken;
    self.savedLinkClickIdentifier = preferenceHelper.linkClickIdentifier;
    self.savedSpotlightIdentifier = preferenceHelper.spotlightIdentifier;
    self.savedUniversalLinkURL = preferenceHelper.universalLinkUrl;
    self.savedExternalIntentURI = preferenceHelper.externalIntentURI;
    self.savedInitialReferrer = preferenceHelper.initialReferrer;
    self.savedUXType = preferenceHelper.uxType;
    self.savedURLLoadMs = preferenceHelper.urlLoadMs;

    preferenceHelper.sessionParams = nil;
    preferenceHelper.referringURL = nil;
    preferenceHelper.attributionLevel = BranchAttributionLevelFull;

    // -sendOpen reads isInstall as !randomizedBundleToken, so without a fixed value the open
    // would take the install path, and its SKAdNetwork and app-group work, on whichever test
    // happens to run first.
    preferenceHelper.randomizedBundleToken = @"lifecycle_open_resolve_bundle_token";
    preferenceHelper.randomizedDeviceToken = @"lifecycle_open_resolve_device_token";

    // Suspended, so the interleaving can be arranged deterministically.
    self.stub = [BranchResolveStubServerInterface new];
    BNCServerRequestQueue *sharedQueue = [BNCServerRequestQueue getInstance];
    self.testQueue = [BNCServerRequestQueue new];
    [self.testQueue configureWithServerInterface:self.stub
                                       branchKey:sharedQueue.branchKey
                                preferenceHelper:preferenceHelper];
    self.testQueue.operationQueue.suspended = YES;

    [self absorbPendingIsolationQueueWork];
    [self.branch setValue:self.testQueue forKey:@"requestQueue"];

    XCTAssertEqualObjects([self enqueuedRequestClassNames], @[],
                          @"Precondition: the queue under test must start empty.");
    XCTAssertEqualObjects(preferenceHelper.attributionLevel, BranchAttributionLevelFull,
                          @"Precondition: attribution must not be None, or the open is suppressed for an unrelated reason.");
    XCTAssertFalse([Branch automaticOpenTrackingDisabled],
                   @"Precondition: automatic open tracking must be on, or -applicationDidBecomeActive returns before it reads the queue.");
}

- (void)tearDown {
    // applicationWillResignActive suspends the open lock and every resolve start suspends the
    // deep link lock. getLatestReferringParamsSynchronous waits on both, so leaving either
    // suspended hangs a later test rather than failing it.
    [BranchOpenRequest releaseOpenResponseLock];
    [BranchRequestOpen releaseOpenResponseLock];
    [BranchRequestDeepLink releaseDeepLinkResponseLock];

    BNCPreferenceHelper *preferenceHelper = [BNCPreferenceHelper sharedInstance];
    preferenceHelper.sessionParams = self.savedSessionParams;
    preferenceHelper.attributionLevel = self.savedAttributionLevel;
    preferenceHelper.referringURL = self.savedReferringURL;
    preferenceHelper.randomizedBundleToken = self.savedBundleToken;
    preferenceHelper.randomizedDeviceToken = self.savedDeviceToken;
    preferenceHelper.linkClickIdentifier = self.savedLinkClickIdentifier;
    preferenceHelper.spotlightIdentifier = self.savedSpotlightIdentifier;
    preferenceHelper.universalLinkUrl = self.savedUniversalLinkURL;
    preferenceHelper.externalIntentURI = self.savedExternalIntentURI;
    preferenceHelper.initialReferrer = self.savedInitialReferrer;
    preferenceHelper.uxType = self.savedUXType;
    preferenceHelper.urlLoadMs = self.savedURLLoadMs;

    // The open callback chain finishes on main. Spin before handing the singleton back, so a
    // block still pending cannot enqueue into the real queue.
    [[NSRunLoop currentRunLoop] runUntilDate:[NSDate dateWithTimeIntervalSinceNow:0.05]];

    [self.branch setValue:[BNCServerRequestQueue getInstance] forKey:@"requestQueue"];

    // Nothing but BNCServerRequestOperation reaches this queue today, so this asserts nothing
    // yet. It is here for the deferred check the later pieces add.
    XCTAssertEqualObjects([self enqueuedNonRequestClassNames], @[],
                          @"The queue under test must hold no operation other than BNCServerRequestOperation.");

    [self.testQueue.operationQueue cancelAllOperations];
    self.testQueue = nil;
    self.stub = nil;

    [self reattachLifecycleObservers];

    self.branch = nil;
    [super tearDown];
}

#pragma mark - Isolating the shared singleton

// A block already sitting on the shared isolation queue reads branch.requestQueue when it runs
// rather than when it was dispatched, so it would enqueue into the queue under test and be
// counted as this test's traffic. Absorbed into a throwaway suspended queue instead.
- (void)absorbPendingIsolationQueueWork {
    BNCServerRequestQueue *absorbingQueue = [BNCServerRequestQueue new];
    absorbingQueue.operationQueue.suspended = YES;
    [self.branch setValue:absorbingQueue forKey:@"requestQueue"];

    [self waitForIsolationQueue:@"pending isolation-queue work to run"];

    [absorbingQueue.operationQueue cancelAllOperations];
}

- (void)detachLifecycleObservers {
    NSNotificationCenter *center = [NSNotificationCenter defaultCenter];
    [center removeObserver:self.branch name:UIApplicationWillResignActiveNotification object:nil];
    [center removeObserver:self.branch name:UIApplicationDidBecomeActiveNotification object:nil];
}

// Restores exactly the two registrations the Branch initializer makes. It runs once per process
// behind a dispatch_once, so leaving them detached would silently disarm every later test.
- (void)reattachLifecycleObservers {
    NSNotificationCenter *center = [NSNotificationCenter defaultCenter];
    [center addObserver:self.branch
               selector:@selector(applicationWillResignActive)
                   name:UIApplicationWillResignActiveNotification
                 object:nil];
    [center addObserver:self.branch
               selector:@selector(applicationDidBecomeActive)
                   name:UIApplicationDidBecomeActiveNotification
                 object:nil];
}

#pragma mark - Helpers

// Barrier on the serial isolation queue: a sentinel dispatched after the lifecycle call cannot
// run until that call's block has finished. Waiting on an expectation rather than dispatch_sync
// keeps main servicing, which the chained open needs, since it is enqueued from main.
- (void)waitForIsolationQueue:(NSString *)description {
    XCTestExpectation *sentinel = [[XCTestExpectation alloc] initWithDescription:description];
    [self.branch dispatchToIsolationQueue:^{
        [sentinel fulfill];
    }];
    XCTWaiterResult result = [XCTWaiter waitForExpectations:@[sentinel] timeout:15.0];
    XCTAssertEqual(result, XCTWaiterResultCompleted, @"Timed out waiting for %@.", description);
}

- (void)waitForCondition:(BOOL (^)(void))condition
             description:(NSString *)description
                 timeout:(NSTimeInterval)timeout {
    NSPredicate *predicate = [NSPredicate predicateWithBlock:^BOOL(id evaluatedObject, NSDictionary *bindings) {
        return condition();
    }];
    XCTNSPredicateExpectation *expectation = [[XCTNSPredicateExpectation alloc] initWithPredicate:predicate object:self];
    XCTWaiterResult result = [XCTWaiter waitForExpectations:@[expectation] timeout:timeout];
    XCTAssertEqual(result, XCTWaiterResultCompleted, @"Timed out waiting for %@.", description);
}

- (NSUInteger)enqueuedOperationCount {
    return self.testQueue.operationQueue.operations.count;
}

// This project loads BNCServerRequestOperation from two images at once, so Class-pointer
// identity is unreliable here; name-based matching is not.
- (NSArray *)enqueuedRequests {
    NSMutableArray *requests = [NSMutableArray array];
    for (NSOperation *op in self.testQueue.operationQueue.operations) {
        if (![NSStringFromClass([op class]) isEqualToString:@"BNCServerRequestOperation"]) continue;
        [requests addObject:[op valueForKey:@"request"]];
    }
    return requests;
}

- (NSArray<NSString *> *)enqueuedRequestClassNames {
    NSMutableArray<NSString *> *names = [NSMutableArray array];
    for (id request in [self enqueuedRequests]) {
        [names addObject:NSStringFromClass([request class])];
    }
    return names;
}

- (NSArray<NSString *> *)enqueuedNonRequestClassNames {
    NSMutableArray<NSString *> *names = [NSMutableArray array];
    for (NSOperation *op in self.testQueue.operationQueue.operations) {
        NSString *className = NSStringFromClass([op class]);
        if ([className isEqualToString:@"BNCServerRequestOperation"]) continue;
        [names addObject:className];
    }
    return names;
}

- (NSArray<NSString *> *)postedEndpoints {
    NSMutableArray<NSString *> *endpoints = [NSMutableArray array];
    for (NSDictionary *request in [self.stub postedRequests]) {
        NSString *url = request[kRecordURLKey];
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

- (NSArray<NSDictionary *> *)postedOpenBodies {
    NSMutableArray<NSDictionary *> *bodies = [NSMutableArray array];
    for (NSDictionary *request in [self.stub postedRequests]) {
        if ([request[kRecordURLKey] containsString:kOpenEndpoint]) {
            [bodies addObject:request[kRecordBodyKey]];
        }
    }
    return bodies;
}

- (NSUInteger)postedOpenCount {
    return [self postedOpenBodies].count;
}

// Enqueues the resolve a launch with no link makes, and returns once it is the only thing queued.
- (void)enqueueOrganicResolve {
    [self.branch requestDeepLinkData:nil callback:nil];
    [self waitForCondition:^BOOL{ return [self enqueuedOperationCount] >= 1; }
               description:@"the deep link resolve to be enqueued"
                   timeout:5.0];
    XCTAssertEqualObjects([self enqueuedRequestClassNames], @[@"BranchRequestDeepLink"],
                          @"Precondition: the queued operation must be the deep link resolve, alone.");

    // urlString is nil here, not empty, and it is what decides whether the resolve chains an
    // open. A predicate written as isEqualToString:@"" would collect nothing and still pass.
    BranchRequestDeepLink *resolve = (BranchRequestDeepLink *)[self enqueuedRequests].firstObject;
    XCTAssertEqual(resolve.urlString.length, (NSUInteger)0,
                   @"Precondition: the resolve under test must carry no URL. urlString: %@.", resolve.urlString);
}

// Drives the production foreground path, and returns once the activation handler's block has run.
- (void)foreground {
    [self.branch applicationWillResignActive];
    [self waitForIsolationQueue:@"the resign handler to run"];

    [self.branch applicationDidBecomeActive];
    [self waitForIsolationQueue:@"the foreground handler to run"];
}

- (void)drainQueue {
    self.testQueue.operationQueue.suspended = NO;
    // Polling for an empty queue is safe only because a chained open is enqueued inside
    // -processResponse:, before the resolve calls -finishOperation, so the queue never dips to
    // empty between the resolve leaving and its open arriving.
    [self waitForCondition:^BOOL{ return [self enqueuedOperationCount] == 0; }
               description:@"the request queue to drain"
                   timeout:15.0];
    [[NSRunLoop currentRunLoop] runUntilDate:[NSDate dateWithTimeIntervalSinceNow:0.1]];
}

#pragma mark - Tests

// Guard (e). An organic launch whose resolve drained before the foreground: nothing chained an
// open and the queue is empty, so the foreground must send exactly one.
- (void)testOrganicResolveDrainedBeforeTheForegroundSendsOneOpen {
    self.stub.deepLinkMode = BranchResolveStubModeOrganicPayload;

    [self enqueueOrganicResolve];
    [self drainQueue];

    XCTAssertEqualObjects([self postedEndpoints], @[kDeepLinkEndpoint],
                          @"Precondition: the resolve must not have chained an open of its own.");

    [self foreground];
    [self waitForCondition:^BOOL{ return [self postedOpenCount] >= 1; }
               description:@"the foreground open to reach the wire"
                   timeout:15.0];
    [self drainQueue];

    XCTAssertEqualObjects([self postedEndpoints], (@[kDeepLinkEndpoint, kOpenEndpoint]),
                          @"A foreground with an empty queue must send exactly one open.");
}

// Guard (d). A deferred link: the same nil-URL resolve, but its response carries ~referring_link,
// so it chains its own attributed open. The foreground runs while it is still queued and must add
// nothing, leaving one open on the wire carrying the link payload.
- (void)testDeferredLinkResolveQueuedAtTheForegroundSendsOneOpenCarryingLinkData {
    self.stub.deepLinkMode = BranchResolveStubModeLinkPayload;

    [self enqueueOrganicResolve];
    [self foreground];

    XCTAssertEqualObjects([self enqueuedRequestClassNames], @[@"BranchRequestDeepLink"],
                          @"Precondition: the foreground must have been evaluated while the resolve was queued.");

    [self drainQueue];

    XCTAssertEqualObjects([self postedEndpoints], (@[kDeepLinkEndpoint, kOpenEndpoint]),
                          @"A foreground during a live resolve must not add an open of its own.");

    NSDictionary *linkData = [self postedOpenBodies].firstObject[@"link_data"];
    XCTAssertEqualObjects(linkData[BRANCH_RESPONSE_KEY_BRANCH_REFERRING_LINK], kResolvedLinkURL,
                          @"The open on the wire must be the resolve's own, carrying the resolved link payload.");
}

@end
