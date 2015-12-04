//
//  BranchConnectDebugRequestTests.m
//  Branch-TestBed
//
//  Created by Graham Mueller on 6/4/15.
//  Copyright (c) 2015 Branch Metrics. All rights reserved.
//

#import "BranchTest.h"
#import "BranchConnectDebugRequest.h"
#import "BNCPreferenceHelper.h"
#import "BranchConstants.h"
#import "BNCSystemObserver.h"
#import <OCMock/OCMock.h>
#import "BNCConfig.h"

@interface BranchConnectDebugRequestTests : BranchTest

@end

@implementation BranchConnectDebugRequestTests

- (void)testRequestBody {
    NSString * const DEVICE_NAME = @"foo-name";
    NSString * const OS = @"foo-os";
    NSString * const OS_VERSION = @"foo-os-version";
    NSString * const MODEL = @"foo-model";
    NSNumber * const IS_SIMULATOR = @YES;
    NSString * const SESSION_ID = @"11111";
    NSString * const BRANCH_IDENTITY = @"22222";

    BNCPreferenceHelper *preferenceHelper = [BNCPreferenceHelper preferenceHelper];
    NSDictionary * const expectedParams = @{
        BRANCH_REQUEST_KEY_DEVICE_FINGERPRINT_ID: preferenceHelper.deviceFingerprintID,
        BRANCH_REQUEST_KEY_DEVICE_NAME: DEVICE_NAME,
        BRANCH_REQUEST_KEY_OS: OS,
        BRANCH_REQUEST_KEY_OS_VERSION: OS_VERSION,
        BRANCH_REQUEST_KEY_MODEL: MODEL,
        BRANCH_REQUEST_KEY_IS_SIMULATOR: IS_SIMULATOR,
        BRANCH_REQUEST_KEY_SESSION_ID: SESSION_ID,
        BRANCH_REQUEST_KEY_BRANCH_IDENTITY: BRANCH_IDENTITY,
        @"sdk": [NSString stringWithFormat:@"ios%@", SDK_VERSION]
    };
    
    id systemObserverMock = OCMClassMock([BNCSystemObserver class]);
    [[[systemObserverMock stub] andReturn:DEVICE_NAME] getDeviceName];
    [[[systemObserverMock stub] andReturn:OS] getOS];
    [[[systemObserverMock stub] andReturn:OS_VERSION] getOSVersion];
    [[[systemObserverMock stub] andReturn:MODEL] getModel];
    [[[systemObserverMock stub] andReturnValue:IS_SIMULATOR] isSimulator];
    
    BranchConnectDebugRequest *request = [[BranchConnectDebugRequest alloc] init];
    id serverInterfaceMock = OCMClassMock([BNCServerInterface class]);
    [[serverInterfaceMock expect] postRequest:expectedParams url:[self stringMatchingPattern:BRANCH_REQUEST_ENDPOINT_CONNECT_DEBUG] key:[OCMArg any] log:NO callback:[OCMArg any]];
    
    [request makeRequest:serverInterfaceMock key:nil callback:NULL];
    
    [serverInterfaceMock verify];
}

- (void)testDebuggerSuccessfulConnect {
    BranchConnectDebugRequest *request = [[BranchConnectDebugRequest alloc] initWithCallback:^(BOOL changed, NSError *error) { }];
    BNCServerResponse *response = [[BNCServerResponse alloc] init];
    response.statusCode = @200;
    
    [request processResponse:response error:nil];
    
    XCTAssertTrue([[BNCPreferenceHelper preferenceHelper] isConnectedToRemoteDebug]);
}

- (void)testDebuggerConnectFailure {
    BranchConnectDebugRequest *request = [[BranchConnectDebugRequest alloc] initWithCallback:^(BOOL changed, NSError *error) { }];
    NSError *connectError = [NSError errorWithDomain:@"foo" code:465 userInfo:@{ NSLocalizedDescriptionKey: @"Server not listening" }];
    BNCServerResponse *response = [[BNCServerResponse alloc] init];
    response.statusCode = @400;
    
    [request processResponse:response error:connectError];
    
    XCTAssertFalse([[BNCPreferenceHelper preferenceHelper] isConnectedToRemoteDebug]);
}

@end
