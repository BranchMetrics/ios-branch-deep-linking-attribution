//
//  BNCSystemObserver.h
//  Branch-SDK
//
//  Created by Alex Austin on 6/5/14.
//  Copyright (c) 2014 Branch Metrics. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface BNCSystemObserver : NSObject

+ (NSString *)getUniqueHardwareId:(BOOL *)isReal isDebug:(BOOL)debug andType:(NSString **)type;
+ (NSString *)getVendorId;
+ (NSString *)getDefaultUriScheme;
+ (NSString *)getAppVersion;
+ (NSString *)getBundleID;
+ (NSString *)getTeamIdentifier;
+ (NSString *)getBrand;
+ (NSString *)getModel;
+ (NSString *)getOS;
+ (NSString *)getOSVersion;
+ (NSNumber *)getScreenWidth;
+ (NSNumber *)getScreenHeight;
+ (NSNumber *)getUpdateState;
+ (void)setUpdateState;
+ (BOOL)isSimulator;
+ (BOOL)adTrackingSafe;

@end
