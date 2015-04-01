//
//  BNCServerInterface.m
//  Branch
//
//  Created by Graham Mueller on 3/31/15.
//  Copyright (c) 2015 Branch Metrics. All rights reserved.
//

#import <XCTest/XCTest.h>
#import "BNCServerInterface.h"
#import "BNCPreferenceHelper.h"
#import <OCMock/OCMock.h>

@interface BNCServerInterfaceTests : XCTestCase

@property (assign, nonatomic) NSInteger originalRetryInterval;
@property (assign, nonatomic) NSInteger originalRetryCount;

@end

@implementation BNCServerInterfaceTests

- (void)setUp {
    self.originalRetryInterval = [BNCPreferenceHelper getRetryInterval];
    self.originalRetryCount = [BNCPreferenceHelper getRetryCount];

    [BNCPreferenceHelper setRetryInterval:1]; // turn down sleep time
}

- (void)tearDown {
    [BNCPreferenceHelper setRetryInterval:self.originalRetryInterval]; // set values back to original
    [BNCPreferenceHelper setRetryCount:self.originalRetryCount];
}

#pragma mark - Retry tests

- (void)testGetRequestAsyncRetriesWhenAppropriate {
    BNCServerInterface *serverInterface = [[BNCServerInterface alloc] init];
    BNCServerResponse *retryableResponse = [[BNCServerResponse alloc] initWithTag:@"foo" andStatusCode:@500];
    
    // Specify retry count as 3
    [BNCPreferenceHelper setRetryCount:3];

    // Mock the actual request part, should happen 4 times (once through, 3 replays). Reject any more
    id serverInterfaceMock = [OCMockObject partialMockForObject:serverInterface];
    [[[serverInterfaceMock expect] andReturn:retryableResponse] genericSyncHTTPRequest:[OCMArg any] withTag:[OCMArg any] andLinkData:[OCMArg any]];
    [[[serverInterfaceMock expect] andReturn:retryableResponse] genericSyncHTTPRequest:[OCMArg any] withTag:[OCMArg any] andLinkData:[OCMArg any]];
    [[[serverInterfaceMock expect] andReturn:retryableResponse] genericSyncHTTPRequest:[OCMArg any] withTag:[OCMArg any] andLinkData:[OCMArg any]];
    [[[serverInterfaceMock expect] andReturn:retryableResponse] genericSyncHTTPRequest:[OCMArg any] withTag:[OCMArg any] andLinkData:[OCMArg any]];
    [[serverInterfaceMock reject] genericSyncHTTPRequest:[OCMArg any] withTag:[OCMArg any] andLinkData:[OCMArg any]];
    
    // Make the request
    [serverInterface getRequestAsync:nil url:@"http://foo" andTag:@"foo"];
    
    // Verify count of retries
    [serverInterfaceMock verify];
}

- (void)testGetRequestAsyncRetriesWhenInappropriateResponse {
    BNCServerInterface *serverInterface = [[BNCServerInterface alloc] init];
    BNCServerResponse *nonRetryableResponse = [[BNCServerResponse alloc] initWithTag:@"foo" andStatusCode:@200];

    // Specify retry count as 3
    [BNCPreferenceHelper setRetryCount:3];
    
    // Mock the actual request part, reject any replays -- shouldn't be replayed.
    id serverInterfaceMock = [OCMockObject partialMockForObject:serverInterface];
    [[[serverInterfaceMock expect] andReturn:nonRetryableResponse] genericSyncHTTPRequest:[OCMArg any] withTag:[OCMArg any] andLinkData:[OCMArg any]];
    [[serverInterfaceMock reject] genericSyncHTTPRequest:[OCMArg any] withTag:[OCMArg any] andLinkData:[OCMArg any]];
    
    // Make the request
    [serverInterface getRequestAsync:nil url:@"http://foo" andTag:@"foo"];
    
    // Verify count of retries
    [serverInterfaceMock verify];
}

