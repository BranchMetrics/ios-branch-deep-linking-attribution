//
//  BranchDisableNextForegroundTests.m
//  Branch-SDK-Tests
//
//  Created by Nidhi Dixit on 02/09/26.
//  Copyright © 2025 Branch, Inc. All rights reserved.
//
//  Tests for disableNextForeground, disableNextForegroundForTimeInterval, and resumeSession APIs.
//

#import <XCTest/XCTest.h>
#import "Branch.h"
#import "BNCPreferenceHelper.h"
#import "BNCServerRequestQueue.h"
#import "BranchOpenRequest.h"

// Expose private methods and properties for testing
@interface Branch (DisableNextForegroundTest)
- (void)applicationDidBecomeActive;
- (void)applicationWillResignActive;
- (void)initUserSessionAndCallCallback:(BOOL)callCallback sceneIdentifier:(NSString *)sceneIdentifier urlString:(NSString *)urlString reset:(BOOL)reset;
@property (strong, nonatomic) BNCServerRequestQueue *requestQueue;
@end

@interface BranchDisableNextForegroundTests : XCTestCase
@property (nonatomic, strong) Branch *branch;
@end

@implementation BranchDisableNextForegroundTests

- (void)setUp {
    [super setUp];
    self.branch = [Branch getInstance];
    // Drain any pending work from previous tests
    [self drainIsolationQueueWithCount:3];
    [BNCPreferenceHelper sharedInstance].trackingDisabled = NO;
}

- (void)tearDown {
    [Branch resumeSession];
    [BNCPreferenceHelper sharedInstance].trackingDisabled = NO;
    // Drain pending work to prevent state leaking into next test
    [self drainIsolationQueueWithCount:3];
    self.branch = nil;
    [super tearDown];
}

#pragma mark - Helper

// BNCInitStatus values: 0 = Uninitialized, 1 = Initializing, 2 = Initialized
- (NSInteger)initializationStatus {
    return [[self.branch valueForKey:@"initializationStatus"] integerValue];
}

- (void)setInitializationStatus:(NSInteger)status {
    [self.branch setValue:@(status) forKey:@"initializationStatus"];
}

- (void)drainIsolationQueue {
    [self drainIsolationQueueWithCount:1];
}

// Count the number of BranchOpenRequest (install or open) entries in the request queue.
- (NSInteger)openRequestCountInQueue {
    BNCServerRequestQueue *queue = [self.branch valueForKey:@"requestQueue"];
    NSInteger count = 0;
    for (NSInteger i = 0; i < [queue queueDepth]; i++) {
        id req = [queue peekAt:(unsigned int)i];
        if ([req isKindOfClass:[BranchOpenRequest class]]) {
            count++;
        }
    }
    return count;
}

// Drain isolation queue multiple times to handle nested dispatch_async calls.
// initUserSessionAndCallCallback -> initializeSessionAndCallCallback uses nested dispatches.
- (void)drainIsolationQueueWithCount:(NSInteger)count {
    dispatch_queue_t isolationQueue = [self.branch valueForKey:@"isolationQueue"];
    for (NSInteger i = 0; i < count; i++) {
        XCTestExpectation *expectation = [self expectationWithDescription:
            [NSString stringWithFormat:@"isolationQueue drain %ld", (long)i]];
        dispatch_async(isolationQueue, ^{
            [expectation fulfill];
        });
        [self waitForExpectationsWithTimeout:3.0 handler:nil];
    }
}

#pragma mark - disableNextForeground blocks applicationDidBecomeActive

- (void)testDisableNextForeground_BlocksApplicationDidBecomeActive {
    [self setInitializationStatus:0]; // BNCInitStatusUninitialized

    [Branch disableNextForeground];

    // applicationDidBecomeActive should early return due to disable flag
    [self.branch applicationDidBecomeActive];

    // Since it returned early (synchronous, no async dispatch), status should remain uninitialized
    XCTAssertEqual([self initializationStatus], 0, @"initializationStatus should remain uninitialized when automatic open tracking is disabled");
}

- (void)testDisableNextForegroundForTimeInterval_BlocksApplicationDidBecomeActive {
    [self setInitializationStatus:0];

    [Branch disableNextForegroundForTimeInterval:10.0];

    [self.branch applicationDidBecomeActive];

    XCTAssertEqual([self initializationStatus], 0, @"initializationStatus should remain uninitialized when automatic open tracking is disabled");
}

