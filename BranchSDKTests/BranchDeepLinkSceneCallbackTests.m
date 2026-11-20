//
//  BranchDeepLinkSceneCallbackTests.m
//  BranchSDKTests
//
//  Copyright © 2026 Branch, Inc. All rights reserved.
//
//  The handler registered with -requestDeepLinkDataWithSceneOptions:scene:callback: receives, with
//  each result, the connected scene whose entry point enqueued it. Each test enqueues on a suspended
//  queue and completes the request by calling its callback directly, so nothing reaches the network.
//

#import <XCTest/XCTest.h>
#import <UIKit/UIKit.h>
#import "Branch.h"
#import "BranchConfiguration.h"
#import "BranchConstants.h"
#import "BNCPreferenceHelper.h"
#import "BNCServerRequestQueue.h"
#import "BranchRequestDeepLink.h"

@interface Branch (SceneCallbackTest)
+ (void)resetInitializationGuardForTesting;
- (void)setSceneDeepLinkHandler:(callbackWithParamsAndScene)handler forSceneIdentifier:(NSString *)sceneIdentifier;
@end

@interface BNCServerRequestQueue (SceneCallbackTest)
@property (strong, nonatomic) NSOperationQueue *operationQueue;
@end

static NSString * const kSceneCallbackLinkURL = @"https://example.app.link/scene-callback-link";
static NSString * const kSceneCallbackSessionParams = @"{\"+clicked_branch_link\":true,\"scene_callback_test\":\"yes\"}";

@interface BranchDeepLinkSceneCallbackTests : XCTestCase
@property (nonatomic, strong) Branch *branch;
@property (nonatomic, strong) BNCServerRequestQueue *fakeQueue;
@property (nonatomic, copy) id savedDeepLinkHandler;
@property (nonatomic, copy) NSDictionary *savedSceneDeepLinkHandlers;
@property (nonatomic, copy) NSString *savedSessionParams;
@property (nonatomic, copy) NSString *savedAttributionLevel;
@property (nonatomic, copy) NSString *savedBundleToken;
@property (nonatomic, copy) NSString *savedDeviceToken;
@end

@implementation BranchDeepLinkSceneCallbackTests

- (void)setUp {
    [super setUp];
    [Branch resetInitializationGuardForTesting];
    BranchConfiguration *config = [[BranchConfiguration alloc] initWithKey:@"key_live_hcnegAumkH7Kv18M8AOHhfgiohpXq5tB"];
    self.branch = [Branch initialize:config];
    self.savedDeepLinkHandler = [self.branch valueForKey:@"deepLinkHandler"];
    self.savedSceneDeepLinkHandlers = [[self.branch valueForKey:@"sceneDeepLinkHandlers"] copy];
    [self.branch setValue:[NSMutableDictionary dictionary] forKey:@"sceneDeepLinkHandlers"];

    BNCPreferenceHelper *preferenceHelper = [BNCPreferenceHelper sharedInstance];
    self.savedSessionParams = preferenceHelper.sessionParams;
    self.savedAttributionLevel = preferenceHelper.attributionLevel;
    self.savedBundleToken = preferenceHelper.randomizedBundleToken;
    self.savedDeviceToken = preferenceHelper.randomizedDeviceToken;

    preferenceHelper.sessionParams = kSceneCallbackSessionParams;
    preferenceHelper.attributionLevel = BranchAttributionLevelFull;
    preferenceHelper.randomizedBundleToken = @"scene_callback_bundle_token";
    preferenceHelper.randomizedDeviceToken = @"scene_callback_device_token";

    [self replaceQueue];
}

