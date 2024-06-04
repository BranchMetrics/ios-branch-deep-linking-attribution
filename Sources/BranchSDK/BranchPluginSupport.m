//
//  BranchPluginSupport.m
//  BranchSDK
//
//  Created by Nipun Singh on 1/6/22.
//  Copyright © 2022 Branch, Inc. All rights reserved.
//

#import "BranchPluginSupport.h"
#import "NSMutableDictionary+Branch.h"
#import "BNCDeviceInfo.h"
#import "BNCPreferenceHelper.h"
#import "Branch.h"
#import "BNCConfig.h"

@implementation BranchPluginSupport

+ (BranchPluginSupport *)instance {
    static BranchPluginSupport *pluginSupport = nil;
    static dispatch_once_t onceToken = 0;
    dispatch_once(&onceToken, ^{
        pluginSupport = [BranchPluginSupport new];
    });
    return pluginSupport;
}

// Provides a subset of BNCDeviceInfo.v2dictionary for Adobe Launch
- (NSDictionary<NSString *, NSString *> *)deviceDescription {
    NSMutableDictionary<NSString *, NSString *> *dictionary = [NSMutableDictionary new];
    BNCDeviceInfo *deviceInfo = [BNCDeviceInfo getInstance];
    @synchronized (deviceInfo) {
        [deviceInfo checkAdvertisingIdentifier];
        [dictionary bnc_safeSetObject:deviceInfo.osName forKey:@"os"];
        [dictionary bnc_safeSetObject:deviceInfo.osVersion forKey:@"os_version"];
        [dictionary bnc_safeSetObject:deviceInfo.environment forKey:@"environment"];
        [dictionary bnc_safeSetObject:deviceInfo.vendorId forKey:@"idfv"];
        [dictionary bnc_safeSetObject:deviceInfo.advertiserId forKey:@"idfa"];
        [dictionary bnc_safeSetObject:deviceInfo.optedInStatus forKey:@"opted_in_status"];
        [dictionary bnc_safeSetObject:[BNCPreferenceHelper sharedInstance].userIdentity forKey:@"developer_identity"];
        [dictionary bnc_safeSetObject:deviceInfo.country forKey:@"country"];
        [dictionary bnc_safeSetObject:deviceInfo.language forKey:@"language"];
        [dictionary bnc_safeSetObject:deviceInfo.localIPAddress forKey:@"local_ip"];
        [dictionary bnc_safeSetObject:deviceInfo.brandName forKey:@"brand"];
        [dictionary bnc_safeSetObject:deviceInfo.applicationVersion forKey:@"app_version"];
        [dictionary bnc_safeSetObject:deviceInfo.modelName forKey:@"model"];
        [dictionary bnc_safeSetObject:deviceInfo.screenScale.stringValue forKey:@"screen_dpi"];
        [dictionary bnc_safeSetObject:deviceInfo.screenHeight.stringValue forKey:@"screen_height"];
        [dictionary bnc_safeSetObject:deviceInfo.screenWidth.stringValue forKey:@"screen_width"];
    }
    
    return dictionary;
}

#pragma mark - Server URL methods

// Overrides base CDN URL
+ (void)setCDNBaseUrl:(NSString *)url {
    [[BNCPreferenceHelper sharedInstance] setPatternListURL:url];
}

@end
