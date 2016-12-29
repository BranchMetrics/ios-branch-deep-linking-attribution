//
//  BNCSystemObserver.m
//  Branch-SDK
//
//  Created by Alex Austin on 6/5/14.
//  Copyright (c) 2014 Branch Metrics. All rights reserved.
//

#import <UIKit/UIKit.h>
#include <sys/utsname.h>
#import "BNCPreferenceHelper.h"
#import "BNCSystemObserver.h"
#import <UIKit/UIDevice.h>
#import <UIKit/UIScreen.h>
#import <SystemConfiguration/SystemConfiguration.h>

@implementation BNCSystemObserver

+ (NSString *)getUniqueHardwareId:(BOOL *)isReal isDebug:(BOOL)debug andType:(NSString **)type {
    NSString *uid = nil;
    *isReal = YES;

    Class ASIdentifierManagerClass = NSClassFromString(@"ASIdentifierManager");
    if (ASIdentifierManagerClass && !debug) {
        SEL sharedManagerSelector = NSSelectorFromString(@"sharedManager");
        id sharedManager = ((id (*)(id, SEL))[ASIdentifierManagerClass methodForSelector:sharedManagerSelector])(ASIdentifierManagerClass, sharedManagerSelector);
        SEL advertisingIdentifierSelector = NSSelectorFromString(@"advertisingIdentifier");
        NSUUID *uuid = ((NSUUID* (*)(id, SEL))[sharedManager methodForSelector:advertisingIdentifierSelector])(sharedManager, advertisingIdentifierSelector);
        uid = [uuid UUIDString];
        // limit ad tracking is enabled. iOS 10+
        if ([uid isEqualToString:@"00000000-0000-0000-0000-000000000000"]) {
            uid = nil;
        }
        *type = @"idfa";
    }

    if (!uid && NSClassFromString(@"UIDevice") && !debug) {
        uid = [[UIDevice currentDevice].identifierForVendor UUIDString];
        *type = @"vendor_id";
    }

    if (!uid) {
        uid = [[NSUUID UUID] UUIDString];
        *type = @"random";
        *isReal = NO;
    }

    return uid;
}

+ (NSString *)getVendorId {
    NSString *vendorId = nil;
    
    if (NSClassFromString(@"UIDevice")) {
        vendorId = [[UIDevice currentDevice].identifierForVendor UUIDString];
    }
    
    return vendorId;
}

+ (BOOL)adTrackingSafe {
    Class ASIdentifierManagerClass = NSClassFromString(@"ASIdentifierManager");
    if (ASIdentifierManagerClass) {
        SEL sharedManagerSelector = NSSelectorFromString(@"sharedManager");
        id sharedManager = ((id (*)(id, SEL))[ASIdentifierManagerClass methodForSelector:sharedManagerSelector])(ASIdentifierManagerClass, sharedManagerSelector);
        SEL advertisingEnabledSelector = NSSelectorFromString(@"isAdvertisingTrackingEnabled");
        BOOL enabled = ((BOOL (*)(id, SEL))[sharedManager methodForSelector:advertisingEnabledSelector])(sharedManager, advertisingEnabledSelector);
        return enabled;
    }
    return YES;
}

