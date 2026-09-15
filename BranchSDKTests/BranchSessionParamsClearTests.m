//
//  BranchSessionParamsClearTests.m
//  BranchSDKTests
//
//  Copyright © 2026 Branch, Inc. All rights reserved.
//
//  EMT-4334: -getLatestReferringParams is cleared when the app enters the background with no open or
//  resolution in flight, and survives a resign or a quick return that never stays in the background.

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
#import "BranchRequestDeepLink.h"
#import "BranchRequestOpen.h"
#import "BranchLifecycleTestIsolation.h"

@interface Branch(Test)
+ (void)resetInitializationGuardForTesting;
@end

@interface BNCServerRequestQueue (SessionParamsClearTest)
@property (strong, nonatomic) NSOperationQueue *operationQueue;
@property (copy, nonatomic) NSString *branchKey;
@end

@interface Branch (LifecycleClearTest)
- (void)applicationWillResignActive;
- (void)applicationDidEnterBackground;
- (void)applicationDidBecomeActive;
@end

static NSString * const kSessionParamsClearTestLinkURL = @"https://example.app.link/session-params-clear-test-link";
static NSString * const kSessionParamsClearTestPayloadJSON =
    @"{\"+clicked_branch_link\":true,\"+is_first_session\":false,\"~campaign\":\"beta launch\"}";

// Guarded by the stub class. The held answer, when set, delivers a /v3/deeplink response the stub kept back.
static NSMutableArray<NSString *> *sPostedURLs = nil;
static BOOL sHoldDeepLinkResponse = NO;
static dispatch_block_t sHeldDeepLinkAnswer = nil;

@interface BranchSessionParamsClearStubServerInterface : BNCServerInterface
@end

@implementation BranchSessionParamsClearStubServerInterface

- (void)postRequest:(NSDictionary *)post
                url:(NSString *)url
                key:(NSString *)key
           callback:(BNCServerCallback)callback {
    BOOL isDeepLink = [url containsString:@"/v3/deeplink"];
    BNCServerResponse *response = [BNCServerResponse new];
    response.statusCode = @200;
    response.data = isDeepLink ? @{ BRANCH_RESPONSE_KEY_SESSION_DATA: kSessionParamsClearTestPayloadJSON }
                               : @{ BRANCH_RESPONSE_KEY_RANDOMIZED_BUNDLE_TOKEN: @"bundle_token",
                                    BRANCH_RESPONSE_KEY_RANDOMIZED_DEVICE_TOKEN: @"device_token" };
    @synchronized ([BranchSessionParamsClearStubServerInterface class]) {
        [sPostedURLs addObject:url ?: @""];
        if (isDeepLink && sHoldDeepLinkResponse) {
            sHeldDeepLinkAnswer = ^{ if (callback) callback(response, nil); };
            return;
        }
    }
    if (callback) callback(response, nil);
}

@end

static void BranchSessionParamsClearResetStub(NSMutableArray<NSString *> *postedURLs) {
    @synchronized ([BranchSessionParamsClearStubServerInterface class]) {
        sPostedURLs = postedURLs;
        sHoldDeepLinkResponse = NO;
        sHeldDeepLinkAnswer = nil;
    }
}

// Supplies the application state through Branch's seam; the host app itself is always active under test.
@interface BranchSessionParamsClearStubApplication : NSObject
@property (nonatomic, assign) UIApplicationState applicationState;
@end

@implementation BranchSessionParamsClearStubApplication
@end

@interface BranchSessionParamsClearTests : XCTestCase
@property (nonatomic, strong) Branch *branch;
@property (nonatomic, strong) BNCServerRequestQueue *stubbedQueue;
@property (nonatomic, strong) BranchSessionParamsClearStubApplication *application;
@property (nonatomic, copy) NSDictionary *savedPreferences;
@end

@implementation BranchSessionParamsClearTests

- (void)setUp {
    [super setUp];
    [Branch resetInitializationGuardForTesting];
    self.branch = [Branch initialize:[[BranchConfiguration alloc] initWithKey:@"key_live_abc"]];
    [self detachLifecycleObserversFromBranch:self.branch];
    BranchSessionParamsClearResetStub([NSMutableArray array]);
    BNCPreferenceHelper *preferenceHelper = [BNCPreferenceHelper sharedInstance];
    self.savedPreferences = [preferenceHelper dictionaryWithValuesForKeys:
        @[@"sessionParams", @"referringURL", @"attributionLevel", @"randomizedBundleToken", @"randomizedDeviceToken"]];
    preferenceHelper.sessionParams = nil;
    preferenceHelper.referringURL = nil;
    preferenceHelper.attributionLevel = BranchAttributionLevelFull;
    XCTAssertNil(preferenceHelper.sessionParams, @"Precondition: sessionParams must be empty before the test runs.");

    // A real queue with the transport stubbed, suspended so each test arranges its own launch.
    self.stubbedQueue = [BNCServerRequestQueue new];
    [self.stubbedQueue configureWithServerInterface:[BranchSessionParamsClearStubServerInterface new]
                                           branchKey:[BNCServerRequestQueue getInstance].branchKey
                                    preferenceHelper:preferenceHelper];
    self.stubbedQueue.operationQueue.suspended = YES;

    [self absorbPendingIsolationQueueWorkForBranch:self.branch];
    [self.branch setValue:self.stubbedQueue forKey:@"requestQueue"];
    self.application = [BranchSessionParamsClearStubApplication new];
    self.application.applicationState = UIApplicationStateActive;
    [self.branch setValue:self.application forKey:@"application"];
}

