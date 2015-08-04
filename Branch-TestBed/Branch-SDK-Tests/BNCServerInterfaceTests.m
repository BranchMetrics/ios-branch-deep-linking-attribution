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

typedef void (^UrlConnectionCallback)(NSURLResponse *, NSData *, NSError *);

@interface BNCServerInterfaceTests : XCTestCase

@end

@implementation BNCServerInterfaceTests


#pragma mark - Key tests

- (void)testParamAddForBranchKey {
    BNCServerInterface *serverInterface = [[BNCServerInterface alloc] init];
    id urlConnectionMock = OCMClassMock([NSURLConnection class]);
    
    // Expect the query to contain branch key
    [[urlConnectionMock expect] sendAsynchronousRequest:[OCMArg checkWithBlock:^BOOL(NSURLRequest *request) {
        return [request.URL.query rangeOfString:@"branch_key=key_foo"].location != NSNotFound;
    }] queue:[OCMArg any] completionHandler:[OCMArg any]];
    
    // Make the request
    [serverInterface getRequest:nil url:@"http://foo" key:@"key_foo" callback:NULL];
    
    [urlConnectionMock verify];
}

- (void)testParamAddForAppKey {
    BNCServerInterface *serverInterface = [[BNCServerInterface alloc] init];
    id urlConnectionMock = OCMClassMock([NSURLConnection class]);
    
    // Expect the query to contain app id
    [[urlConnectionMock expect] sendAsynchronousRequest:[OCMArg checkWithBlock:^BOOL(NSURLRequest *request) {
        return [request.URL.query rangeOfString:@"app_id=non_branch_key"].location != NSNotFound;
    }] queue:[OCMArg any] completionHandler:[OCMArg any]];
    
    // Make the request
    [serverInterface getRequest:nil url:@"http://foo" key:@"non_branch_key" callback:NULL];
    
    [urlConnectionMock verify];
}


#pragma mark - Retry tests

- (void)testGetRequestAsyncRetriesWhenAppropriate {
    BNCServerInterface *serverInterface = [[BNCServerInterface alloc] init];
    serverInterface.preferenceHelper = [[BNCPreferenceHelper alloc] init];
    id urlConnectionMock = OCMClassMock([NSURLConnection class]);
    
    // Specify retry count as 3
    serverInterface.preferenceHelper.retryCount = 3;

    // 3 retries means 4 total requests
    [self expectSendAsyncRequestForBranchError:urlConnectionMock times:4];
    
    // Make the request
    XCTestExpectation *getRequestExpectation = [self expectationWithDescription:@"GET Request Expectation"];
    [serverInterface getRequest:nil url:@"http://foo" key:@"key_foo" callback:^(BNCServerResponse *response, NSError *error) {
        XCTAssertNotNil(error);

        [getRequestExpectation fulfill];
    }];
    
    [self waitForExpectationsWithTimeout:5 handler:NULL];
    
    [urlConnectionMock verify];
}

- (void)testGetRequestAsyncRetriesWhenInappropriateResponse {
    BNCServerInterface *serverInterface = [[BNCServerInterface alloc] init];
    serverInterface.preferenceHelper = [[BNCPreferenceHelper alloc] init];
    id urlConnectionMock = OCMClassMock([NSURLConnection class]);

    // Specify retry count as 3
    serverInterface.preferenceHelper.retryCount = 3;

    // Should be no retries, just a single request
    [self expectSendAsyncRequestForSuccessfulRequest:urlConnectionMock];
    
    // Make the request
    XCTestExpectation *getRequestExpectation = [self expectationWithDescription:@"GET Request Expectation"];
    [serverInterface getRequest:nil url:@"http://foo" key:@"key_foo" callback:^(BNCServerResponse *response, NSError *error) {
        XCTAssertNil(error);
        
        [getRequestExpectation fulfill];
    }];
    
    [self waitForExpectationsWithTimeout:1 handler:NULL];
}

- (void)testGetRequestAsyncRetriesWhenInappropriateRetryCount {
    BNCServerInterface *serverInterface = [[BNCServerInterface alloc] init];
    serverInterface.preferenceHelper = [[BNCPreferenceHelper alloc] init];
    id urlConnectionMock = OCMClassMock([NSURLConnection class]);
    
    // Specify retry count as 0
    serverInterface.preferenceHelper.retryCount = 0;
    
    // 0 retries means 1 total requests
    [self expectSendAsyncRequestForBranchError:urlConnectionMock times:1];
    
    // Make the request
    XCTestExpectation *getRequestExpectation = [self expectationWithDescription:@"GET Request Expectation"];
    [serverInterface getRequest:nil url:@"http://foo" key:@"key_foo" callback:^(BNCServerResponse *response, NSError *error) {
        XCTAssertNotNil(error);
        
        [getRequestExpectation fulfill];
    }];
    
    [self waitForExpectationsWithTimeout:1 handler:NULL];
}

