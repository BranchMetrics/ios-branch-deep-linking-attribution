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
 Meta (FBSDK) anonymous ID, sent as `anon_id`. Read once per launch from +[FBSDKBasicUtility anonymousID]
 and cached in memory. Returns nil if the Meta SDK is not present or the value does not start with "XZ".
 */
- (NSString *)fbSdkAnonId;
@property (nonatomic, copy, readwrite) NSString *advertiserId;
@property (nonatomic, copy, readwrite) NSString *vendorId;
@property (nonatomic, copy, readwrite) NSString *optedInStatus;
@property (nonatomic, assign, readwrite) BOOL isFirstOptIn;
- (NSString *)localIPAddress;
- (NSString *)connectionType;
- (NSString *)timezone; //!< The current IANA time zone name (Asia/Seoul, etc).

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