- (void)tearDown {
    [self.branch setValue:[BNCServerRequestQueue getInstance] forKey:@"requestQueue"];
    [self.branch setValue:self.savedDeepLinkHandler forKey:@"deepLinkHandler"];
    [self.branch setValue:[self.savedSceneDeepLinkHandlers mutableCopy] ?: [NSMutableDictionary dictionary] forKey:@"sceneDeepLinkHandlers"];
    self.fakeQueue = nil;

    BNCPreferenceHelper *preferenceHelper = [BNCPreferenceHelper sharedInstance];
    preferenceHelper.sessionParams = self.savedSessionParams;
    preferenceHelper.attributionLevel = self.savedAttributionLevel;
    preferenceHelper.randomizedBundleToken = self.savedBundleToken;
    preferenceHelper.randomizedDeviceToken = self.savedDeviceToken;

    [[NSRunLoop currentRunLoop] runUntilDate:[NSDate dateWithTimeIntervalSinceNow:0.05]];
    self.branch = nil;
    [super tearDown];
}

#pragma mark - Helpers

// Installs a new suspended queue. A suspended, never-started operation must not be cancelled, and
// enqueueing a link cancels pending deep link requests, so a test that enqueues twice swaps first.
- (void)replaceQueue {
    self.fakeQueue = [BNCServerRequestQueue new];
    self.fakeQueue.operationQueue.suspended = YES;
    [self.branch setValue:self.fakeQueue forKey:@"requestQueue"];
}

// Returns the test host app's connected scene, waiting for it to connect.
- (UIScene *)waitForConnectedScene {
    NSPredicate *predicate = [NSPredicate predicateWithBlock:^BOOL(id evaluatedObject, NSDictionary *bindings) {
        return [UIApplication sharedApplication].connectedScenes.anyObject != nil;
    }];
    XCTNSPredicateExpectation *expectation = [[XCTNSPredicateExpectation alloc] initWithPredicate:predicate object:self];
    XCTWaiterResult result = [XCTWaiter waitForExpectations:@[expectation] timeout:15.0];
    XCTAssertEqual(result, XCTWaiterResultCompleted, @"Timed out waiting for the test host app to connect a scene.");
    return [UIApplication sharedApplication].connectedScenes.anyObject;
}

// Returns the single BranchRequestDeepLink on the current queue.
- (BranchRequestDeepLink *)onlyEnqueuedDeepLinkRequest {
    NSMutableArray<BranchRequestDeepLink *> *requests = [NSMutableArray array];
    for (NSOperation *op in self.fakeQueue.operationQueue.operations) {
        if (![NSStringFromClass([op class]) isEqualToString:@"BNCServerRequestOperation"]) continue;
        id request = [op valueForKey:@"request"];
        if ([NSStringFromClass([request class]) isEqualToString:@"BranchRequestDeepLink"]) {
            [requests addObject:request];
        }
    }
    XCTAssertEqual(requests.count, (NSUInteger)1, @"Expected exactly one deep link request. Enqueued: %@", requests);
    return requests.firstObject;
}

// Completes request with success and error, then waits for the stored handler to be called.
- (void)completeRequest:(BranchRequestDeepLink *)request
                  error:(NSError *)error
            expectation:(XCTestExpectation *)expectation {
    XCTAssertNotNil(request.callback);
    request.callback(error == nil, error);
    [self waitForExpectations:@[expectation] timeout:5.0];
}

- (NSUserActivity *)universalLinkActivity {
    NSUserActivity *activity = [[NSUserActivity alloc] initWithActivityType:NSUserActivityTypeBrowsingWeb];
    activity.webpageURL = [NSURL URLWithString:kSceneCallbackLinkURL];
    return activity;
}

#pragma mark - Tests

- (void)testSceneConnectHandlerReceivesConnectingSceneOnColdStartWithNoLink {
    UIScene *scene = [self waitForConnectedScene];

    XCTestExpectation *called = [self expectationWithDescription:@"stored handler called"];
    __block UIScene *receivedScene = nil;
    __block NSDictionary *receivedParams = nil;
    [self.branch requestDeepLinkDataWithSceneOptions:nil scene:scene callback:^(NSDictionary *params, NSError *error, UIScene *callbackScene) {
        XCTAssertNil(error);
        receivedParams = params;
        receivedScene = callbackScene;
        [called fulfill];
    }];

    [self completeRequest:[self onlyEnqueuedDeepLinkRequest] error:nil expectation:called];

    XCTAssertEqual(receivedScene, scene);
    XCTAssertEqualObjects(receivedParams[@"scene_callback_test"], @"yes");
}

