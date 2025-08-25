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
#import "BranchSDK.h"

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

- (void) testFetchODMInfoFromDevice {
    
    XCTestExpectation *expectation = [self expectationWithDescription:@"Network call"];
    [BNCPreferenceHelper sharedInstance].odmInfo = nil;
    [[BNCODMInfoCollector instance ] fetchODMInfoFromDeviceWithInitDate:[NSDate date] andCompletion:^(NSString * _Nullable odmInfo, NSError * _Nullable error) {
            if ((error.code != BNCClassNotFoundError) && (error.code != BNCMethodNotFoundError)){
                if (odmInfo) {
                    XCTAssertNotNil(odmInfo, "ODM Info returned is nil");
                }
                XCTAssertTrue((error == nil), "%s", [[error description] UTF8String]);
                [expectation fulfill];
            }
    }];
    [self waitForExpectationsWithTimeout:30 handler:nil];
}

- (void) testODMAPICall {
    
    [Branch setThirdPartyAPIsTimeout:10];
    
    [BNCPreferenceHelper sharedInstance].odmInfo = nil;
    [[BNCODMInfoCollector instance ] loadODMInfo];
    
    XCTAssertTrue([[BNCODMInfoCollector instance ].odmInfo isEqualToString:[BNCPreferenceHelper sharedInstance].odmInfo]);
    XCTAssertTrue([BNCPreferenceHelper sharedInstance].odmInfoInitDate != nil);
  
   
}

@end
