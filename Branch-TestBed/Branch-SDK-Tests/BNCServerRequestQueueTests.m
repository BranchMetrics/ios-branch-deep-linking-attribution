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

// Analytics requests
#import "BranchInstallRequest.h"
#import "BranchOpenRequest.h"
#import "BranchEvent.h"
#import "BranchShortURLRequest.h"
#import "BranchLATDRequest.h"

@interface BNCServerRequestQueue ()
- (NSData *)archiveQueue:(NSArray<BNCServerRequest *> *)queue;
- (NSMutableArray<BNCServerRequest *> *)unarchiveQueueFromData:(NSData *)data;

- (NSData *)archiveObject:(NSObject *)object;
- (id)unarchiveObjectFromData:(NSData *)data;

// returns data in the legacy format
- (NSData *)oldArchiveQueue:(NSArray<BNCServerRequest *> *)queue;

+ (NSURL * _Nonnull) URLForQueueFile;
- (void)retrieve;

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

- (NSArray *)getQueueCachedOnDisk {
    NSMutableArray *decodedQueue = nil;
    NSData *data = [NSData dataWithContentsOfURL:[BNCServerRequestQueue URLForQueueFile] options:0 error:nil];
    if (data) {
        decodedQueue = [_queue unarchiveQueueFromData:data];
    }
    return decodedQueue;
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
    
    NSData *data = [self.queue oldArchiveQueue:tmp];
    XCTAssertNotNil(data);

    NSMutableArray *unarchived = [self.queue unarchiveQueueFromData:data];
    
    XCTAssertNotNil(unarchived);
    XCTAssert(unarchived.count == 2);
}

- (void)testMultipleRequests {
    BranchEventRequest *eventObject = [BranchEventRequest new];
    BranchOpenRequest *openObject = [BranchOpenRequest new];
 
    [_queue enqueue: eventObject];
    [_queue enqueue: openObject];
    [_queue persistImmediately];
    
    NSArray *decodedQueue = [self getQueueCachedOnDisk];
    
    XCTAssert([decodedQueue count] == 2);
    [_queue clearQueue];
    XCTAssert([_queue queueDepth] == 0);
    [_queue retrieve];
    XCTAssert([_queue queueDepth] == 2);

     // Request are loaded. So there should not be any queue file on disk.
    XCTAssert([NSFileManager.defaultManager fileExistsAtPath:[[BNCServerRequestQueue URLForQueueFile] path]] == NO);
}

- (void)testUUIDANDTimeStampPersistence {
    BranchEventRequest *eventObject = [BranchEventRequest new];
    BranchOpenRequest *openObject = [BranchOpenRequest new];
    NSString *uuidFromEventObject = eventObject.requestUUID;
    NSNumber *timeStampFromEventObject = eventObject.requestCreationTimeStamp;
    NSString *uuidFromOpenObject = openObject.requestUUID;
    NSNumber *timeStampFromOpenObject = openObject.requestCreationTimeStamp;
    
    XCTAssertTrue(![uuidFromEventObject isEqualToString:uuidFromOpenObject]);
    
    [_queue enqueue: eventObject];
    [_queue enqueue: openObject];
    [_queue persistImmediately];
    
    NSArray *decodedQueue = [self getQueueCachedOnDisk];
    
    for (id requestObject in decodedQueue) {
        if ([requestObject isKindOfClass:BranchEventRequest.class]) {
            XCTAssertTrue([uuidFromEventObject isEqualToString:[(BranchEventRequest *)requestObject requestUUID]]);
            XCTAssertTrue([timeStampFromEventObject isEqualToNumber:[(BranchEventRequest *)requestObject requestCreationTimeStamp]]);
        }
        if ([requestObject isKindOfClass:BranchOpenRequest.class]) {
            XCTAssertTrue([uuidFromOpenObject isEqualToString:[(BranchOpenRequest *)requestObject requestUUID]]);
            XCTAssertTrue([timeStampFromOpenObject isEqualToNumber:[(BranchOpenRequest *)requestObject requestCreationTimeStamp]]);
        }
    }
}