#pragma mark - Zero timeout requires manual resume

- (void)testDisableNextForegroundForTimeInterval_ZeroTimeout_RequiresManualResume {
    [self setInitializationStatus:0];

    // Zero timeout means indefinite disable, no timer is created
    [Branch disableNextForegroundForTimeInterval:0];

    [self.branch applicationDidBecomeActive];
    XCTAssertEqual([self initializationStatus], 0, @"Should be blocked immediately");

    // Even after waiting, should still be blocked (no auto-resume timer)
    XCTestExpectation *expectation = [self expectationWithDescription:@"Wait to verify no auto-resume"];
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [self.branch applicationDidBecomeActive];
        XCTAssertEqual([self initializationStatus], 0, @"Should still be blocked without manual resumeSession call");
        [expectation fulfill];
    });

    [self waitForExpectationsWithTimeout:3.0 handler:nil];
}

#pragma mark - Timer auto-resumes after timeout

- (void)testDisableNextForegroundForTimeInterval_TimerAutoResumes {
    [self setInitializationStatus:0];

    // Disable with a short 1 second timeout
    [Branch disableNextForegroundForTimeInterval:1.0];

    // Immediately, applicationDidBecomeActive should be blocked
    [self.branch applicationDidBecomeActive];
    XCTAssertEqual([self initializationStatus], 0, @"Should be blocked before timer fires");

    // After the timer fires (~1 second), resumeSession is called automatically.
    // Verify that applicationDidBecomeActive no longer early returns by checking
    // that it proceeds to the async dispatch (which changes initializationStatus).
    XCTestExpectation *expectation = [self expectationWithDescription:@"Timer fires and auto-resumes"];
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1.5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        // Timer should have fired by now, calling resumeSession.
        // applicationDidBecomeActive should no longer early return.
        [self.branch applicationDidBecomeActive];

        // Give the isolationQueue time to process (nested dispatches)
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            NSInteger status = [self initializationStatus];
            XCTAssertTrue(status != 0, @"After timer auto-resume, applicationDidBecomeActive should proceed (status: %ld)", (long)status);
            [expectation fulfill];
        });
    });

    [self waitForExpectationsWithTimeout:5.0 handler:nil];
}

#pragma mark - Lifecycle cycle while disabled leaves SDK uninitialized

- (void)testLifecycleCycleWhileDisabled_LeavesSDKUninitialized {
    // This tests the problematic scenario documented in the @warning:
    // 1. disableNextForegroundForTimeInterval called
    // 2. applicationWillResignActive fires -> sets initializationStatus = uninitialized
    // 3. applicationDidBecomeActive fires -> skipped due to disable
    // Result: SDK is stuck in uninitialized state

    // Start with SDK in initialized state
    [self setInitializationStatus:2]; // BNCInitStatusInitialized

    // Step 1: Disable next foreground
    [Branch disableNextForegroundForTimeInterval:30.0];

    // Step 2: App goes to background (async on isolationQueue)
    [self.branch applicationWillResignActive];
    [self drainIsolationQueue];

    // Verify SDK is now uninitialized
    XCTAssertEqual([self initializationStatus], 0, @"SDK should be uninitialized after applicationWillResignActive");

    // Step 3: App returns to foreground - blocked by disable flag
    [self.branch applicationDidBecomeActive];

    // SDK should STILL be uninitialized
    XCTAssertEqual([self initializationStatus], 0, @"SDK should remain uninitialized because applicationDidBecomeActive was skipped due to disable");
}

#pragma mark - resumeSession does not reinitialize

- (void)testResumeSession_DoesNotReinitializeSDK {
    // Verify that resumeSession only re-enables automatic open tracking
    // and does NOT reinitialize the SDK itself
    [self setInitializationStatus:0]; // BNCInitStatusUninitialized

    [Branch disableNextForegroundForTimeInterval:30.0];
    [Branch resumeSession];

    // resumeSession should NOT have changed initializationStatus
    XCTAssertEqual([self initializationStatus], 0, @"resumeSession should not reinitialize the SDK, only re-enable automatic open tracking");
}

#pragma mark - resumeSession when not disabled is safe

