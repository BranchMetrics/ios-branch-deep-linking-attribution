//
//  BNCServerRequestQueueSessionWaitTests.m
//  BranchSDKTests
//
//  Behavioral coverage for the session wait lock: requests that need an initialized
//  session must not reach the network before the session establishing request does.
//

#import <XCTest/XCTest.h>
#import "BNCServerRequestQueue.h"
#import "BNCServerRequestOperation.h"
#import "BNCServerRequest.h"
#import "BNCPreferenceHelper.h"
#import "BranchOpenRequest.h"
#import "BranchInstallRequest.h"
#import "BranchRequestOpen.h"
#import "BranchRequestDeepLink.h"
#import "Branch.h"

#pragma mark - Test doubles

@interface BNCSessionWaitRecorder : NSObject
@property (strong, nonatomic) NSMutableArray<NSString *> *executionOrder;
@end

@implementation BNCSessionWaitRecorder

- (instancetype)init {
    self = [super init];
    if (self) {
        _executionOrder = [NSMutableArray array];
    }
    return self;
}

- (void)recordExecutionOf:(NSString *)label {
    @synchronized (self) {
        [self.executionOrder addObject:label];
    }
}

- (NSArray<NSString *> *)snapshot {
    @synchronized (self) {
        return [self.executionOrder copy];
    }
}

@end

// Stands in for v1/url and v2/event: any request that needs an initialized session.
@interface BNCFakeSessionDependentRequest : BNCServerRequest
@property (copy, nonatomic) NSString *label;
@property (strong, nonatomic) BNCSessionWaitRecorder *recorder;
@property (copy, nonatomic) void (^onExecute)(void);
@end

@implementation BNCFakeSessionDependentRequest

- (void)makeRequest:(BNCServerInterface *)serverInterface key:(NSString *)key callback:(BNCServerCallback)callback {
    [self.recorder recordExecutionOf:self.label];
    if (self.onExecute) {
        self.onExecute();
    }
    if (callback) {
        callback(nil, nil);
    }
}

- (void)processResponse:(BNCServerResponse *)response error:(NSError *)error {
    // No-op: keeps the test off the network and out of the real session bookkeeping.
}

@end

// Stands in for the install/open that establishes the session.
@interface BNCFakeOpenRequest : BranchOpenRequest
@property (copy, nonatomic) NSString *label;
@property (strong, nonatomic) BNCSessionWaitRecorder *recorder;
@property (copy, nonatomic) void (^onExecute)(void);
@end

@implementation BNCFakeOpenRequest

- (void)makeRequest:(BNCServerInterface *)serverInterface key:(NSString *)key callback:(BNCServerCallback)callback {
    [self.recorder recordExecutionOf:self.label];
    if (self.onExecute) {
        self.onExecute();
    }
    if (callback) {
        callback(nil, nil);
    }
}

- (void)processResponse:(BNCServerResponse *)response error:(NSError *)error {
    [BranchOpenRequest releaseOpenResponseLock];
}

@end

#pragma mark - Internals under test

@interface BNCServerRequestQueue (SessionWaitTesting)
- (NSUInteger)sessionWaitingRequestCount;
- (BOOL)isSessionWaitLockReleased;
- (NSInteger)queueDepth;
- (NSTimeInterval)sessionWaitLockTimeout;
- (void)setSessionWaitLockTimeout:(NSTimeInterval)sessionWaitLockTimeout;
@end

#pragma mark - Tests

@interface BNCServerRequestQueueSessionWaitTests : XCTestCase
@property (strong, nonatomic) BNCServerRequestQueue *queue;
@property (strong, nonatomic) BNCSessionWaitRecorder *recorder;
@property (strong, nonatomic) BNCPreferenceHelper *preferenceHelper;
@property (copy, nonatomic) NSString *savedDeviceToken;
@property (copy, nonatomic) NSString *savedBundleToken;
@property (copy, nonatomic) NSString *savedAttributionLevel;
@end

@implementation BNCServerRequestQueueSessionWaitTests