- (void)testGetRequestAsyncRetriesWhenInappropriateRetryCount {
    BNCServerInterface *serverInterface = [[BNCServerInterface alloc] init];
    BNCServerResponse *retryableResponse = [[BNCServerResponse alloc] initWithTag:@"foo" andStatusCode:@500];

    // Specify retry count as 0
    [BNCPreferenceHelper setRetryCount:0];
    
    // Mock the actual request part, reject any replays -- shouldn't be replayed.
    id serverInterfaceMock = [OCMockObject partialMockForObject:serverInterface];
    [[[serverInterfaceMock expect] andReturn:retryableResponse] genericSyncHTTPRequest:[OCMArg any] withTag:[OCMArg any] andLinkData:[OCMArg any]];
    [[serverInterfaceMock reject] genericSyncHTTPRequest:[OCMArg any] withTag:[OCMArg any] andLinkData:[OCMArg any]];
    
    // Make the request
    [serverInterface getRequestAsync:nil url:@"http://foo" andTag:@"foo"];
    
    // Verify count of retries
    [serverInterfaceMock verify];
}

- (void)testPostRequestAsyncRetriesWhenAppropriate {
    BNCServerInterface *serverInterface = [[BNCServerInterface alloc] init];
    BNCServerResponse *retryableResponse = [[BNCServerResponse alloc] initWithTag:@"foo" andStatusCode:@500];

    // Specify retry count as 3
    [BNCPreferenceHelper setRetryCount:3];
    
    // Mock the actual request part, should happen 4 times (once through, 3 replays). Reject any more
    id serverInterfaceMock = [OCMockObject partialMockForObject:serverInterface];
    [[[serverInterfaceMock expect] andReturn:retryableResponse] genericSyncHTTPRequest:[OCMArg any] withTag:[OCMArg any] andLinkData:[OCMArg any]];
    [[[serverInterfaceMock expect] andReturn:retryableResponse] genericSyncHTTPRequest:[OCMArg any] withTag:[OCMArg any] andLinkData:[OCMArg any]];
    [[[serverInterfaceMock expect] andReturn:retryableResponse] genericSyncHTTPRequest:[OCMArg any] withTag:[OCMArg any] andLinkData:[OCMArg any]];
    [[[serverInterfaceMock expect] andReturn:retryableResponse] genericSyncHTTPRequest:[OCMArg any] withTag:[OCMArg any] andLinkData:[OCMArg any]];
    [[serverInterfaceMock reject] genericSyncHTTPRequest:[OCMArg any] withTag:[OCMArg any] andLinkData:[OCMArg any]];
    
    // Make the request
    [serverInterface postRequestAsync:nil url:@"http://foo" andTag:@"foo"];
    
    // Verify count of retries
    [serverInterfaceMock verify];
}

- (void)testPostRequestAsyncRetriesWhenInappropriateResponse {
    BNCServerInterface *serverInterface = [[BNCServerInterface alloc] init];
    BNCServerResponse *nonRetryableResponse = [[BNCServerResponse alloc] initWithTag:@"foo" andStatusCode:@200];
    
    // Specify retry count as 3
    [BNCPreferenceHelper setRetryCount:3];
    
    // Mock the actual request part, reject any replays -- shouldn't be replayed.
    id serverInterfaceMock = [OCMockObject partialMockForObject:serverInterface];
    [[[serverInterfaceMock expect] andReturn:nonRetryableResponse] genericSyncHTTPRequest:[OCMArg any] withTag:[OCMArg any] andLinkData:[OCMArg any]];
    [[serverInterfaceMock reject] genericSyncHTTPRequest:[OCMArg any] withTag:[OCMArg any] andLinkData:[OCMArg any]];
    
    // Make the request
    [serverInterface postRequestAsync:nil url:@"http://foo" andTag:@"foo"];
    
    // Verify count of retries
    [serverInterfaceMock verify];
}

- (void)testPostRequestAsyncRetriesWhenInappropriateRetryCount {
    BNCServerInterface *serverInterface = [[BNCServerInterface alloc] init];
    BNCServerResponse *retryableResponse = [[BNCServerResponse alloc] initWithTag:@"foo" andStatusCode:@500];
    
    // Specify retry count as 3
    [BNCPreferenceHelper setRetryCount:0];
    
    // Mock the actual request part, reject any replays -- shouldn't be replayed.
    id serverInterfaceMock = [OCMockObject partialMockForObject:serverInterface];
    [[[serverInterfaceMock expect] andReturn:retryableResponse] genericSyncHTTPRequest:[OCMArg any] withTag:[OCMArg any] andLinkData:[OCMArg any]];
    [[serverInterfaceMock reject] genericSyncHTTPRequest:[OCMArg any] withTag:[OCMArg any] andLinkData:[OCMArg any]];
    
    // Make the request
    [serverInterface postRequestAsync:nil url:@"http://foo" andTag:@"foo"];
    
    // Verify count of retries
    [serverInterfaceMock verify];
}

@end
