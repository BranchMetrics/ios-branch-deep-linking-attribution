//
//  BNCNetworkInterface.m
//  Branch
//
//  Created by Ernest Cho on 11/19/19.
//  Copyright © 2019 Branch, Inc. All rights reserved.
//

#import "BNCNetworkInterface.h"
#import "BranchLogger.h"

#import <net/if.h>
#import <ifaddrs.h>
#import <arpa/inet.h>
#import <netinet/in.h>

typedef NS_ENUM(NSInteger, BNCNetworkAddressType) {
    BNCNetworkAddressTypeUnknown = 0,
    BNCNetworkAddressTypeIPv4,
    BNCNetworkAddressTypeIPv6
};

@interface BNCNetworkInterface()

@property (nonatomic, copy, readwrite) NSString *interfaceName;
@property (nonatomic, assign, readwrite) BNCNetworkAddressType addressType;
@property (nonatomic, copy, readwrite) NSString *address;

+ (NSArray<BNCNetworkInterface *> *)currentInterfaces;

@end

@implementation BNCNetworkInterface

- (NSString*) description {
    return [NSString stringWithFormat:@"<%@ %p %@ %@>",
        NSStringFromClass(self.class),
        self,
        self.interfaceName,
        self.address
    ];
}

// Reads network interface information to the device IP address
+ (NSArray<BNCNetworkInterface *> *)currentInterfaces {

    struct ifaddrs *interfaces = NULL;
    NSMutableArray *currentInterfaces = [NSMutableArray arrayWithCapacity:8];

    // Retrieve the current interfaces - returns 0 on success
    if (getifaddrs(&interfaces) != 0) {
        int e = errno;
        [[BranchLogger shared] logWarning:[NSString stringWithFormat:@"Failed to read IP Address: (%d): %s", e, strerror(e)] error:nil];
        
        goto exit;
    }

    // Loop through linked list of interfaces --
    struct ifaddrs *interface = NULL;
    for (interface=interfaces; interface; interface=interface->ifa_next) {
                
        // Check the state: IFF_RUNNING, IFF_UP, IFF_LOOPBACK, etc.
        if ((interface->ifa_flags & IFF_UP) && (interface->ifa_flags & IFF_RUNNING) && !(interface->ifa_flags & IFF_LOOPBACK)) {
        } else {
            continue;
        }

        const struct sockaddr_in *addr = (const struct sockaddr_in*)interface->ifa_addr;
        if (!addr) continue;

        BNCNetworkAddressType type = BNCNetworkAddressTypeUnknown;
        char addrBuf[MAX(INET_ADDRSTRLEN, INET6_ADDRSTRLEN)];

        if (addr->sin_family == AF_INET) {
            if (inet_ntop(AF_INET, &addr->sin_addr, addrBuf, INET_ADDRSTRLEN)) {
                type = BNCNetworkAddressTypeIPv4;
            }
        } else if (addr->sin_family == AF_INET6) {
            const struct sockaddr_in6 *addr6 = (const struct sockaddr_in6*)interface->ifa_addr;
            if (inet_ntop(AF_INET6, &addr6->sin6_addr, addrBuf, INET6_ADDRSTRLEN)) {
                type = BNCNetworkAddressTypeIPv6;
            }
        } else {
            continue;
        }

        NSString *name = [NSString stringWithUTF8String:interface->ifa_name];
        if (name && type != BNCNetworkAddressTypeUnknown) {
            BNCNetworkInterface *interface = [BNCNetworkInterface new];
            interface.interfaceName = name;
            interface.addressType = type;
            interface.address = [NSString stringWithUTF8String:addrBuf];
            [currentInterfaces addObject:interface];
        }
    }

    // Error handling in C code is one case where goto can improve readability.
    // https://www.kernel.org/doc/html/v4.19/process/coding-style.html
exit:
    if (interfaces) freeifaddrs(interfaces);
    return currentInterfaces;
}

+ (nullable NSString *)localIPAddress {
    NSArray<BNCNetworkInterface *> *interfaces = [BNCNetworkInterface currentInterfaces];
    for (BNCNetworkInterface *interface in interfaces) {
        if (interface.addressType == BNCNetworkAddressTypeIPv4) {
            return interface.address;
        }
    }
    return nil;
}

+ (NSArray<NSString *> *)allIPAddresses {
    NSMutableArray *array = [NSMutableArray new];
    for (BNCNetworkInterface *inf in [BNCNetworkInterface currentInterfaces]) {
        if (inf.description) {
            [array addObject:inf.description];
        }
    }
    return array;
}

@end