- (void)testResumeSession_WhenNotDisabled_HasNoEffect {
    [self setInitializationStatus:2]; // BNCInitStatusInitialized

    // Calling resumeSession without prior disable should be safe (no-op)
    [Branch resumeSession];

    XCTAssertEqual([self initializationStatus], 2, @"resumeSession when not disabled should not affect SDK state");
}

#pragma mark - Multiple disable calls cancel existing timer

- (void)testMultipleDisableCalls_CancelsExistingTimer {
    [self setInitializationStatus:0];

    // First call with short timeout
    [Branch disableNextForegroundForTimeInterval:0.5];
    // Second call with longer timeout replaces the first timer
    [Branch disableNextForegroundForTimeInterval:10.0];

    // After the first timer would have fired, should still be blocked
    XCTestExpectation *expectation = [self expectationWithDescription:@"First timer should have been cancelled"];
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        // Reset status to 0 right before check, in case a previous test's async init completed
        [self setInitializationStatus:0];
        [self.branch applicationDidBecomeActive];
        XCTAssertEqual([self initializationStatus], 0, @"Should still be blocked because second disable call replaced the first timer");
        [expectation fulfill];
    });

    [self waitForExpectationsWithTimeout:3.0 handler:nil];
}

#pragma mark - Full lifecycle scenario: disable -> background -> foreground -> resume

- (void)testFullLifecycleScenario_ResumeAfterLifecycleCycle {
    // Complete scenario: disable -> resign -> become active -> resume
    // After resume, SDK should still be uninitialized (no automatic re-init)
    [self setInitializationStatus:2]; // Start initialized

    // Disable
    [Branch disableNextForegroundForTimeInterval:30.0];

    // Background (sets uninitialized)
    [self.branch applicationWillResignActive];
    [self drainIsolationQueue];
    XCTAssertEqual([self initializationStatus], 0, @"Should be uninitialized after background");

    // Foreground (blocked, skipped)
    [self.branch applicationDidBecomeActive];
    XCTAssertEqual([self initializationStatus], 0, @"Should remain uninitialized, foreground skipped");

    // Resume session (only flips the flag)
    [Branch resumeSession];
    XCTAssertEqual([self initializationStatus], 0, @"Should remain uninitialized after resumeSession, SDK will re-init on next foreground");
}

#pragma mark - Race condition: handleDeepLink while disabled

- (void)testHandleDeepLink_WhileDisabled_ResetsInitStatus {
    // handleDeepLink directly sets initializationStatus = Uninitialized (synchronously)
    // and calls initUserSessionAndCallCallback, bypassing the disable flag.
    // The disable flag only blocks applicationDidBecomeActive, NOT handleDeepLink.
    [self setInitializationStatus:2]; // Start initialized

    [Branch disableNextForegroundForTimeInterval:30.0];

    // handleDeepLink should still work even when disable is active.
    // It synchronously resets initializationStatus to 0 before dispatching async work.
    NSURL *testURL = [NSURL URLWithString:@"testbed://open?link_click_id=test123"];
    [self.branch handleDeepLink:testURL];

    // Verify handleDeepLink synchronously reset initializationStatus to Uninitialized (0).
    // Note: async init work may have already started on isolationQueue,
    // but the synchronous reset on line 858 proves handleDeepLink was NOT blocked by the disable flag.
    NSInteger statusAfterCall = [self initializationStatus];
    XCTAssertEqual(statusAfterCall, 0, @"handleDeepLink should synchronously reset initializationStatus to Uninitialized even when disable is active");
}

- (void)testHandleDeepLink_DuringDisabledLifecycleCycle {
    // Scenario: disable -> background -> handleDeepLink -> foreground
    // handleDeepLink should trigger init even though applicationDidBecomeActive is blocked
    [self setInitializationStatus:2]; // Start initialized

    // Step 1: Disable
    [Branch disableNextForegroundForTimeInterval:30.0];

    // Step 2: Background
    [self.branch applicationWillResignActive];
    [self drainIsolationQueue];
    XCTAssertEqual([self initializationStatus], 0, @"Should be uninitialized after background");

    // Step 3: handleDeepLink arrives (e.g., universal link while app was in background)
    NSURL *testURL = [NSURL URLWithString:@"testbed://open?link_click_id=test456"];
    [self.branch handleDeepLink:testURL];
    // Drain multiple times for nested dispatches in initializeSessionAndCallCallback
    [self drainIsolationQueueWithCount:3];

    // handleDeepLink bypasses the disable flag and triggers init
    NSInteger statusAfterDeepLink = [self initializationStatus];
    XCTAssertTrue(statusAfterDeepLink != 0, @"handleDeepLink should trigger init even while disable is active (status: %ld)", (long)statusAfterDeepLink);
}

