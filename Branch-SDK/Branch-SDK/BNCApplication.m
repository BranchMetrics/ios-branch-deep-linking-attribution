/**
 @file          BNCApplication.m
 @package       Branch-SDK
 @brief         Current application and extension info.

 @author        Edward Smith
 @date          January 8, 2018
 @copyright     Copyright © 2018 Branch. All rights reserved.
*/

#import "BNCApplication.h"
#import "BNCLog.h"
#import "BNCKeyChain.h"

static NSString*const kBranchKeychainService          = @"BranchKeychainService";
static NSString*const kBranchKeychainDevicesKey       = @"BranchKeychainDevices";
static NSString*const kBranchKeychainFirstBuildKey    = @"BranchKeychainFirstBuild";
static NSString*const kBranchKeychainFirstInstalldKey = @"BranchKeychainFirstInstall";

typedef CFTypeRef SecTaskRef;
extern CFDictionaryRef SecTaskCopyValuesForEntitlements(SecTaskRef task, CFArrayRef entitlements, CFErrorRef  _Nullable *error)
    __attribute__((weak_import));

extern SecTaskRef SecTaskCreateFromSelf(CFAllocatorRef allocator)
    __attribute__((weak_import));

#pragma mark - BNCApplication

@implementation BNCApplication

+ (BNCApplication*) currentApplication {
    static BNCApplication *bnc_currentApplication = nil;
    static dispatch_once_t onceToken = 0;
    dispatch_once(&onceToken, ^{
        bnc_currentApplication = [BNCApplication createCurrentApplication];
    });
    return bnc_currentApplication;
}

+ (BNCApplication*) createCurrentApplication {
    BNCApplication *application = [[BNCApplication alloc] init];
    NSDictionary *info = [NSBundle mainBundle].infoDictionary;

    application->_bundleID = [NSBundle mainBundle].bundleIdentifier;
    application->_displayName = info[@"CFBundleDisplayName"];
    application->_shortDisplayName = info[@"CFBundleName"];

    application->_displayVersionString = info[@"CFBundleShortVersionString"];
    application->_versionString = info[@"CFBundleVersion"];

    application->_firstInstallBuildDate = [BNCApplication firstInstallBuildDate];
    application->_currentBuildDate = [BNCApplication currentBuildDate];

    application->_firstInstallDate = [BNCApplication firstInstallDate];
    application->_currentInstallDate = [BNCApplication currentInstallDate];

    NSDictionary *entitlements = [self entitlementsDictionary];
    application->_applicationID = entitlements[@"application-identifier"];
    application->_pushNotificationEnvironment = entitlements[@"aps-environment"];
    application->_keychainAccessGroups = entitlements[@"keychain-access-groups"];
    application->_associatedDomains = entitlements[@"com.apple.developer.associated-domains"];
    application->_teamID = entitlements[@"com.apple.developer.team-identifier"];
    if (application->_teamID.length == 0 && application->_applicationID) {
        // Some simulator apps aren't signed the same way?
        NSRange range = [application->_applicationID rangeOfString:@"."];
        if (range.location != NSNotFound) {
            application->_teamID = [application->_applicationID substringWithRange:NSMakeRange(0, range.location)];
        }
    }

    return application;
}

+ (NSDictionary*) entitlementsDictionary {
    if (SecTaskCreateFromSelf == NULL || SecTaskCopyValuesForEntitlements == NULL)
        return nil;

    NSArray *entitlementKeys = @[
        @"application-identifier",
        @"com.apple.developer.team-identifier",
        @"com.apple.developer.associated-domains",
        @"keychain-access-groups",
        @"aps-environment"
    ];

    SecTaskRef myself = SecTaskCreateFromSelf(NULL);
    if (!myself) return nil;

    CFErrorRef errorRef = NULL;
    NSDictionary *entitlements = (__bridge_transfer NSDictionary *)
        (SecTaskCopyValuesForEntitlements(myself, (__bridge CFArrayRef)entitlementKeys, &errorRef));
    if (errorRef) {
        BNCLogError(@"Can't retrieve entitlements: %@.", errorRef);
        CFRelease(errorRef);
    }
    CFRelease(myself);

    return entitlements;
}