- (void)testPostRequestAsyncRetriesWhenAppropriate {
    BNCServerInterface *serverInterface = [[BNCServerInterface alloc] init];
    serverInterface.preferenceHelper = [[BNCPreferenceHelper alloc] init];
    id urlConnectionMock = OCMClassMock([NSURLConnection class]);
    
    // Specify retry count as 3
    serverInterface.preferenceHelper.retryCount = 3;
    
    // 3 retries means 4 total requests
    [self expectSendAsyncRequestForBranchError:urlConnectionMock times:4];
    
    // Make the request
    XCTestExpectation *postRequestExpectation = [self expectationWithDescription:@"POST Request Expectation"];
    [serverInterface postRequest:nil url:@"http://foo" key:@"key_foo" callback:^(BNCServerResponse *response, NSError *error) {
        XCTAssertNotNil(error);
        
        [postRequestExpectation fulfill];
    }];

    [self waitForExpectationsWithTimeout:5 handler:NULL];
}

- (void)testPostRequestAsyncRetriesWhenInappropriateResponse {
    BNCServerInterface *serverInterface = [[BNCServerInterface alloc] init];
    serverInterface.preferenceHelper = [[BNCPreferenceHelper alloc] init];
    id urlConnectionMock = OCMClassMock([NSURLConnection class]);
    
    // Specify retry count as 3
    serverInterface.preferenceHelper.retryCount = 3;
    
    // Should be no retries, just a single request
    [self expectSendAsyncRequestForSuccessfulRequest:urlConnectionMock];
    
    // Make the request
    XCTestExpectation *postRequestExpectation = [self expectationWithDescription:@"POST Request Expectation"];
    [serverInterface postRequest:nil url:@"http://foo" key:@"key_foo" callback:^(BNCServerResponse *response, NSError *error) {
        XCTAssertNil(error);
        
        [postRequestExpectation fulfill];
    }];
    
    [self waitForExpectationsWithTimeout:1 handler:NULL];
}

- (void)testPostRequestAsyncRetriesWhenInappropriateRetryCount {
    BNCServerInterface *serverInterface = [[BNCServerInterface alloc] init];
    serverInterface.preferenceHelper = [[BNCPreferenceHelper alloc] init];
    id urlConnectionMock = OCMClassMock([NSURLConnection class]);
    
    // Specify retry count as 0
    serverInterface.preferenceHelper.retryCount = 0;
    
    // 0 retries means 1 total requests
    [self expectSendAsyncRequestForBranchError:urlConnectionMock times:1];
    
    // Make the request
    XCTestExpectation *postRequestExpectation = [self expectationWithDescription:@"POST Request Expectation"];
    [serverInterface postRequest:nil url:@"http://foo" key:@"key_foo" callback:^(BNCServerResponse *response, NSError *error) {
        XCTAssertNotNil(error);
        
        [postRequestExpectation fulfill];
    }];
    
    [self waitForExpectationsWithTimeout:1 handler:NULL];
}

#pragma mark - Internals
- (void)expectSendAsyncRequestForBranchError:(id)connectionMock times:(NSInteger)times {
    __block UrlConnectionCallback urlConnectionCallback;
    
    id urlConnectionBlock = [OCMArg checkWithBlock:^BOOL(UrlConnectionCallback callback) {
        urlConnectionCallback = callback;
        return YES;
    }];
    
    void (^urlConnectionInvocation)(NSInvocation *) = ^(NSInvocation *invocation) {
        NSHTTPURLResponse *response = [[NSHTTPURLResponse alloc] initWithURL:[[NSURL alloc] init] statusCode:504 HTTPVersion:nil headerFields:nil];
        urlConnectionCallback(response, nil, nil);
    };
    
    for (NSInteger i = 0; i < times; i++) {
        [[[connectionMock expect] andDo:urlConnectionInvocation] sendAsynchronousRequest:[OCMArg any] queue:[OCMArg any] completionHandler:urlConnectionBlock];
    }
    
    [[connectionMock reject] sendAsynchronousRequest:[OCMArg any] queue:[OCMArg any] completionHandler:[OCMArg any]];
}

- (void)expectSendAsyncRequestForSuccessfulRequest:(id)connectionMock {
    __block UrlConnectionCallback urlConnectionCallback;
    
    id urlConnectionBlock = [OCMArg checkWithBlock:^BOOL(UrlConnectionCallback callback) {
        urlConnectionCallback = callback;
        return YES;
    }];
    
    void (^urlConnectionInvocation)(NSInvocation *) = ^(NSInvocation *invocation) {
        NSHTTPURLResponse *response = [[NSHTTPURLResponse alloc] initWithURL:[[NSURL alloc] init] statusCode:200 HTTPVersion:nil headerFields:nil];
        urlConnectionCallback(response, nil, nil);
    };
    
    [[[connectionMock expect] andDo:urlConnectionInvocation] sendAsynchronousRequest:[OCMArg any] queue:[OCMArg any] completionHandler:urlConnectionBlock];
    [[connectionMock reject] sendAsynchronousRequest:[OCMArg any] queue:[OCMArg any] completionHandler:[OCMArg any]];
}

@end
