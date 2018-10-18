//
//  BNCServerRequestQueueTests.m
//  Branch-TestBed
//
//  Created by Graham Mueller on 6/17/15.
//  Copyright (c) 2015 Branch Metrics. All rights reserved.
//

#import "BNCTestCase.h"
#import "BNCServerRequestQueue.h"
#import "BranchOpenRequest.h"
#import "BranchCloseRequest.h"
#import <OCMock/OCMock.h>
#import "Branch.h"

@interface BNCServerRequestQueue (BNCTests)
- (void)retrieve;
- (void) cancelTimer;
@end

@interface BNCServerRequestQueueTests : BNCTestCase
@end

@implementation BNCServerRequestQueueTests

#pragma mark - MoveOpenOrInstallToFront tests

+ (void) setUp {
    [self clearAllBranchSettings]; // Clear any saved data before our tests start.
//    Branch*branch = [Branch getInstance:@"key_live_foo"];
//    [self clearAllBranchSettings];
}

- (void)testMoveOpenOrInstallToFrontWhenEmpty {
    BNCServerRequestQueue *requestQueue = [[BNCServerRequestQueue alloc] init];
    XCTAssertNoThrow([requestQueue moveInstallOrOpenToFront:0]);
}

- (void)testMoveOpenOrInstallToFrontWhenNotPresent {
    BNCServerRequestQueue *requestQueue = [[BNCServerRequestQueue alloc] init];
    [requestQueue insert:[[BNCServerRequest alloc] init] at:0];
    [requestQueue insert:[[BNCServerRequest alloc] init] at:0];
    XCTAssertNoThrow([requestQueue moveInstallOrOpenToFront:0]);
}

- (void)testMoveOpenOrInstallToFrontWhenAlreadyInFrontAndNoRequestsInProgress {
    BNCServerRequestQueue *requestQueue = [[BNCServerRequestQueue alloc] init];
    [requestQueue insert:[[BranchOpenRequest alloc] init] at:0];
    
    id requestQueueMock = OCMPartialMock(requestQueue);
    [[requestQueueMock reject] removeAt:0];
    
    [requestQueue moveInstallOrOpenToFront:0];
}

- (void)testMoveOpenOrInstallToFrontWhenAlreadyInFrontWithRequestsInProgress {
    BNCServerRequestQueue *requestQueue = [[BNCServerRequestQueue alloc] init];
    [requestQueue insert:[[BranchOpenRequest alloc] init] at:0];

    id requestQueueMock = OCMPartialMock(requestQueue);
    [[requestQueueMock reject] removeAt:0];
    
    [requestQueue moveInstallOrOpenToFront:1];
}

- (void)testMoveOpenOrInstallToFrontWhenSecondInLineWithRequestsInProgress {
    BNCServerRequestQueue *requestQueue = [[BNCServerRequestQueue alloc] init];
    [requestQueue insert:[[BNCServerRequest alloc] init] at:0];
    [requestQueue insert:[[BranchOpenRequest alloc] init] at:1];
    
    id requestQueueMock = OCMPartialMock(requestQueue);
    [[requestQueueMock reject] removeAt:1];
    
    [requestQueue moveInstallOrOpenToFront:1];
}

- (void)testMoveOpenOrInstallToFrontWhenSecondInLineWithNoRequestsInProgress {
    BNCServerRequestQueue *requestQueue = [[BNCServerRequestQueue alloc] init];
    BranchOpenRequest *openRequest = [[BranchOpenRequest alloc] init];
    [requestQueue insert:[[BNCServerRequest alloc] init] at:0];
    [requestQueue insert:openRequest at:1];
    
    id requestQueueMock = OCMPartialMock(requestQueue);
    [[[requestQueueMock expect] andForwardToRealObject] removeAt:1];
    
    [requestQueue moveInstallOrOpenToFront:0];
    XCTAssertEqual([requestQueue peek], openRequest);
    
    [requestQueueMock verify];
}

