//
//  BNCServerRequestQueueTests.m
//  Branch-TestBed
//
//  Created by Graham Mueller on 6/17/15.
//  Copyright (c) 2015 Branch Metrics. All rights reserved.
//

#import "BranchTest.h"
#import "BNCServerRequestQueue.h"
#import "BranchOpenRequest.h"
#import "BranchCloseRequest.h"
#import <OCMock/OCMock.h>

@interface BNCServerRequestQueueTests : BranchTest

@end

@implementation BNCServerRequestQueueTests

#pragma mark - MoveOpenOrInstallToFront tests
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

#pragma mark - Retrive Tests
- (void)testPersistWhenArchiveFails {
    BNCServerRequestQueue *queue = [[BNCServerRequestQueue alloc] init];
    [queue enqueue:[[BNCServerRequest alloc] init]];
    
    id archiverMock = OCMClassMock([NSKeyedArchiver class]);
    [[[archiverMock expect] andReturn:[NSData data]] archivedDataWithRootObject:[OCMArg any]];
    [[[archiverMock expect] andThrow:[NSException exceptionWithName:@"Exception" reason:@"I said so" userInfo:nil]] archiveRootObject:[OCMArg any] toFile:[OCMArg any]];
    
    [queue persistImmediately];
    
    // Wait for operation to occur
    XCTestExpectation *expectation = [self expectationWithDescription:@"PersistExpectation"];
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, NSEC_PER_SEC), dispatch_get_main_queue(), ^{
        [self safelyFulfillExpectation:expectation];
    });
    
    [self awaitExpectations];
    [archiverMock verify];
    [archiverMock stopMocking];
}

- (void)testCloseRequestsArentPersisted {
    BNCServerRequestQueue *requestQueue = [[BNCServerRequestQueue alloc] init];
    BranchCloseRequest *closeRequest = [[BranchCloseRequest alloc] init];
    
    [requestQueue enqueue:closeRequest];
    
    id archiverMock = OCMClassMock([NSKeyedArchiver class]);
    [[archiverMock reject] archivedDataWithRootObject:[OCMArg any]];
    [[archiverMock expect] archiveRootObject:[OCMArg checkWithBlock:^BOOL(NSArray *reqs) { return [reqs count] == 0; }] toFile:[OCMArg any]];

    [requestQueue persistImmediately];
    
    // Wait for operation to occur
    XCTestExpectation *expectation = [self expectationWithDescription:@"PersistExpectation"];
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, NSEC_PER_SEC), dispatch_get_main_queue(), ^{
        [self safelyFulfillExpectation:expectation];
    });
    
    [self awaitExpectations];
    [archiverMock verify];
    [archiverMock stopMocking];
}

- (void)testDebugRequestsArentPersisted {
    BNCServerRequestQueue *requestQueue = [[BNCServerRequestQueue alloc] init];
    
    id archiverMock = OCMClassMock([NSKeyedArchiver class]);
    [[archiverMock reject] archivedDataWithRootObject:[OCMArg any]];
    [[archiverMock expect] archiveRootObject:[OCMArg checkWithBlock:^BOOL(NSArray *reqs) { return [reqs count] == 0; }] toFile:[OCMArg any]];

    [requestQueue persistImmediately];
    
    // Wait for operation to occur
    XCTestExpectation *expectation = [self expectationWithDescription:@"PersistExpectation"];
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, NSEC_PER_SEC), dispatch_get_main_queue(), ^{
        [self safelyFulfillExpectation:expectation];
    });
    
    [self awaitExpectations];
    [archiverMock verify];
    [archiverMock stopMocking];
}

- (void)testRetrieveWhenUnarchiveFails {
    BNCServerRequestQueue *queue = [[BNCServerRequestQueue alloc] init];
    
    id unarchiverMock = OCMClassMock([NSKeyedUnarchiver class]);
    [[[unarchiverMock expect] andReturn:@[ [@"foo" dataUsingEncoding:NSUTF8StringEncoding] ]] unarchiveObjectWithFile:[OCMArg any]];
    [[[unarchiverMock expect] andThrow:[NSException exceptionWithName:@"Exception" reason:@"I said so" userInfo:nil]] unarchiveObjectWithData:[OCMArg any]];
    
    [queue performSelector:@selector(retrieve)];
    
    [unarchiverMock verify];
}

