//
//  BNCServerInterface.m
//  Branch-TestBed
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

@end

@implementation BNCServerInterfaceTests

- (void)setUp {
    self.originalRetryInterval = [BNCPreferenceHelper getRetryInterval];
    [BNCPreferenceHelper setRetryInterval:1]; // turn down sleep time
}

- (void)tearDown {
    [BNCPreferenceHelper setRetryInterval:self.originalRetryInterval]; // set sleep time back to original
}

#pragma mark - Retry tests

- (void)testGetRequestAsyncRetriesWhenAppropriate {
    BNCServerInterface *serverInterface = [[BNCServerInterface alloc] init];
    BNCServerResponse *retryableResponse = [[BNCServerResponse alloc] initWithTag:@"foo" andStatusCode:@500];
    
    // Mock the actual request part, should happen 4 times (once through, 3 replays). Reject any more
    id serverInterfaceMock = [OCMockObject partialMockForObject:serverInterface];
    [[[serverInterfaceMock expect] andReturn:retryableResponse] genericSyncHTTPRequest:[OCMArg any] withTag:[OCMArg any] andLinkData:[OCMArg any]];
    [[[serverInterfaceMock expect] andReturn:retryableResponse] genericSyncHTTPRequest:[OCMArg any] withTag:[OCMArg any] andLinkData:[OCMArg any]];
    [[[serverInterfaceMock expect] andReturn:retryableResponse] genericSyncHTTPRequest:[OCMArg any] withTag:[OCMArg any] andLinkData:[OCMArg any]];
    [[[serverInterfaceMock expect] andReturn:retryableResponse] genericSyncHTTPRequest:[OCMArg any] withTag:[OCMArg any] andLinkData:[OCMArg any]];
    [[serverInterfaceMock reject] genericSyncHTTPRequest:[OCMArg any] withTag:[OCMArg any] andLinkData:[OCMArg any]];
    
    // Make the request
    [serverInterface getRequestAsync:nil url:@"http://foo" andTag:@"foo" retryCount:3];
    
    // Verify count of retries
    [serverInterfaceMock verify];
}

- (void)testGetRequestAsyncRetriesWhenInappropriateResponse {
    BNCServerInterface *serverInterface = [[BNCServerInterface alloc] init];
    BNCServerResponse *nonRetryableResponse = [[BNCServerResponse alloc] initWithTag:@"foo" andStatusCode:@200];
    
    // Mock the actual request part, reject any replays -- shouldn't be replayed.
    id serverInterfaceMock = [OCMockObject partialMockForObject:serverInterface];
    [[[serverInterfaceMock expect] andReturn:nonRetryableResponse] genericSyncHTTPRequest:[OCMArg any] withTag:[OCMArg any] andLinkData:[OCMArg any]];
    [[serverInterfaceMock reject] genericSyncHTTPRequest:[OCMArg any] withTag:[OCMArg any] andLinkData:[OCMArg any]];
    
    // Make the request
    [serverInterface getRequestAsync:nil url:@"http://foo" andTag:@"foo" retryCount:3];
    
    // Verify count of retries
    [serverInterfaceMock verify];
}

- (void)testGetRequestAsyncRetriesWhenInappropriateRetryCount {
    BNCServerInterface *serverInterface = [[BNCServerInterface alloc] init];
    BNCServerResponse *retryableResponse = [[BNCServerResponse alloc] initWithTag:@"foo" andStatusCode:@500];
    
    // Mock the actual request part, reject any replays -- shouldn't be replayed.
    id serverInterfaceMock = [OCMockObject partialMockForObject:serverInterface];
    [[[serverInterfaceMock expect] andReturn:retryableResponse] genericSyncHTTPRequest:[OCMArg any] withTag:[OCMArg any] andLinkData:[OCMArg any]];
    [[serverInterfaceMock reject] genericSyncHTTPRequest:[OCMArg any] withTag:[OCMArg any] andLinkData:[OCMArg any]];
    
    // Make the request
    [serverInterface getRequestAsync:nil url:@"http://foo" andTag:@"foo" retryCount:0];
    
    // Verify count of retries
    [serverInterfaceMock verify];
}

