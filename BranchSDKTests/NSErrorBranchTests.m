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

@end
