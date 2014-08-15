//
//  SystemObserver.h
//  Branch-SDK
//
//  Created by Alex Austin on 6/5/14.
//  Copyright (c) 2014 Branch Metrics. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface SystemObserver : NSObject

+ (NSString *)getUniqueHardwareId;
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

@end
