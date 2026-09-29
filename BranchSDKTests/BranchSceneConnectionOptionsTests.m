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

#import <XCTest/XCTest.h>
#import <UIKit/UIKit.h>
#import <CoreSpotlight/CoreSpotlight.h>
#import "Branch.h"
#import "BranchConfiguration.h"
#import "BranchConstants.h"
#import "BNCPreferenceHelper.h"
#import "BNCServerRequestQueue.h"
#import "BranchRequestDeepLink.h"

// Test-only reset for the +initialize: reinitialization guard (file-private in Branch.m).
@interface Branch (Test)
+ (void)resetInitializationGuardForTesting;
@end

// Lets a test suspend the queue and inspect what was enqueued before it can hit the network.
@interface BNCServerRequestQueue (SceneConnectionOptionsTest)
@property (strong, nonatomic) NSOperationQueue *operationQueue;
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

@interface BranchSceneConnectionOptionsTests : XCTestCase
@property (nonatomic, strong) Branch *branch;
@property (nonatomic, strong) BNCServerRequestQueue *fakeQueue;
@property (nonatomic, copy) NSString *savedSpotlightIdentifier;
@end

@implementation BranchSceneConnectionOptionsTests

- (void)setUp {
    [super setUp];
    // +sharedInstance requires the SDK to be initialized first. Reset the guard so each test can
    // (re)initialize the singleton, then configure it via the canonical entry point.
    [Branch resetInitializationGuardForTesting];
    BranchConfiguration *config = [[BranchConfiguration alloc] initWithKey:@"key_live_hcnegAumkH7Kv18M8AOHhfgiohpXq5tB"];
    self.branch = [Branch initialize:config];

    self.savedSpotlightIdentifier = [BNCPreferenceHelper sharedInstance].spotlightIdentifier;
    [BNCPreferenceHelper sharedInstance].spotlightIdentifier = nil;

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
    [BNCPreferenceHelper sharedInstance].spotlightIdentifier = self.savedSpotlightIdentifier;
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
    XCTWaiterResult result = [XCTWaiter waitForExpectations:@[expectation] timeout:5.0];
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

@end
