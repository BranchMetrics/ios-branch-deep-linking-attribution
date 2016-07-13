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
#import <OHHTTPStubs/OHHTTPStubs.h>
#import "OHHTTPStubsResponse+JSON.h"



typedef void (^UrlConnectionCallback)(NSURLResponse *, NSData *, NSError *);

@interface BNCServerInterfaceTests : XCTestCase

@end

@implementation BNCServerInterfaceTests

#pragma mark - Tear Down
- (void)tearDown
{
  [OHHTTPStubs removeAllStubs];
  [super tearDown];
}


#pragma mark - Key tests

//==================================================================================
//TEST 01
//This test checks to see that the branch key has been added to the GET request

- (void)testParamAddForBranchKey {
  BNCServerInterface *serverInterface = [[BNCServerInterface alloc] init];
  XCTestExpectation* expectation = [self expectationWithDescription:@"NSURLSessionDataTask completed"];
  
  [OHHTTPStubs stubRequestsPassingTest:^BOOL(NSURLRequest *request) {
    // We're not sending a request, just verifying a "branch_key=key_foo" is present.
    XCTAssertTrue([request.URL.query rangeOfString:@"branch_key=key_foo"].location != NSNotFound, @"Branch Key not added");
    [expectation fulfill];
    return [request.URL.query rangeOfString:@"branch_key=key_foo"].location != NSNotFound;
  } withStubResponse:^OHHTTPStubsResponse *(NSURLRequest *request) {
    NSDictionary* dummyJSONResponse = @{@"key": @"value"};
    return [OHHTTPStubsResponse responseWithJSONObject:dummyJSONResponse statusCode:200 headers:nil];
  }];
  
  [serverInterface getRequest:nil url:@"http://foo" key:@"key_foo" callback:NULL];
  
  [self waitForExpectationsWithTimeout:5.0 /* 5 seconds */ handler:nil];
  
}

#pragma mark - Retry tests

//==================================================================================
//TEST 03
//This test simulates a poor network, with three failed GET attempts and one final success,
// for 4 connections.

- (void)testGetRequestAsyncRetriesWhenAppropriate {
  
  //Set up nsurlsession and data task, catching response
  BNCServerInterface *serverInterface = [[BNCServerInterface alloc] init];
  serverInterface.preferenceHelper = [[BNCPreferenceHelper alloc] init];
  serverInterface.preferenceHelper.retryCount = 3;
  
  XCTestExpectation* successExpectation = [self expectationWithDescription:@"success"];
  
  __block NSUInteger connectionAttempts = 0;
  __block NSUInteger failedConnections = 0;
  __block NSUInteger successfulConnections = 0;
  
  [OHHTTPStubs stubRequestsPassingTest:^BOOL(NSURLRequest *request) {
    BOOL foundBranchKey = [request.URL.query rangeOfString:@"branch_key=key_foo"].location != NSNotFound;
    XCTAssertEqual(foundBranchKey, TRUE);
    return foundBranchKey;
    
  } withStubResponse:^OHHTTPStubsResponse*(NSURLRequest *request) {
    if (connectionAttempts++ < 3) {
      // Return an error the first three times
      NSDictionary* dummyJSONResponse = @{@"bad": @"data"};
      
      NSLog(@"attempt # %lu", (unsigned long)connectionAttempts);
      ++failedConnections;
      return [OHHTTPStubsResponse responseWithJSONObject:dummyJSONResponse statusCode:504 headers:nil];
      
    } else {
      // Return actual data afterwards
      ++successfulConnections;
      NSDictionary* dummyJSONResponse = @{@"key": @"value"};
      XCTAssertEqual(connectionAttempts, failedConnections + successfulConnections);
      [successExpectation fulfill];
      
      return [OHHTTPStubsResponse responseWithJSONObject:dummyJSONResponse statusCode:200 headers:nil];
    }
  }];
  
  [serverInterface getRequest:nil url:@"http://foo" key:@"key_foo" callback:NULL];
  [self waitForExpectationsWithTimeout:5.0 handler:nil];
}

//==================================================================================
//TEST 04
// This test checks to make sure that GET retries are not attempted when they have a retry
// count > 0, but retries aren't needed. Based on Test #3 above.

