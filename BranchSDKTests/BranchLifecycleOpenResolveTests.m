//
//  BranchLifecycleOpenResolveTests.m
//  BranchSDKTests
//
//  Copyright © 2026 Branch, Inc. All rights reserved.
//
//  How many /v3/events/open a foreground sends while a /v3/deeplink resolve is around, measured
//  against a real BNCServerRequestQueue with a stubbed transport: real operations, real serial
//  ordering, no network.
//
//  The two cases here are the base behaviours that must not change. -applicationDidBecomeActive
//  reads the queue and sends an organic open only when nothing init-shaped is in it, so the
//  outcome turns on whether the resolve is still queued when that read happens: drained (the
//  foreground owns the open) or queued (the resolve owns it).
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

// Test-only entry points, all file-private to Branch.m. Driving the lifecycle handlers rather
// than calling -sendOpen directly is what makes the interleaving real rather than staged.
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

// A resolve whose response carries ~referring_link chains its own attributed open; one without it
// chains nothing. These two payloads are the only difference between the two tests below.
static NSString * const kLinkPayloadJSON =
    @"{\"+clicked_branch_link\":true,\"+is_first_session\":false,"
     "\"$canonical_identifier\":\"content/4362\",\"~campaign\":\"lifecycle open\","
     "\"~referring_link\":\"https://example.app.link/lifecycle-open-resolve\"}";
static NSString * const kOrganicPayloadJSON =
    @"{\"+clicked_branch_link\":false,\"+is_first_session\":false}";

static NSString * const kRecordURLKey = @"url";
static NSString * const kRecordBodyKey = @"body";

