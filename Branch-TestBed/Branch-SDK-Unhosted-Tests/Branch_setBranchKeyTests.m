//
//  Branch_setBranchKeyTests.m
//  Branch-SDK-Unhosted-Tests
//
//  Created by Ernest Cho on 12/3/18.
//  Copyright © 2018 Branch, Inc. All rights reserved.
//

#import <XCTest/XCTest.h>
#import "Branch.h"

// expose private methods used by tests
@interface Branch()
+ (void) resetBranchKey;
@end

// Tests pre-init methods.  These run unhosted in order to avoid initialization that the test app does.
@interface Branch_setBranchKeyTests : XCTestCase

@end

@implementation Branch_setBranchKeyTests

- (void)setUp {
    [Branch resetBranchKey];
}

- (void)tearDown {

}

- (void)testSetBranchKey_validKey {
    NSString *testKey = @"key_live_foo";
    
    // previous implementation would throw exceptions on misconfiguration, this is deprecated behavior.
    XCTAssertNoThrow([Branch setBranchKey:testKey]);
    XCTAssert([[Branch branchKey] isEqualToString:testKey]);
}

- (void)testSetBranchKey_nilKey {
    NSString *testKey = nil;
    
    // previous implementation would throw exceptions on misconfiguration, this is deprecated behavior.
    XCTAssertNoThrow([Branch setBranchKey:testKey]);
    XCTAssert([Branch branchKey] == nil);
}

- (void)testSetBranchKey_invalidKey {
    NSString *testKey = @"invalid_key";
    
    // previous implementation would throw exceptions on misconfiguration, this is deprecated behavior.
    XCTAssertNoThrow([Branch setBranchKey:testKey]);
    XCTAssert([Branch branchKey] == nil);
}

- (void)testSetBranchKeyWithError_validKey {
    NSString *testKey = @"key_live_foo";
    
    NSError *error = nil;
    [Branch setBranchKey:testKey error:&error];
    XCTAssertNil(error);
    
    XCTAssert([[Branch branchKey] isEqualToString:testKey]);
}

- (void)testSetBranchKeyWithError_nilKey {
    NSError *error = nil;
    [Branch setBranchKey:nil error:&error];
    XCTAssertNotNil(error);
    
    XCTAssert([error.localizedFailureReason isEqualToString:@"Invalid Branch key of type '<nil>'."]);
    XCTAssert([Branch branchKey] == nil);
}

- (void)testSetBranchKeyWithError_invalidKey {
    NSError *error = nil;
    [Branch setBranchKey:@"invalid_key" error:&error];
    XCTAssertNotNil(error);
    
    XCTAssert([error.localizedFailureReason isEqualToString:@"Invalid Branch key format. Did you add your Branch key to your Info.plist? Passed key is 'invalid_key'."]);
    XCTAssert([Branch branchKey] == nil);
}

- (void)testSetBranchKeyWithError_validKeyTwice {
    NSString *testKey = @"key_live_foo";
    
    NSError *error = nil;
    [Branch setBranchKey:testKey error:&error];
    XCTAssertNil(error);
    XCTAssert([[Branch branchKey] isEqualToString:testKey]);

    // Cannot change the key after it is set once
    [Branch setBranchKey:@"key_live_bar" error:&error];
    XCTAssertNotNil(error);
    XCTAssert([error.localizedFailureReason isEqualToString:@"Branch key can only be set once."]);
    XCTAssert([[Branch branchKey] isEqualToString:testKey]);
}

@end
