//
//  BNCAppleReceiptTests.m
//  Branch-SDK-Tests
//
//  Created by Ernest Cho on 7/15/19.
//  Copyright © 2019 Branch, Inc. All rights reserved.
//

#import <XCTest/XCTest.h>
#import "BNCAppleReceipt.h"

@interface BNCAppleReceiptTests : XCTestCase

@end

@implementation BNCAppleReceiptTests

- (void)setUp {
    // Put setup code here. This method is called before the invocation of each test method in the class.
}

- (void)tearDown {
    // Put teardown code here. This method is called after the invocation of each test method in the class.
}

- (void)testReceiptIsNil {
    BNCAppleReceipt *receipt = [BNCAppleReceipt new];
    XCTAssertNil([receipt installReceipt]);
    XCTAssertFalse([receipt isTestFlight]);
}

@end