- (void)setUp {
    [super setUp];

    self.preferenceHelper = [BNCPreferenceHelper sharedInstance];
    self.savedDeviceToken = self.preferenceHelper.randomizedDeviceToken;
    self.savedBundleToken = self.preferenceHelper.randomizedBundleToken;
    self.savedAttributionLevel = self.preferenceHelper.attributionLevel;

    // Tokens are present from the start, simulating a second launch where they were
    // restored from NSUserDefaults. This is exactly the case where the old
    // initializationStatus guard used to block the request and the token check does not.
    self.preferenceHelper.attributionLevel = BranchAttributionLevelFull;
    self.preferenceHelper.randomizedDeviceToken = @"test_randomized_device_token";
    self.preferenceHelper.randomizedBundleToken = @"test_randomized_bundle_token";

    self.recorder = [BNCSessionWaitRecorder new];
    self.queue = [[BNCServerRequestQueue alloc] init];
    [self.queue configureWithServerInterface:nil
                                   branchKey:@"key_live_testkey"
                            preferenceHelper:self.preferenceHelper];
}

- (void)tearDown {
    [self.queue clearQueue];
    self.queue = nil;

    [BranchOpenRequest releaseOpenResponseLock];

    self.preferenceHelper.randomizedDeviceToken = self.savedDeviceToken;
    self.preferenceHelper.randomizedBundleToken = self.savedBundleToken;
    self.preferenceHelper.attributionLevel = self.savedAttributionLevel;

    [super tearDown];
}

#pragma mark - Helpers

- (BNCFakeSessionDependentRequest *)sessionDependentRequestLabeled:(NSString *)label
                                                       expectation:(XCTestExpectation *)expectation {
    BNCFakeSessionDependentRequest *request = [BNCFakeSessionDependentRequest new];
    request.label = label;
    request.recorder = self.recorder;
    request.onExecute = ^{ [expectation fulfill]; };
    return request;
}

- (BNCFakeOpenRequest *)openRequestLabeled:(NSString *)label
                               expectation:(XCTestExpectation *)expectation {
    BNCFakeOpenRequest *request = [[BNCFakeOpenRequest alloc] initWithCallback:nil];
    request.label = label;
    request.recorder = self.recorder;
    request.onExecute = ^{ [expectation fulfill]; };
    return request;
}

- (void)waitForSessionWaitLockRelease {
    NSPredicate *released = [NSPredicate predicateWithBlock:^BOOL(id object, NSDictionary *bindings) {
        return [(BNCServerRequestQueue *)object isSessionWaitLockReleased];
    }];
    [self expectationForPredicate:released evaluatedWithObject:self.queue handler:nil];
    [self waitForExpectationsWithTimeout:5.0 handler:nil];
}

#pragma mark - Classification

- (void)testSessionEstablishingRequestsDoNotRequireASession {
    XCTAssertFalse([BNCServerRequestOperation requestRequiresSession:[[BranchOpenRequest alloc] initWithCallback:nil]]);
    XCTAssertFalse([BNCServerRequestOperation requestRequiresSession:[[BranchInstallRequest alloc] initWithCallback:nil]]);
    XCTAssertFalse([BNCServerRequestOperation requestRequiresSession:[[BranchRequestOpen alloc] initWithCallback:nil]]);
    XCTAssertFalse([BNCServerRequestOperation requestRequiresSession:[[BranchRequestDeepLink alloc] initWithCallback:nil]]);
}

- (void)testEveryOtherRequestRequiresASession {
    XCTAssertTrue([BNCServerRequestOperation requestRequiresSession:[BNCServerRequest new]]);
    XCTAssertTrue([BNCServerRequestOperation requestRequiresSession:[BNCFakeSessionDependentRequest new]]);
}

#pragma mark - Core behavior

// The regression this change targets: a request enqueued before the open must not reach
// the network first, even though a persisted device token would satisfy the token check.
- (void)testRequestNeedingSessionRunsAfterTheSessionRequest {
    XCTestExpectation *openRan = [self expectationWithDescription:@"open executed"];
    XCTestExpectation *eventRan = [self expectationWithDescription:@"event executed"];

    BNCFakeSessionDependentRequest *event = [self sessionDependentRequestLabeled:@"event" expectation:eventRan];
    [self.queue enqueue:event];

    XCTAssertEqual([self.queue sessionWaitingRequestCount], (NSUInteger)1,
                   @"Request needing a session should be held before any open is enqueued");
    XCTAssertFalse([self.queue isSessionWaitLockReleased]);
    XCTAssertEqualObjects([self.recorder snapshot], @[],
                          @"Held request must not hit the network while waiting");

    BNCFakeOpenRequest *open = [self openRequestLabeled:@"open" expectation:openRan];
    [self.queue enqueue:open];

    [self waitForExpectations:@[openRan, eventRan] timeout:5.0];

    XCTAssertEqualObjects([self.recorder snapshot], (@[@"open", @"event"]),
                          @"The open must reach the network before the request that needs the session");
    XCTAssertEqual([self.queue sessionWaitingRequestCount], (NSUInteger)0);
}

