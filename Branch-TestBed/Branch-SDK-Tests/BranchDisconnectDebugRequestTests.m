//
//  BranchDisconnectDebugRequestTests.m
//  Branch-TestBed
//
//  Created by Graham Mueller on 6/24/15.
//  Copyright (c) 2015 Branch Metrics. All rights reserved.
//

#import "BranchTest.h"
#import "BranchDisconnectDebugRequest.h"
#import "BranchConstants.h"
#import "BNCPreferenceHelper.h"
#import <OCMock/OCMock.h>

@interface BranchDisconnectDebugRequestTests : BranchTest

@end

@implementation BranchDisconnectDebugRequestTests

- (void)testRequestBody {
    NSDictionary * const expectedParams = @{
        BRANCH_REQUEST_KEY_DEVICE_FINGERPRINT_ID: [BNCPreferenceHelper preferenceHelper].deviceFingerprintID
    };
    
    BranchDisconnectDebugRequest *request = [[BranchDisconnectDebugRequest alloc] init];
    id serverInterfaceMock = OCMClassMock([BNCServerInterface class]);
    [[serverInterfaceMock expect] postRequest:expectedParams url:[self stringMatchingPattern:BRANCH_REQUEST_ENDPOINT_DISCONNECT_DEBUG] key:[OCMArg any] log:NO callback:[OCMArg any]];
    
    [request makeRequest:serverInterfaceMock key:nil callback:NULL];
    
    [serverInterfaceMock verify];
}

- (void)testDebuggerSuccessfulConnect {
    BranchDisconnectDebugRequest *request = [[BranchDisconnectDebugRequest alloc] init];
    
    [request processResponse:nil error:nil];
    
    XCTAssertFalse([BNCPreferenceHelper preferenceHelper].isConnectedToRemoteDebug);
}

@end
