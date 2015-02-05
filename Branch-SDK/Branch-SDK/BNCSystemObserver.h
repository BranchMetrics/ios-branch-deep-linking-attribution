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
+ (NSString *)getURIScheme;
+ (NSString *)getAppVersion;
+ (NSString *)getCarrier;
+ (NSString *)getBrand;
+ (NSString *)getModel;
+ (NSString *)getOS;
+ (NSString *)getOSVersion;
+ (NSNumber *)getScreenWidth;
+ (NSNumber *)getScreenHeight;
+ (NSNumber *)getUpdateState;
+ (NSString *)getDeviceName;
+ (NSDictionary *)getListOfApps;
+ (BOOL)isSimulator;
+ (BOOL)adTrackingSafe;

@end