+ (NSString *)getDefaultUriScheme {
    NSArray *urlTypes = [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleURLTypes"];

    for (NSDictionary *urlType in urlTypes) {
        NSArray *urlSchemes = [urlType objectForKey:@"CFBundleURLSchemes"];
        for (NSString *uriScheme in urlSchemes) {
            BOOL isFBScheme = [uriScheme hasPrefix:@"fb"];
            BOOL isDBScheme = [uriScheme hasPrefix:@"db"];
            BOOL isPinScheme = [uriScheme hasPrefix:@"pin"];
            
            // Don't use the schemes set aside for other integrations.
            if (!isFBScheme && !isDBScheme && !isPinScheme) {
                return uriScheme;
            }
        }
    }

    return nil;
}

+ (NSString *)getAppVersion {
    return [[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleShortVersionString"];
}

+ (NSString *)getBundleID {
    return [[NSBundle mainBundle] bundleIdentifier];
}

+ (NSString *)getTeamIdentifier {
    NSString *teamWithDot = [[NSBundle mainBundle] objectForInfoDictionaryKey:@"AppIdentifierPrefix"];
    if (teamWithDot.length) {
        return [teamWithDot substringToIndex:([teamWithDot length] - 1)];
    }
    return nil;
}

+ (NSString *)getBrand {
    return @"Apple";
}

+ (NSString *)getModel {
    struct utsname systemInfo;
    uname(&systemInfo);

    return [NSString stringWithCString:systemInfo.machine encoding:NSUTF8StringEncoding];
}

+ (BOOL)isSimulator {
    UIDevice *currentDevice = [UIDevice currentDevice];
    NSString *device;
    if ([BNCSystemObserver getOSVersion].integerValue >= 9) {
        device = currentDevice.name;
    }
    else {
        device = currentDevice.model;
    }
    return [device rangeOfString:@"Simulator"].location != NSNotFound;
}

typedef NS_ENUM(NSInteger, BNCUpdateStatus) {
    BNCUpdateStatusInstall      = 0,    //  App was recently installed.
    BNCUpdateStatusNonUpdate    = 1,    //  App was neither newly installed nor updated.
    BNCUpdateStatusUpdate       = 2,    //  App was recently updated.
};

+ (NSNumber*) getUpdateState_10_2_2 {

    NSString *storedAppVersion = [BNCPreferenceHelper preferenceHelper].appVersion;
    NSString *currentAppVersion = [BNCSystemObserver getAppVersion];

    if (storedAppVersion) {
        if ([storedAppVersion isEqualToString:currentAppVersion])
            return @(BNCUpdateStatusNonUpdate);
        else
            return @(BNCUpdateStatusUpdate);
    }

    //  This is the first Branch install.  Check file dates for app install status:

    //  Get the install date:

    NSError *error = nil;
    NSFileManager *manager = [NSFileManager defaultManager];
    NSURL *libraryURL =
        [[manager URLsForDirectory:NSLibraryDirectory inDomains:NSUserDomainMask] firstObject];
    NSDictionary *attributes = [manager attributesOfItemAtPath:libraryURL.path error:&error];
    NSDate *installDate = [attributes fileCreationDate];

    //  Get the build date:

    NSString *bundleRoot = [[NSBundle mainBundle] bundlePath];
    NSString *filename = [bundleRoot stringByAppendingPathComponent:@"_CodeSignature"];
    attributes = [manager attributesOfItemAtPath:filename error:&error];
    NSDate *buildDate = [attributes fileModificationDate];

    if ([buildDate compare:installDate] > 0) {
        return @(BNCUpdateStatusUpdate);
    }

    if ([installDate timeIntervalSinceNow] > (-60.0 * 60.0 * 24.0)) {
        return @(BNCUpdateStatusInstall);
    }

    return @(BNCUpdateStatusNonUpdate);
}


+ (NSNumber *)getUpdateState {

    NSString *storedAppVersion = [BNCPreferenceHelper preferenceHelper].appVersion;
    NSString *currentAppVersion = [BNCSystemObserver getAppVersion];
    NSFileManager *manager = [NSFileManager defaultManager];

    // for creation date
    NSURL *documentsDirRoot = [[manager URLsForDirectory:NSDocumentDirectory inDomains:NSUserDomainMask] lastObject];
    NSDictionary *documentsDirAttributes = [manager attributesOfItemAtPath:documentsDirRoot.path error:nil];
    NSDate *creationDate = [documentsDirAttributes fileCreationDate];

    // for modification date
    NSError *error = nil;
    NSString *bundleRoot = [[NSBundle mainBundle] bundlePath];
    NSDictionary *bundleAttributes = [manager attributesOfItemAtPath:bundleRoot error:&error];
    NSDate *modificationDate = [bundleAttributes fileModificationDate];

    if (creationDate == nil || [creationDate timeIntervalSince1970] <= 0.0 ||
        modificationDate == nil || [modificationDate timeIntervalSince1970] <= 0.0)
        return [self getUpdateState_10_2_2];

    // No stored version
    if (!storedAppVersion) {
        // Modification and Creation date are more than 24 hours' worth of seconds different indicates
        // an update. This would be the case that they were installing a new version of the app that was
        // adding Branch for the first time, where we don't already have an NSUserDefaults value.
        if (ABS([modificationDate timeIntervalSinceDate:creationDate]) > 86400) {
            return @(BNCUpdateStatusUpdate);
        }

        // If we don't have one of the previous dates, or they're less than 60 apart,
        // we understand this to be an install.
        return @(BNCUpdateStatusInstall);
    }
    // Have a stored version, but it isn't the same as the current value indicates an update
    else if (![storedAppVersion isEqualToString:currentAppVersion]) {
        return @(BNCUpdateStatusUpdate);
    }

    // Otherwise, we have a stored version, and it is equal.
    // Not an update, not an install.
    return @(BNCUpdateStatusNonUpdate);
}

+ (void)setUpdateState {
    NSString *currentAppVersion = [BNCSystemObserver getAppVersion];
    [BNCPreferenceHelper preferenceHelper].appVersion = currentAppVersion;
}

+ (NSString *)getOS {
    return @"iOS";
}

+ (NSString *)getOSVersion {
    UIDevice *device = [UIDevice currentDevice];
    return [device systemVersion];
}

+ (NSNumber *)getScreenWidth {
    UIScreen *mainScreen = [UIScreen mainScreen];
    float scaleFactor = mainScreen.scale;
    CGFloat width = mainScreen.bounds.size.width * scaleFactor;
    return [NSNumber numberWithInteger:(NSInteger)width];
}

+ (NSNumber *)getScreenHeight {
    UIScreen *mainScreen = [UIScreen mainScreen];
    float scaleFactor = mainScreen.scale;
    CGFloat height = mainScreen.bounds.size.height * scaleFactor;
    return [NSNumber numberWithInteger:(NSInteger)height];
}

@end
