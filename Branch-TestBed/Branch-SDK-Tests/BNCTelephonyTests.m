//
//  BNCTelephonyTests.m
//  Branch-SDK-Tests
//
//  Created by Ernest Cho on 11/14/19.
//  Copyright © 2019 Branch, Inc. All rights reserved.
//

#import <XCTest/XCTest.h>
#import "BNCTelephony.h"

@interface BNCTelephonyTests : XCTestCase

@property (nonatomic, strong, readwrite) BNCTelephony *telephony;

@end

@implementation BNCTelephonyTests

- (void)setUp {
    self.telephony = [BNCTelephony new];
}

- (void)tearDown {

}

- (void)testCarrierInfo_NoSim {
    XCTAssertNil(self.telephony.carrierName);
    XCTAssertNil(self.telephony.mobileNetworkCode);
    XCTAssertNil(self.telephony.mobileCountryCode);
    XCTAssertNil(self.telephony.isoCountryCode);
}

// must be run on a real device with an At&t sim
//- (void)testCarrierInfo_AttSim {
//    XCTAssert([@"AT&T" isEqualToString:self.telephony.carrierName]);
//    XCTAssert([@"us" isEqualToString:self.telephony.isoCountryCode]);
//    XCTAssert([@"310" isEqualToString:self.telephony.mobileCountryCode]);
//    XCTAssert([@"410" isEqualToString:self.telephony.mobileNetworkCode]);
//}

@end
