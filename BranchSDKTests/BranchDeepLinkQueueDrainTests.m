//
//  BranchDeepLinkQueueDrainTests.m
//  BranchSDKTests
//
//  Copyright © 2026 Branch, Inc. All rights reserved.
//
//  EMT-4028: while a deep link resolution is in flight, a lifecycle foreground must not enqueue
//  an organic open at all. Measured against a real BNCServerRequestQueue with a stubbed
//  transport — real operations, real serial ordering, real dependencies, no network.
//
//  A test that asserts inside the requestDeepLinkData: callback cannot see this, because the
//  callback fires while the queue is still draining. This test therefore asserts after the
//  isolation queue has run the lifecycle call, and after the request queue has fully drained.
//

#import <XCTest/XCTest.h>
#import "Branch.h"
#import "BranchConstants.h"
#import "BNCPreferenceHelper.h"
#import "BNCServerInterface.h"
#import "BNCServerRequestQueue.h"
#import "BNCServerRequestOperation.h"
#import "BNCServerResponse.h"
#import "BranchOpenRequest.h"
#import "BranchRequestOpen.h"

@interface BNCServerRequestQueue (DrainTest)
@property (strong, nonatomic) NSOperationQueue *operationQueue;
@property (copy, nonatomic) NSString *branchKey;
@end

// Private lifecycle entry points. These are the production callers; driving them rather than
// calling -sendOpen directly is what makes the interleaving real rather than staged.
@interface Branch (LifecycleDrainTest)
- (void)applicationDidBecomeActive;
- (void)applicationWillResignActive;
@end

static NSString * const kResolvedLinkURL = @"https://example.app.link/drain-order-link";
static NSString * const kResolvedLinkPayloadJSON =
    @"{\"+clicked_branch_link\":true,\"+is_first_session\":false,"
     "\"$canonical_identifier\":\"content/12345\",\"$og_title\":\"Resolved Content\","
     "\"~campaign\":\"beta launch\","
     "\"~referring_link\":\"https://example.app.link/drain-order-link\"}";

// Every URL the SDK actually posted, in execution order. This is how the test proves the
// interleaving happened rather than assuming it.
static NSMutableArray<NSString *> *sPostedURLs = nil;

// Answers both endpoints from measured response shapes: /v3/deeplink carries the link payload
// at "data" as a JSON string; the open's own response carries no "data" key at all, which is
// the overwrite vector under test.
@interface BranchDrainStubServerInterface : BNCServerInterface
@end

@implementation BranchDrainStubServerInterface

- (void)postRequest:(NSDictionary *)post
                url:(NSString *)url
                key:(NSString *)key
           callback:(BNCServerCallback)callback {
    @synchronized (sPostedURLs) {
        [sPostedURLs addObject:url ?: @""];
    }

    BNCServerResponse *response = [BNCServerResponse new];
    response.statusCode = @200;
    if ([url containsString:@"/v3/deeplink"]) {
        response.data = @{ BRANCH_RESPONSE_KEY_SESSION_DATA: kResolvedLinkPayloadJSON };
    } else {
        response.data = @{
            BRANCH_RESPONSE_KEY_SESSION_ID: @"session_id",
            BRANCH_RESPONSE_KEY_RANDOMIZED_BUNDLE_TOKEN: @"bundle_token",
            BRANCH_RESPONSE_KEY_RANDOMIZED_DEVICE_TOKEN: @"device_token"
        };
    }

    if (callback) {
        callback(response, nil);
    }
}

@end

@interface BranchDeepLinkQueueDrainTests : XCTestCase
@property (nonatomic, strong) Branch *branch;
@property (nonatomic, strong) BNCServerRequestQueue *drainingQueue;
@property (nonatomic, copy) NSString *savedSessionParams;
@property (nonatomic, copy) NSString *savedAttributionLevel;
// The stubbed responses write real-looking session credentials. BNCServerRequestOperation
// drops a non-init request when these are missing, so leaving them behind lets later tests
// reach the network they would otherwise have skipped. Saved here, restored in -tearDown.
@property (nonatomic, copy) NSString *savedSessionID;
@property (nonatomic, copy) NSString *savedBundleToken;
@property (nonatomic, copy) NSString *savedDeviceToken;
// These tests drive the real lifecycle entry points, which move the session state machine.
// Left armed, a later test's logEvent proceeds to the network instead of being deferred.
@property (nonatomic, strong) id savedInitializationStatus;
@end

