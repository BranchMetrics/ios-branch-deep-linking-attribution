/**
 @file          NSErrorBranchCategoryTests.m
 @package       Branch-SDK
 @brief         Branch error tests.

 @author        Edward Smith
 @date          August 2017
 @copyright     Copyright © 2017 Branch. All rights reserved.
*/

#import <XCTest/XCTest.h>
#import "NSError+Branch.h"

@interface NSErrorBranchTests : XCTestCase
@end

@implementation NSErrorBranchTests

- (void)testErrorDomain {
    XCTAssertTrue([@"io.branch.sdk.error" isEqualToString:[NSError bncErrorDomain]]);
}

- (void)testError {
    NSError *error = [NSError branchErrorWithCode:BNCInitError];
    XCTAssert(error.domain == [NSError bncErrorDomain]);
    XCTAssert(error.code == BNCInitError);
    XCTAssert([error.localizedDescription isEqualToString:
        @"The Branch user session has not been initialized."]
    );
}

- (void)testErrorWithUnderlyingError {
    NSError *underlyingError = [NSError errorWithDomain:NSCocoaErrorDomain code:NSFileNoSuchFileError userInfo:nil];
    NSError *error = [NSError branchErrorWithCode:BNCServerProblemError error:underlyingError];

    XCTAssert(error.domain == [NSError bncErrorDomain]);
    XCTAssert(error.code == BNCServerProblemError);
    XCTAssert([error.localizedDescription isEqualToString: @"Trouble reaching the Branch servers, please try again shortly."]);
    
    XCTAssert(error.userInfo[NSUnderlyingErrorKey] == underlyingError);
    XCTAssert([error.localizedFailureReason isEqualToString:@"The file doesn’t exist."]);
}

- (void)testErrorWithMessage {
    NSString *message = [NSString stringWithFormat:@"Network operation of class '%@' does not conform to the BNCNetworkOperationProtocol.", NSStringFromClass([self class])];
    NSError *error = [NSError branchErrorWithCode:BNCNetworkServiceInterfaceError localizedMessage:message];

    XCTAssert(error.domain == [NSError bncErrorDomain]);
    XCTAssert(error.code == BNCNetworkServiceInterfaceError);
    XCTAssert([error.localizedDescription isEqualToString: @"The underlying network service does not conform to the BNCNetworkOperationProtocol."]);
    XCTAssert([error.localizedFailureReason isEqualToString: @"Network operation of class 'NSErrorBranchTests' does not conform to the BNCNetworkOperationProtocol."]);
}

#pragma mark - BNCErrorIsRetryableKey

- (void)testRetryableClassification_transientCodesAreRetryable {
    XCTAssertTrue([NSError branchErrorIsRetryableForCode:BNCServerProblemError]);
}

// BNCNetworkServiceInterfaceError means the host app's own BNCNetworkServiceProtocol conformer
// is broken (nil/non-conforming operation, or missing startDate/timeoutDate/request) — retrying
// can't fix that, and verifyNetworkOperation: never reaches the SDK's own retry path anyway.
- (void)testRetryableClassification_configAndAuthCodesAreNotRetryable {
    XCTAssertFalse([NSError branchErrorIsRetryableForCode:BNCBadRequestError]);
    XCTAssertFalse([NSError branchErrorIsRetryableForCode:BNCInitError]);
    XCTAssertFalse([NSError branchErrorIsRetryableForCode:BNCAttributionLevelNoneError]);
    XCTAssertFalse([NSError branchErrorIsRetryableForCode:BNCDNSAdBlockerError]);
    XCTAssertFalse([NSError branchErrorIsRetryableForCode:BNCVPNAdBlockerError]);
    XCTAssertFalse([NSError branchErrorIsRetryableForCode:BNCNetworkServiceInterfaceError]);
}

- (void)testRetryableKeyPresentAndTrueForTransientError {
    NSError *error = [NSError branchErrorWithCode:BNCServerProblemError];
    XCTAssertNotNil(error.userInfo[BNCErrorIsRetryableKey]);
    XCTAssertTrue([error.userInfo[BNCErrorIsRetryableKey] boolValue]);
}

- (void)testRetryableKeyPresentAndFalseForNonTransientError {
    NSError *error = [NSError branchErrorWithCode:BNCBadRequestError];
    XCTAssertNotNil(error.userInfo[BNCErrorIsRetryableKey]);
    XCTAssertFalse([error.userInfo[BNCErrorIsRetryableKey] boolValue]);
}