- (void)testRetrieveWhenUnarchiveFailsAfterOneSuccessful {
    BNCServerRequestQueue *queue = [[BNCServerRequestQueue alloc] init];
    BNCServerRequest *request = [[BNCServerRequest alloc] init];
    
    id unarchiverMock = OCMClassMock([NSKeyedUnarchiver class]);
    [[[unarchiverMock expect] andReturn:@[ [@"foo" dataUsingEncoding:NSUTF8StringEncoding], [@"foo" dataUsingEncoding:NSUTF8StringEncoding] ]] unarchiveObjectWithFile:[OCMArg any]];
    [[[unarchiverMock expect] andReturn:request] unarchiveObjectWithData:[OCMArg any]];
    [[[unarchiverMock expect] andThrow:[NSException exceptionWithName:@"Exception" reason:@"I said so" userInfo:nil]] unarchiveObjectWithData:[OCMArg any]];
    
    [queue performSelector:@selector(retrieve)];
    
    XCTAssertEqual([queue size], 1);
    XCTAssertEqualObjects([queue peek], request);
    
    [unarchiverMock verify];
}

- (void)testRetrieveWhenUnarchiveFailsThenHasOneSuccess {
    BNCServerRequestQueue *queue = [[BNCServerRequestQueue alloc] init];
    BNCServerRequest *request = [[BNCServerRequest alloc] init];
    
    id unarchiverMock = OCMClassMock([NSKeyedUnarchiver class]);
    [[[unarchiverMock expect] andReturn:@[ [@"foo" dataUsingEncoding:NSUTF8StringEncoding], [@"foo" dataUsingEncoding:NSUTF8StringEncoding] ]] unarchiveObjectWithFile:[OCMArg any]];
    [[[unarchiverMock expect] andThrow:[NSException exceptionWithName:@"Exception" reason:@"I said so" userInfo:nil]] unarchiveObjectWithData:[OCMArg any]];
    [[[unarchiverMock expect] andReturn:request] unarchiveObjectWithData:[OCMArg any]];
    
    [queue performSelector:@selector(retrieve)];
    
    XCTAssertEqual([queue size], 1);
    XCTAssertEqualObjects([queue peek], request);
    
    [unarchiverMock verify];
}

- (void)testPersistedCloseRequestsArentLoaded {
    BNCServerRequestQueue *queue = [[BNCServerRequestQueue alloc] init];
    BranchCloseRequest *closeRequest = [[BranchCloseRequest alloc] init];

    id unarchiverMock = OCMClassMock([NSKeyedUnarchiver class]);
    [[[unarchiverMock expect] andReturn:@[ [@"foo" dataUsingEncoding:NSUTF8StringEncoding] ]] unarchiveObjectWithFile:[OCMArg any]];
    [[[unarchiverMock expect] andReturn:closeRequest] unarchiveObjectWithData:[OCMArg any]];

    [queue performSelector:@selector(retrieve)];
    
    XCTAssertEqual([queue size], 0);
    
    [unarchiverMock verify];
}

- (void)testPersistedDebugRequestsArentLoaded {
    BNCServerRequestQueue *queue = [[BNCServerRequestQueue alloc] init];
    
    id unarchiverMock = OCMClassMock([NSKeyedUnarchiver class]);
    [[[unarchiverMock expect] andReturn:@[ [@"foo" dataUsingEncoding:NSUTF8StringEncoding] ]] unarchiveObjectWithFile:[OCMArg any]];
    
    [queue performSelector:@selector(retrieve)];
    
    XCTAssertEqual([queue size], 0);
    
    [unarchiverMock verify];
}

// Fool compiler.
- (void)retrieve { }

@end
