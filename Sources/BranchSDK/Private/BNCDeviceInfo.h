//
//  BNCDeviceInfo.h
//  BranchSDK
//
//  Class responsible for collating device information.
//
//  Created by Sojan P.R. on 3/22/16.
//  Copyright © 2016 Branch Metrics. All rights reserved.
//

#if __has_feature(modules)
@import Foundation;
#else
#import <Foundation/Foundation.h>
#endif

@interface BNCDeviceInfo : NSObject

+ (BNCDeviceInfo *)getInstance;

- (void)registerPluginName:(NSString *)name version:(NSString *)version;

/*
 Thread safety is the callee's responsibility!
 
 BNCServerInterface.updateDeviceInfoToMutableDictionary, BNCAppGroupsData.saveAppClipData and unit tests use these.
 */

- (void)checkAdvertisingIdentifier;

@property (nonatomic, copy, readwrite) NSString *hardwareId;
@property (nonatomic, copy, readwrite) NSString *hardwareIdType;
@property (nonatomic, assign, readwrite) BOOL isRealHardwareId;

/*
 Meta (FBSDK) anonymous ID, sent as `anon_id`. Branch no longer generates its own anon id.
 Read via reflection of +[FBSDKBasicUtility anonymousID].
 Lookup order: in-memory cache, then BNCPreferenceHelper.fbSdkAnonID (bnc_fb_sdk_anon_id), then the Meta SDK.
 A valid ("XZ"-prefixed) value from the Meta SDK is cached in memory and saved to bnc_fb_sdk_anon_id.
 An empty or invalid value is never cached or saved, and nil is returned.
 Upgrade: the legacy GUID in bnc_anon_id is never read.
 Branch never writes or modifies Meta's own copy of this value.
 */
- (NSString *)fbSdkAnonId;
@property (nonatomic, copy, readwrite) NSString *advertiserId;
@property (nonatomic, copy, readwrite) NSString *vendorId;
@property (nonatomic, copy, readwrite) NSString *optedInStatus;
@property (nonatomic, assign, readwrite) BOOL isFirstOptIn;
- (NSString *)localIPAddress;
- (NSString *)connectionType;

@property (nonatomic, copy, readwrite) NSString *brandName;
@property (nonatomic, copy, readwrite) NSString *modelName;
@property (nonatomic, copy, readwrite) NSString *osName;
@property (nonatomic, copy, readwrite) NSString *osVersion;
@property (nonatomic, copy, readwrite) NSString *osBuildVersion;
@property (nonatomic, copy, readwrite) NSString *environment;
@property (nonatomic, copy, readwrite) NSString *cpuType;
@property (nonatomic, copy, readwrite) NSNumber *screenWidth;
@property (nonatomic, copy, readwrite) NSNumber *screenHeight;
@property (nonatomic, copy, readwrite) NSNumber *screenScale;
@property (nonatomic, copy, readwrite) NSString *locale;
@property (nonatomic, copy, readwrite) NSString *country; //!< The iso2 Country name (us, in,etc).
@property (nonatomic, copy, readwrite) NSString *language; //!< The iso2 language code (en, ml).
- (NSString *)userAgentString;

@property (nonatomic, copy, readwrite) NSString *applicationVersion;
@property (nonatomic, copy, readwrite) NSString *pluginName;
@property (nonatomic, copy, readwrite) NSString *pluginVersion;
@property (nonatomic, copy, readwrite) NSString *branchSDKVersion;

@end
