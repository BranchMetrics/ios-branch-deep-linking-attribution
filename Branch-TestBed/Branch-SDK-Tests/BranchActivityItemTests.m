//
//  BranchActivityItemTests.m
//  Branch-SDK-Tests
//
//  Created by Nipun Singh on 9/21/23.
//  Copyright © 2023 Branch, Inc. All rights reserved.
//

#import <XCTest/XCTest.h>
#import "Branch.h"

@interface BranchActivityItemTests: XCTestCase
@end

@implementation BranchActivityItemTests

// Rework this test, it's not reliable.
//- (void)testGetBranchActivityItemWithAllParams {
//    NSDictionary *params = @{@"key": @"value"};
//    NSString *feature = @"feature4";
//    NSString *stage = @"stage3";
//    NSArray *tags = @[@"tag3", @"tag4"];
//    NSString *campaign = @"campaign1";
//    NSString *alias = [[NSUUID UUID] UUIDString];
//    BranchActivityItemProvider *provider = [Branch getBranchActivityItemWithParams:params feature:feature stage:stage campaign:campaign tags:tags alias:alias];
//    sleep(2000);
//    if ([[provider item] isKindOfClass:[NSURL class]]) {
//        NSURL *urlObject = (NSURL *)[provider item];
//        NSString *url = [urlObject absoluteString];
//        
//        NSLog(@"Provider URL as String: %@", url);
//        
//        XCTAssertTrue([url isEqualToString:[@"https://bnctestbed.app.link/" stringByAppendingString:alias]]);
//    } else {
//        XCTFail("Provider Data is not of type NSURL");
//    }
//}

@end