- (void)testMoveOpenOrInstallToFrontWhenThirdInLineWithRequestsInProgress {
    BNCServerRequestQueue *requestQueue = [[BNCServerRequestQueue alloc] init];
    BranchOpenRequest *openRequest = [[BranchOpenRequest alloc] init];
    [requestQueue insert:[[BNCServerRequest alloc] init] at:0];
    [requestQueue insert:[[BNCServerRequest alloc] init] at:1];
    [requestQueue insert:openRequest at:2];
    
    id requestQueueMock = OCMPartialMock(requestQueue);
    [[[requestQueueMock expect] andForwardToRealObject] removeAt:2];
    
    [requestQueue moveInstallOrOpenToFront:1];
    XCTAssertEqual([requestQueue peekAt:1], openRequest);
    
    [requestQueueMock verify];
}

- (void)testMoveOpenOrInstallToFrontWhenThirdInLineWithNoRequestsInProgress {
    BNCServerRequestQueue *requestQueue = [[BNCServerRequestQueue alloc] init];
    BranchOpenRequest *openRequest = [[BranchOpenRequest alloc] init];
    [requestQueue insert:[[BNCServerRequest alloc] init] at:0];
    [requestQueue insert:[[BNCServerRequest alloc] init] at:1];
    [requestQueue insert:openRequest at:2];
    
    id requestQueueMock = OCMPartialMock(requestQueue);
    [[[requestQueueMock expect] andForwardToRealObject] removeAt:2];
    
    [requestQueue moveInstallOrOpenToFront:0];
    XCTAssertEqual([requestQueue peek], openRequest);
    
    [requestQueueMock verify];
}

#pragma mark - Persist Tests

- (void)testPersistEventually {
    BNCServerRequestQueue *queue = [[BNCServerRequestQueue alloc] init];
    [queue persistEventually];
    XCTAssert(queue.isDirty);
    sleep(4);
    XCTAssert(!queue.isDirty);
}

// TODO: Mocking NSKeyedArchiver interferes with too many other classes. Maybe try something else?
/*
- (void)testPersistWhenArchiveFails {
    BNCServerRequestQueue *queue = [[BNCServerRequestQueue alloc] init];
    [queue cancelTimer];

    XCTestExpectation *expectation = [self expectationWithDescription:@"testPersistWhenArchiveFails"];
    id archiverMock = OCMClassMock([NSKeyedArchiver class]);
    [[[[[archiverMock expect]
        andDo:^(NSInvocation *invocation) {
            [expectation fulfill];
        }]
        andThrow:[NSException exceptionWithName:@"Exception" reason:@"I said so" userInfo:@{@"Test": @"TestReason"}]]
        andReturn:[NSData data]]
            archivedDataWithRootObject:[OCMArg any]];

    [queue enqueue:[[BNCServerRequest alloc] init]];
    [queue cancelTimer];

    [queue persistImmediately];
    [self awaitExpectations];
    [archiverMock verify];
    [archiverMock stopMocking];
    [queue cancelTimer];
}
*/

// TODO: Mocking NSKeyedArchiver interferes with too many other classes. Maybe try something else?
/*
- (void)testCloseRequestsArentPersisted {
    XCTestExpectation *expectation = [self expectationWithDescription:@"testCloseRequestsArentPersisted"];
    BNCServerRequestQueue *requestQueue = [[BNCServerRequestQueue alloc] init];
    [requestQueue cancelTimer];

    id archiverMock = OCMClassMock([NSKeyedArchiver class]);
    [[archiverMock reject] archiveRootObject:[OCMArg any] toFile:[OCMArg any]];
    [[[archiverMock expect]
        andReturn:[NSData data]]
            archivedDataWithRootObject:[OCMArg checkWithBlock:^BOOL(NSArray *reqs) {
                if ([reqs isKindOfClass:[NSArray class]]) {
                    XCTAssert(reqs.count == 0);
                    [self safelyFulfillExpectation:expectation];
                    return YES;
                }
                return NO;
            }]];

    BranchCloseRequest *closeRequest = [[BranchCloseRequest alloc] init];
    [requestQueue enqueue:closeRequest];
    XCTAssertEqual(requestQueue.queueDepth, 1);
    [requestQueue cancelTimer];
    [requestQueue persistImmediately];

    // Wait for operation to occur
    [self awaitExpectations];
    [archiverMock verify];
    [archiverMock stopMocking];
}
*/