@implementation BranchDeepLinkQueueDrainTests

- (void)setUp {
    [super setUp];
    self.branch = [Branch getInstance];
    sPostedURLs = [NSMutableArray array];

    BNCPreferenceHelper *preferenceHelper = [BNCPreferenceHelper sharedInstance];
    self.savedSessionParams = preferenceHelper.sessionParams;
    self.savedAttributionLevel = preferenceHelper.attributionLevel;
    self.savedSessionID = preferenceHelper.sessionID;
    self.savedBundleToken = preferenceHelper.randomizedBundleToken;
    self.savedDeviceToken = preferenceHelper.randomizedDeviceToken;
    self.savedInitializationStatus = [self.branch valueForKey:@"initializationStatus"];

    preferenceHelper.sessionParams = nil;
    preferenceHelper.referringURL = nil;
    preferenceHelper.attributionLevel = BranchAttributionLevelFull;

    // BNCPreferenceHelper is a singleton backed by NSUserDefaults. Residue read back as if the
    // code under test had written it would hide the overwrite entirely.
    XCTAssertNil(preferenceHelper.sessionParams,
                 @"Precondition: sessionParams must be empty before the test runs.");

    // A real queue that will actually execute its operations, with the network replaced at the
    // transport boundary. Starts suspended so the interleaving can be arranged deterministically.
    BNCServerRequestQueue *realQueue = [BNCServerRequestQueue getInstance];
    self.drainingQueue = [BNCServerRequestQueue new];
    [self.drainingQueue configureWithServerInterface:[BranchDrainStubServerInterface new]
                                           branchKey:realQueue.branchKey
                                    preferenceHelper:preferenceHelper];
    self.drainingQueue.operationQueue.suspended = YES;
    [self.branch setValue:self.drainingQueue forKey:@"requestQueue"];
}

- (void)tearDown {
    [self.branch setValue:[BNCServerRequestQueue getInstance] forKey:@"requestQueue"];
    self.drainingQueue = nil;
    sPostedURLs = nil;

    // applicationWillResignActive suspends this lock; leaving it suspended would hang any later
    // test that calls getLatestReferringParamsSynchronous.
    [BranchOpenRequest releaseOpenResponseLock];
    [BranchRequestOpen releaseOpenResponseLock];

    BNCPreferenceHelper *preferenceHelper = [BNCPreferenceHelper sharedInstance];
    preferenceHelper.sessionParams = self.savedSessionParams;
    preferenceHelper.referringURL = nil;
    preferenceHelper.attributionLevel = self.savedAttributionLevel;
    preferenceHelper.sessionID = self.savedSessionID;
    preferenceHelper.randomizedBundleToken = self.savedBundleToken;
    preferenceHelper.randomizedDeviceToken = self.savedDeviceToken;
    [self.branch setValue:self.savedInitializationStatus forKey:@"initializationStatus"];

    [[NSRunLoop currentRunLoop] runUntilDate:[NSDate dateWithTimeIntervalSinceNow:0.05]];

    self.branch = nil;
    [super tearDown];
}

#pragma mark - Helpers

// Polls rather than sleeping a fixed duration: as fast as the real event, with a ceiling
// generous enough for loaded CI.
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
    return self.drainingQueue.operationQueue.operations.count;
}

// This project loads BNCServerRequestOperation from two images at once, so Class-pointer
// identity is unreliable here; name-based matching is not.
- (NSArray<NSString *> *)enqueuedRequestClassNames {
    NSMutableArray<NSString *> *names = [NSMutableArray array];
    for (NSOperation *op in self.drainingQueue.operationQueue.operations) {
        if (![NSStringFromClass([op class]) isEqualToString:@"BNCServerRequestOperation"]) continue;
        [names addObject:NSStringFromClass([[op valueForKey:@"request"] class])];
    }
    return names;
}

