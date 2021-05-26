//
//  BNCServerRequestQueueTests.m
//  Branch-SDK-Tests
//
//  Created by Ernest Cho on 5/14/21.
//  Copyright © 2021 Branch, Inc. All rights reserved.
//

#import <XCTest/XCTest.h>
#import "BNCServerRequestQueue.h"
#import "BNCServerRequest.h"
#import "BranchCloseRequest.h"

// Analytics requests
#import "BranchInstallRequest.h"
#import "BranchOpenRequest.h"
#import "BranchEvent.h"
#import "BNCCommerceEvent.h"
#import "BranchUserCompletedActionRequest.h"
#import "BranchSetIdentityRequest.h"
#import "BranchLogoutRequest.h"

@interface BNCServerRequestQueue ()
- (NSData *)archiveQueue:(NSArray<BNCServerRequest *> *)queue;
- (NSMutableArray<BNCServerRequest *> *)unarchiveQueueFromData:(NSData *)data;

- (NSData *)archiveObject:(NSObject *)object;
- (id)unarchiveObjectFromData:(NSData *)data;

// returns data in the legacy format
- (NSData *)oldArchiveQueue:(NSArray<BNCServerRequest *> *)queue;

@end

@interface BNCServerRequestQueueTests : XCTestCase
@property (nonatomic, strong, readwrite) BNCServerRequestQueue *queue;
@end

@implementation BNCServerRequestQueueTests

- (void)setUp {
    self.queue = [BNCServerRequestQueue new];
}

- (void)tearDown {
    self.queue = nil;
}

- (void)testArchiveNil {
    NSString *object = nil;
    
    NSData *archived = [self.queue archiveObject:object];
    XCTAssertNotNil(archived);
    
    NSString *unarchived = [self.queue unarchiveObjectFromData:archived];
    XCTAssertNil(unarchived);
}

- (void)testArchiveString {
    NSString *object = @"Hello World";
    
    NSData *archived = [self.queue archiveObject:object];
    XCTAssertNotNil(archived);
    
    NSString *unarchived = [self.queue unarchiveObjectFromData:archived];
    XCTAssertNotNil(unarchived);
    XCTAssert([object isEqual:unarchived]);
}

- (void)testArchiveInstallRequest {
    BranchInstallRequest *object = [BranchInstallRequest new];
    
    NSData *archived = [self.queue archiveObject:object];
    XCTAssertNotNil(archived);
    
    BranchInstallRequest *unarchived = [self.queue unarchiveObjectFromData:archived];
    XCTAssertNotNil(unarchived);
    XCTAssert([unarchived isKindOfClass:[BranchInstallRequest class]]);

    // The request object is not very test friendly, so comparing the two is not helpful at the moment
}

- (void)testArchiveOpenRequest {
    BranchOpenRequest *object = [BranchOpenRequest new];
    
    NSData *archived = [self.queue archiveObject:object];
    XCTAssertNotNil(archived);
    
    BranchOpenRequest *unarchived = [self.queue unarchiveObjectFromData:archived];
    XCTAssertNotNil(unarchived);
    XCTAssert([unarchived isKindOfClass:[BranchOpenRequest class]]);

    // The request object is not very test friendly, so comparing the two is not helpful at the moment
}

- (void)testArchiveEventRequest {
    BranchEventRequest *object = [BranchEventRequest new];
    
    NSData *archived = [self.queue archiveObject:object];
    XCTAssertNotNil(archived);
    
    BranchEventRequest *unarchived = [self.queue unarchiveObjectFromData:archived];
    XCTAssertNotNil(unarchived);
    XCTAssert([unarchived isKindOfClass:[BranchEventRequest class]]);

    // The request object is not very test friendly, so comparing the two is not helpful at the moment
}

- (void)testArchiveCommerceEventRequest {
    BranchCommerceEventRequest *object = [BranchCommerceEventRequest new];
    
    NSData *archived = [self.queue archiveObject:object];
    XCTAssertNotNil(archived);
    
    BranchCommerceEventRequest *unarchived = [self.queue unarchiveObjectFromData:archived];
    XCTAssertNotNil(unarchived);
    XCTAssert([unarchived isKindOfClass:[BranchCommerceEventRequest class]]);

    // The request object is not very test friendly, so comparing the two is not helpful at the moment
}

