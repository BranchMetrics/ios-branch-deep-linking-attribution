//
//  BNCODMTests.m
//  Branch-SDK-Tests
//
//  Created by Nidhi Dixit on 4/16/25.
//  Copyright © 2025 Branch, Inc. All rights reserved.
//

#import <XCTest/XCTest.h>
#import "Branch.h"
#import "BNCPreferenceHelper.h"
#import "BNCRequestFactory.h"
#import "BNCEncodingUtils.h"
#import "BNCODMInfoCollector.h"
#import "NSError+Branch.h"

@interface BNCODMTests : XCTestCase
@property (nonatomic, strong, readwrite) BNCPreferenceHelper *prefHelper;
@end

@implementation BNCODMTests

- (void)setUp {
    _prefHelper = [BNCPreferenceHelper sharedInstance];
}

- (void)testSetODM {
    NSString *odm = @"testODMString";
    [Branch setODMInfo:odm];
    XCTAssertTrue([_prefHelper.odmInfo isEqualToString:odm]);
}

- (void)testSetODMandSDKRequests {
    NSString* requestUUID = [[NSUUID UUID ] UUIDString];
    NSNumber* requestCreationTimeStamp = BNCWireFormatFromDate([NSDate date]);
    NSString *odm = @"testODMString";
    
    [Branch setODMInfo:odm];
    
    [[Branch getInstance] setConsumerProtectionAttributionLevel:BranchAttributionLevelFull];
    BNCRequestFactory *factory = [[BNCRequestFactory alloc] initWithBranchKey:@"key_abcd" UUID:requestUUID TimeStamp:requestCreationTimeStamp];
    NSDictionary *jsonInstall = [factory dataForInstallWithURLString:@"https://branch.io"];
    XCTAssertTrue([odm isEqualToString:[jsonInstall objectForKey:@"odm_info"]]);
    
    NSDictionary *jsonOpen = [factory dataForOpenWithURLString:@"https://branch.io"];
    XCTAssertTrue([odm isEqualToString:[jsonOpen objectForKey:@"odm_info"]]);
    
    NSDictionary *event = @{@"name": @"ADD_TO_CART"};
    NSDictionary *jsonEvent = [factory dataForEventWithEventDictionary:[event mutableCopy]];
    XCTAssertTrue([jsonEvent objectForKey:@"odm_info"] == nil);
    
    [[Branch getInstance] setConsumerProtectionAttributionLevel:BranchAttributionLevelReduced];
    jsonInstall = [factory dataForInstallWithURLString:@"https://branch.io"];
    XCTAssertTrue([jsonInstall objectForKey:@"odm_info"] == nil);
    
    jsonOpen = [factory dataForOpenWithURLString:@"https://branch.io"];
    XCTAssertTrue([jsonOpen objectForKey:@"odm_info"] == nil);
    
    self.prefHelper.odmInfo = nil;
}

- (void) testODMAPIsNotLoaded {
    XCTestExpectation *expectation = [self expectationWithDescription:@"Check if ODCManager class is loaded."];
    [[BNCODMInfoCollector instance ] loadODMInfoWithCompletion:^(NSString * _Nullable odmInfo, NSError * _Nullable error) {
            if (error.code == BNCClassNotFoundError){
                [expectation fulfill];
            }
    }];
    [self waitForExpectationsWithTimeout:15 handler:nil];
}

@end
