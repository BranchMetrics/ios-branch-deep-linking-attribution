//
//  BNCAppGroupsData.m
//  Branch
//
//  Created by Ernest Cho on 9/27/20.
//  Copyright © 2020 Branch, Inc. All rights reserved.
//

#import "BNCAppGroupsData.h"

#import "BNCLog.h"
#import "BNCDeviceInfo.h"
#import "BNCApplication.h"
#import "BNCPreferenceHelper.h"

@interface BNCAppGroupsData()
@property (nonatomic, strong, readwrite) NSUserDefaults *groupDefaults;
@end

@implementation BNCAppGroupsData

+ (instancetype)shared {
    static BNCAppGroupsData *appGroupsData;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        appGroupsData = [BNCAppGroupsData new];
    });
    return appGroupsData;
}

// lazy load the App Group NSUserDefaults
- (BOOL)appGroupsAvailable {
    if (!self.groupDefaults && self.appGroup) {
        self.groupDefaults = [[NSUserDefaults alloc] initWithSuiteName:self.appGroup];
    }
    
    if (self.groupDefaults) {
        return YES;
    } else {
        return NO;
    }
}

- (void)saveObject:(NSObject *)obj forKey:(NSString *)key {
    if ([self appGroupsAvailable] && obj) {
        [self.groupDefaults setObject:obj forKey:key];
    }
}

- (NSString *)getStringForKey:(NSString *)key {
    if ([self appGroupsAvailable]) {
        return [self.groupDefaults stringForKey:key];
    }
    return nil;
}

- (NSDate *)getDateForKey:(NSString *)key {
    if ([self appGroupsAvailable]) {
        id date = [self.groupDefaults objectForKey:key];
        if ([date isKindOfClass:NSDate.class]) {
            return (NSDate *)date;
        } else {
            return nil;
        }
    }
    return nil;
}

- (void)saveAppClipData {
    BNCDeviceInfo *deviceInfo = [BNCDeviceInfo getInstance];
    if ([deviceInfo isAppClip]) {
        
        BNCApplication *application = [BNCApplication currentApplication];
        
        // bundle id - sanity check that data isn't coming cross app
        // this should never happen as we only save from an App Clip
        NSString *bundleId = application.bundleID;
        NSDate *installDate = application.firstInstallDate;
        
        [self saveObject:bundleId forKey:@"BranchAppClipBundleId"];
        [self saveObject:installDate forKey:@"BranchAppClipFirstInstallDate"];
        
        BNCPreferenceHelper *preferenceHelper = [BNCPreferenceHelper sharedInstance];
        
        NSString *url = preferenceHelper.referringURL;
        NSString *token = preferenceHelper.randomizedDeviceToken;
        NSString *bundleToken = preferenceHelper.randomizedBundleToken;
        
        [self saveObject:url forKey:@"BranchAppClipURL"];
        [self saveObject:token forKey:@"BranchAppClipToken"];
        [self saveObject:bundleToken forKey:@"BranchAppClipBundleToken"];
    }
}

- (BOOL)loadAppClipData {
    BNCDeviceInfo *deviceInfo = [BNCDeviceInfo getInstance];
    if (![deviceInfo isAppClip]) {
        
        self.bundleID = [self getStringForKey:@"BranchAppClipBundleId"];
        self.installDate = [self getDateForKey:@"BranchAppClipFirstInstallDate"];
        self.url = [self getStringForKey:@"BranchAppClipURL"];
        self.branchToken = [self getStringForKey:@"BranchAppClipToken"];
        self.bundleToken = [self getStringForKey:@"BranchAppClipBundleToken"];
        
        if (self.bundleID && self.installDate && self.url && self.branchToken && self.bundleToken) {
            return YES;
        } else {
            return NO;
        }
    }
    return NO;
}

@end