- (void)testArchiveUserCompletedActionRequest {
    BranchUserCompletedActionRequest *object = [BranchUserCompletedActionRequest new];
    
    NSData *archived = [self.queue archiveObject:object];
    XCTAssertNotNil(archived);
    
    BranchUserCompletedActionRequest *unarchived = [self.queue unarchiveObjectFromData:archived];
    XCTAssertNotNil(unarchived);
    XCTAssert([unarchived isKindOfClass:[BranchUserCompletedActionRequest class]]);

    // The request object is not very test friendly, so comparing the two is not helpful at the moment
}

- (void)testArchiveSetIdentityRequest {
    BranchSetIdentityRequest *object = [BranchSetIdentityRequest new];
    
    NSData *archived = [self.queue archiveObject:object];
    XCTAssertNotNil(archived);
    
    BranchSetIdentityRequest *unarchived = [self.queue unarchiveObjectFromData:archived];
    XCTAssertNotNil(unarchived);
    XCTAssert([unarchived isKindOfClass:[BranchSetIdentityRequest class]]);

    // The request object is not very test friendly, so comparing the two is not helpful at the moment
}

- (void)testArchiveLogoutRequest {
    BranchLogoutRequest *object = [BranchLogoutRequest new];
    
    NSData *archived = [self.queue archiveObject:object];
    XCTAssertNotNil(archived);
    
    BranchLogoutRequest *unarchived = [self.queue unarchiveObjectFromData:archived];
    XCTAssertNotNil(unarchived);
    XCTAssert([unarchived isKindOfClass:[BranchLogoutRequest class]]);

    // The request object is not very test friendly, so comparing the two is not helpful at the moment
}

- (void)testArchiveArrayOfRequests {
    NSMutableArray<BNCServerRequest *> *tmp = [NSMutableArray<BNCServerRequest *> new];
    [tmp addObject:[BranchOpenRequest new]];
    [tmp addObject:[BranchEventRequest new]];
    
    NSData *data = [self.queue archiveQueue:tmp];
    XCTAssertNotNil(data);

    NSMutableArray *unarchived = [self.queue unarchiveQueueFromData:data];
    XCTAssertNotNil(unarchived);
    XCTAssert(unarchived.count == 2);
}

- (void)testOldArchiveArrayOfRequests {
    NSMutableArray<BNCServerRequest *> *tmp = [NSMutableArray<BNCServerRequest *> new];
    [tmp addObject:[BranchOpenRequest new]];
    [tmp addObject:[BranchEventRequest new]];
    
    NSData *data = [self.queue oldArchiveQueue:tmp];
    XCTAssertNotNil(data);

    NSMutableArray *unarchived = [self.queue unarchiveQueueFromData:data];
    XCTAssertNotNil(unarchived);
    XCTAssert(unarchived.count == 2);
}

- (void)testArchiveArrayOfInvalidObjects {
    NSMutableArray<BNCServerRequest *> *tmp = [NSMutableArray<BNCServerRequest *> new];
    [tmp addObject:[BranchOpenRequest new]];
    [tmp addObject:@"Hello World"];
    [tmp addObject:[BranchEventRequest new]];
    [tmp addObject:[BranchCloseRequest new]];
    
    NSData *data = [self.queue archiveQueue:tmp];
    XCTAssertNotNil(data);

    NSMutableArray *unarchived = [self.queue unarchiveQueueFromData:data];
    
    XCTAssertNotNil(unarchived);
    XCTAssert(unarchived.count == 2);
}

- (void)testOldArchiveArrayOfInvalidObjects {
    NSMutableArray<BNCServerRequest *> *tmp = [NSMutableArray<BNCServerRequest *> new];
    [tmp addObject:[BranchOpenRequest new]];
    [tmp addObject:@"Hello World"];
    [tmp addObject:[BranchEventRequest new]];
    [tmp addObject:[BranchCloseRequest new]];
    
    NSData *data = [self.queue oldArchiveQueue:tmp];
    XCTAssertNotNil(data);

    NSMutableArray *unarchived = [self.queue unarchiveQueueFromData:data];
    
    XCTAssertNotNil(unarchived);
    XCTAssert(unarchived.count == 2);
}

@end