#pragma mark - Race condition: setCPP level while disabled

- (void)testSetCPPLevelToFull_WhileDisabled_TriggersInit {
    // setConsumerProtectionAttributionLevel(Full) from None state
    // calls initUserSessionAndCallCallback, bypassing the disable flag
    [self setInitializationStatus:0]; // Start uninitialized
    [BNCPreferenceHelper sharedInstance].trackingDisabled = YES;

    [Branch disableNextForegroundForTimeInterval:30.0];

    // Setting CPP to Full re-enables tracking and calls initUserSessionAndCallCallback
    [self.branch setConsumerProtectionAttributionLevel:BranchAttributionLevelFull];
    [self drainIsolationQueueWithCount:3];

    // init should have been triggered despite disable being active
    NSInteger status = [self initializationStatus];
    XCTAssertTrue(status != 0, @"setCPP to Full should trigger init even while disable is active (status: %ld)", (long)status);
    XCTAssertFalse([Branch trackingDisabled], @"Tracking should be re-enabled after setCPP to Full");
}

- (void)testSetCPPLevelToFull_DuringDisabledLifecycleCycle {
    // Scenario: disable -> background -> foreground (blocked) -> setCPP Full
    // setCPP Full should recover the SDK from the uninitialized state
    [self setInitializationStatus:2]; // Start initialized
    [BNCPreferenceHelper sharedInstance].trackingDisabled = NO;

    // Disable and cycle through background/foreground
    [Branch disableNextForegroundForTimeInterval:30.0];
    [self.branch applicationWillResignActive];
    [self drainIsolationQueue];
    [self.branch applicationDidBecomeActive]; // blocked

    XCTAssertEqual([self initializationStatus], 0, @"SDK should be stuck uninitialized");

    // First set to None to enable the None->Full transition
    [self.branch setConsumerProtectionAttributionLevel:BranchAttributionLevelNone];
    XCTAssertEqual([self initializationStatus], 0, @"Should remain uninitialized after setCPP to None");

    // Now set to Full - this should trigger init
    [self.branch setConsumerProtectionAttributionLevel:BranchAttributionLevelFull];
    [self drainIsolationQueueWithCount:3];

    NSInteger status = [self initializationStatus];
    XCTAssertTrue(status != 0, @"setCPP Full should recover SDK from uninitialized state (status: %ld)", (long)status);
}

#pragma mark - Race condition: initSession while disabled

- (void)testInitSession_WhileDisabled_BypassesDisableFlag {
    // initSession calls initUserSessionAndCallCallback directly
    // It does NOT check bnc_disableAutomaticOpenTracking
    // Only applicationDidBecomeActive checks that flag
    [self setInitializationStatus:0]; // Start uninitialized

    [Branch disableNextForegroundForTimeInterval:30.0];

    // initUserSessionAndCallCallback has nested dispatches to isolationQueue
    [self.branch initUserSessionAndCallCallback:YES sceneIdentifier:nil urlString:nil reset:NO];
    [self drainIsolationQueueWithCount:3];

    // init should proceed despite disable being active
    NSInteger status = [self initializationStatus];
    XCTAssertTrue(status != 0, @"initSession should bypass disable flag (status: %ld)", (long)status);
}

- (void)testInitSession_DuringDisabledLifecycleCycle {
    // Scenario: disable -> background -> foreground (blocked) -> explicit initSession
    // Explicit initSession should recover the SDK
    [self setInitializationStatus:2]; // Start initialized

    [Branch disableNextForegroundForTimeInterval:30.0];
    [self.branch applicationWillResignActive];
    [self drainIsolationQueue];
    [self.branch applicationDidBecomeActive]; // blocked

    XCTAssertEqual([self initializationStatus], 0, @"SDK should be stuck uninitialized");

    // Explicit initSession should recover
    [self.branch initUserSessionAndCallCallback:YES sceneIdentifier:nil urlString:nil reset:NO];
    [self drainIsolationQueueWithCount:3];

    NSInteger status = [self initializationStatus];
    XCTAssertTrue(status != 0, @"Explicit initSession should recover SDK from uninitialized state (status: %ld)", (long)status);
}