- (void)testGetRequestAsyncRetriesWhenInappropriateResponse {
  BNCServerInterface *serverInterface = [[BNCServerInterface alloc] init];
  serverInterface.preferenceHelper = [[BNCPreferenceHelper alloc] init];
  serverInterface.preferenceHelper.retryCount = 3;
  
  XCTestExpectation* successExpectation = [self expectationWithDescription:@"success"];
  
  __block NSUInteger connectionAttempts = 0;
  
  [OHHTTPStubs stubRequestsPassingTest:^BOOL(NSURLRequest *request) {
    BOOL foundBranchKey = [request.URL.query rangeOfString:@"branch_key=key_foo"].location != NSNotFound;
    XCTAssertEqual(foundBranchKey, TRUE);
    return foundBranchKey;
    
  } withStubResponse:^OHHTTPStubsResponse*(NSURLRequest *request) {
    // Return actual data on first attempt
    NSDictionary* dummyJSONResponse = @{@"key": @"value"};
    connectionAttempts++;
    XCTAssertEqual(connectionAttempts, 1);
    [successExpectation fulfill];
    
    return [OHHTTPStubsResponse responseWithJSONObject:dummyJSONResponse statusCode:200 headers:nil];
    
  }];
  
  [serverInterface getRequest:nil url:@"http://foo" key:@"key_foo" callback:NULL];
  [self waitForExpectationsWithTimeout:1.0 handler:nil];
  
}

//==================================================================================
//TEST 05
// This test checks to make sure that GET retries are not attempted when they have a retry
// count == 0, but retries aren't needed. Based on Test #4 above

- (void)testGetRequestAsyncRetriesWhenInappropriateRetryCount {
  
  BNCServerInterface *serverInterface = [[BNCServerInterface alloc] init];
  serverInterface.preferenceHelper = [[BNCPreferenceHelper alloc] init];
  serverInterface.preferenceHelper.retryCount = 0;
  
  XCTestExpectation* successExpectation = [self expectationWithDescription:@"success"];
  
  __block NSUInteger connectionAttempts = 0;
  
  [OHHTTPStubs stubRequestsPassingTest:^BOOL(NSURLRequest *request) {
    BOOL foundBranchKey = [request.URL.query rangeOfString:@"branch_key=key_foo"].location != NSNotFound;
    XCTAssertEqual(foundBranchKey, TRUE);
    return foundBranchKey;
    
  } withStubResponse:^OHHTTPStubsResponse*(NSURLRequest *request) {
    // Return actual data on first attempt
    NSDictionary* dummyJSONResponse = @{@"key": @"value"};
    connectionAttempts++;
    XCTAssertEqual(connectionAttempts, 1);
    [successExpectation fulfill];
    
    return [OHHTTPStubsResponse responseWithJSONObject:dummyJSONResponse statusCode:200 headers:nil];
    
  }];
  
  [serverInterface getRequest:nil url:@"http://foo" key:@"key_foo" callback:NULL];
  [self waitForExpectationsWithTimeout:1.0 handler:nil];
  
}

//==================================================================================
//TEST 06
//This test simulates a poor network, with three failed GET attempts and one final success,
//for 4 connections. Based on Test #3 above

- (void)testPostRequestAsyncRetriesWhenAppropriate {
  
  //Set up nsurlsession and data task, catching response
  BNCServerInterface *serverInterface = [[BNCServerInterface alloc] init];
  serverInterface.preferenceHelper = [[BNCPreferenceHelper alloc] init];
  serverInterface.preferenceHelper.retryCount = 3;
  
  XCTestExpectation* successExpectation = [self expectationWithDescription:@"success"];
  
  __block NSUInteger connectionAttempts = 0;
  __block NSUInteger failedConnections = 0;
  __block NSUInteger successfulConnections = 0;
  
  [OHHTTPStubs stubRequestsPassingTest:^BOOL(NSURLRequest *request) {
    BOOL foundBranchKey = [request.URL.query rangeOfString:@"branch_key=key_foo"].location != NSNotFound;
    XCTAssertEqual(foundBranchKey, TRUE);
    return foundBranchKey;
    
  } withStubResponse:^OHHTTPStubsResponse*(NSURLRequest *request) {
    if (connectionAttempts++ < 3) {
      // Return an error the first three times
      NSDictionary* dummyJSONResponse = @{@"bad": @"data"};
      
      NSLog(@"attempt # %lu", (unsigned long)connectionAttempts);
      ++failedConnections;
      return [OHHTTPStubsResponse responseWithJSONObject:dummyJSONResponse statusCode:504 headers:nil];
      
    } else {
      // Return actual data afterwards
      ++successfulConnections;
      NSDictionary* dummyJSONResponse = @{@"key": @"value"};
      XCTAssertEqual(connectionAttempts, failedConnections + successfulConnections);
      [successExpectation fulfill];
      
      return [OHHTTPStubsResponse responseWithJSONObject:dummyJSONResponse statusCode:200 headers:nil];
    }
  }];
  
  [serverInterface postRequest:nil url:@"http://foo" key:@"key_foo" callback:NULL];
  [self waitForExpectationsWithTimeout:5.0 handler:nil];
}

