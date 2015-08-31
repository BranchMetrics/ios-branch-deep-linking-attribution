//
//  BNCSystemObserver.h
//  Branch-SDK
//
//  Created by Alex Austin on 6/5/14.
//  Copyright (c) 2014 Branch Metrics. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface BNCSystemObserver : NSObject

+ (NSString *)getUniqueHardwareId:(BOOL *)isReal andIsDebug:(BOOL)debug;
+ (NSString *)getDefaultUriScheme;
+ (NSString *)getAppVersion;
+ (NSString *)getBundleID;
+ (NSString *)getTeamIdentifier;
+ (NSString *)getCarrier;
+ (NSString *)getBrand;
+ (NSString *)getModel;
+ (NSString *)getOS;
+ (NSString *)getOSVersion;
+ (NSNumber *)getScreenWidth;
+ (NSNumber *)getScreenHeight;
+ (NSNumber *)getUpdateState;
+ (void)setUpdateState;
+ (NSString *)getDeviceName;
+ (BOOL)isSimulator;
+ (BOOL)adTrackingSafe;

@end
