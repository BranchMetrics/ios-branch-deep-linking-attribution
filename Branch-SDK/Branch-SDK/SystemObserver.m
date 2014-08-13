//
//  SystemObserver.m
//  Branch-SDK
//
//  Created by Alex Austin on 6/5/14.
//  Copyright (c) 2014 Branch Metrics. All rights reserved.
//

#include <sys/utsname.h>
#import "PreferenceHelper.h"
#import "SystemObserver.h"
#import <UIKit/UIDevice.h>
#import <UIKit/UIScreen.h>
#import <CoreTelephony/CTCarrier.h>
#import <CoreTelephony/CTTelephonyNetworkInfo.h>
#import <SystemConfiguration/SystemConfiguration.h>

//#define SYSTEM_VERSION_GREATER_THAN_OR_EQUAL_TO(v)  ([[[UIDevice currentDevice] systemVersion] compare:v options:NSNumericSearch] != NSOrderedAscending)

@implementation SystemObserver

+ (NSString *)getUniqueHardwareId {
    NSString *uid = nil;
    Class ASIdentifierManagerClass = NSClassFromString(@"ASIdentifierManager");
    if (ASIdentifierManagerClass) {
        SEL sharedManagerSelector = NSSelectorFromString(@"sharedManager");
        id sharedManager = ((id (*)(id, SEL))[ASIdentifierManagerClass methodForSelector:sharedManagerSelector])(ASIdentifierManagerClass, sharedManagerSelector);
        SEL advertisingIdentifierSelector = NSSelectorFromString(@"advertisingIdentifier");
        NSUUID *uuid = ((NSUUID* (*)(id, SEL))[sharedManager methodForSelector:advertisingIdentifierSelector])(sharedManager, advertisingIdentifierSelector);
        uid = [uuid UUIDString];
    }
    
    if (!uid && NSClassFromString(@"UIDevice")) {
        //if (SYSTEM_VERSION_GREATER_THAN_OR_EQUAL_TO(@"6.0")) {
        uid = [[UIDevice currentDevice].identifierForVendor UUIDString];
        //} else {
        //    uid = [[UIDevice currentDevice].uniqueIdentifer UUIDString];
        //}
    }

    return uid;
}

+ (NSString *)getAppVersion {
    return [[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleVersion"];
}

+ (NSString *)getCarrier {
    CTTelephonyNetworkInfo *networkInfo = [[CTTelephonyNetworkInfo alloc] init];
    CTCarrier *carrier = [networkInfo subscriberCellularProvider];
    return carrier.carrierName;
}

+ (NSString *)getBrand {
    return @"Apple";
}

+ (NSString *)getModel {
    struct utsname systemInfo;
    uname(&systemInfo);
    
    return [NSString stringWithCString:systemInfo.machine
                              encoding:NSUTF8StringEncoding];
}

+ (NSNumber *)getUpdateState {
    NSString *bundleRoot = [[NSBundle mainBundle] bundlePath];    NSFileManager *manager = [NSFileManager defaultManager];
    NSDictionary* attrs = [manager attributesOfItemAtPath:bundleRoot error:nil];
    if ((int)([[attrs fileCreationDate] timeIntervalSince1970]/(60*60*24)) == (int)([[attrs fileModificationDate] timeIntervalSince1970]/(60*60*24))) {
        return nil;
    } else {
        return [NSNumber numberWithInt:1];
    }
}

+ (NSString *)getOS {
    return @"iOS";
}

+ (NSString *)getOSVersion {
    UIDevice *device = [UIDevice currentDevice];
    return [device systemVersion];
}

+ (NSNumber *)getScreenWidth {
    CGSize size = [UIScreen mainScreen].bounds.size;
    return [NSNumber numberWithInteger:(NSInteger)size.width];
}

+ (NSNumber *)getScreenHeight {
    CGSize size = [UIScreen mainScreen].bounds.size;
    return [NSNumber numberWithInteger:(NSInteger)size.height];
}

@end
