//
//  Reflection_ODM_Tests.m
//  Reflection_ODM_Tests
//
//  Created by Nidhi Dixit on 4/16/25.
//  Copyright © 2025 Branch, Inc. All rights reserved.
//

#import <XCTest/XCTest.h>
#import "BNCODMInfoCollector.h"
#import "NSError+Branch.h"
#import "BNCPreferenceHelper.h"

@interface Reflection_ODM_Tests : XCTestCase

@end

@implementation Reflection_ODM_Tests


- (void) testODMAPIsLoaded {
    
    XCTestExpectation *expectation = [self expectationWithDescription:@"Network call"];
    
    [[BNCODMInfoCollector instance] fetchODMInfoFromDeviceWithInitDate:[NSDate date] andCompletion:^(NSString * _Nonnull odmInfo, NSError * _Nonnull error) {
        if ((error.code != BNCClassNotFoundError) && (error.code != BNCMethodNotFoundError)){
            [expectation fulfill];
        }
    }];
    
    [self waitForExpectationsWithTimeout:15 handler:nil];
    
}

- (void) testODMAPICall {
    
    XCTestExpectation *expectation = [self expectationWithDescription:@"Network call"];
    [BNCPreferenceHelper sharedInstance].odmInfo = nil;
    [[BNCODMInfoCollector instance ] loadODMInfoWithTimeOut:15 andCompletionHandler:^(NSString * _Nullable odmInfo, NSError * _Nullable error) {
            if ((error.code != BNCClassNotFoundError) && (error.code != BNCMethodNotFoundError)){
                if (odmInfo) {
                    XCTAssertTrue([odmInfo isEqualToString:[BNCPreferenceHelper sharedInstance].odmInfo]);
                    XCTAssertTrue([BNCPreferenceHelper sharedInstance].odmInfoInitDate != nil);
                }
                XCTAssertTrue((error == nil), "%s", [[error description] UTF8String]);
                [expectation fulfill];
            }
    }];
    [self waitForExpectationsWithTimeout:30 handler:nil];
}

@end