- (void)testUUIDANDTimeStampPersistenceForOpen {
    BranchOpenRequest *openObject = [[BranchOpenRequest alloc] init];
    BranchOpenRequest *openWithCallbackObject = [[BranchOpenRequest alloc] initWithCallback:^(BOOL changed, NSError * _Nullable error) {}];
    openObject.urlString = @"https://www.branch.io";
    openWithCallbackObject.urlString = @"https://www.branch.testWithCallback.io";
    [_queue enqueue: openObject];
    [_queue enqueue: openWithCallbackObject];
    [_queue persistImmediately];
    
    NSArray *decodedQueue = [self getQueueCachedOnDisk];
    
    for (id requestObject in decodedQueue) {
        if ([requestObject isKindOfClass:BranchOpenRequest.class]) {
            BranchOpenRequest *tmpCopy = (BranchOpenRequest *)requestObject;
            if ([tmpCopy.urlString isEqualToString:openObject.urlString]) {
                XCTAssertTrue([tmpCopy.requestUUID isEqualToString:openObject.requestUUID]);
                XCTAssertTrue([tmpCopy.requestCreationTimeStamp isEqualToNumber:openObject.requestCreationTimeStamp]);
            } else if ([tmpCopy.urlString isEqualToString:openWithCallbackObject.urlString]) {
                XCTAssertTrue([tmpCopy.requestUUID isEqualToString:openWithCallbackObject.requestUUID]);
                XCTAssertTrue([tmpCopy.requestCreationTimeStamp isEqualToNumber:openWithCallbackObject.requestCreationTimeStamp]);
            } else {
                XCTFail("Invalid URL found");
            }
            
        } else {
            XCTFail("Invalid Object type found");
        }
    }
}

- (void)testUUIDANDTimeStampPersistenceForInstall {
    BranchInstallRequest *installObject = [[BranchInstallRequest alloc] init];
    BranchInstallRequest *installWithCallbackObject = [[BranchInstallRequest alloc] initWithCallback:^(BOOL changed, NSError * _Nullable error) {}];
    installObject.urlString = @"https://www.branch.io";
    installWithCallbackObject.urlString = @"https://www.branch.testWithCallback.io";
    [_queue enqueue: installObject];
    [_queue enqueue: installWithCallbackObject];
    [_queue persistImmediately];
    
    NSArray *decodedQueue = [self getQueueCachedOnDisk];
    
    for (id requestObject in decodedQueue) {
        if ([requestObject isKindOfClass:BranchInstallRequest.class]) {
            BranchInstallRequest *tmpCopy = (BranchInstallRequest *)requestObject;
            if ([tmpCopy.urlString isEqualToString:installObject.urlString]) {
                XCTAssertTrue([tmpCopy.requestUUID isEqualToString:installObject.requestUUID]);
                XCTAssertTrue([tmpCopy.requestCreationTimeStamp isEqualToNumber:installObject.requestCreationTimeStamp]);
            } else if ([tmpCopy.urlString isEqualToString:installWithCallbackObject.urlString]) {
                XCTAssertTrue([tmpCopy.requestUUID isEqualToString:installWithCallbackObject.requestUUID]);
                XCTAssertTrue([tmpCopy.requestCreationTimeStamp isEqualToNumber:installWithCallbackObject.requestCreationTimeStamp]);
            } else {
                XCTFail("Invalid URL found");
            }
        } else {
            XCTFail("Invalid Object type found");
        }
    }
}

- (void)testUUIDANDTimeStampPersistenceForEvent {
    BranchEventRequest *eventObject = [[BranchEventRequest alloc] init];
    [_queue enqueue: eventObject];
    [_queue persistImmediately];

    NSArray *decodedQueue = [self getQueueCachedOnDisk];
    
    for (id requestObject in decodedQueue) {
        if ([requestObject isKindOfClass:BranchEventRequest.class]) {
                XCTAssertTrue([eventObject.requestUUID isEqualToString:((BranchEventRequest *)requestObject).requestUUID]);
                XCTAssertTrue([eventObject.requestCreationTimeStamp isEqualToNumber:((BranchEventRequest *)requestObject).requestCreationTimeStamp]);
        } else {
            XCTFail("Invalid Object type found");
        }
    }
}

