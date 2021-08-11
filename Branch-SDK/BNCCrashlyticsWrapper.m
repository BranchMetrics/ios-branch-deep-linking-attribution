//
//  BNCCrashlyticsReportingHelper.m
//  Branch.framework
//
//  Created by Jimmy Dee on 7/18/17.
//  Copyright © 2017 Branch Metrics. All rights reserved.
//

#import "BNCCrashlyticsWrapper.h"

@interface BNCCrashlyticsWrapper()
@property (nonatomic, nullable) id firCrashlytics;
@end

@implementation BNCCrashlyticsWrapper

+ (id)crashlytics
{
    // This just exists so that sharedInstance is not an unknown selector.
    return nil;
}

+ (instancetype)wrapper
{
    return [[self alloc] init];
}

- (instancetype)init
{
    self = [super init];
    if (self) {
        // Dynamically obtain Crashlytics.sharedInstance if the Crashlytics SDK is linked.
        Class FIRCrashlytics = NSClassFromString(@"FIRCrashlytics");
        if ([FIRCrashlytics respondsToSelector:@selector(crashlytics)]) {
            id crashlyticsInstance = [FIRCrashlytics crashlytics];
            if ([crashlyticsInstance isKindOfClass:FIRCrashlytics] &&
                [crashlyticsInstance respondsToSelector:@selector(setCustomValue:forKey:)])
                _firCrashlytics = crashlyticsInstance;
        }
    }
    return self;
}

- (void)setCustomValue:(id)value forKey:(NSString *)key
{
    if (!self.firCrashlytics) return;
    [self.firCrashlytics setCustomValue:value forKey:key];
}

@end