- (void)testSceneConnectHandlerReceivesSceneOfWarmUniversalLink {
    UIScene *scene = [self waitForConnectedScene];

    XCTestExpectation *called = [self expectationWithDescription:@"stored handler called for the warm link"];
    __block UIScene *receivedScene = nil;
    __block BOOL warmLinkEnqueued = NO;
    [self.branch requestDeepLinkDataWithSceneOptions:nil scene:scene callback:^(NSDictionary *params, NSError *error, UIScene *callbackScene) {
        if (!warmLinkEnqueued) return;
        receivedScene = callbackScene;
        [called fulfill];
    }];

    [self replaceQueue];
    warmLinkEnqueued = YES;
    [self.branch requestDeepLinkDataWithScene:scene continueUserActivity:[self universalLinkActivity]];

    BranchRequestDeepLink *request = [self onlyEnqueuedDeepLinkRequest];
    XCTAssertEqualObjects(request.urlString, kSceneCallbackLinkURL);
    [self completeRequest:request error:nil expectation:called];

    XCTAssertEqual(receivedScene, scene);
}

- (void)testSceneConnectHandlerReceivesSceneWithError {
    UIScene *scene = [self waitForConnectedScene];
    NSError *failure = [NSError errorWithDomain:@"BranchDeepLinkSceneCallbackTests" code:1 userInfo:nil];

    XCTestExpectation *called = [self expectationWithDescription:@"stored handler called with error"];
    __block UIScene *receivedScene = nil;
    __block NSError *receivedError = nil;
    [self.branch requestDeepLinkDataWithSceneOptions:nil scene:scene callback:^(NSDictionary *params, NSError *error, UIScene *callbackScene) {
        receivedError = error;
        receivedScene = callbackScene;
        [called fulfill];
    }];

    [self completeRequest:[self onlyEnqueuedDeepLinkRequest] error:failure expectation:called];

    XCTAssertEqualObjects(receivedError, failure);
    XCTAssertEqual(receivedScene, scene);
}

- (void)testLegacySceneIdentifierEntryPointResolvesScene {
    UIScene *scene = [self waitForConnectedScene];

    XCTestExpectation *called = [self expectationWithDescription:@"stored handler called"];
    __block UIScene *receivedScene = nil;
    [self.branch setValue:^(NSDictionary *params, NSError *error, UIScene *callbackScene) {
        receivedScene = callbackScene;
        [called fulfill];
    } forKey:@"deepLinkHandler"];

    [self.branch continueUserActivity:[self universalLinkActivity] sceneIdentifier:scene.session.persistentIdentifier];

    [self completeRequest:[self onlyEnqueuedDeepLinkRequest] error:nil expectation:called];

    XCTAssertEqual(receivedScene, scene);
}

- (void)testUnknownSceneIdentifierDeliversNilScene {
    [self waitForConnectedScene];

    XCTestExpectation *called = [self expectationWithDescription:@"stored handler called"];
    __block BOOL sceneWasNil = NO;
    [self.branch setValue:^(NSDictionary *params, NSError *error, UIScene *callbackScene) {
        sceneWasNil = (callbackScene == nil);
        [called fulfill];
    } forKey:@"deepLinkHandler"];

    [self.branch continueUserActivity:[self universalLinkActivity] sceneIdentifier:@"scene-that-is-not-connected"];

    [self completeRequest:[self onlyEnqueuedDeepLinkRequest] error:nil expectation:called];

    XCTAssertTrue(sceneWasNil);
}