- (void)testUUIDANDTimeStampPersistenceForEventWithCallback {
    
    NSURL *url = [NSURL URLWithString:@"https://api3.branch.io/v2/event/standard"];
    BranchEventRequest *eventObject = [[BranchEventRequest alloc] initWithServerURL:url eventDictionary:nil completion:nil];
    
    [_queue enqueue: eventObject];
    [_queue persistImmediately];

    NSArray *decodedQueue = [self getQueueCachedOnDisk];
    
    for (id requestObject in decodedQueue) {
        if ([requestObject isKindOfClass:BranchEventRequest.class]) {
                XCTAssertTrue([eventObject.requestUUID isEqualToString:((BranchEventRequest *)requestObject).requestUUID]);
                XCTAssertTrue([eventObject.requestCreationTimeStamp isEqualToNumber:((BranchEventRequest *)requestObject).requestCreationTimeStamp]);
        } else {
            XCTFail("Invalid Object type found");
        }
    }
}

- (void)testUUIDANDTimeStampPersistenceForShortURL {
    BranchShortUrlRequest *shortURLObject = [BranchShortUrlRequest new];
    [_queue enqueue: shortURLObject];
    [_queue persistImmediately];

    NSArray *decodedQueue = [self getQueueCachedOnDisk];
    
    for (id requestObject in decodedQueue) {
        if ([requestObject isKindOfClass:BranchShortUrlRequest.class]) {
                XCTAssertTrue([shortURLObject.requestUUID isEqualToString:((BranchShortUrlRequest *)requestObject).requestUUID]);
                XCTAssertTrue([shortURLObject.requestCreationTimeStamp isEqualToNumber:((BranchShortUrlRequest *)requestObject).requestCreationTimeStamp]);
        } else {
            XCTFail("Invalid Object type found");
        }
    }
}

- (void)testUUIDANDTimeStampPersistenceForShortURLWithParams {
    
    BranchShortUrlRequest *shortURLObject = [[BranchShortUrlRequest alloc] initWithTags:nil alias:nil type:BranchLinkTypeUnlimitedUse matchDuration:0 channel:nil feature:nil stage:nil campaign:nil params:nil linkData:nil linkCache:nil callback:^(NSString * _Nullable url, NSError * _Nullable error) {}];
    [_queue enqueue: shortURLObject];
    [_queue persistImmediately];

    NSArray *decodedQueue = [self getQueueCachedOnDisk];
    
    for (id requestObject in decodedQueue) {
        if ([requestObject isKindOfClass:BranchShortUrlRequest.class]) {
                XCTAssertTrue([shortURLObject.requestUUID isEqualToString:((BranchShortUrlRequest *)requestObject).requestUUID]);
                XCTAssertTrue([shortURLObject.requestCreationTimeStamp isEqualToNumber:((BranchShortUrlRequest *)requestObject).requestCreationTimeStamp]);
        } else {
            XCTFail("Invalid Object type found");
        }
    }
}

- (void)testUUIDANDTimeStampPersistenceForLATD {
    
    BranchLATDRequest *latdObject = [BranchLATDRequest new];
    [_queue enqueue: latdObject];
    [_queue persistImmediately];

    NSArray *decodedQueue = [self getQueueCachedOnDisk];
    
    for (id requestObject in decodedQueue) {
        if ([requestObject isKindOfClass:BranchLATDRequest.class]) {
                XCTAssertTrue([latdObject.requestUUID isEqualToString:((BranchLATDRequest *)requestObject).requestUUID]);
                XCTAssertTrue([latdObject.requestCreationTimeStamp isEqualToNumber:((BranchLATDRequest *)requestObject).requestCreationTimeStamp]);
        } else {
            XCTFail("Invalid Object type found");
        }
    }
}


@end
