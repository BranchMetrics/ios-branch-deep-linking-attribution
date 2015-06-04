//
//  BranchConnectDebugRequestTests.m
//  Branch-TestBed
//
//  Created by Graham Mueller on 6/4/15.
//  Copyright (c) 2015 Branch Metrics. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <XCTest/XCTest.h>
#import "BranchConnectDebugRequest.h"
#import "BNCPreferenceHelper.h"

@interface BranchConnectDebugRequestTests : XCTestCase

@end

@implementation BranchConnectDebugRequestTests

- (void)testDebuggerSuccessfulConnect {
    BranchConnectDebugRequest *request = [[BranchConnectDebugRequest alloc] initWithCallback:^(BOOL changed, NSError *error) { }];
    BNCServerResponse *response = [[BNCServerResponse alloc] init];
    response.statusCode = @200;
    
    [request processResponse:response error:nil];
    
    XCTAssertTrue([BNCPreferenceHelper isConnectedToRemoteDebug]);
}

- (void)testDebuggerConnectFailure {
    BranchConnectDebugRequest *request = [[BranchConnectDebugRequest alloc] initWithCallback:^(BOOL changed, NSError *error) { }];
    NSError *connectError = [NSError errorWithDomain:@"foo" code:465 userInfo:@{ NSLocalizedDescriptionKey: @"Server not listening" }];
    BNCServerResponse *response = [[BNCServerResponse alloc] init];
    response.statusCode = @400;
    
    [request processResponse:response error:connectError];
    
    XCTAssertFalse([BNCPreferenceHelper isConnectedToRemoteDebug]);
}

@end