#pragma mark - Retrieve Tests

- (void)testRetrieveFailWhenReadingData {
    //  Test handling an exception when reading data from storage.

    XCTestExpectation *expectation = [self expectationWithDescription:@"RetrieveExpectation"];
    id nsdataMock = [OCMockObject mockForClass:[NSData class]];
    [[[[nsdataMock expect]
        andDo:^(NSInvocation *invocation) {
            [expectation fulfill];
        }]
        andReturn:nil]
            dataWithContentsOfURL:[OCMArg any]
            options:0
            error:[OCMArg anyObjectRef]];

    BNCServerRequestQueue *queue = [[BNCServerRequestQueue alloc] init];
    [queue cancelTimer];
    [queue retrieve];
    [self awaitExpectations];
    [nsdataMock verify];
    [nsdataMock stopMocking];
}

- (void)testRetrieveFailWhenUnarchivingFile {
    //  Test handling an exception when unarchiving.

    XCTestExpectation *expectation = [self expectationWithDescription:@"UnarchiveThrowExpectation"];
    id unarchiverMock = [OCMockObject mockForClass:[NSKeyedUnarchiver class]];
    [[[[unarchiverMock expect]
        andDo:^(NSInvocation *invocation) {
            [expectation fulfill];
        }]
        andThrow:[NSException exceptionWithName:@"Exception" reason:@"I said so" userInfo:nil]]
            unarchiveObjectWithData:[OCMArg any]];

    BNCServerRequestQueue *queue = [[BNCServerRequestQueue alloc] init];
    [queue cancelTimer];
    [queue retrieve];
    [self awaitExpectations];
    [unarchiverMock verify];
    [unarchiverMock stopMocking];
}

- (void)testRetrieveFailWhenUnarchivingRecord {
    //  Test handling an exception when unarchiving.

    XCTestExpectation *expectation = [self expectationWithDescription:@"UnarchiveThrowExpectation"];
    id unarchiverMock = [OCMockObject mockForClass:[NSKeyedUnarchiver class]];
    [[[[unarchiverMock expect]
        andDo:^(NSInvocation *invocation) {
            [expectation fulfill];
        }]
        andReturn:@[ [@"Garbage" dataUsingEncoding:NSUTF8StringEncoding] ]]
            unarchiveObjectWithData:[OCMArg any]];

    BNCServerRequestQueue *queue = [[BNCServerRequestQueue alloc] init];
    [queue retrieve];
    [self awaitExpectations];
    [unarchiverMock verify];
    [unarchiverMock stopMocking];
}

- (void)testPersistedCloseRequestsArentLoaded {
    //  Mock up the 'saved' data:

    BranchCloseRequest *closeRequest = [[BranchCloseRequest alloc] init];
    BranchOpenRequest *openRequest = [[BranchOpenRequest alloc] init];
    NSArray *requests = @[
        [NSKeyedArchiver archivedDataWithRootObject:closeRequest],
        [NSKeyedArchiver archivedDataWithRootObject:openRequest],
        [NSKeyedArchiver archivedDataWithRootObject:closeRequest]
    ];

    id nsdataMock = [OCMockObject mockForClass:[NSData class]];
    [[[nsdataMock expect]
        andReturn:[NSKeyedArchiver archivedDataWithRootObject:requests]]
            dataWithContentsOfURL:[OCMArg any]
            options:0
            error:[OCMArg anyObjectRef]];

    BNCServerRequestQueue *queue = [[BNCServerRequestQueue alloc] init];
    [queue retrieve];
    [nsdataMock verify];
    XCTAssertEqual([queue queueDepth], 1);
    [nsdataMock stopMocking];
}

@end
