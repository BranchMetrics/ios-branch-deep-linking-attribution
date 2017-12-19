//
//  BNCSystemObserver.m
//  Branch-SDK
//
//  Created by Alex Austin on 6/5/14.
//  Copyright (c) 2014 Branch Metrics. All rights reserved.
//

#import "BNCPreferenceHelper.h"
#import "BNCSystemObserver.h"
#import "BNCLog.h"
#if __has_feature(modules)
@import UIKit;
@import SystemConfiguration;
@import Darwin.POSIX.sys.utsname;
#else
#import <UIKit/UIKit.h>
#import <SystemConfiguration/SystemConfiguration.h>
#import <sys/utsname.h>
#endif

@implementation BNCSystemObserver

+ (NSString *)getUniqueHardwareId:(BOOL *)isReal
                          isDebug:(BOOL)debug
                          andType:(NSString *__autoreleasing*)type {
    NSString *uid = nil;
    *isReal = YES;

    if (!debug) {
        uid = [self getAdId];
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

+ (NSString*) getAdId {
    NSString *uid = nil;

    Class ASIdentifierManagerClass = NSClassFromString(@"ASIdentifierManager");
    if (ASIdentifierManagerClass) {
        SEL sharedManagerSelector = NSSelectorFromString(@"sharedManager");
        id sharedManager =
            ((id (*)(id, SEL))[ASIdentifierManagerClass methodForSelector:sharedManagerSelector])
                (ASIdentifierManagerClass, sharedManagerSelector);
        SEL advertisingIdentifierSelector = NSSelectorFromString(@"advertisingIdentifier");
        NSUUID *uuid =
            ((NSUUID* (*)(id, SEL))[sharedManager methodForSelector:advertisingIdentifierSelector])
                (sharedManager, advertisingIdentifierSelector);
        uid = [uuid UUIDString];
        // limit ad tracking is enabled. iOS 10+
        if ([uid isEqualToString:@"00000000-0000-0000-0000-000000000000"]) {
            uid = nil;
        }
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
            if ([uriScheme hasPrefix:@"fb"]) continue;  // Facebook
            if ([uriScheme hasPrefix:@"db"]) continue;  // DB?
            if ([uriScheme hasPrefix:@"pin"]) continue; // Pinterest
            if ([uriScheme hasPrefix:@"com.googleusercontent.apps"]) continue; // Google

            // Otherwise this must be it!
            return uriScheme;
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
    #if (TARGET_OS_SIMULATOR)
    return YES;
    #else
    return NO;
    #endif
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
    CGFloat scaleFactor = mainScreen.scale;
    CGFloat width = mainScreen.bounds.size.width * scaleFactor;
    return [NSNumber numberWithInteger:(NSInteger)width];
}

+ (NSNumber *)getScreenHeight {
    UIScreen *mainScreen = [UIScreen mainScreen];
    CGFloat scaleFactor = mainScreen.scale;
    CGFloat height = mainScreen.bounds.size.height * scaleFactor;
    return [NSNumber numberWithInteger:(NSInteger)height];
}

#pragma mark - getUpdateState Suite

+ (NSNumber*) getUpdateState {

    NSDate * buildDate = [self appBuildDate];
    NSDate * appInstallDate = [self appInstallDate];
    NSString *storedAppVersion = [BNCPreferenceHelper preferenceHelper].appVersion;
    NSString *currentAppVersion = [self getAppVersion];

    BNCUpdateState result =
        [self updateStateWithBuildDate:buildDate
            appInstallDate:appInstallDate
            storedAppVersion:storedAppVersion
            currentAppVersion:currentAppVersion];

#if 0 // Display an alert for testing.  Only for debugging.
    NSString *message = @"No result.";
    switch (result) {
        case BNCUpdateStateInstall:     message = @"New install.";      break;
        case BNCUpdateStateNonUpdate:   message = @"Non-update.";       break;
        case BNCUpdateStateUpdate:      message = @"App update.";       break;
        default:                        message = @"Invalid value.";    break;
    }
    message =
        [NSString stringWithFormat:@"iOS: %@\n%@",
            [UIDevice currentDevice].systemVersion,
            message];
    dispatch_async(dispatch_get_main_queue(), ^{
        UIAlertView *alert =
            [[UIAlertView alloc]
                initWithTitle:@"Update State"
                message:message
                delegate:nil
                cancelButtonTitle:@"OK"
                otherButtonTitles:nil];
        [alert show];
    });
#endif

    return @(result);
}

+ (BNCUpdateState) updateStateWithBuildDate:(NSDate*)buildDate
                             appInstallDate:(NSDate*)appInstallDate
                           storedAppVersion:(NSString*)storedAppVersion
                          currentAppVersion:(NSString*)currentAppVersion {

    if (storedAppVersion) {
        if (currentAppVersion && [storedAppVersion isEqualToString:currentAppVersion])
            return BNCUpdateStateNonUpdate;
        else
            return BNCUpdateStateUpdate;
    }

    // If there isn't a stored app version it might be because Branch is just starting to be used in
    // this project.  So use the app dates to figure out if this is a new install or an update.

    if (buildDate && [buildDate timeIntervalSince1970] <= 0.0) {
        // Invalid buildDate.
        buildDate = nil;
    }
    if (appInstallDate && [appInstallDate timeIntervalSince1970] <= 0.0) {
        // Invalid appInstallDate.
        appInstallDate = nil;
    }

    // If app dates can't be found it may be because iOS isn't reporting them.
    if (buildDate == nil || appInstallDate == nil) {
        BNCLogError(@"Please report this to Branch: Build date is %@ and install date is %@. iOS version %@.",
            buildDate, appInstallDate, [UIDevice currentDevice].systemVersion);
        return BNCUpdateStateInstall;
    }

    if ([buildDate compare:appInstallDate] > 0) {
        return BNCUpdateStateUpdate;
    }

    if ([appInstallDate timeIntervalSinceNow] > (-7.0 * 24.0 * 60.0 * 60.0)) {
        return BNCUpdateStateInstall;
    }

    return BNCUpdateStateNonUpdate;
}

+ (NSDate*) appInstallDate {
    //  Get the app install date:

    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSError *error = nil;
    NSURL *libraryURL =
        [[fileManager URLsForDirectory:NSLibraryDirectory inDomains:NSUserDomainMask] firstObject];
    NSDictionary *attributes = [fileManager attributesOfItemAtPath:libraryURL.path error:&error];
    if (error) {
        BNCLogError(@"Can't get library date: %@.", error);
        return nil;
    }
    NSDate *installDate = [attributes fileCreationDate];
    if (installDate == nil || [installDate timeIntervalSince1970] <= 0.0) {
        BNCLogError(@"Invalid install date.");
        return nil;
    }
    return installDate;
}

+ (NSDate*) dateForPathComponent:(NSString*)component inURLs:(NSArray<NSURL*>*)fileInfoURLs {
    BOOL success = NO;
    NSError *error = nil;
    NSDate *buildDate = nil;
    for (NSURL *fileInfoURL in fileInfoURLs) {
        if ([[fileInfoURL lastPathComponent] isEqualToString:component]) {
            success = [fileInfoURL getResourceValue:&buildDate
                forKey:NSURLCreationDateKey
                error:&error];
            break;
        }
    }
    if (!success || error) {
        BNCLogWarning(@"Can't retrieve bundle attributes. Success: %d Error: %@.", success, error);
        return nil;
    }
    return buildDate;
}

+ (NSDate*) appBuildDate {
    //  Get the build date:

    NSFileManager *fileManager = [NSFileManager defaultManager];

    NSError *error = nil;
    NSString *bundleRoot = [[NSBundle mainBundle] bundlePath];
    if (!bundleRoot) bundleRoot = @".";
    NSURL *bundleRootURL = [NSURL URLWithString:[@"file://" stringByAppendingString:bundleRoot]];
    if (bundleRootURL == nil) return nil;
    NSArray *fileInfoURLs =
        [fileManager contentsOfDirectoryAtURL:bundleRootURL
            includingPropertiesForKeys:@[ NSURLCreationDateKey ]
            options:0
            error:&error];            
    if (error) {
        BNCLogError(@"Error retreiving bundle info: %@.", error);
        return nil;
    }
    NSDate *buildDate = nil;
    buildDate = [self dateForPathComponent:@"_CodeSignature" inURLs:fileInfoURLs];
    if (!buildDate) {
        buildDate = [self dateForPathComponent:@"META-INF" inURLs:fileInfoURLs];
    }
    if (!buildDate) {
        buildDate = [self dateForPathComponent:@"PkgInfo" inURLs:fileInfoURLs];
    }
    if (!buildDate) {
        buildDate = [self dateForPathComponent:@"xctest" inURLs:fileInfoURLs];
    }
    if (buildDate == nil || [buildDate timeIntervalSince1970] <= 0.0) {
        BNCLogError(@"Invalid build date.");
        return nil;
    }
    return buildDate;
}

+ (void)setUpdateState {
    NSString *currentAppVersion = [BNCSystemObserver getAppVersion];
    [BNCPreferenceHelper preferenceHelper].appVersion = currentAppVersion;
    [[BNCPreferenceHelper preferenceHelper] synchronize];
}

@end
