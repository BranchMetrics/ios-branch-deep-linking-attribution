//
//  BNCDeviceInfo.m
//  Branch-TestBed
//
//  Created by Sojan P.R. on 3/22/16.
//  Copyright © 2016 Branch Metrics. All rights reserved.
//

#import "BNCDeviceInfo.h"
#import "BNCPreferenceHelper.h"
#import "BNCSystemObserver.h"
#import "BNCAvailability.h"
#import "BNCLog.h"
#import "BNCConfig.h"
#import "BNCNetworkInterface.h"
#import "BNCUserAgentCollector.h"
#import "BNCTelephony.h"
#import "BNCReachability.h"
#import "BNCLocale.h"

#if __has_feature(modules)
@import UIKit;
#else
#import <UIKit/UIKit.h>
#endif

#pragma mark - BNCDeviceInfo

@interface BNCDeviceInfo()

@property (nonatomic, strong, readwrite) BNCLocale *locale;
@property (nonatomic, strong, readwrite) BNCTelephony *telephony;
@property (nonatomic, strong, readwrite) BNCReachability *reachability;

@end

@implementation BNCDeviceInfo

+ (BNCDeviceInfo *)getInstance {
    static BNCDeviceInfo *bnc_deviceInfo = 0;
    static dispatch_once_t onceToken = 0;
    dispatch_once(&onceToken, ^{
        bnc_deviceInfo = [BNCDeviceInfo new];
    });
    return bnc_deviceInfo;
}

- (instancetype)init {
    self = [super init];
    if (self) {
        [self loadDeviceInfo];
    }
    return self;
}

- (void)loadDeviceInfo {
    self.locale = [BNCLocale new];
    self.telephony = [BNCTelephony new];
    self.reachability = [BNCReachability new];

    BNCPreferenceHelper *preferenceHelper = [BNCPreferenceHelper preferenceHelper];
    BOOL isRealHardwareId;
    NSString *hardwareIdType;
    NSString *hardwareId = [BNCSystemObserver getUniqueHardwareId:&isRealHardwareId isDebug:preferenceHelper.isDebug andType:&hardwareIdType];
    if (hardwareId) {
        self.hardwareId = hardwareId;
        self.isRealHardwareId = isRealHardwareId;
        self.hardwareIdType = hardwareIdType;
    }

    self.brandName = [BNCSystemObserver getBrand];
    self.modelName = [BNCSystemObserver getModel];
    self.osName = [BNCSystemObserver getOS];
    self.osVersion = [BNCSystemObserver getOSVersion];
    self.screenWidth = [BNCSystemObserver getScreenWidth];
    self.screenHeight = [BNCSystemObserver getScreenHeight];
    self.isAdTrackingEnabled = [BNCSystemObserver adTrackingSafe];

    self.country = [self.locale country];
    self.language = [self.locale language];
    self.extensionType = self.class.extensionType;
    self.branchSDKVersion = [NSString stringWithFormat:@"ios%@", BNC_SDK_VERSION];
    self.applicationVersion = [NSBundle mainBundle].infoDictionary[@"CFBundleShortVersionString"];
    if (!self.applicationVersion.length) {
        self.applicationVersion = [NSBundle mainBundle].infoDictionary[@"CFBundleVersionKey"];
    }
    self.screenScale = [UIScreen mainScreen].scale;
    self.adId = [BNCSystemObserver getAdId];
}

+ (NSString *) extensionType {
    NSString *result = @"FULL_APP";
    NSString *extensionType = [NSBundle mainBundle].infoDictionary[@"NSExtension"][@"NSExtensionPointIdentifier"];
    if ([extensionType isEqualToString:@"com.apple.identitylookup.message-filter"]) {
        result = @"IMESSAGE_APP";
    }
    return result;
}

- (BOOL)unidentifiedDevice {
    return ([BNCSystemObserver getVendorId] == nil && self.adId == nil);
}

+ (NSString *)userAgentString {
    // Cached WebView user agent
    return [BNCUserAgentCollector instance].userAgent;
}

+ (NSString *)vendorId {
    return [BNCSystemObserver getVendorId];
}

+ (NSString *)localIPAddress {
    return [BNCNetworkInterface localIPAddress];
}

- (NSDictionary *)v2dictionary {
    NSMutableDictionary *dictionary = [NSMutableDictionary new];

    // TODO: Which can be nil?
    dictionary[@"os"] = self.osName;
    dictionary[@"os_version"] = self.osVersion;
    dictionary[@"environment"] = self.extensionType;
    dictionary[@"idfv"] = [BNCSystemObserver getVendorId];

    if ([BNCPreferenceHelper preferenceHelper].isDebug) {
        dictionary[@"unidentified_device"] = @(YES);
    } else {
        dictionary[@"idfa"] = self.adId;
    }
    
    dictionary[@"country"] = self.country;
    dictionary[@"language"] = self.language;
    dictionary[@"brand"] = self.brandName;
    dictionary[@"app_version"] = self.applicationVersion;
    dictionary[@"model"] = self.modelName;
    dictionary[@"screen_dpi"] = @(self.screenScale);
    dictionary[@"screen_height"] = self.screenHeight;
    dictionary[@"screen_width"] = self.screenWidth;
    
    // omit if false
    if ([self unidentifiedDevice]) {
        dictionary[@"unidentified_device"] = @(YES);
    }
    
    dictionary[@"local_ip"] = [BNCDeviceInfo localIPAddress];
    dictionary[@"user_agent"] = [BNCDeviceInfo userAgentString];

    // omit if false
    if (!self.isAdTrackingEnabled) {
        dictionary[@"limit_ad_tracking"] = @(YES);
    }
        
    NSString *s = nil;
    BNCPreferenceHelper *preferences = [BNCPreferenceHelper preferenceHelper];

    s = preferences.userIdentity;
    if (s.length) dictionary[@"developer_identity"] = s;

    s = preferences.deviceFingerprintID;
    if (s.length) dictionary[@"device_fingerprint_id"] = s;

    // omit if false
    if (preferences.limitFacebookTracking) {
        dictionary[@"limit_facebook_tracking"] = @(YES);
    }
    
    dictionary[@"sdk"] = @"ios";
    dictionary[@"sdk_version"] = BNC_SDK_VERSION;

    return dictionary;
}

@end