+ (NSDate*) currentBuildDate {
    NSURL *appURL = nil;
    NSURL *bundleURL = [NSBundle mainBundle].bundleURL;
    NSDictionary *info = [NSBundle mainBundle].infoDictionary;
    NSString *appName = info[(__bridge NSString*)kCFBundleExecutableKey];
    if (appName.length > 0 && bundleURL) {
        appURL = [bundleURL URLByAppendingPathComponent:appName];
    } else {
        NSString *path = [[NSProcessInfo processInfo].arguments firstObject];
        if (path) appURL = [NSURL fileURLWithPath:path];
    }
    if (appURL == nil)
        return nil;

    NSError *error = nil;
    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSDictionary *attributes = [fileManager attributesOfItemAtPath:appURL.path error:&error];
    if (error) {
        BNCLogError(@"Can't get build date: %@.", error);
        return nil;
    }
    NSDate * buildDate = [attributes fileCreationDate];
    if (buildDate == nil || [buildDate timeIntervalSince1970] <= 0.0) {
        BNCLogError(@"Invalid build date: %@.", buildDate);
    }
    return buildDate;
}

+ (NSDate*) firstInstallBuildDate {
    NSError *error = nil;
    NSDate *firstBuildDate =
        [BNCKeyChain retrieveValueForService:kBranchKeychainService
            key:kBranchKeychainFirstBuildKey
            error:&error];
    if (firstBuildDate)
        return firstBuildDate;

    firstBuildDate = [self currentBuildDate];
    error = [BNCKeyChain storeValue:firstBuildDate
        forService:kBranchKeychainService
        key:kBranchKeychainFirstBuildKey
        cloudAccessGroup:nil];

    return firstBuildDate;
}

+ (NSDate*) currentInstallDate {
    NSError *error = nil;
    NSFileManager *fileManager = [NSFileManager defaultManager];
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
    }
    return installDate;
}

+ (NSDate*) firstInstallDate {
    NSError *error = nil;
    NSDate* firstInstallDate =
        [BNCKeyChain retrieveValueForService:kBranchKeychainService
            key:kBranchKeychainFirstInstalldKey
            error:&error];
    if (firstInstallDate)
        return firstInstallDate;

    firstInstallDate = [self currentInstallDate];
    error = [BNCKeyChain storeValue:firstInstallDate
        forService:kBranchKeychainService
        key:kBranchKeychainFirstInstalldKey
        cloudAccessGroup:nil];

    return firstInstallDate;
}

- (NSDictionary*) deviceKeyIdentityValueDictionary {
    @synchronized (self.class) {
        NSError *error = nil;
        NSDictionary *deviceDictionary =
            [BNCKeyChain retrieveValueForService:kBranchKeychainService
                key:kBranchKeychainDevicesKey
                error:&error];
        if (error) BNCLogWarning(@"While retrieving deviceKeyIdentityValueDictionary: %@.", error);
        if (!deviceDictionary) deviceDictionary = @{};
        return deviceDictionary;
    }
}

- (void) addDeviceID:(NSString*)deviceID identityID:(NSString*)identityID {
    @synchronized (self.class) {
        NSMutableDictionary *dictionary =
            [NSMutableDictionary dictionaryWithDictionary:[self deviceKeyIdentityValueDictionary]];
        dictionary[deviceID] = identityID;

        NSString*const kCloudAccessGroup = [self.class currentApplication].applicationID;

        NSError *error =
            [BNCKeyChain storeValue:dictionary
                forService:kBranchKeychainService
                key:kBranchKeychainDevicesKey
                cloudAccessGroup:kCloudAccessGroup];
        if (error) {
            BNCLogError(@"Can't add device/identity pair: %@.", error);
        }
    }
}

@end
