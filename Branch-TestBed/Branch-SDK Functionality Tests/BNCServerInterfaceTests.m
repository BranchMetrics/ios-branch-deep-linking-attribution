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
#import <Nocilla/Nocilla.h>

@interface BNCServerInterfaceTests : XCTestCase

@property (assign, nonatomic) NSInteger originalRetryInterval;
@property (assign, nonatomic) NSInteger originalRetryCount;

@end

@implementation BNCServerInterfaceTests

+ (void)setUp {
    [super setUp];

    [[LSNocilla sharedInstance] start];
}

+ (void)tearDown {
    [[LSNocilla sharedInstance] stop];

    [super tearDown];
}

- (void)setUp {
    [super setUp];

    self.originalRetryInterval = [BNCPreferenceHelper getRetryInterval];
    self.originalRetryCount = [BNCPreferenceHelper getRetryCount];

    [BNCPreferenceHelper setRetryInterval:0]; // turn down sleep time
}

- (void)tearDown {
    [[LSNocilla sharedInstance] clearStubs];

    [BNCPreferenceHelper setRetryInterval:self.originalRetryInterval]; // set values back to original
    [BNCPreferenceHelper setRetryCount:self.originalRetryCount];

    [super tearDown];
}

#pragma mark - Retry tests

- (void)testGetRequestAsyncRetriesWhenAppropriate {
    BNCServerInterface *serverInterface = [[BNCServerInterface alloc] init];
    
    stubRequest(@"GET", @"http://foo\?.*?retryNumber=0|1|2|3$".regex).andReturn(500);
    
    // Specify retry count as 3
    [BNCPreferenceHelper setRetryCount:3];
    
    // Make the request
    XCTestExpectation *getRequestExpectation = [self expectationWithDescription:@"GET Request Expectation"];
    [serverInterface getRequest:nil url:@"http://foo" andTag:@"foo" callback:^(BNCServerResponse *response, NSError *error) {
        XCTAssertNotNil(error);

        [getRequestExpectation fulfill];
    }];
    
    [self waitForExpectationsWithTimeout:5 handler:NULL];
}

- (void)testGetRequestAsyncRetriesWhenInappropriateResponse {
    BNCServerInterface *serverInterface = [[BNCServerInterface alloc] init];
    
    stubRequest(@"GET", @"http://foo?.*retryNumber=0".regex).andReturn(200);
    
    // Specify retry count as 3
    [BNCPreferenceHelper setRetryCount:3];
    
    // Make the request
    XCTestExpectation *getRequestExpectation = [self expectationWithDescription:@"GET Request Expectation"];
    [serverInterface getRequest:nil url:@"http://foo" andTag:@"foo" callback:^(BNCServerResponse *response, NSError *error) {
        XCTAssertNil(error);
        
        [getRequestExpectation fulfill];
    }];
    
    [self waitForExpectationsWithTimeout:1 handler:NULL];
}

- (void)testGetRequestAsyncRetriesWhenInappropriateRetryCount {
    BNCServerInterface *serverInterface = [[BNCServerInterface alloc] init];
    
    stubRequest(@"GET", @"http://foo?.*retryNumber=0".regex).andReturn(500);

    // Specify retry count as 0
    [BNCPreferenceHelper setRetryCount:0];
    
    // Make the request
    XCTestExpectation *getRequestExpectation = [self expectationWithDescription:@"GET Request Expectation"];
    [serverInterface getRequest:nil url:@"http://foo" andTag:@"foo" callback:^(BNCServerResponse *response, NSError *error) {
        XCTAssertNotNil(error);
        
        [getRequestExpectation fulfill];
    }];
    
    [self waitForExpectationsWithTimeout:1 handler:NULL];
}

- (void)testPostRequestAsyncRetriesWhenAppropriate {
    BNCServerInterface *serverInterface = [[BNCServerInterface alloc] init];
    
    stubRequest(@"POST", @"http://foo").withBody(@"\"retryNumber\":0|1|2|3".regex).andReturn(500);

    // Specify retry count as 3
    [BNCPreferenceHelper setRetryCount:3];
    
    // Make the request
    XCTestExpectation *postRequestExpectation = [self expectationWithDescription:@"POST Request Expectation"];
    [serverInterface postRequest:nil url:@"http://foo" andTag:@"foo" callback:^(BNCServerResponse *response, NSError *error) {
        XCTAssertNotNil(error);
        
        [postRequestExpectation fulfill];
    }];

    [self waitForExpectationsWithTimeout:5 handler:NULL];
}

- (void)testPostRequestAsyncRetriesWhenInappropriateResponse {
    BNCServerInterface *serverInterface = [[BNCServerInterface alloc] init];
    
    stubRequest(@"POST", @"http://foo").withBody(@"\"retryNumber\":0".regex).andReturn(200);
    
    // Specify retry count as 3
    [BNCPreferenceHelper setRetryCount:3];
    
    // Make the request
    XCTestExpectation *postRequestExpectation = [self expectationWithDescription:@"POST Request Expectation"];
    [serverInterface postRequest:nil url:@"http://foo" andTag:@"foo" callback:^(BNCServerResponse *response, NSError *error) {
        XCTAssertNil(error);
        
        [postRequestExpectation fulfill];
    }];
    
    [self waitForExpectationsWithTimeout:1 handler:NULL];
}

- (void)testPostRequestAsyncRetriesWhenInappropriateRetryCount {
    BNCServerInterface *serverInterface = [[BNCServerInterface alloc] init];
    
    stubRequest(@"POST", @"http://foo").withBody(@"\"retryNumber\":0".regex).andReturn(500);

    // Specify retry count as 3
    [BNCPreferenceHelper setRetryCount:0];
    
    // Make the request
    XCTestExpectation *postRequestExpectation = [self expectationWithDescription:@"POST Request Expectation"];
    [serverInterface postRequest:nil url:@"http://foo" andTag:@"foo" callback:^(BNCServerResponse *response, NSError *error) {
        XCTAssertNotNil(error);
        
        [postRequestExpectation fulfill];
    }];
    
    [self waitForExpectationsWithTimeout:1 handler:NULL];
}

@end
