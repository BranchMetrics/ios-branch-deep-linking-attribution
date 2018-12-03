//
//  Branch_setBranchKeyTests.m
//  Branch-SDK-Unhosted-Tests
//
//  Created by Ernest Cho on 12/3/18.
//  Copyright © 2018 Branch, Inc. All rights reserved.
//

#import <XCTest/XCTest.h>
#import "Branch.h"

/**
 Tests pre-init methods.  These must run unhosted in order to avoid initialization that the test app does.
 */
@interface Branch_setBranchKeyTests : XCTestCase

@end

@implementation Branch_setBranchKeyTests

- (void)setUp {

}

- (void)tearDown {

}

- (void)testSetBranchKey_validKey {
    XCTAssertNoThrow([Branch setBranchKey:@"key_live_foo"]);
}

- (void)testSetBranchKey_nilKey {
    XCTAssertNoThrow([Branch setBranchKey:nil]);
}

- (void)testSetBranchKey_invalidKey {
    XCTAssertNoThrow([Branch setBranchKey:@"invalid_key"]);
}

@end
