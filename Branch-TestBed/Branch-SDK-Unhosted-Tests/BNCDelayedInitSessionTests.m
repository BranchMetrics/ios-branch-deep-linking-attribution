//
//  BNCDelayedInitSessionTests.m
//  Branch-SDK-Tests
//
//  Created by Benas Klastaitis on 12/3/19.
//  Copyright © 2019 Branch, Inc. All rights reserved.
//

#import <XCTest/XCTest.h>
#import "Branch.h"

@interface BNCDelayedInitSessionTests : XCTestCase
@property (nonatomic, strong, readwrite) Branch *branch;
@end

@implementation BNCDelayedInitSessionTests


- (void)setUp {
    self.branch = [Branch getInstance];
}

- (void)tearDown {}

- (void)testDispatchInitSession {
    __block XCTestExpectation *expectation = [self expectationWithDescription:@""];
    dispatch_block_t  initBlock = dispatch_block_create(DISPATCH_BLOCK_ASSIGN_CURRENT, ^{
        [self.branch initSessionWithLaunchOptions:nil
            andRegisterDeepLinkHandlerUsingBranchUniversalObject:
            ^ (BranchUniversalObject * _Nullable universalObject, BranchLinkProperties * _Nullable linkProperties, NSError * _Nullable error) {
            [expectation fulfill];
        }];
    });
    
    [self.branch dispatchInitSession:initBlock After:2];
    
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(3 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        id initializationStatus = [self.branch valueForKey:@"initializationStatus"];
        XCTAssertTrue([self enumIntValueFromId:initializationStatus] == 2);// is initialized
    });
    
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        id initializationStatus = [self.branch valueForKey:@"initializationStatus"];
        XCTAssertTrue([self enumIntValueFromId:initializationStatus] == 0);// uninitialized
    });
    
    
    [self waitForExpectationsWithTimeout:4 handler:^(NSError * _Nullable error) {
        NSLog(@"%@", error);
    }];
}

- (void)testCancelDelayedInitSession {
    dispatch_block_t  initBlock = dispatch_block_create(DISPATCH_BLOCK_ASSIGN_CURRENT, ^{
        [self.branch initSessionWithLaunchOptions:nil
            andRegisterDeepLinkHandlerUsingBranchUniversalObject:
            ^ (BranchUniversalObject * _Nullable universalObject, BranchLinkProperties * _Nullable linkProperties, NSError * _Nullable error) {
        }];
    });
    
    [self.branch dispatchInitSession:initBlock After:1];
    [self.branch cancelDelayedInitSession];
    
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(3 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        id initializationStatus = [self.branch valueForKey:@"initializationStatus"];
        XCTAssertTrue([self enumIntValueFromId:initializationStatus] == 0);// uninitialized
    });
}

- (void)testInvokeDelayedInitSession {
    __block XCTestExpectation *expectation = [self expectationWithDescription:@""];
    dispatch_block_t  initBlock = dispatch_block_create(DISPATCH_BLOCK_ASSIGN_CURRENT, ^{
        [self.branch initSessionWithLaunchOptions:nil
            andRegisterDeepLinkHandlerUsingBranchUniversalObject:
            ^ (BranchUniversalObject * _Nullable universalObject, BranchLinkProperties * _Nullable linkProperties, NSError * _Nullable error) {
            [expectation fulfill];
        }];
    });
    
    [self.branch dispatchInitSession:initBlock After:4];
    
    [self.branch invokeDelayedInitSession];
    
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(3 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        id initializationStatus = [self.branch valueForKey:@"initializationStatus"];
        XCTAssertTrue([self enumIntValueFromId:initializationStatus] == 2);// uninitialized
    });

    [self waitForExpectationsWithTimeout:4 handler:^(NSError * _Nullable error) {
        NSLog(@"%@", error);
    }];
}

-(int)enumIntValueFromId:(id)enumValueId {
    if (![enumValueId respondsToSelector:@selector(intValue)])
        return -1;

    return [enumValueId intValue];
}

@end