- (void)testRetryableKeySetByAllConvenienceInitializers {
    NSError *underlying = [NSError errorWithDomain:NSCocoaErrorDomain code:NSFileNoSuchFileError userInfo:nil];

    NSError *withError = [NSError branchErrorWithCode:BNCServerProblemError error:underlying];
    XCTAssertTrue([withError.userInfo[BNCErrorIsRetryableKey] boolValue]);

    NSError *withMessage = [NSError branchErrorWithCode:BNCBadRequestError localizedMessage:@"bad"];
    XCTAssertFalse([withMessage.userInfo[BNCErrorIsRetryableKey] boolValue]);
}

- (void)testAnnotateNilReturnsNil {
    XCTAssertNil([NSError branchErrorByAnnotatingRetryable:nil]);
}

- (void)testAnnotateTransientNetworkErrorIsRetryable {
    // Genuinely transient raw network errors are surfaced as retryable.
    NSArray<NSNumber *> *transientCodes = @[
        @(NSURLErrorTimedOut),
        @(NSURLErrorCannotConnectToHost),
        @(NSURLErrorNetworkConnectionLost),
        @(NSURLErrorDNSLookupFailed),
        @(NSURLErrorNotConnectedToInternet),
        @(NSURLErrorCannotFindHost),
        @(NSURLErrorResourceUnavailable),
    ];
    for (NSNumber *code in transientCodes) {
        NSError *err = [NSError errorWithDomain:NSURLErrorDomain code:code.integerValue userInfo:nil];
        NSError *annotated = [NSError branchErrorByAnnotatingRetryable:err];
        XCTAssertEqualObjects(annotated.domain, NSURLErrorDomain);
        XCTAssertEqual(annotated.code, code.integerValue);
        XCTAssertTrue([annotated.userInfo[BNCErrorIsRetryableKey] boolValue],
                      @"code %@ should be retryable", code);
    }
}

- (void)testAnnotateNonTransientNetworkErrorIsNotRetryable {
    // Network-level errors that retrying cannot fix are surfaced as non-retryable.
    NSArray<NSNumber *> *nonTransientCodes = @[
        @(NSURLErrorBadURL),          // -1000, also what a DNS sinkhole produces
        @(NSURLErrorCancelled),       // -999
        @(NSURLErrorUnsupportedURL),  // -1002
        @(NSURLErrorSecureConnectionFailed),
    ];
    for (NSNumber *code in nonTransientCodes) {
        NSError *err = [NSError errorWithDomain:NSURLErrorDomain code:code.integerValue userInfo:nil];
        NSError *annotated = [NSError branchErrorByAnnotatingRetryable:err];
        XCTAssertNotNil(annotated.userInfo[BNCErrorIsRetryableKey]);
        XCTAssertFalse([annotated.userInfo[BNCErrorIsRetryableKey] boolValue],
                       @"code %@ should not be retryable", code);
    }
}

- (void)testAnnotateBranchErrorRespectsCodeClassification {
    // A Branch error created without the key still gets classified by its code.
    NSError *raw = [NSError errorWithDomain:[NSError bncErrorDomain] code:BNCBadRequestError userInfo:nil];
    NSError *annotated = [NSError branchErrorByAnnotatingRetryable:raw];
    XCTAssertFalse([annotated.userInfo[BNCErrorIsRetryableKey] boolValue]);

    NSError *rawServer = [NSError errorWithDomain:[NSError bncErrorDomain] code:BNCServerProblemError userInfo:nil];
    NSError *annotatedServer = [NSError branchErrorByAnnotatingRetryable:rawServer];
    XCTAssertTrue([annotatedServer.userInfo[BNCErrorIsRetryableKey] boolValue]);
}

- (void)testAnnotatePreservesExistingClassification {
    // If already classified, the value is not overwritten.
    NSError *error = [NSError errorWithDomain:[NSError bncErrorDomain]
                                         code:BNCServerProblemError
                                     userInfo:@{ BNCErrorIsRetryableKey: @NO }];
    NSError *annotated = [NSError branchErrorByAnnotatingRetryable:error];
    XCTAssertFalse([annotated.userInfo[BNCErrorIsRetryableKey] boolValue]);
}

- (void)testAnnotatePreservesOtherUserInfo {
    NSError *error = [NSError branchErrorWithCode:BNCServerProblemError localizedMessage:@"reason"];
    NSError *annotated = [NSError branchErrorByAnnotatingRetryable:error];
    // Already-classified Branch errors are returned unchanged, keeping localized info intact.
    XCTAssertEqualObjects(annotated.localizedDescription, error.localizedDescription);
    XCTAssertTrue([annotated.userInfo[BNCErrorIsRetryableKey] boolValue]);
}

@end
