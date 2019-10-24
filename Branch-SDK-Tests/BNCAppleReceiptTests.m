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
    
}

- (void)tearDown {
    
}

- (void)testReceiptOnSimulator {
    BNCAppleReceipt *receipt = [[BNCAppleReceipt alloc] init];
    XCTAssertNil([receipt installReceipt]);
    XCTAssertFalse([receipt isTestFlight]);
}

@end
