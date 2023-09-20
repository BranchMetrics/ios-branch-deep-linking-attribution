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
@property (nonatomic, strong, readwrite) BNCServerAPI *serverAPI;
@property (nonatomic, strong, readwrite) NSString *optedInStatus;
@end

@implementation BNCAPIServerTest

- (void)setUp {
    self.serverAPI = [BNCServerAPI sharedInstance];
    self.optedInStatus = [BNCSystemObserver attOptedInStatus];
}

- (void)testGetBaseURLWithVersion {
    
    NSString *urlStr = [[BNCServerAPI sharedInstance] getBaseURLWithVersion];
    NSString *expectedUrlStr;
    
    if ([self.optedInStatus isEqualToString:@"authorized"]){
        expectedUrlStr =  [BNC_SAFETRACK_API_URL stringByAppendingFormat:@"/%@/", BNC_API_VERSION_3];
    } else {
        expectedUrlStr =  [BNC_API_URL stringByAppendingFormat:@"/%@/", BNC_API_VERSION_3];
    }
    
    XCTAssertTrue([urlStr isEqualToString:expectedUrlStr]);
    
    [self.serverAPI setUseEUServers:true];
    urlStr = [[BNCServerAPI sharedInstance] getBaseURLWithVersion];
    
    if ([self.optedInStatus isEqualToString:@"authorized"]){
        expectedUrlStr =  [BNC_SAFETRACK_EU_API_URL stringByAppendingFormat:@"/%@/", BNC_API_VERSION_3];
    } else {
        expectedUrlStr =  [BNC_EU_API_URL stringByAppendingFormat:@"/%@/", BNC_API_VERSION_3];
    }
    
    XCTAssertTrue([urlStr isEqualToString:expectedUrlStr]);
    [self.serverAPI setUseEUServers:false];
}

- (void)testInstallServiceURL {
    NSURL *url;
    NSString *expectedUrlStr;
    
    [self.serverAPI setUseEUServers:true];
    url = [[BNCServerAPI sharedInstance] installServiceURL];
    
    if ([self.optedInStatus isEqualToString:@"authorized"]){
        expectedUrlStr =  [BNC_SAFETRACK_EU_API_URL stringByAppendingFormat:@"/%@/%@", BNC_API_VERSION_3, BRANCH_REQUEST_ENDPOINT_INSTALL];
    } else {
        expectedUrlStr =  [BNC_EU_API_URL stringByAppendingFormat:@"/%@/%@", BNC_API_VERSION_3, BRANCH_REQUEST_ENDPOINT_INSTALL];
    }
    
    XCTAssertTrue([url isEqual:[ NSURL URLWithString:expectedUrlStr]]);
    [self.serverAPI setUseEUServers:false];
}

- (void)testOpenServiceURL {
    NSURL *url;
    NSString *expectedUrlStr;
    
    [self.serverAPI setUseEUServers:true];
    url = [[BNCServerAPI sharedInstance] openServiceURL];
    
    if ([self.optedInStatus isEqualToString:@"authorized"]){
        expectedUrlStr =  [BNC_SAFETRACK_EU_API_URL stringByAppendingFormat:@"/%@/%@", BNC_API_VERSION_3, BRANCH_REQUEST_ENDPOINT_OPEN];
    } else {
        expectedUrlStr =  [BNC_EU_API_URL stringByAppendingFormat:@"/%@/%@", BNC_API_VERSION_3, BRANCH_REQUEST_ENDPOINT_OPEN];
    }
    
    XCTAssertTrue([url isEqual:[ NSURL URLWithString:expectedUrlStr]]);
    [self.serverAPI setUseEUServers:false];
}

- (void)testEventServiceURL {
    NSURL *url;
    NSString *expectedUrlStr;
    
    [self.serverAPI setUseEUServers:true];
    url = [[BNCServerAPI sharedInstance] eventServiceURL];
    
    if ([self.optedInStatus isEqualToString:@"authorized"]){
        expectedUrlStr =  [BNC_SAFETRACK_EU_API_URL stringByAppendingFormat:@"/%@/%@", BNC_API_VERSION_3, BRANCH_REQUEST_ENDPOINT_USER_COMPLETED_ACTION];
    } else {
        expectedUrlStr =  [BNC_EU_API_URL stringByAppendingFormat:@"/%@/%@", BNC_API_VERSION_3, BRANCH_REQUEST_ENDPOINT_USER_COMPLETED_ACTION];
    }
    
    XCTAssertTrue([url isEqual:[ NSURL URLWithString:expectedUrlStr]]);
    [self.serverAPI setUseEUServers:false];
}

- (void)testLinkServiceURL {
    NSURL *url;
    NSString *expectedUrlStr;
    
    [self.serverAPI setUseEUServers:true];
    url = [[BNCServerAPI sharedInstance] linkServiceURL];
    
    if ([self.optedInStatus isEqualToString:@"authorized"]){
        expectedUrlStr =  [BNC_SAFETRACK_EU_API_URL stringByAppendingFormat:@"/%@/%@", BNC_API_VERSION_3, BRANCH_REQUEST_ENDPOINT_GET_SHORT_URL];
    } else {
        expectedUrlStr =  [BNC_EU_API_URL stringByAppendingFormat:@"/%@/%@", BNC_API_VERSION_3, BRANCH_REQUEST_ENDPOINT_GET_SHORT_URL];
    }
    
    XCTAssertTrue([url isEqual:[ NSURL URLWithString:expectedUrlStr]]);
    [self.serverAPI setUseEUServers:false];
}

@end