- (void)tearDown {
    [Branch resumeSession];
    [self.branch setValue:nil forKey:@"application"];
    [self.branch setValue:[BNCServerRequestQueue getInstance] forKey:@"requestQueue"];
    self.stubbedQueue = nil;
    BranchSessionParamsClearResetStub(nil);
    [BranchOpenRequest releaseOpenResponseLock];
    [BranchRequestOpen releaseOpenResponseLock];
    [BranchRequestDeepLink releaseDeepLinkResponseLock];
    [[BNCPreferenceHelper sharedInstance] setValuesForKeysWithDictionary:self.savedPreferences];
    [[NSRunLoop currentRunLoop] runUntilDate:[NSDate dateWithTimeIntervalSinceNow:0.05]];
    [self reattachLifecycleObserversToBranch:self.branch];
    self.branch = nil;
    [super tearDown];
}

#pragma mark - Helpers

- (void)waitForCondition:(BOOL (^)(void))condition description:(NSString *)description {
    NSPredicate *predicate = [NSPredicate predicateWithBlock:^BOOL(id object, NSDictionary *bindings) {
        return condition();
    }];
    XCTNSPredicateExpectation *expectation = [[XCTNSPredicateExpectation alloc] initWithPredicate:predicate object:self];
    XCTWaiterResult result = [XCTWaiter waitForExpectations:@[expectation] timeout:5.0];
    XCTAssertEqual(result, XCTWaiterResultCompleted, @"Timed out waiting for %@.", description);
}

// Spins the run loop until a sentinel queued now has run, so every block queued before it has too.
- (void)waitForQueue:(dispatch_queue_t)queue description:(NSString *)description {
    NSObject *lock = [NSObject new];
    __block BOOL ran = NO;
    dispatch_async(queue, ^{ @synchronized (lock) { ran = YES; } });
    [self waitForCondition:^BOOL{ @synchronized (lock) { return ran; } } description:description];
}

- (void)waitForLifecycleWork {
    [self waitForQueue:[self.branch valueForKey:@"isolationQueue"] description:@"the isolation queue"];
    [self waitForQueue:dispatch_get_main_queue() description:@"the main queue"];
}

- (void)waitForDrain {
    [self waitForCondition:^BOOL{ return self.stubbedQueue.operationQueue.operations.count == 0; } description:@"the queue to drain"];
    [self waitForLifecycleWork];
}

- (NSUInteger)postedOpenCount {
    NSPredicate *isOpen = [NSPredicate predicateWithFormat:@"SELF CONTAINS %@", @"/v3/events/open"];
    @synchronized ([BranchSessionParamsClearStubServerInterface class]) { return [sPostedURLs filteredArrayUsingPredicate:isOpen].count; }
}

- (dispatch_block_t)heldDeepLinkAnswer {
    @synchronized ([BranchSessionParamsClearStubServerInterface class]) { return sHeldDeepLinkAnswer; }
}

- (NSString *)latestCampaign {
    return [self.branch getLatestReferringParams][@"~campaign"];
}

- (void)launchFromLinkAndDrain {
    [self.branch requestDeepLinkData:kSessionParamsClearTestLinkURL callback:nil];
    self.stubbedQueue.operationQueue.suspended = NO;
    [self waitForCondition:^BOOL{ return self.latestCampaign != nil; } description:@"the link launch to persist its payload"];
    [self waitForDrain];
    XCTAssertEqualObjects(self.latestCampaign, @"beta launch", @"Precondition: the link launch must persist its payload.");
}

- (void)background {
    self.application.applicationState = UIApplicationStateBackground;
    [self.branch applicationWillResignActive];
    [self.branch applicationDidEnterBackground];
}

// Leaves the resolution executing with its /v3/deeplink response held by the stub.
- (void)holdTheResolutionWithCallback:(callbackWithParams)callback {
    @synchronized ([BranchSessionParamsClearStubServerInterface class]) { sHoldDeepLinkResponse = YES; }
    [self.branch requestDeepLinkData:kSessionParamsClearTestLinkURL callback:callback];
    self.stubbedQueue.operationQueue.suspended = NO;
    [self waitForCondition:^BOOL{ return [self heldDeepLinkAnswer] != nil; } description:@"the resolution's response to be held"];
}

#pragma mark - Tests

