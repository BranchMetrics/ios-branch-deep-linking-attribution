//
//  BNCDeviceInfo.m
//  BranchSDK
//
//  Created by Sojan P.R. on 3/22/16.
//  Copyright © 2016 Branch Metrics. All rights reserved.
//

#import "BNCDeviceInfo.h"
#import "BNCPreferenceHelper.h"
#import "BNCSystemObserver.h"
#import "BNCConfig.h"
#import "BNCNetworkInterface.h"
#import "BNCReachability.h"
#import "BNCDeviceSystem.h"

#if !TARGET_OS_TV
// tvOS does not support webkit
#import "BNCUserAgentCollector.h"
#endif

#if __has_feature(modules)
@import UIKit;
#else
#import <UIKit/UIKit.h>
#endif

#pragma mark - BNCDeviceInfo

@interface BNCDeviceInfo()
@property (nonatomic, copy, readwrite) NSString *randomId;
@property (nonatomic, copy, readwrite) NSString *cachedFbSdkAnonId;
// Name of the Meta SDK class that provides +anonymousID.
@property (nonatomic, copy, readwrite) NSString *fbSdkUtilityClassName;
@end

@implementation BNCDeviceInfo

+ (BNCDeviceInfo *)getInstance {
    static BNCDeviceInfo *bnc_deviceInfo = nil;
    static dispatch_once_t onceToken = 0;
    dispatch_once(&onceToken, ^{
        bnc_deviceInfo = [BNCDeviceInfo new];
    });
    return bnc_deviceInfo;
}

- (instancetype)init {
    self = [super init];
    if (self) {
        self.fbSdkUtilityClassName = @"FBSDKBasicUtility";
        [self loadDeviceInfo];
    }
    return self;
}

- (void)registerPluginName:(NSString *)name version:(NSString *)version {
    @synchronized (self) {
        self.pluginName = name;
        self.pluginVersion = version;
    }
}

// Returns +[FBSDKBasicUtility anonymousID] via reflection, or nil if the Meta SDK is not present.
- (NSString *)readFbSdkAnonIdFromMetaSDK {
    Class cls = NSClassFromString(self.fbSdkUtilityClassName);
    SEL sel = NSSelectorFromString(@"anonymousID");
    if (!cls || ![cls respondsToSelector:sel]) {
        return nil; // Meta SDK not present
    }
    typedef id (*AnonymousIDFn)(id, SEL);
    AnonymousIDFn fn = (AnonymousIDFn)[cls methodForSelector:sel];
    id value = fn ? fn((id)cls, sel) : nil;
    if (![value isKindOfClass:[NSString class]]) {
        return nil;
    }
    return (NSString *)value;
}

// Meta anonymous IDs always start with "XZ".
- (BOOL)isValidFbSdkAnonId:(NSString *)value {
    return [value isKindOfClass:[NSString class]] && value.length > 2 && [value hasPrefix:@"XZ"];
}

- (NSString *)fbSdkAnonId {
    @synchronized (self) {
        if (self.cachedFbSdkAnonId) {
            return self.cachedFbSdkAnonId;
        }
        NSString *value = [self readFbSdkAnonIdFromMetaSDK];
        if (![self isValidFbSdkAnonId:value]) {
            return nil;
        }
        self.cachedFbSdkAnonId = value;
        return value;
    }
}

- (void)loadDeviceInfo {
    BNCDeviceSystem *deviceSystem = [BNCDeviceSystem new];

    // The random id is regenerated per app launch.  This maintains existing behavior.
    self.randomId = [[NSUUID UUID] UUIDString];
    self.vendorId = [[UIDevice currentDevice].identifierForVendor UUIDString];
    [self checkAdvertisingIdentifier];

    self.brandName = [BNCSystemObserver brand];
    self.modelName = [BNCSystemObserver model];
    self.osName = [BNCSystemObserver osName];
    self.osVersion = [BNCSystemObserver osVersion];
    self.osBuildVersion = deviceSystem.systemBuildVersion;

    if (deviceSystem.cpuType) {
        self.cpuType = [deviceSystem.cpuType stringValue];
    }

    self.screenWidth = [BNCSystemObserver screenWidth];
    self.screenHeight = [BNCSystemObserver screenHeight];
    self.screenScale = [BNCSystemObserver screenScale];

    self.locale = [NSLocale currentLocale].localeIdentifier;
    self.country = [[NSLocale currentLocale] countryCode];
    self.language = [[NSLocale currentLocale] languageCode];
    self.environment = [BNCSystemObserver environment];
    self.branchSDKVersion = [NSString stringWithFormat:@"ios%@", BNC_SDK_VERSION];
    self.applicationVersion = [BNCSystemObserver applicationVersion];
}

- (NSString *)localIPAddress {
    return [BNCNetworkInterface localIPAddress];
}

- (NSString *)connectionType {
    return [[BNCReachability shared] reachabilityStatus];
}

- (NSString *)timezone {
    return [NSTimeZone localTimeZone].name;
}

- (NSString *)userAgentString {
    #if !TARGET_OS_TV
    return [BNCUserAgentCollector instance].userAgent;
    #else
    // tvOS has no web browser or webview
    return @"";
    #endif
}

// IDFA should never be cached
- (void)checkAdvertisingIdentifier {
    self.optedInStatus = [BNCSystemObserver attOptedInStatus];
    
    // indicate if this is first time we've seen the user opt in, this reduces work on the server
    if ([self.optedInStatus isEqualToString:@"authorized"] && ![BNCPreferenceHelper sharedInstance].hasOptedInBefore) {
        self.isFirstOptIn = YES;
    } else {
        self.isFirstOptIn = NO;
    }
    
    self.advertiserId = [BNCSystemObserver advertiserIdentifier];
    BOOL ignoreIdfa = [BNCPreferenceHelper sharedInstance].isDebug;

    if (self.advertiserId && !ignoreIdfa) {
        self.hardwareId = self.advertiserId;
        self.hardwareIdType = @"idfa";
        self.isRealHardwareId = YES;

    } else if (self.vendorId) {
        self.hardwareId = self.vendorId;
        self.hardwareIdType = @"vendor_id";
        self.isRealHardwareId = YES;

    } else {
        self.hardwareId = self.randomId;
        self.hardwareIdType = @"random";
        self.isRealHardwareId = NO;
    }
}

@end