//==================================================================================
//TEST 07
// This test checks to make sure that POST retries are not attempted when they have a retry
// count == 0, and retries aren't needed. Based on Test #4 above

- (void)testPostRequestAsyncRetriesWhenInappropriateResponse {
  
  BNCServerInterface *serverInterface = [[BNCServerInterface alloc] init];
  serverInterface.preferenceHelper = [[BNCPreferenceHelper alloc] init];
  serverInterface.preferenceHelper.retryCount = 3;
  
  XCTestExpectation* successExpectation = [self expectationWithDescription:@"success"];
  
  __block NSUInteger connectionAttempts = 0;
  
  [OHHTTPStubs stubRequestsPassingTest:^BOOL(NSURLRequest *request) {
    BOOL foundBranchKey = [request.URL.query rangeOfString:@"branch_key=key_foo"].location != NSNotFound;
    XCTAssertEqual(foundBranchKey, TRUE);
    return foundBranchKey;
    
  } withStubResponse:^OHHTTPStubsResponse*(NSURLRequest *request) {
    // Return actual data on first attempt
    NSDictionary* dummyJSONResponse = @{@"key": @"value"};
    connectionAttempts++;
    XCTAssertEqual(connectionAttempts, 1);
    [successExpectation fulfill];
    
    return [OHHTTPStubsResponse responseWithJSONObject:dummyJSONResponse statusCode:200 headers:nil];
    
  }];
  
  [serverInterface postRequest:nil url:@"http://foo" key:@"key_foo" callback:NULL];
  [self waitForExpectationsWithTimeout:1.0 handler:nil];
  
}

//==================================================================================
//TEST 08
// This test checks to make sure that GET retries are not attempted when they have a retry
// count == 0, and retries aren't needed. Based on Test #4 above

- (void)testPostRequestAsyncRetriesWhenInappropriateRetryCount {
  BNCServerInterface *serverInterface = [[BNCServerInterface alloc] init];
  serverInterface.preferenceHelper = [[BNCPreferenceHelper alloc] init];
  serverInterface.preferenceHelper.retryCount = 0;
  
  XCTestExpectation* successExpectation = [self expectationWithDescription:@"success"];
  
  __block NSUInteger connectionAttempts = 0;
  
  [OHHTTPStubs stubRequestsPassingTest:^BOOL(NSURLRequest *request) {
    BOOL foundBranchKey = [request.URL.query rangeOfString:@"branch_key=key_foo"].location != NSNotFound;
    XCTAssertEqual(foundBranchKey, TRUE);
    return foundBranchKey;
    
  } withStubResponse:^OHHTTPStubsResponse*(NSURLRequest *request) {
    // Return actual data on first attempt
    NSDictionary* dummyJSONResponse = @{@"key": @"value"};
    connectionAttempts++;
    XCTAssertEqual(connectionAttempts, 1);
    [successExpectation fulfill];
    
    return [OHHTTPStubsResponse responseWithJSONObject:dummyJSONResponse statusCode:200 headers:nil];
    
  }];
  
  [serverInterface getRequest:nil url:@"http://foo" key:@"key_foo" callback:NULL];
  [self waitForExpectationsWithTimeout:1.0 handler:nil];
  
}

@end