#pragma mark - Race condition: continueUserActivity while disabled

- (void)testContinueUserActivity_WhileDisabled_BypassesDisableFlag {
    // continueUserActivity calls handleDeepLink or initUserSessionAndCallCallback
    // Neither checks bnc_disableAutomaticOpenTracking
    [self setInitializationStatus:2]; // Start initialized

    [Branch disableNextForegroundForTimeInterval:30.0];

    NSUserActivity *activity = [[NSUserActivity alloc] initWithActivityType:NSUserActivityTypeBrowsingWeb];
    activity.webpageURL = [NSURL URLWithString:@"https://testbed.app.link/test123"];
    [self.branch continueUserActivity:activity];
    [self drainIsolationQueueWithCount:3];

    // continueUserActivity calls handleDeepLink which resets and re-initializes
    NSInteger status = [self initializationStatus];
    XCTAssertTrue(status != 2, @"continueUserActivity should trigger re-init even while disable is active (status: %ld)", (long)status);
}

#pragma mark - Race condition: handleDeepLink concurrent with applicationDidBecomeActive

- (void)testHandleDeepLink_ThenApplicationDidBecomeActive_WhileDisabled {
    // If handleDeepLink is called and kicks off initialization, then
    // applicationDidBecomeActive fires, the disable flag should still block the duplicate open
    [self setInitializationStatus:0];

    [Branch disableNextForegroundForTimeInterval:30.0];

    // handleDeepLink triggers init (bypasses disable)
    NSURL *testURL = [NSURL URLWithString:@"testbed://open?link_click_id=test789"];
    [self.branch handleDeepLink:testURL];

    // applicationDidBecomeActive should still be blocked
    [self.branch applicationDidBecomeActive];

    [self drainIsolationQueueWithCount:3];

    // The init from handleDeepLink should have proceeded
    NSInteger status = [self initializationStatus];
    XCTAssertTrue(status != 0, @"handleDeepLink init should have proceeded (status: %ld)", (long)status);
}

#pragma mark - Race condition: handleDeepLink concurrent with applicationDidBecomeActive Reverse Order

- (void)testApplicationDidBecomeActive_Then_HandleDeepLink_WhileDisabled {
    // If handleDeepLink is called and kicks off initialization, then
    // applicationDidBecomeActive fires, the disable flag should still block the duplicate open
    [self setInitializationStatus:0];

    [Branch disableNextForegroundForTimeInterval:30.0];

    // applicationDidBecomeActive should still be blocked
    [self.branch applicationDidBecomeActive];
    
    // handleDeepLink triggers init (bypasses disable)
    NSURL *testURL = [NSURL URLWithString:@"testbed://open?link_click_id=test789"];
    [self.branch handleDeepLink:testURL];

    [self drainIsolationQueueWithCount:3];

    // The init from handleDeepLink should have proceeded
    NSInteger status = [self initializationStatus];
    XCTAssertTrue(status != 0, @"handleDeepLink init should have proceeded (status: %ld)", (long)status);
}

#pragma mark - Duplicate OPEN prevention: handleDeepLink + applicationDidBecomeActive

- (void)testHandleDeepLink_ThenResumeThenForeground_NoDuplicateOpen {
    // Scenario:
    // 1. disableNextForeground is active
    // 2. handleDeepLink triggers init (queues OPEN)
    // 3. applicationDidBecomeActive fires
    // Verify: only one OPEN request should be in the queue (no duplicate)
    [self setInitializationStatus:0];

    [Branch disableNextForegroundForTimeInterval:30.0];

    // handleDeepLink queues an OPEN
    NSURL *testURL = [NSURL URLWithString:@"testbed://open?link_click_id=test_no_dup"];
    [self.branch handleDeepLink:testURL];
    [self drainIsolationQueueWithCount:3];

    NSInteger opensAfterDeepLink = [self openRequestCountInQueue];

    [self.branch applicationDidBecomeActive];
    [self drainIsolationQueueWithCount:3];

    NSInteger opensAfterForeground = [self openRequestCountInQueue];

    // applicationDidBecomeActive should NOT have added another OPEN because either:
    // - initializationStatus is already Initializing/Initialized, OR
    // - containsInstallOrOpen returns YES
    XCTAssertTrue(opensAfterForeground <= opensAfterDeepLink,
        @"applicationDidBecomeActive should not add a duplicate OPEN (before: %ld, after: %ld)",
        (long)opensAfterDeepLink, (long)opensAfterForeground);
}

