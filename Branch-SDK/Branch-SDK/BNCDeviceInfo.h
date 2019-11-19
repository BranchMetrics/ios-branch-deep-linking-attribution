//
//  BNCDeviceInfo.h
//  Branch-TestBed
//
//  Created by Sojan P.R. on 3/22/16.
//  Copyright © 2016 Branch Metrics. All rights reserved.
//

#if __has_feature(modules)
@import Foundation;
@import CoreGraphics;
#else
#import <Foundation/Foundation.h>
#import <CoreGraphics/CoreGraphics.h>
#endif

@interface BNCDeviceInfo : NSObject

+ (BNCDeviceInfo *)getInstance;

@property (nonatomic, copy, readwrite) NSString *hardwareId;
@property (nonatomic, copy, readwrite) NSString *hardwareIdType;
@property (nonatomic, assign, readwrite) BOOL isRealHardwareId;
@property (nonatomic, copy, readwrite) NSString *brandName;
@property (nonatomic, copy, readwrite) NSString *modelName;
@property (nonatomic, copy, readwrite) NSString *osName;
@property (nonatomic, copy, readwrite) NSString *osVersion;
@property (nonatomic, copy, readwrite) NSNumber *screenWidth;
@property (nonatomic, copy, readwrite) NSNumber *screenHeight;
@property (nonatomic, assign, readwrite) BOOL isAdTrackingEnabled;

@property (nonatomic, copy, readwrite) NSString *extensionType;
@property (nonatomic, copy, readwrite) NSString *branchSDKVersion;
@property (nonatomic, copy, readwrite) NSString *applicationVersion;
@property (nonatomic, assign, readwrite) CGFloat screenScale;
@property (nonatomic, copy, readwrite) NSString *adId;
@property (nonatomic, assign, readwrite) BOOL unidentifiedDevice;

@property (nonatomic, copy, readwrite) NSString *country; //!< The iso2 Country name (us, in,etc).
@property (nonatomic, copy, readwrite) NSString *language; //!< The iso2 language code (en, ml).

@property (nonatomic, strong, readwrite) NSString *pluginName;
@property (nonatomic, strong, readwrite) NSString *pluginVersion;

+ (NSString *)localIPAddress;
+ (NSString *)vendorId;
+ (NSString *)userAgentString;

- (NSDictionary *) v2dictionary;

@end
