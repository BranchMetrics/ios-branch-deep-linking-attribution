//
//  BNCNetworkInterfaceTests.m
//  Branch-SDK-Tests
//
//  Created by Ernest Cho on 3/10/23.
//  Copyright © 2023 Branch, Inc. All rights reserved.
//

#import <XCTest/XCTest.h>
#import <arpa/inet.h>
#import "BNCNetworkInterface.h"

// Category using inet_pton to validate
@implementation NSString (Test)

- (BOOL)isValidIPAddress {
    const char *utf8 = [self UTF8String];
    int success;

    struct in_addr dst;
    success = inet_pton(AF_INET, utf8, &dst);
    if (success != 1) {
        struct in6_addr dst6;
        success = inet_pton(AF_INET6, utf8, &dst6);
    }

    return success == 1;
}

@end

@interface BNCNetworkInterfaceTests : XCTestCase

@end

@implementation BNCNetworkInterfaceTests

- (void)setUp {
    
}

- (void)tearDown {

}

// verify tooling method works
- (void)testIPValidationCategory {
    XCTAssert(![@"" isValidIPAddress]);
    
    // ipv4
    XCTAssert([@"0.0.0.0" isValidIPAddress]);
    XCTAssert([@"127.0.0.1" isValidIPAddress]);
    XCTAssert([@"10.1.2.3" isValidIPAddress]);
    XCTAssert([@"172.0.0.0" isValidIPAddress]);
    XCTAssert([@"192.0.0.0" isValidIPAddress]);
    XCTAssert([@"255.255.255.255" isValidIPAddress]);
    
    // invalid ipv4
    XCTAssert(![@"-1.0.0.0" isValidIPAddress]);
    XCTAssert(![@"256.0.0.0" isValidIPAddress]);
    
    // ipv6
    XCTAssert([@"2001:0db8:0000:0000:0000:8a2e:0370:7334" isValidIPAddress]);
    XCTAssert([@"2001:db8::8a2e:370:7334" isValidIPAddress]);
    
    // invalid ipv6
    XCTAssert(![@"2001:0db8:0000:0000:0000:8a2e:0370:733g" isValidIPAddress]);
    XCTAssert(![@"2001:0db8:0000:0000:0000:8a2e:0370:7330:1234" isValidIPAddress]);
}

- (void)testLocalIPAddress {
    XCTAssert([[BNCNetworkInterface localIPAddress] isValidIPAddress]);
}

- (void)testAllIPAddresses {
    // All IP addresses is a debug method that returns object descriptions
    for (NSString *address in BNCNetworkInterface.allIPAddresses) {
        XCTAssert([address containsString:@"BNCNetworkInterface"]);
    }
}

@end
