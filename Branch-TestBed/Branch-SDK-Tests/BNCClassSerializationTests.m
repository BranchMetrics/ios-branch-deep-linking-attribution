//
//  BNCClassSerializationTests.m
//  Branch-SDK-Tests
//
//  Created by Ernest Cho on 3/28/24.
//  Copyright © 2024 Branch, Inc. All rights reserved.
//

#import <XCTest/XCTest.h>
#import "BranchEvent.h"

@interface BranchEvent()
// private BranchEvent methods used to build a BranchEventRequest
- (NSDictionary *)buildEventDictionary;
@end

@interface BNCClassSerializationTests : XCTestCase

@end

// Test serialization of replayable requests
@implementation BNCClassSerializationTests

- (void)setUp {
    // Put setup code here. This method is called before the invocation of each test method in the class.
}

- (void)tearDown {
    // Put teardown code here. This method is called after the invocation of each test method in the class.
}

// BranchEventRequest is creation is tightly coupled with the BranchEvent class
// In order to test building it, we need to expose some private methods. :(
- (BranchEventRequest *)buildBranchEventRequest {
    BranchEvent *event = [BranchEvent standardEvent:BranchStandardEventPurchase];
    NSURL *url = [NSURL URLWithString:@"https://api3.branch.io/v3/events/standard"];
    NSDictionary *eventDictionary = [event buildEventDictionary];
    
    BranchEventRequest *request = [[BranchEventRequest alloc] initWithServerURL:url eventDictionary:eventDictionary completion:nil];
    return request;
}

- (void)testBranchEventRequestArchive {
    BranchEventRequest *request = [self buildBranchEventRequest];

    // archive the event
    NSError *error = nil;
    NSData *data = [NSKeyedArchiver archivedDataWithRootObject:request requiringSecureCoding:YES error:&error];
    XCTAssertNil(error);
    XCTAssertNotNil(data);
    
    // unarchive the event
    id object = [NSKeyedUnarchiver unarchivedObjectOfClasses:[NSSet setWithArray:@[BranchEventRequest.class]] fromData:data error:&error];
    XCTAssertNil(error);
    XCTAssertNotNil(object);
    
    // check object
    XCTAssertTrue([object isKindOfClass:BranchEventRequest.class]);
    BranchEventRequest *unarchivedRequest = (BranchEventRequest *)object;
    
    XCTAssertTrue([request.serverURL.absoluteString isEqualToString:unarchivedRequest.serverURL.absoluteString]);
    XCTAssertTrue(request.eventDictionary.count == unarchivedRequest.eventDictionary.count);
    XCTAssertNil(unarchivedRequest.completion);
}

@end
