//
//  BNCPreInitBlockTests.m
//  Branch-SDK-Tests
//
//  Created by Benas Klastaitis on 12/9/19.
//  Copyright © 2019 Branch, Inc. All rights reserved.
//

#import <XCTest/XCTest.h>
// #import "Branch.h"

@interface DispatchToIsolationQueueTests : XCTestCase
// @property (nonatomic, strong, readwrite) Branch *branch;
// @property (nonatomic, strong, readwrite) BNCPreferenceHelper *prefHelper;
@end

// this is an integration test, needs to be moved to a new target
@implementation DispatchToIsolationQueueTests

- (void)setUp {
   // self.branch = [Branch getInstance];
   // self.prefHelper = [[BNCPreferenceHelper alloc] init];
}

- (void)tearDown {
   // [self.prefHelper setRequestMetadataKey:@"$marketing_cloud_visitor_id" value:@"dummy"];
}

- (void)testPreInitBlock {
   // __block XCTestExpectation *expectation = [self expectationWithDescription:@""];

   // [self.branch dispatchToIsolationQueue:^{
   //     dispatch_semaphore_t semaphore = dispatch_semaphore_create(0);
   //     dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(3 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
   //         [self.branch setRequestMetadataKey:@"$marketing_cloud_visitor_id" value:@"adobeID123"];
   //         dispatch_semaphore_signal(semaphore);
   //     });
   //     dispatch_semaphore_wait(semaphore, DISPATCH_TIME_FOREVER);
   // }];

   // [self.branch requestDeepLinkDataWithLaunchOptions:nil andRegisterDeepLinkHandlerUsingBranchUniversalObject:
   //     ^ (BranchUniversalObject * _Nullable universalObject,
   //        BranchLinkProperties * _Nullable linkProperties,
   //        NSError * _Nullable error) {
   //     [expectation fulfill];
   // }];

   //     XCTAssertTrue([[[self.prefHelper requestMetadataDictionary] objectForKey:@"$marketing_cloud_visitor_id"] isEqualToString:@"adobeID123"]);
   // });


   // [self waitForExpectationsWithTimeout:6 handler:^(NSError * _Nullable error) {
   //     NSLog(@"%@", error);
   // }];
}

// -(int)enumIntValueFromId:(id)enumValueId {
//    if (![enumValueId respondsToSelector:@selector(intValue)])
//        return -1;

//    return [enumValueId intValue];
// }

@end
