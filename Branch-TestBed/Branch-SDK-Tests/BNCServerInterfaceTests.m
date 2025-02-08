//
//  BNCServerInterfaceTests.m
//  Branch-SDK-Tests
//
//  Created by Nidhi Dixit on 1/7/25.
//  Copyright © 2025 Branch, Inc. All rights reserved.
//

#import <XCTest/XCTest.h>
#import "Branch/BNCServerInterface.h"

@interface BNCServerInterface()
- (BOOL)isLinkingRelatedRequest:(NSString *)endpoint postParams:(NSDictionary *)post;
@end

@interface BNCServerInterfaceTests : XCTestCase
@end

@implementation BNCServerInterfaceTests

- (void)testIsLinkingRelatedRequest {
    
    BNCServerInterface *serverInterface = [[BNCServerInterface alloc] init];
    
    // install
    XCTAssertTrue([serverInterface isLinkingRelatedRequest:@"/v1/install" postParams:nil]);
    
    // open
    XCTAssertFalse([serverInterface isLinkingRelatedRequest:@"/v1/open" postParams:nil]);
    XCTAssertFalse([serverInterface isLinkingRelatedRequest:@"/v1/open" postParams:@{}]);
    XCTAssertTrue([serverInterface isLinkingRelatedRequest:@"/v1/open" postParams:@{@"spotlight_identifier":@"io.branch.link.v1.url.testbed.app.link/1234"}]);
    XCTAssertTrue([serverInterface isLinkingRelatedRequest:@"/v1/open" postParams:@{@"link_identifier": @"1305991233204308323"}]);
    XCTAssertTrue([serverInterface isLinkingRelatedRequest:@"/v1/open" postParams:@{@"universal_link_url":@"branchtest://open?_branch_referrer=H4sIAAAAAAAAA8soKSkottLXT8pLLkktLklKTd"}]);
    XCTAssertFalse([serverInterface isLinkingRelatedRequest:@"/v1/open" postParams:@{@"uri_scheme" : @"branchtest"}]);
    
    // v2/event
    XCTAssertFalse([serverInterface isLinkingRelatedRequest:@"/v2/event" postParams:@{@"spotlight_identifier":@"io.branch.link.v1.url.testbed.app.link/1234"}]);
    
    // v1/url
    XCTAssertTrue([serverInterface isLinkingRelatedRequest:@"/v1/url" postParams:nil]);

}
@end