#pragma mark - Duplicate OPEN prevention: initSession + applicationDidBecomeActive

- (void)testInitSession_ThenResumeThenForeground_NoDuplicateOpen {
    // Scenario:
    // 1. disableNextForeground is active
    // 2. Explicit initSession triggers init (queues OPEN)
    // 3. applicationDidBecomeActive fires
    // Verify: no duplicate OPEN
    [self setInitializationStatus:0];

    [Branch disableNextForegroundForTimeInterval:30.0];

    // initSession queues an OPEN
    [self.branch initUserSessionAndCallCallback:YES sceneIdentifier:nil urlString:nil reset:NO];
    [self drainIsolationQueueWithCount:3];

    NSInteger opensAfterInit = [self openRequestCountInQueue];

    [self.branch applicationDidBecomeActive];
    [self drainIsolationQueueWithCount:3];

    NSInteger opensAfterForeground = [self openRequestCountInQueue];

    XCTAssertTrue(opensAfterForeground <= opensAfterInit,
        @"applicationDidBecomeActive should not add a duplicate OPEN (before: %ld, after: %ld)",
        (long)opensAfterInit, (long)opensAfterForeground);
}

#pragma mark - Duplicate OPEN prevention: setCPP Full + applicationDidBecomeActive

- (void)testSetCPPFull_ThenResumeThenForeground_NoDuplicateOpen {
    // Scenario:
    // 1. disableNextForeground is active, tracking disabled
    // 2. setCPP Full triggers init (queues OPEN)
    // 3. resumeSession re-enables tracking
    // 4. applicationDidBecomeActive fires
    // Verify: no duplicate OPEN
    [self setInitializationStatus:0];
    [BNCPreferenceHelper sharedInstance].trackingDisabled = YES;

    [Branch disableNextForegroundForTimeInterval:30.0];

    // setCPP Full triggers init
    [self.branch setConsumerProtectionAttributionLevel:BranchAttributionLevelFull];
    [self drainIsolationQueueWithCount:3];

    NSInteger opensAfterCPP = [self openRequestCountInQueue];

    // Resume and trigger applicationDidBecomeActive
    [Branch resumeSession];
    [self.branch applicationDidBecomeActive];
    [self drainIsolationQueueWithCount:3];

    NSInteger opensAfterForeground = [self openRequestCountInQueue];

    XCTAssertTrue(opensAfterForeground <= opensAfterCPP,
        @"applicationDidBecomeActive should not add a duplicate OPEN (before: %ld, after: %ld)",
        (long)opensAfterCPP, (long)opensAfterForeground);
}

#pragma mark - Duplicate OPEN prevention: continueUserActivity + applicationDidBecomeActive

- (void)testContinueUserActivity_ThenResumeThenForeground_NoDuplicateOpen {
    // Scenario:
    // 1. disableNextForeground is active
    // 2. continueUserActivity triggers init (queues OPEN)
    // 3. resumeSession re-enables tracking
    // 4. applicationDidBecomeActive fires
    // Verify: no duplicate OPEN
    [self setInitializationStatus:2];

    [Branch disableNextForegroundForTimeInterval:30.0];

    NSUserActivity *activity = [[NSUserActivity alloc] initWithActivityType:NSUserActivityTypeBrowsingWeb];
    activity.webpageURL = [NSURL URLWithString:@"https://testbed.app.link/test_no_dup"];
    [self.branch continueUserActivity:activity];
    [self drainIsolationQueueWithCount:3];

    NSInteger opensAfterActivity = [self openRequestCountInQueue];

    // Resume and trigger applicationDidBecomeActive
    [Branch resumeSession];
    [self.branch applicationDidBecomeActive];
    [self drainIsolationQueueWithCount:3];

    NSInteger opensAfterForeground = [self openRequestCountInQueue];

    XCTAssertTrue(opensAfterForeground <= opensAfterActivity,
        @"applicationDidBecomeActive should not add a duplicate OPEN (before: %ld, after: %ld)",
        (long)opensAfterActivity, (long)opensAfterForeground);
}

@end