- (void)testSessionEstablishingRequestIsNeverHeld {
    XCTestExpectation *openRan = [self expectationWithDescription:@"open executed"];
    BNCFakeOpenRequest *open = [self openRequestLabeled:@"open" expectation:openRan];

    [self.queue enqueue:open];

    XCTAssertEqual([self.queue sessionWaitingRequestCount], (NSUInteger)0,
                   @"An open must never wait on itself");
    [self waitForExpectations:@[openRan] timeout:5.0];
}

- (void)testRequestIsNotHeldOnceSessionIsEstablished {
    XCTestExpectation *openRan = [self expectationWithDescription:@"open executed"];
    [self.queue enqueue:[self openRequestLabeled:@"open" expectation:openRan]];
    [self waitForExpectations:@[openRan] timeout:5.0];
    [self waitForSessionWaitLockRelease];

    XCTestExpectation *eventRan = [self expectationWithDescription:@"event executed"];
    BNCFakeSessionDependentRequest *event = [self sessionDependentRequestLabeled:@"event" expectation:eventRan];
    [self.queue enqueue:event];

    XCTAssertEqual([self.queue sessionWaitingRequestCount], (NSUInteger)0,
                   @"Steady state requests must go straight to the operation queue");
    [self waitForExpectations:@[eventRan] timeout:5.0];
    XCTAssertEqualObjects([self.recorder snapshot], (@[@"open", @"event"]));
}

// Held requests are released even when the host app never initializes a session, so a
// misintegrated app fails the way it did before instead of leaking the request forever.
- (void)testHeldRequestIsReleasedWhenSessionNeverStarts {
    [self.queue setSessionWaitLockTimeout:0.25];

    XCTestExpectation *eventRan = [self expectationWithDescription:@"event released by timeout"];
    BNCFakeSessionDependentRequest *event = [self sessionDependentRequestLabeled:@"event" expectation:eventRan];
    [self.queue enqueue:event];

    XCTAssertEqual([self.queue sessionWaitingRequestCount], (NSUInteger)1);

    [self waitForExpectations:@[eventRan] timeout:5.0];
    XCTAssertTrue([self.queue isSessionWaitLockReleased]);
    XCTAssertEqual([self.queue sessionWaitingRequestCount], (NSUInteger)0);
}

- (void)testMultipleHeldRequestsAreReleasedInEnqueueOrder {
    XCTestExpectation *openRan = [self expectationWithDescription:@"open executed"];
    XCTestExpectation *firstRan = [self expectationWithDescription:@"first executed"];
    XCTestExpectation *secondRan = [self expectationWithDescription:@"second executed"];

    [self.queue enqueue:[self sessionDependentRequestLabeled:@"first" expectation:firstRan]];
    [self.queue enqueue:[self sessionDependentRequestLabeled:@"second" expectation:secondRan]];
    XCTAssertEqual([self.queue sessionWaitingRequestCount], (NSUInteger)2);

    [self.queue enqueue:[self openRequestLabeled:@"open" expectation:openRan]];
    [self waitForExpectations:@[openRan, firstRan, secondRan] timeout:5.0];

    XCTAssertEqualObjects([self.recorder snapshot], (@[@"open", @"first", @"second"]));
}

- (void)testQueueDepthCountsHeldRequests {
    XCTestExpectation *eventRan = [self expectationWithDescription:@"event executed"];
    [self.queue enqueue:[self sessionDependentRequestLabeled:@"event" expectation:eventRan]];

    XCTAssertEqual([self.queue queueDepth], (NSInteger)1,
                   @"A held request is still pending work and must be visible in the depth");
    eventRan.inverted = YES;
    [self waitForExpectations:@[eventRan] timeout:0.5];
}

- (void)testClearQueueDropsHeldRequests {
    XCTestExpectation *eventRan = [self expectationWithDescription:@"event must not execute"];
    eventRan.inverted = YES;
    [self.queue enqueue:[self sessionDependentRequestLabeled:@"event" expectation:eventRan]];
    XCTAssertEqual([self.queue sessionWaitingRequestCount], (NSUInteger)1);

    [self.queue clearQueue];

    XCTAssertEqual([self.queue sessionWaitingRequestCount], (NSUInteger)0);
    [self waitForExpectations:@[eventRan] timeout:0.5];
    XCTAssertEqualObjects([self.recorder snapshot], @[],
                          @"Cleared requests must never reach the network");
}

@end
