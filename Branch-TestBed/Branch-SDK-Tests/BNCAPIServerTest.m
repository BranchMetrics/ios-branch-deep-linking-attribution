//
//  BNCAPIServerTest.m
//  Branch-SDK-Tests
//
//  Created by Nidhi Dixit on 9/6/23.
//  Copyright © 2023 Branch, Inc. All rights reserved.
//

#import <XCTest/XCTest.h>
#import "BNCServerAPI.h"
#import "BNCSystemObserver.h"
#import "BNCConfig.h"
#import "BranchConstants.h"

@interface BNCAPIServerTest : XCTestCase

@end

@implementation BNCAPIServerTest

- (void)testInstallServiceURL {
    BNCServerAPI *serverAPI = [BNCServerAPI new];
    serverAPI.automaticallyEnableTrackingDomain = NO;
    
    NSString *url = [serverAPI installServiceURL];
    NSString *expectedUrlStr = @"https://api3.branch.io/v1/install";
    
    XCTAssertTrue([url isEqualToString:expectedUrlStr]);
}

- (void)testOpenServiceURL {
    BNCServerAPI *serverAPI = [BNCServerAPI new];
    serverAPI.automaticallyEnableTrackingDomain = NO;
    
    NSString *url = [serverAPI openServiceURL];
    NSString *expectedUrlStr = @"https://api3.branch.io/v1/open";
    
    XCTAssertTrue([url isEqualToString:expectedUrlStr]);
}

- (void)testStandardEventServiceURL {
    BNCServerAPI *serverAPI = [BNCServerAPI new];
    serverAPI.automaticallyEnableTrackingDomain = NO;
    
    NSString *url = [serverAPI standardEventServiceURL];
    NSString *expectedUrlStr = @"https://api3.branch.io/v2/event/standard";
    
    XCTAssertTrue([url isEqualToString:expectedUrlStr]);
}

- (void)testCustomEventServiceURL {
    BNCServerAPI *serverAPI = [BNCServerAPI new];
    serverAPI.automaticallyEnableTrackingDomain = NO;
    
    NSString *url = [serverAPI customEventServiceURL];
    NSString *expectedUrlStr = @"https://api3.branch.io/v2/event/custom";
    
    XCTAssertTrue([url isEqualToString:expectedUrlStr]);
}

- (void)testLinkServiceURL {
    BNCServerAPI *serverAPI = [BNCServerAPI new];
    serverAPI.automaticallyEnableTrackingDomain = NO;
    
    NSString *url = [serverAPI linkServiceURL];
    NSString *expectedUrlStr = @"https://api3.branch.io/v1/url";
    
    XCTAssertTrue([url isEqualToString:expectedUrlStr]);
}

- (void)testInstallServiceURL_Tracking {
    BNCServerAPI *serverAPI = [BNCServerAPI new];
    serverAPI.automaticallyEnableTrackingDomain = NO;
    serverAPI.useTrackingDomain = YES;
    
    NSString *url = [serverAPI installServiceURL];
    NSString *expectedUrlStr = @"https://api-safetrack.branch.io/v1/install";
    
    XCTAssertTrue([url isEqualToString:expectedUrlStr]);
}

- (void)testOpenServiceURL_Tracking {
    BNCServerAPI *serverAPI = [BNCServerAPI new];
    serverAPI.automaticallyEnableTrackingDomain = NO;
    serverAPI.useTrackingDomain = YES;
    
    NSString *url = [serverAPI openServiceURL];
    NSString *expectedUrlStr = @"https://api-safetrack.branch.io/v1/open";
    
    XCTAssertTrue([url isEqualToString:expectedUrlStr]);
}

- (void)testStandardEventServiceURL_Tracking {
    BNCServerAPI *serverAPI = [BNCServerAPI new];
    serverAPI.automaticallyEnableTrackingDomain = NO;
    serverAPI.useTrackingDomain = YES;
    
    NSString *url = [serverAPI standardEventServiceURL];
    NSString *expectedUrlStr = @"https://api-safetrack.branch.io/v2/event/standard";
    
    XCTAssertTrue([url isEqualToString:expectedUrlStr]);
}

- (void)testCustomEventServiceURL_Tracking {
    BNCServerAPI *serverAPI = [BNCServerAPI new];
    serverAPI.automaticallyEnableTrackingDomain = NO;
    serverAPI.useTrackingDomain = YES;
    
    NSString *url = [serverAPI customEventServiceURL];
    NSString *expectedUrlStr = @"https://api-safetrack.branch.io/v2/event/custom";
    
    XCTAssertTrue([url isEqualToString:expectedUrlStr]);
}

- (void)testLinkServiceURL_Tracking {
    BNCServerAPI *serverAPI = [BNCServerAPI new];
    serverAPI.automaticallyEnableTrackingDomain = NO;
    serverAPI.useTrackingDomain = YES;
    
    NSString *url = [serverAPI linkServiceURL];
    NSString *expectedUrlStr = @"https://api3.branch.io/v1/url";
    
    XCTAssertTrue([url isEqualToString:expectedUrlStr]);
}