- (void)testAppDelegateEntryPointDeliversNilScene {
    [self waitForConnectedScene];

    XCTestExpectation *called = [self expectationWithDescription:@"stored handler called"];
    __block BOOL sceneWasNil = NO;
    [self.branch setValue:^(NSDictionary *params, NSError *error, UIScene *callbackScene) {
        sceneWasNil = (callbackScene == nil);
        [called fulfill];
    } forKey:@"deepLinkHandler"];

    [self.branch requestDeepLinkDataWithUserActivity:[self universalLinkActivity]];

    [self completeRequest:[self onlyEnqueuedDeepLinkRequest] error:nil expectation:called];

    XCTAssertTrue(sceneWasNil);
}

- (void)testLaunchOptionsHandlerStillReceivesResults {
    XCTestExpectation *called = [self expectationWithDescription:@"launch options handler called"];
    __block NSDictionary *receivedParams = nil;
    [self.branch requestDeepLinkDataWithLaunchOptions:nil callback:^(NSDictionary *params, NSError *error) {
        XCTAssertNil(error);
        receivedParams = params;
        [called fulfill];
    }];

    [self completeRequest:[self onlyEnqueuedDeepLinkRequest] error:nil expectation:called];

    XCTAssertEqualObjects(receivedParams[@"scene_callback_test"], @"yes");
}

- (void)testExplicitCallbackIsUsedInsteadOfStoredHandler {
    __block BOOL storedHandlerCalled = NO;
    [self.branch setValue:^(NSDictionary *params, NSError *error, UIScene *callbackScene) {
        storedHandlerCalled = YES;
    } forKey:@"deepLinkHandler"];

    XCTestExpectation *called = [self expectationWithDescription:@"explicit callback called"];
    [self.branch requestDeepLinkData:kSceneCallbackLinkURL callback:^(NSDictionary *params, NSError *error) {
        [called fulfill];
    }];

    [self completeRequest:[self onlyEnqueuedDeepLinkRequest] error:nil expectation:called];

    XCTAssertFalse(storedHandlerCalled);
}

#pragma mark - Per-scene handlers

- (void)testEachSceneHandlerReceivesOnlyItsOwnScenesResult {
    __block NSUInteger firstCalls = 0;
    __block NSUInteger secondCalls = 0;
    XCTestExpectation *firstCalled = [self expectationWithDescription:@"first scene handler called"];
    XCTestExpectation *secondCalled = [self expectationWithDescription:@"second scene handler called"];
    [self.branch setSceneDeepLinkHandler:^(NSDictionary *params, NSError *error, UIScene *callbackScene) {
        firstCalls++;
        [firstCalled fulfill];
    } forSceneIdentifier:@"scene-first"];
    [self.branch setSceneDeepLinkHandler:^(NSDictionary *params, NSError *error, UIScene *callbackScene) {
        secondCalls++;
        [secondCalled fulfill];
    } forSceneIdentifier:@"scene-second"];

    [self.branch continueUserActivity:[self universalLinkActivity] sceneIdentifier:@"scene-first"];
    BranchRequestDeepLink *firstRequest = [self onlyEnqueuedDeepLinkRequest];

    [self replaceQueue];
    [self.branch continueUserActivity:[self universalLinkActivity] sceneIdentifier:@"scene-second"];
    BranchRequestDeepLink *secondRequest = [self onlyEnqueuedDeepLinkRequest];

    [self completeRequest:firstRequest error:nil expectation:firstCalled];
    XCTAssertEqual(firstCalls, (NSUInteger)1);
    XCTAssertEqual(secondCalls, (NSUInteger)0);

    [self completeRequest:secondRequest error:nil expectation:secondCalled];
    XCTAssertEqual(firstCalls, (NSUInteger)1);
    XCTAssertEqual(secondCalls, (NSUInteger)1);
}

