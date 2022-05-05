//
//  BranchShareLinkTests.m
//  Branch-SDK-Tests
//
//  Created by Nipun Singh on 5/5/22.
//  Copyright © 2022 Branch, Inc. All rights reserved.
//

#import <XCTest/XCTest.h>
#import "BranchShareLink.h"
#import "BranchLinkProperties.h"
#import "Branch.h"

@interface BranchShareLinkTests : XCTestCase

@end

@implementation BranchShareLinkTests

- (void)testAddLPLinkMetadata {
    BranchUniversalObject *buo = [[BranchUniversalObject alloc] initWithCanonicalIdentifier:@"test/001"];
    BranchLinkProperties *lp = [[BranchLinkProperties alloc] init];
    
    BranchShareLink *bsl = [[BranchShareLink alloc] initWithUniversalObject:buo linkProperties:lp];
    
    if (@available(iOS 13.0, *)) {
        NSURL *imageURL = [NSURL URLWithString:@"https://cdn.branch.io/branch-assets/1598575682753-og_image.png"];
        [bsl addLPLinkMetadata:@"Test Preview Title" iconURL:imageURL];
        XCTAssertNotNil([bsl lpMetaData]);
    } else {
        // Fallback on earlier versions
        XCTAssertTrue(true);
    }
    
    
    
    
}

@end
