//
//  BNCReferringURLUtilityTests.m
//  Branch-SDK-Tests
//
//  Created by Nipun Singh on 3/9/23.
//  Copyright © 2023 Branch, Inc. All rights reserved.
//

#import <XCTest/XCTest.h>
#import "BNCReferringURLUtility.h"

@interface BNCReferringURLUtilityTests : XCTestCase

@end

@implementation BNCReferringURLUtilityTests

- (void)setUp {
    // Put setup code here. This method is called before the invocation of each test method in the class.
}

- (void)tearDown {
    // Put teardown code here. This method is called after the invocation of each test method in the class.
}

- (void)testExample {
    NSURL *url = [NSURL URLWithString:@"https://www.google.com?gbraid=a123&test=456"];
    
    BNCReferringURLUtility *utility = [BNCReferringURLUtility new];
    [utility parseReferringURL:url];
}

@end