- (void)testSecondSceneConnectDoesNotReplaceFirstScenesHandler {
    UIScene *scene = [self waitForConnectedScene];

    XCTestExpectation *called = [self expectationWithDescription:@"first scene handler called for its warm link"];
    __block BOOL warmLinkEnqueued = NO;
    __block UIScene *receivedScene = nil;
    __block BOOL otherHandlerCalled = NO;
    [self.branch requestDeepLinkDataWithSceneOptions:nil scene:scene callback:^(NSDictionary *params, NSError *error, UIScene *callbackScene) {
        if (!warmLinkEnqueued) return;
        receivedScene = callbackScene;
        [called fulfill];
    }];
    [self.branch setSceneDeepLinkHandler:^(NSDictionary *params, NSError *error, UIScene *callbackScene) {
        otherHandlerCalled = YES;
    } forSceneIdentifier:@"scene-other-window"];

    [self replaceQueue];
    warmLinkEnqueued = YES;
    [self.branch requestDeepLinkDataWithScene:scene continueUserActivity:[self universalLinkActivity]];

    [self completeRequest:[self onlyEnqueuedDeepLinkRequest] error:nil expectation:called];

    XCTAssertEqual(receivedScene, scene);
    XCTAssertFalse(otherHandlerCalled);
}

- (void)testResultWithoutSceneGoesToLatestSceneHandler {
    __block BOOL firstHandlerCalled = NO;
    XCTestExpectation *called = [self expectationWithDescription:@"latest scene handler called"];
    __block BOOL sceneWasNil = NO;
    [self.branch setSceneDeepLinkHandler:^(NSDictionary *params, NSError *error, UIScene *callbackScene) {
        firstHandlerCalled = YES;
    } forSceneIdentifier:@"scene-first"];
    [self.branch setSceneDeepLinkHandler:^(NSDictionary *params, NSError *error, UIScene *callbackScene) {
        sceneWasNil = (callbackScene == nil);
        [called fulfill];
    } forSceneIdentifier:@"scene-second"];

    [self.branch requestDeepLinkDataWithUserActivity:[self universalLinkActivity]];

    [self completeRequest:[self onlyEnqueuedDeepLinkRequest] error:nil expectation:called];

    XCTAssertTrue(sceneWasNil);
    XCTAssertFalse(firstHandlerCalled);
}

- (void)testNilHandlerRemovesOnlyThatScene {
    callbackWithParamsAndScene firstHandler = ^(NSDictionary *params, NSError *error, UIScene *callbackScene) {};
    [self.branch setSceneDeepLinkHandler:firstHandler forSceneIdentifier:@"scene-first"];
    [self.branch setSceneDeepLinkHandler:^(NSDictionary *params, NSError *error, UIScene *callbackScene) {} forSceneIdentifier:@"scene-second"];

    [self.branch setSceneDeepLinkHandler:nil forSceneIdentifier:@"scene-second"];

    NSDictionary *handlers = [self.branch valueForKey:@"sceneDeepLinkHandlers"];
    XCTAssertEqualObjects(handlers.allKeys, @[ @"scene-first" ]);
    XCTAssertNotNil([self.branch valueForKey:@"deepLinkHandler"]);

    [self.branch setSceneDeepLinkHandler:nil forSceneIdentifier:@"scene-first"];

    XCTAssertEqual([[self.branch valueForKey:@"sceneDeepLinkHandlers"] count], (NSUInteger)0);
    XCTAssertNil([self.branch valueForKey:@"deepLinkHandler"]);
}

- (void)testSceneDisconnectRemovesItsHandler {
    UIScene *scene = [self waitForConnectedScene];
    [self.branch requestDeepLinkDataWithSceneOptions:nil scene:scene callback:^(NSDictionary *params, NSError *error, UIScene *callbackScene) {}];
    XCTAssertNotNil([self.branch valueForKey:@"sceneDeepLinkHandlers"][scene.session.persistentIdentifier]);

    [[NSNotificationCenter defaultCenter] postNotificationName:UISceneDidDisconnectNotification object:scene];

    XCTAssertNil([self.branch valueForKey:@"sceneDeepLinkHandlers"][scene.session.persistentIdentifier]);
}

@end