// Branch defers its lifecycle work onto a serial isolation queue. Sitting behind that queue is
// what turns "nothing was enqueued" into a fact rather than a race: once this returns, the block
// the lifecycle call posted has already run to completion.
- (void)waitForIsolationQueue {
    dispatch_queue_t isolationQueue = [self.branch valueForKey:@"isolationQueue"];
    XCTAssertNotNil(isolationQueue,
                    @"Precondition: the isolation queue must be reachable, or this barrier proves nothing.");
    dispatch_sync(isolationQueue, ^{});
}

- (NSInteger)initializationStatus {
    return [[self.branch valueForKey:@"initializationStatus"] integerValue];
}

- (NSArray<NSString *> *)postedURLs {
    @synchronized (sPostedURLs) {
        return [sPostedURLs copy];
    }
}

- (NSUInteger)postedOpenCount {
    NSUInteger count = 0;
    for (NSString *url in [self postedURLs]) {
        if ([url containsString:@"/v3/events/open"]) count++;
    }
    return count;
}

#pragma mark - Tests

// The app resolves a link, then backgrounds and foregrounds while that resolution is still in
// flight. The organic open -applicationDidBecomeActive would normally send must not be enqueued
// at all: -containsInstallOrOpen counts an in-flight BranchRequestDeepLink as init traffic, so
// the foreground short-circuits rather than racing the resolution it would have overwritten.
//
// -applicationDidBecomeActive sends that open only when three things hold at once: attribution
// is not None, the session reads uninitialized, and no install or open is already queued. The
// first two are established and asserted below, so a missing open can only be the third — this
// fails if the queue stops recognising the 4.0 request classes.
- (void)testLiveResolutionSuppressesTheLifecycleOrganicOpen {
    [self.branch requestDeepLinkData:kResolvedLinkURL callback:nil];
    [self waitForCondition:^BOOL{ return [self enqueuedOperationCount] >= 1; }
               description:@"the deep link resolution to be enqueued"
                   timeout:5.0];

    // Precondition: the resolution is the only thing in the queue. Anything else already queued
    // and the count below would be measuring something other than the lifecycle open.
    XCTAssertEqualObjects([self enqueuedRequestClassNames], @[@"BranchRequestDeepLink"],
                          @"Precondition: the queued operation must be the deep link resolution, alone.");

    // Production path: resign marks the session uninitialized, which is what arms the organic
    // open on the next foreground.
    [self.branch applicationWillResignActive];
    [self waitForIsolationQueue];

    // Precondition: the session really does read uninitialized. Attribution is set to Full in
    // -setUp. Without both, -applicationDidBecomeActive would skip the open for a reason that
    // has nothing to do with the in-flight resolution, and this test would pass hollow.
    XCTAssertEqual([self initializationStatus], (NSInteger)0,
                   @"Precondition: the session must read uninitialized (BNCInitStatusUninitialized) after resigning active.");
    XCTAssertEqualObjects([BNCPreferenceHelper sharedInstance].attributionLevel, BranchAttributionLevelFull,
                          @"Precondition: attribution must not be None, or the open is suppressed for an unrelated reason.");

    [self.branch applicationDidBecomeActive];
    [self waitForIsolationQueue];

    XCTAssertEqualObjects([self enqueuedRequestClassNames], @[@"BranchRequestDeepLink"],
                          @"A foreground during a live resolution must not enqueue an organic open.");

    // The same guarantee at the transport boundary: once everything runs, the only open on the
    // wire is the one the resolution sends itself. A second would be the suppressed organic open
    // arriving late rather than never.
    self.drainingQueue.operationQueue.suspended = NO;
    [self waitForCondition:^BOOL{ return [self enqueuedOperationCount] == 0; }
               description:@"the request queue to drain"
                   timeout:15.0];
    [[NSRunLoop currentRunLoop] runUntilDate:[NSDate dateWithTimeIntervalSinceNow:0.1]];

    XCTAssertEqual([self postedOpenCount], 1u,
                   @"Exactly one open must reach the wire: the resolution's own. Posted in order: %@.",
                   [self postedURLs]);
}

@end