- (void)testPostRequestAsyncRetriesWhenAppropriate {
    BNCServerInterface *serverInterface = [[BNCServerInterface alloc] init];
    BNCServerResponse *retryableResponse = [[BNCServerResponse alloc] initWithTag:@"foo" andStatusCode:@500];
    
    // Mock the actual request part, should happen 4 times (once through, 3 replays). Reject any more
    id serverInterfaceMock = [OCMockObject partialMockForObject:serverInterface];
    [[[serverInterfaceMock expect] andReturn:retryableResponse] genericSyncHTTPRequest:[OCMArg any] withTag:[OCMArg any] andLinkData:[OCMArg any]];
    [[[serverInterfaceMock expect] andReturn:retryableResponse] genericSyncHTTPRequest:[OCMArg any] withTag:[OCMArg any] andLinkData:[OCMArg any]];
    [[[serverInterfaceMock expect] andReturn:retryableResponse] genericSyncHTTPRequest:[OCMArg any] withTag:[OCMArg any] andLinkData:[OCMArg any]];
    [[[serverInterfaceMock expect] andReturn:retryableResponse] genericSyncHTTPRequest:[OCMArg any] withTag:[OCMArg any] andLinkData:[OCMArg any]];
    [[serverInterfaceMock reject] genericSyncHTTPRequest:[OCMArg any] withTag:[OCMArg any] andLinkData:[OCMArg any]];
    
    // Make the request
    [serverInterface postRequestAsync:nil url:@"http://foo" andTag:@"foo" retryCount:3];
    
    // Verify count of retries
    [serverInterfaceMock verify];
}

- (void)testPostRequestAsyncRetriesWhenInappropriateResponse {
    BNCServerInterface *serverInterface = [[BNCServerInterface alloc] init];
    BNCServerResponse *nonRetryableResponse = [[BNCServerResponse alloc] initWithTag:@"foo" andStatusCode:@200];
    
    // Mock the actual request part, reject any replays -- shouldn't be replayed.
    id serverInterfaceMock = [OCMockObject partialMockForObject:serverInterface];
    [[[serverInterfaceMock expect] andReturn:nonRetryableResponse] genericSyncHTTPRequest:[OCMArg any] withTag:[OCMArg any] andLinkData:[OCMArg any]];
    [[serverInterfaceMock reject] genericSyncHTTPRequest:[OCMArg any] withTag:[OCMArg any] andLinkData:[OCMArg any]];
    
    // Make the request
    [serverInterface postRequestAsync:nil url:@"http://foo" andTag:@"foo" retryCount:3];
    
    // Verify count of retries
    [serverInterfaceMock verify];
}

- (void)testPostRequestAsyncRetriesWhenInappropriateRetryCount {
    BNCServerInterface *serverInterface = [[BNCServerInterface alloc] init];
    BNCServerResponse *retryableResponse = [[BNCServerResponse alloc] initWithTag:@"foo" andStatusCode:@500];
    
    // Mock the actual request part, reject any replays -- shouldn't be replayed.
    id serverInterfaceMock = [OCMockObject partialMockForObject:serverInterface];
    [[[serverInterfaceMock expect] andReturn:retryableResponse] genericSyncHTTPRequest:[OCMArg any] withTag:[OCMArg any] andLinkData:[OCMArg any]];
    [[serverInterfaceMock reject] genericSyncHTTPRequest:[OCMArg any] withTag:[OCMArg any] andLinkData:[OCMArg any]];
    
    // Make the request
    [serverInterface postRequestAsync:nil url:@"http://foo" andTag:@"foo" retryCount:0];
    
    // Verify count of retries
    [serverInterfaceMock verify];
}


#pragma mark - Encoding tests

- (void)testEncodePostToUniversalStringWithExpectedParams {
    NSDictionary *dataDict = @{ @"foo": @"bar", @"num": @1, @"dict": @{ @"sub": @1 } };
    NSString *expectedEncodedString = @"{\"foo\":\"bar\",\"num\":1,\"dict\":{\"sub\":1}}";
    
    NSString *encodedValue = [BNCServerInterface encodePostToUniversalString:dataDict needSource:NO];
    
    XCTAssertEqualObjects(expectedEncodedString, encodedValue);
}

- (void)testEncodePostToUniversalStringWithUnexpectedParams {
    // TODO better "unknown" type since NSDate should be handled
    NSDictionary *dataDict = @{ @"foo": @"bar", @"date": [NSDate date] };
    NSString *expectedEncodedString = @"{\"foo\":\"bar\"}";
    
    NSString *encodedValue = [BNCServerInterface encodePostToUniversalString:dataDict needSource:NO];
    
    XCTAssertEqualObjects(expectedEncodedString, encodedValue);
}

- (void)testEncodePostToUniversalStringWithNull {
    NSDictionary *dataDict = @{ @"foo": [NSNull null] };
    NSString *expectedEncodedString = @"{\"foo\":null}";
    
    NSString *encodedValue = [BNCServerInterface encodePostToUniversalString:dataDict needSource:NO];
    
    XCTAssertEqualObjects(expectedEncodedString, encodedValue);
}

- (void)testEncodePostToUniversalStringWithSubDictWithNeedSource {
    NSDictionary *dataDict = @{ @"root": @{ @"sub": @1 } };
    NSString *expectedEncodedString = @"{\"root\":{\"sub\":1},\"source\":\"ios\"}";
    
    NSString *encodedValue = [BNCServerInterface encodePostToUniversalString:dataDict needSource:YES];
    
    XCTAssertEqualObjects(expectedEncodedString, encodedValue);
}

@end