- (void)testBackgroundWithAnEmptyQueueClearsThePayloadBeforeTheOrganicForeground {
    [self launchFromLinkAndDrain];
    NSUInteger opensBeforeForeground = [self postedOpenCount];
    [self background];
    [self waitForLifecycleWork];
    XCTAssertNil(self.latestCampaign, @"Backgrounding with nothing in flight must clear the payload.");

    self.application.applicationState = UIApplicationStateActive;
    [self.branch applicationDidBecomeActive];
    [self waitForCondition:^BOOL{ return [self postedOpenCount] > opensBeforeForeground; }
               description:@"the organic foreground's open to reach the wire"];
    [self waitForDrain];
    XCTAssertEqual([self postedOpenCount], opensBeforeForeground + 1, @"The organic foreground must send exactly one open.");
    XCTAssertNil(self.latestCampaign, @"The organic foreground must not read the previous link.");
}

- (void)testResignAndBecomeActiveWithoutBackgroundKeepsThePayload {
    [self launchFromLinkAndDrain];
    NSUInteger opensBeforeForeground = [self postedOpenCount];
    [self.branch applicationWillResignActive];
    [self waitForLifecycleWork];
    [self.branch applicationDidBecomeActive];
    [self waitForCondition:^BOOL{ return [self postedOpenCount] > opensBeforeForeground; }
               description:@"the foreground's open to reach the wire"];
    [self waitForDrain];
    XCTAssertEqualObjects(self.latestCampaign, @"beta launch", @"A transient interruption must not clear the payload.");
}

// The isolation queue can sit behind -loadUserAgent for seconds; a clear decided there would land after the return.
- (void)testQuickReturnToForegroundWhileTheIsolationQueueIsHeldKeepsThePayload {
    [self launchFromLinkAndDrain];
    NSUInteger opensBeforeForeground = [self postedOpenCount];
    dispatch_semaphore_t releaseIsolationQueue = dispatch_semaphore_create(0);
    dispatch_async([self.branch valueForKey:@"isolationQueue"], ^{
        dispatch_semaphore_wait(releaseIsolationQueue, dispatch_time(DISPATCH_TIME_NOW, (int64_t)(10 * NSEC_PER_SEC)));
    });
    [self background];
    self.application.applicationState = UIApplicationStateActive;
    [self.branch applicationDidBecomeActive];
    dispatch_semaphore_signal(releaseIsolationQueue);
    [self waitForCondition:^BOOL{ return [self postedOpenCount] > opensBeforeForeground; }
               description:@"the foreground's open to reach the wire"];
    [self waitForDrain];
    XCTAssertEqualObjects(self.latestCampaign, @"beta launch", @"A return to foreground must not be followed by a late clear.");
}

- (void)testBackgroundWhileTheResolutionIsInFlightKeepsThePayloadItWrites {
    [self holdTheResolutionWithCallback:nil];
    [self background];
    // Delivered on main before the background decision runs: the write lands first, and the launch's open is queued.
    [self heldDeepLinkAnswer]();
    [self waitForDrain];
    XCTAssertEqualObjects(self.latestCampaign, @"beta launch",
                          @"Backgrounding during a link launch must not clear the payload it writes.");
}

- (void)testBackgroundUnderAttributionLevelNoneClearsWhenTheQueueIsEmpty {
    [BNCPreferenceHelper sharedInstance].attributionLevel = BranchAttributionLevelNone;
    [self launchFromLinkAndDrain];
    [self background];
    [self waitForLifecycleWork];
    XCTAssertNil(self.latestCampaign, @"/v3/deeplink still writes under None, so backgrounding must still clear.");
}

- (void)testBackgroundInManualOpenModeKeepsThePayload {
    [Branch disableNextForegroundForTimeInterval:0];
    [self launchFromLinkAndDrain];
    [self background];
    [self waitForLifecycleWork];
    XCTAssertEqualObjects(self.latestCampaign, @"beta launch", @"Manual-open mode sends no open on return, so the payload must survive.");
}

// The resolution has left the queue but its callback is still pending on main, so the clear runs; it must run after.
- (void)testDeepLinkCallbackReceivesTheResolvedParamsWhenBackgroundingDuringTheResolution {
    [BNCPreferenceHelper sharedInstance].attributionLevel = BranchAttributionLevelNone;
    __block NSDictionary *callbackParams = nil;
    [self holdTheResolutionWithCallback:^(NSDictionary *params, NSError *error) { callbackParams = params; }];
    [self heldDeepLinkAnswer]();
    NSDate *deadline = [NSDate dateWithTimeIntervalSinceNow:5.0];
    while (self.stubbedQueue.operationQueue.operations.count > 0 && deadline.timeIntervalSinceNow > 0) usleep(10000);
    XCTAssertEqual(self.stubbedQueue.operationQueue.operations.count, 0u, @"Precondition: the resolution must have left the queue.");
    XCTAssertNil(callbackParams, @"Precondition: the callback must still be pending on main.");

    [self background];
    [self waitForLifecycleWork];
    XCTAssertEqualObjects(callbackParams[@"~campaign"], @"beta launch", @"The callback must receive the params the resolution wrote.");
    XCTAssertNil(self.latestCampaign, @"Precondition: the clear must have run, or the callback ordering was not exercised.");
}

@end
