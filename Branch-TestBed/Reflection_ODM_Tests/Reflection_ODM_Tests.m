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
    
    [[BNCODMInfoCollector instance] fetchODMInfoFromDeviceWithInitDate:[NSDate date] andCompletion:^(NSString * _Nullable odmInfo, NSError * _Nullable error) {
        if ( !error) {
            [expectation fulfill];
        } else {
            if ((error.code != BNCClassNotFoundError) && (error.code != BNCMethodNotFoundError)) {
                [expectation fulfill];
            } else {
                XCTFail(@"Unexpected ODM error: %@", error.localizedDescription);
                [expectation fulfill];
            }
        }
    }];
    
    [self waitForExpectationsWithTimeout:15 handler:nil];
    
}


- (void) testODMAPICall {

    XCTestExpectation *expectation = [self expectationWithDescription:@"Network call"];
    [BNCPreferenceHelper sharedInstance].odmInfo = nil;
    [[BNCODMInfoCollector instance ] loadODMInfoWithCompletionHandler:^(NSString * _Nullable odmInfo, NSError * _Nullable error) {
            if (!error){
                if (odmInfo) {
                    XCTAssertTrue([odmInfo isEqualToString:[BNCPreferenceHelper sharedInstance].odmInfo]);
                    XCTAssertTrue([BNCPreferenceHelper sharedInstance].odmInfoInitDate != nil);
                }
                XCTAssertTrue((error == nil), "%s", [[error description] UTF8String]);
                [expectation fulfill];
            } else {
                XCTFail(@"Unexpected ODM error: %@", error.localizedDescription);
                [expectation fulfill];
            }
    }];
    [self waitForExpectationsWithTimeout:15 handler:nil];
}

@end
