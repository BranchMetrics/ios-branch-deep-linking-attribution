//
//  BNCServerInterfaceTests.m
//  BranchSDKTests
//

#import <XCTest/XCTest.h>
#import "BNCServerInterface.h"
#import "NSError+Branch.h"

@interface BNCServerInterfaceTests : XCTestCase
@end

@implementation BNCServerInterfaceTests

// `verifyNetworkOperation:` reads state that only `-start` populates, so validating an
// operation before starting it rejects every request. The target is a closed local port:
// a started request fails in NSURLErrorDomain, a rejected one fails with
// BNCNetworkServiceInterfaceError without opening a connection.
- (void)testGenericHTTPRequestStartsTheOperation {
    BNCServerInterface *serverInterface = [[BNCServerInterface alloc] init];

    NSMutableURLRequest *request =
        [NSMutableURLRequest requestWithURL:[NSURL URLWithString:@"http://127.0.0.1:1/probe"]];
    request.HTTPMethod = @"POST";
    request.timeoutInterval = 5.0;

    XCTestExpectation *completed = [self expectationWithDescription:@"callback"];
    __block NSError *callbackError = nil;

    [serverInterface genericHTTPRequest:request
                            retryNumber:0
                               callback:^(BNCServerResponse *response, NSError *error) {
        callbackError = error;
        [completed fulfill];
    }
                           retryHandler:^NSURLRequest *(NSInteger retryNumber) { return nil; }];

    [self waitForExpectationsWithTimeout:30 handler:nil];

    BOOL rejectedBeforeStarting =
        [callbackError.domain isEqualToString:[NSError bncErrorDomain]] &&
        callbackError.code == BNCNetworkServiceInterfaceError;
    XCTAssertFalse(rejectedBeforeStarting,
                   @"Operation was rejected by validation before it started: %@", callbackError);
}

@end