- (void)testInstallServiceURL_EU {
    BNCServerAPI *serverAPI = [BNCServerAPI new];
    serverAPI.automaticallyEnableTrackingDomain = NO;
    serverAPI.useEUServers = YES;
    
    NSString *url = [serverAPI installServiceURL];
    NSString *expectedUrlStr = @"https://api3-eu.branch.io/v1/install";
    
    XCTAssertTrue([url isEqualToString:expectedUrlStr]);
}

- (void)testOpenServiceURL_EU {
    BNCServerAPI *serverAPI = [BNCServerAPI new];
    serverAPI.automaticallyEnableTrackingDomain = NO;
    serverAPI.useEUServers = YES;

    NSString *url = [serverAPI openServiceURL];
    NSString *expectedUrlStr = @"https://api3-eu.branch.io/v1/open";
    
    XCTAssertTrue([url isEqualToString:expectedUrlStr]);
}

- (void)testStandardEventServiceURL_EU {
    BNCServerAPI *serverAPI = [BNCServerAPI new];
    serverAPI.automaticallyEnableTrackingDomain = NO;
    serverAPI.useEUServers = YES;

    NSString *url = [serverAPI standardEventServiceURL];
    NSString *expectedUrlStr = @"https://api3-eu.branch.io/v2/event/standard";
    
    XCTAssertTrue([url isEqualToString:expectedUrlStr]);
}

- (void)testCustomEventServiceURL_EU {
    BNCServerAPI *serverAPI = [BNCServerAPI new];
    serverAPI.automaticallyEnableTrackingDomain = NO;
    serverAPI.useEUServers = YES;

    NSString *url = [serverAPI customEventServiceURL];
    NSString *expectedUrlStr = @"https://api3-eu.branch.io/v2/event/custom";
    
    XCTAssertTrue([url isEqualToString:expectedUrlStr]);
}

- (void)testLinkServiceURL_EU {
    BNCServerAPI *serverAPI = [BNCServerAPI new];
    serverAPI.automaticallyEnableTrackingDomain = NO;
    serverAPI.useEUServers = YES;

    NSString *url = [serverAPI linkServiceURL];
    NSString *expectedUrlStr = @"https://api3-eu.branch.io/v1/url";
    
    XCTAssertTrue([url isEqualToString:expectedUrlStr]);
}

- (void)testInstallServiceURL_EUTracking {
    BNCServerAPI *serverAPI = [BNCServerAPI new];
    serverAPI.automaticallyEnableTrackingDomain = NO;
    serverAPI.useEUServers = YES;
    serverAPI.useTrackingDomain = YES;
    
    NSString *url = [serverAPI installServiceURL];
    NSString *expectedUrlStr = @"https://api-safetrack-eu.branch.io/v1/install";
    
    XCTAssertTrue([url isEqualToString:expectedUrlStr]);
}

- (void)testOpenServiceURL_EUTracking {
    BNCServerAPI *serverAPI = [BNCServerAPI new];
    serverAPI.automaticallyEnableTrackingDomain = NO;
    serverAPI.useEUServers = YES;
    serverAPI.useTrackingDomain = YES;

    NSString *url = [serverAPI openServiceURL];
    NSString *expectedUrlStr = @"https://api-safetrack-eu.branch.io/v1/open";
    
    XCTAssertTrue([url isEqualToString:expectedUrlStr]);
}

- (void)testStandardEventServiceURL_EUTracking {
    BNCServerAPI *serverAPI = [BNCServerAPI new];
    serverAPI.automaticallyEnableTrackingDomain = NO;
    serverAPI.useEUServers = YES;
    serverAPI.useTrackingDomain = YES;

    NSString *url = [serverAPI standardEventServiceURL];
    NSString *expectedUrlStr = @"https://api-safetrack-eu.branch.io/v2/event/standard";
    
    XCTAssertTrue([url isEqualToString:expectedUrlStr]);
}

- (void)testCustomEventServiceURL_EUTracking {
    BNCServerAPI *serverAPI = [BNCServerAPI new];
    serverAPI.automaticallyEnableTrackingDomain = NO;
    serverAPI.useEUServers = YES;
    serverAPI.useTrackingDomain = YES;

    NSString *url = [serverAPI customEventServiceURL];
    NSString *expectedUrlStr = @"https://api-safetrack-eu.branch.io/v2/event/custom";
    
    XCTAssertTrue([url isEqualToString:expectedUrlStr]);
}

- (void)testLinkServiceURL_EUTracking {
    BNCServerAPI *serverAPI = [BNCServerAPI new];
    serverAPI.automaticallyEnableTrackingDomain = NO;
    serverAPI.useEUServers = YES;
    serverAPI.useTrackingDomain = YES;

    NSString *url = [serverAPI linkServiceURL];
    NSString *expectedUrlStr = @"https://api3-eu.branch.io/v1/url";
    
    XCTAssertTrue([url isEqualToString:expectedUrlStr]);
}

@end
