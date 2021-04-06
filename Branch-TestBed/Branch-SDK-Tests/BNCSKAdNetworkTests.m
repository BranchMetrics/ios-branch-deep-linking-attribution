//
//  BNCSKAdNetworkTests.m
//  Branch-SDK-Tests
//
//  Created by Ernest Cho on 8/13/20.
//  Copyright © 2020 Branch, Inc. All rights reserved.
//

#import <XCTest/XCTest.h>
#import "BNCSKAdNetwork.h"

// Expose private methods for testing
@interface BNCSKAdNetwork()

@property (nonatomic, copy, readwrite) NSDate *installDate;

- (BOOL)shouldAttemptSKAdNetworkCallout;

@end

@interface BNCSKAdNetworkTests : XCTestCase

@property (nonatomic, strong, readwrite) BNCSKAdNetwork *skAdNetwork;

@end

@implementation BNCSKAdNetworkTests

- (void)setUp {
    self.skAdNetwork = [BNCSKAdNetwork new];
    self.skAdNetwork.installDate = [NSDate date];
}

- (void)tearDown {

}

- (void)testDefaultMaxTimeout {
    NSTimeInterval oneDay = 3600.0 * 24.0;
    XCTAssertTrue(self.skAdNetwork.maxTimeSinceInstall == oneDay);
}

- (void)testShouldAttemptSKAdNetworkCallout {
    XCTAssertTrue([self.skAdNetwork shouldAttemptSKAdNetworkCallout]);
}

- (void)testShouldAttemptSKAdNetworkCalloutFalse {
    self.skAdNetwork.maxTimeSinceInstall = 0.0;
    XCTAssertFalse([self.skAdNetwork shouldAttemptSKAdNetworkCallout]);
}

@end