typedef NS_ENUM(NSInteger, BranchResolveStubMode) {
    /// /v3/deeplink answers with a payload carrying ~referring_link.
    BranchResolveStubModeLinkPayload,
    /// /v3/deeplink answers with a payload that carries no ~referring_link.
    BranchResolveStubModeOrganicPayload,
    /// /v3/deeplink answers with a transport error.
    BranchResolveStubModeError
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
    NSError *error = nil;

    if ([url containsString:kDeepLinkEndpoint]) {
        switch (self.deepLinkMode) {
            case BranchResolveStubModeLinkPayload:
                response.data = @{ BRANCH_RESPONSE_KEY_SESSION_DATA: kLinkPayloadJSON };
                break;
            case BranchResolveStubModeOrganicPayload:
                response.data = @{ BRANCH_RESPONSE_KEY_SESSION_DATA: kOrganicPayloadJSON };
                break;
            case BranchResolveStubModeError:
                response.statusCode = @500;
                error = [NSError errorWithDomain:NSURLErrorDomain code:NSURLErrorTimedOut userInfo:nil];
                break;
        }
    } else {
        response.data = @{
            BRANCH_RESPONSE_KEY_RANDOMIZED_BUNDLE_TOKEN: @"bundle_token",
            BRANCH_RESPONSE_KEY_RANDOMIZED_DEVICE_TOKEN: @"device_token"
        };
    }

    if (callback) {
        callback(response, error);
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
// The stubbed open response writes real-looking session credentials, and a resolve rewrites
// dropURLOpen. Left behind, both change how a later test's requests are handled.
@property (nonatomic, copy) NSString *savedBundleToken;
@property (nonatomic, copy) NSString *savedDeviceToken;
@property (nonatomic, assign) BOOL savedDropURLOpen;
@end

@implementation BranchLifecycleOpenResolveTests

- (void)setUp {
    [super setUp];
    // +sharedInstance requires the SDK to be initialized first. Reset the guard so each test can
    // (re)initialize the singleton, then configure it via the canonical entry point.
    [Branch resetInitializationGuardForTesting];
    BranchConfiguration *config = [[BranchConfiguration alloc] initWithKey:@"key_live_hcnegAumkH7Kv18M8AOHhfgiohpXq5tB"];
    self.branch = [Branch initialize:config];

    // Branch observes the real UIApplication lifecycle notifications, and its handlers are the two
    // methods these tests drive by hand. A genuine foreground arriving mid-test enqueues an organic
    // open indistinguishable from the one under test.
    [self detachLifecycleObservers];

    BNCPreferenceHelper *preferenceHelper = [BNCPreferenceHelper sharedInstance];
    self.savedSessionParams = preferenceHelper.sessionParams;
    self.savedAttributionLevel = preferenceHelper.attributionLevel;
    self.savedReferringURL = preferenceHelper.referringURL;
    self.savedBundleToken = preferenceHelper.randomizedBundleToken;
    self.savedDeviceToken = preferenceHelper.randomizedDeviceToken;
    self.savedDropURLOpen = preferenceHelper.dropURLOpen;

    preferenceHelper.sessionParams = nil;
    preferenceHelper.referringURL = nil;
    preferenceHelper.dropURLOpen = NO;
    preferenceHelper.attributionLevel = BranchAttributionLevelFull;

    // A real queue that executes its operations, with the network replaced at the transport
    // boundary. Starts suspended so the interleaving can be arranged deterministically.
    self.stub = [BranchResolveStubServerInterface new];
    BNCServerRequestQueue *sharedQueue = [BNCServerRequestQueue getInstance];
    self.testQueue = [BNCServerRequestQueue new];
    [self.testQueue configureWithServerInterface:self.stub
                                       branchKey:sharedQueue.branchKey
                                preferenceHelper:preferenceHelper];
    self.testQueue.operationQueue.suspended = YES;

    [self absorbPendingIsolationQueueWork];
    [self.branch setValue:self.testQueue forKey:@"requestQueue"];

    // Every assertion below counts queue contents and posted requests, so a request that is not
    // this test's own corrupts all of them. Fail here rather than three assertions later.
    XCTAssertEqualObjects([self enqueuedRequestClassNames], @[],
                          @"Precondition: the queue under test must start empty.");
    XCTAssertEqualObjects(preferenceHelper.attributionLevel, BranchAttributionLevelFull,
                          @"Precondition: attribution must not be None, or the open is suppressed for an unrelated reason.");
    XCTAssertFalse([Branch automaticOpenTrackingDisabled],
                   @"Precondition: automatic open tracking must be on, or -applicationDidBecomeActive returns before it reads the queue.");
}

- (void)tearDown {
    [self.branch setValue:[BNCServerRequestQueue getInstance] forKey:@"requestQueue"];

    // Every operation this queue should ever hold is a BNCServerRequestOperation. A deferred
    // check left behind would run later against whatever queue is installed then, so a stray
    // operation class is caught here rather than as unexplained traffic in another test.
    XCTAssertEqualObjects([self enqueuedNonRequestClassNames], @[],
                          @"The queue under test must hold no operation other than BNCServerRequestOperation.");

    [self.testQueue.operationQueue cancelAllOperations];
    self.testQueue = nil;
    self.stub = nil;

    // applicationWillResignActive suspends this lock; leaving it suspended would hang any later
    // test that calls getLatestReferringParamsSynchronous.
    [BranchOpenRequest releaseOpenResponseLock];
    [BranchRequestOpen releaseOpenResponseLock];

    BNCPreferenceHelper *preferenceHelper = [BNCPreferenceHelper sharedInstance];
    preferenceHelper.sessionParams = self.savedSessionParams;
    preferenceHelper.attributionLevel = self.savedAttributionLevel;
    preferenceHelper.referringURL = self.savedReferringURL;
    preferenceHelper.randomizedBundleToken = self.savedBundleToken;
    preferenceHelper.randomizedDeviceToken = self.savedDeviceToken;
    preferenceHelper.dropURLOpen = self.savedDropURLOpen;

    [[NSRunLoop currentRunLoop] runUntilDate:[NSDate dateWithTimeIntervalSinceNow:0.05]];

    [self reattachLifecycleObservers];

    self.branch = nil;
    [super tearDown];
}

#pragma mark - Isolating the shared singleton

// Branch is a process-wide singleton, and -setUp installs a private request queue into it. A block
// already sitting on its shared isolation queue reads branch.requestQueue when it runs rather than
// when it was dispatched, so it would otherwise enqueue into the queue under test and be counted as
// this test's traffic. Absorbed into a throwaway suspended queue so it reaches neither the network
// nor this test.
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

// Restores exactly the two registrations -[Branch initWithInterface:queue:cache:preferenceHelper:key:]
// makes. That initializer runs once per process behind a dispatch_once, so leaving them detached
// would silently disarm every later test.
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

// Barrier on the serial isolation queue: a sentinel dispatched after the lifecycle call cannot run
// until that call's block has finished. Waiting on an expectation rather than dispatch_sync keeps
// main servicing, which the chained open needs — it is enqueued from main.
- (void)waitForIsolationQueue:(NSString *)description {
    XCTestExpectation *sentinel = [[XCTestExpectation alloc] initWithDescription:description];
    [self.branch dispatchToIsolationQueue:^{
        [sentinel fulfill];
    }];
    XCTWaiterResult result = [XCTWaiter waitForExpectations:@[sentinel] timeout:15.0];
    XCTAssertEqual(result, XCTWaiterResultCompleted, @"Timed out waiting for %@.", description);
}

// Polls rather than sleeping a fixed duration: as fast as the real event, with a ceiling generous
// enough for loaded CI.
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

// This project loads BNCServerRequestOperation from two images at once, so Class-pointer identity
// is unreliable here; name-based matching is not.
- (NSArray<NSString *> *)enqueuedRequestClassNames {
    NSMutableArray<NSString *> *names = [NSMutableArray array];
    for (NSOperation *op in self.testQueue.operationQueue.operations) {
        if (![NSStringFromClass([op class]) isEqualToString:@"BNCServerRequestOperation"]) continue;
        [names addObject:NSStringFromClass([[op valueForKey:@"request"] class])];
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

// The endpoints the SDK posted, in order, named rather than full URLs so an assertion failure
// reads as the sequence it is.
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
}

// Drives the production foreground path: a resign, then the activation whose handler decides
// whether to send an organic open. Returns once that handler's block has run to completion.
- (void)foreground {
    [self.branch applicationWillResignActive];
    [self waitForIsolationQueue:@"the resign handler to run"];

    [self.branch applicationDidBecomeActive];
    [self waitForIsolationQueue:@"the foreground handler to run"];
}

- (void)drainQueue {
    self.testQueue.operationQueue.suspended = NO;
    [self waitForCondition:^BOOL{ return [self enqueuedOperationCount] == 0; }
               description:@"the request queue to drain"
                   timeout:15.0];
    [[NSRunLoop currentRunLoop] runUntilDate:[NSDate dateWithTimeIntervalSinceNow:0.1]];
}

#pragma mark - Tests

// Guard (e). An organic launch whose resolve has already drained when the foreground runs: the
// queue is empty, nothing chained an open, and the foreground is the only thing that can send one.
// It must send exactly one.
- (void)testOrganicResolveDrainedBeforeTheForegroundSendsOneOpen {
    self.stub.deepLinkMode = BranchResolveStubModeOrganicPayload;

    [self enqueueOrganicResolve];
    [self drainQueue];

    // Precondition: a response without ~referring_link chains nothing, so every open counted
    // below belongs to the foreground rather than to the resolve.
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
// nothing, leaving exactly one open on the wire — the resolve's, carrying the link payload.
- (void)testDeferredLinkResolveQueuedAtTheForegroundSendsOneOpenCarryingLinkData {
    self.stub.deepLinkMode = BranchResolveStubModeLinkPayload;

    [self enqueueOrganicResolve];
    [self foreground];

    // Precondition: the queue is suspended, so the resolve was still in it when the foreground
    // handler read it. Without this the test would pass for the wrong reason on a fast machine.
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
