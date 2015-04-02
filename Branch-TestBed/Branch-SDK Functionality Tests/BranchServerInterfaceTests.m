//
//  BranchServerInterfaceTests.m
//  Branch-TestBed
//
//  Created by Graham Mueller on 4/1/15.
//  Copyright (c) 2015 Branch Metrics. All rights reserved.
//

#import <XCTest/XCTest.h>
#import <OCMock/OCMock.h>
#import "BranchServerInterface.h"
#import "BNCPreferenceHelper.h"
#import "BNCSystemObserver.h"

@interface BranchServerInterfaceTests : XCTestCase

@end

@implementation BranchServerInterfaceTests

#pragma mark - RegisterInstall tests

- (void)testRegisterInstallWithSpecifiedUriScheme {
    BranchServerInterface *serverInterface = [[BranchServerInterface alloc] init];
    id serverInterfaceMock = [OCMockObject partialMockForObject:serverInterface];
    
    NSString *expectedUriScheme = @"foo://";
    NSString *unexpectedUriScheme = @"bar://";
    id preferenceHelperMock = [OCMockObject mockForClass:[BNCPreferenceHelper class]];
    [[[preferenceHelperMock stub] andReturn:expectedUriScheme] getUriScheme];
    id systemObserverMock = [OCMockObject mockForClass:[BNCSystemObserver class]];
    [[[systemObserverMock stub] andReturn:unexpectedUriScheme] getDefaultUriScheme];
    
    id paramCheckBlock = [OCMArg checkWithBlock:^BOOL(NSDictionary *params) {
        NSString *uriScheme = params[@"uri_scheme"];
        BOOL hasExpectedUriScheme = [uriScheme isEqualToString:expectedUriScheme];
        
        // TODO add additional items we care about
        return hasExpectedUriScheme;
    }];
    
    // Expect the postRequestAsync method to be called, verify the post params
    [[serverInterfaceMock expect] postRequestAsync:paramCheckBlock url:[OCMArg any] andTag:[OCMArg any]];
    
    // Make the actual call
    [serverInterface registerInstall:NO];
    
    // Verify post was called with correct params
    [serverInterfaceMock verify];
}

- (void)testRegisterInstallWithoutSpecifiedUriScheme {
    BranchServerInterface *serverInterface = [[BranchServerInterface alloc] init];
    id serverInterfaceMock = [OCMockObject partialMockForObject:serverInterface];
    
    NSString *expectedUriScheme = @"foo://";
    id preferenceHelperMock = [OCMockObject mockForClass:[BNCPreferenceHelper class]];
    [[[preferenceHelperMock stub] andReturn:nil] getUriScheme];
    id systemObserverMock = [OCMockObject mockForClass:[BNCSystemObserver class]];
    [[[systemObserverMock stub] andReturn:expectedUriScheme] getDefaultUriScheme];
    
    id paramCheckBlock = [OCMArg checkWithBlock:^BOOL(NSDictionary *params) {
        NSString *uriScheme = params[@"uri_scheme"];
        BOOL hasExpectedUriScheme = [uriScheme isEqualToString:expectedUriScheme];
        
        // TODO add additional items we care about
        return hasExpectedUriScheme;
    }];
    
    // Expect the postRequestAsync method to be called, verify the post params
    [[serverInterfaceMock expect] postRequestAsync:paramCheckBlock url:[OCMArg any] andTag:[OCMArg any]];
    
    // Make the actual call
    [serverInterface registerInstall:NO];
    
    // Verify post was called with correct params
    [serverInterfaceMock verify];
}


#pragma mark - RegisterOpen tests

- (void)testRegisterOpenWithSpecifiedUriScheme {
    BranchServerInterface *serverInterface = [[BranchServerInterface alloc] init];
    id serverInterfaceMock = [OCMockObject partialMockForObject:serverInterface];
    
    NSString *expectedUriScheme = @"foo://";
    NSString *unexpectedUriScheme = @"bar://";
    id preferenceHelperMock = [OCMockObject mockForClass:[BNCPreferenceHelper class]];
    [[[preferenceHelperMock stub] andReturn:expectedUriScheme] getUriScheme];
    id systemObserverMock = [OCMockObject mockForClass:[BNCSystemObserver class]];
    [[[systemObserverMock stub] andReturn:unexpectedUriScheme] getDefaultUriScheme];
    
    id paramCheckBlock = [OCMArg checkWithBlock:^BOOL(NSDictionary *params) {
        NSString *uriScheme = params[@"uri_scheme"];
        BOOL hasExpectedUriScheme = [uriScheme isEqualToString:expectedUriScheme];
        
        // TODO add additional items we care about
        return hasExpectedUriScheme;
    }];
    
    // Expect the postRequestAsync method to be called, verify the post params
    [[serverInterfaceMock expect] postRequestAsync:paramCheckBlock url:[OCMArg any] andTag:[OCMArg any]];
    
    // Make the actual call
    [serverInterface registerOpen:NO];
    
    // Verify post was called with correct params
    [serverInterfaceMock verify];
}

- (void)testRegisterOpenWithoutSpecifiedUriScheme {
    BranchServerInterface *serverInterface = [[BranchServerInterface alloc] init];
    id serverInterfaceMock = [OCMockObject partialMockForObject:serverInterface];
    
    NSString *expectedUriScheme = @"foo://";
    id preferenceHelperMock = [OCMockObject mockForClass:[BNCPreferenceHelper class]];
    [[[preferenceHelperMock stub] andReturn:nil] getUriScheme];
    id systemObserverMock = [OCMockObject mockForClass:[BNCSystemObserver class]];
    [[[systemObserverMock stub] andReturn:expectedUriScheme] getDefaultUriScheme];
    
    id paramCheckBlock = [OCMArg checkWithBlock:^BOOL(NSDictionary *params) {
        NSString *uriScheme = params[@"uri_scheme"];
        BOOL hasExpectedUriScheme = [uriScheme isEqualToString:expectedUriScheme];
        
        // TODO add additional items we care about
        return hasExpectedUriScheme;
    }];
    
    // Expect the postRequestAsync method to be called, verify the post params
    [[serverInterfaceMock expect] postRequestAsync:paramCheckBlock url:[OCMArg any] andTag:[OCMArg any]];
    
    // Make the actual call
    [serverInterface registerOpen:NO];
    
    // Verify post was called with correct params
    [serverInterfaceMock verify];
}

@end
