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

@interface BNCServerRequestQueueTests : BNCTestCase
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

#pragma mark - Persist Tests

- (void)testPersistEventually {
    BNCServerRequestQueue *queue = [[BNCServerRequestQueue alloc] init];
    [queue persistEventually];
    XCTAssert(queue.isDirty);
    sleep(4);
    XCTAssert(!queue.isDirty);
}

- (void)testPersistWhenArchiveFails {
    BNCServerRequestQueue *queue = [[BNCServerRequestQueue alloc] init];
    [queue enqueue:[[BNCServerRequest alloc] init]];

    id archiverMock = OCMClassMock([NSKeyedArchiver class]);
    [[[[archiverMock expect]
        andThrow:[NSException exceptionWithName:@"Exception" reason:@"I said so" userInfo:nil]]
        andReturn:[NSData data]]
            archivedDataWithRootObject:[OCMArg any]];

    [queue persistImmediately];
    
    // Wait for operation to occur
    XCTestExpectation *expectation = [self expectationWithDescription:@"PersistExpectation"];
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, ((double)NSEC_PER_SEC*0.1)), dispatch_get_main_queue(), ^{
        [self safelyFulfillExpectation:expectation];
    });
    
    [self awaitExpectations];
    [archiverMock verify];
}

- (void)testCloseRequestsArentPersisted {
    @autoreleasepool {
        XCTestExpectation *expectation = [self expectationWithDescription:@"PersistExpectation"];

        id archiverMock = OCMClassMock([NSKeyedArchiver class]);
        [[archiverMock reject] archiveRootObject:[OCMArg any] toFile:[OCMArg any]];
        [[[archiverMock expect]
            andReturn:[NSData data]]
                archivedDataWithRootObject:[OCMArg checkWithBlock:^BOOL(NSArray *reqs) {
                    if ([reqs isKindOfClass:[NSArray class]]) {
                        XCTAssert(reqs.count == 0);
                        BNCAfterSecondsPerformBlock(0.01, ^{ [self safelyFulfillExpectation:expectation]; });
                        return YES;
                    }
                    return NO;
                }]];

        BNCServerRequestQueue *requestQueue = [[BNCServerRequestQueue alloc] init];
        BranchCloseRequest *closeRequest = [[BranchCloseRequest alloc] init];
        [requestQueue enqueue:closeRequest];
        [requestQueue persistImmediately];
        
        // Wait for operation to occur    
        [self awaitExpectations];
        [archiverMock verify];
        BNCSleepForTimeInterval(0.001); // Allow for mock class to be un-mocked.
    }
}

- (void)testDebugRequestsArentPersisted {
    @autoreleasepool {
        XCTestExpectation *expectation = [self expectationWithDescription:@"PersistExpectation"];
        id archiverMock = OCMClassMock([NSKeyedArchiver class]);
        [[archiverMock reject] archiveRootObject:[OCMArg any] toFile:[OCMArg any]];
        [[[archiverMock expect]
            andReturn:[NSData data]]
                archivedDataWithRootObject:[OCMArg checkWithBlock:^BOOL(NSArray *reqs) {
                    if ([reqs isKindOfClass:[NSArray class]]) {
                        XCTAssert(reqs.count == 0);
                        BNCAfterSecondsPerformBlock(0.01, ^{ [self safelyFulfillExpectation:expectation]; });
                        return YES;
                    }
                    return NO;
                }]];
                
        BNCServerRequestQueue *requestQueue = [[BNCServerRequestQueue alloc] init];
        [requestQueue persistImmediately];

        // Wait for operation to occur    
        [self awaitExpectations];
        [archiverMock verify];
        BNCSleepForTimeInterval(0.001); // Allow for mock class to be un-mocked.
    }
}

#pragma mark - Retrieve Tests

- (void)testRetrieveFailWhenReadingData {

    //  Test handling an exception when reading data from storage.

    id nsdataMock = [OCMockObject mockForClass:[NSData class]];
    [[[nsdataMock expect]
        andReturn:nil]
            dataWithContentsOfURL:[OCMArg any]
            options:0
            error:[OCMArg anyObjectRef]];

    BNCServerRequestQueue *queue = [[BNCServerRequestQueue alloc] init];
    [queue performSelector:@selector(retrieve)];
    [nsdataMock verify];
}

- (void)testRetrieveFailWhenUnarchivingFile {

    //  Test handling an exception when unarchiving.

    id unarchiverMock = [OCMockObject mockForClass:[NSKeyedUnarchiver class]];
    [[[unarchiverMock expect]
        andThrow:[NSException exceptionWithName:@"Exception" reason:@"I said so" userInfo:nil]]
            unarchiveObjectWithData:[OCMArg any]];

    BNCServerRequestQueue *queue = [[BNCServerRequestQueue alloc] init];
    [queue performSelector:@selector(retrieve)];
    [unarchiverMock verify];
}

- (void)testRetrieveFailWhenUnarchivingRecord {

    //  Test handling an exception when unarchiving.

    id unarchiverMock = [OCMockObject mockForClass:[NSKeyedUnarchiver class]];
    [[[unarchiverMock expect]
        andReturn:@[ [@"Garbage" dataUsingEncoding:NSUTF8StringEncoding] ]]
            unarchiveObjectWithData:[OCMArg any]];

    BNCServerRequestQueue *queue = [[BNCServerRequestQueue alloc] init];
    [queue performSelector:@selector(retrieve)];
    [unarchiverMock verify];
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
    [queue performSelector:@selector(retrieve)];
    [nsdataMock verify];
    XCTAssertEqual([queue queueDepth], 1);
}

// Fool the compiler by defining the 'retrieve', which normally wouldn't be visible.
- (void)retrieve {
}

@end
