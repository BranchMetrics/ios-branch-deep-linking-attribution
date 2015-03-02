//
//  Branch_SDK_Debugger_Tests.m
//  Branch-TestBed
//
//  Created by Qinwei Gong on 2/23/15.
//  Copyright (c) 2015 Branch Metrics. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <XCTest/XCTest.h>
#import "BNCPreferenceHelper.h"
#import "BranchServerInterface.h"
#import "Nocilla.h"

@interface Branch_SDK_Debugger_Tests : XCTestCase {
    
@private
    BNCPreferenceHelper *prefHelper;
    BranchServerInterface *serverInterface;
}

@end

@implementation Branch_SDK_Debugger_Tests

- (void)setUp {
    [super setUp];
    
    [[LSNocilla sharedInstance] start];
    
    prefHelper = [[BNCPreferenceHelper alloc] init];
    serverInterface = [[BranchServerInterface alloc] init];
    serverInterface.delegate = (id<BNCServerInterfaceDelegate>)prefHelper;
}

- (void)tearDown {
    [[LSNocilla sharedInstance] clearStubs];
    [[LSNocilla sharedInstance] stop];
    
    [super tearDown];
}

- (void)testConnectSucceed {
    stubRequest(@"POST", [BNCPreferenceHelper getAPIURL:@"debug/connect"])
    .andReturn(200);
    
    [serverInterface connectToDebug];
    
    XCTAssertTrue([BNCPreferenceHelper isRemoteDebug]);
}

- (void)testConnectFail {
    NSDictionary *responseDict = @{@"error": @{@"code": @465, @"message": @"Server not listening"}};
    NSData *responseData = [BNCServerInterface encodePostParams:responseDict];
    
    stubRequest(@"POST", [BNCPreferenceHelper getAPIURL:@"debug/connect"])
    .andReturn(465)
    .withHeaders(@{@"application/json": @"Content-Type"})
    .withBody(responseData);
    
    [serverInterface connectToDebug];
    XCTAssertFalse([BNCPreferenceHelper isRemoteDebug]);
}

@end
