//
//  BNCApplication.m
//  BranchMonsterFactory
//
//  Created by Edward on 1/8/18.
//  Copyright © 2018 Branch. All rights reserved.
//

#import "BNCApplication.h"
#import "BNCLog.h"
#import "BNCKeyChain.h"

@implementation BNCApplication

+ (BNCApplication*) currentApplication {
    static BNCApplication *bnc_currentApplication = nil;
    static dispatch_once_t onceToken = 0;
    dispatch_once(&onceToken, ^{
        bnc_currentApplication = [[BNCApplication alloc] init];

        NSDictionary *infoPlist = [NSBundle mainBundle].infoDictionary;
        NSDictionary *provisioning = [self.class provisioningDictionary];

        // ??? Also, there's CFBundleVersionKey ???
        // Also, _applicationVersion = [NSBundle mainBundle].infoDictionary[@"CFBundleVersionKey"];

        bnc_currentApplication->_bundleID = [NSBundle mainBundle].bundleIdentifier;
        bnc_currentApplication->_applicationIDPrefix = provisioning[@"ApplicationIdentifierPrefix"];
        bnc_currentApplication->_displayName = infoPlist[@"CFBundleDisplayName"];
        bnc_currentApplication->_displayVersionString = infoPlist[@"CFBundleShortVersionString"];
        bnc_currentApplication->_versionString = infoPlist[@"CFBundleVersion"];

        bnc_currentApplication->_firstInstallBuildDate = [BNCApplication firstInstallBuildDate];
        bnc_currentApplication->_currentBuildDate = [BNCApplication currentBuildDate];

        bnc_currentApplication->_firstInstallDate = [BNCApplication firstInstallDate];
        bnc_currentApplication->_currentInstallDate = [BNCApplication currentInstallDate];
    });
    return bnc_currentApplication;
}

+ (NSDate*) currentBuildDate {
    NSDate* brn_currentBuildDate = nil;

    NSDictionary *info = [NSBundle mainBundle].infoDictionary;
    NSString *appName = info[(NSString*)kCFBundleExecutableKey];
    NSURL *appURL = [NSBundle mainBundle].bundleURL;
    appURL = [appURL URLByAppendingPathComponent:appName];

    NSError *error = nil;
    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSDictionary *attributes = [fileManager attributesOfItemAtPath:appURL.path error:&error];
    if (error) {
        BNCLogError(@"Can't get library date: %@.", error);
        return brn_currentBuildDate;
    }
    brn_currentBuildDate = [attributes fileCreationDate];
    if (brn_currentBuildDate == nil || [brn_currentBuildDate timeIntervalSince1970] <= 0.0) {
        BNCLogError(@"Invalid app build date: %@.", brn_currentBuildDate);
        brn_currentBuildDate = nil;
        return brn_currentBuildDate;
    }

    return brn_currentBuildDate;
}

static NSString * const kBranchKeychainService = @"Branch";

+ (NSDate*) firstInstallBuildDate {
    NSDate* brn_firstBuildDate = nil;

    NSError *error = nil;
    NSString * const kBranchKeychainAccountFirstBuild = @"BranchFirstBuild";
    brn_firstBuildDate = [BNCKeyChain retrieveValueForService:kBranchKeychainService
        key:kBranchKeychainAccountFirstBuild error:&error];
    if (brn_firstBuildDate) return brn_firstBuildDate;

    brn_firstBuildDate = [self currentBuildDate];
    error = [BNCKeyChain storeValue:brn_firstBuildDate
        forService:kBranchKeychainService
        key:kBranchKeychainAccountFirstBuild
        iCloud:NO];

    return brn_firstBuildDate;
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
        return nil;
    }
    return installDate;
}

+ (NSDate*) firstInstallDate {
    NSDate* brn_firstInstallDate = nil;

    NSError *error = nil;
    NSString * const kBranchKeychainAccountFirstInstall = @"BranchFirstInstall";
    brn_firstInstallDate = [BNCKeyChain retrieveValueForService:kBranchKeychainService
        key:kBranchKeychainAccountFirstInstall error:&error];
    if (brn_firstInstallDate) return brn_firstInstallDate;

    brn_firstInstallDate = [self currentInstallDate];
    error = [BNCKeyChain storeValue:brn_firstInstallDate
        forService:kBranchKeychainService
        key:kBranchKeychainAccountFirstInstall
        iCloud:NO];

    return brn_firstInstallDate;
}

static NSString*const kBranchKeychainAccountDevices = @"kBranchKeychainAccountDevices";

- (NSDictionary*) deviceKeyIdentityValueDictionary {
    @synchronized (self.class) {
        NSError *error = nil;
        NSDictionary *deviceDictionary =
            [BNCKeyChain retrieveValueForService:kBranchKeychainService
                key:kBranchKeychainAccountDevices
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
        if (!identityID) identityID = @"";
        dictionary[deviceID] = identityID;

        NSError *error =
            [BNCKeyChain storeValue:dictionary
                forService:kBranchKeychainService
                key:kBranchKeychainAccountDevices
                iCloud:YES];
        if (error) {
            BNCLogError(@"Can't add device/identity pair: %@.", error);
        }
    }
}

+ (NSDictionary*) provisioningDictionary {
    NSURL *provisionURL = [[NSBundle mainBundle].bundleURL URLByAppendingPathComponent:@"embedded.mobileprovision"];
    NSData *provisionData = [NSData dataWithContentsOfURL:provisionURL];
    if (!provisionData) return nil;

    char*const xmlHeader = "<?xml version=\"1.0\" encoding=\"UTF-8\"?>";
    const uint8_t*const bytes = provisionData.bytes;
    uint8_t*const p = memmem(bytes, provisionData.length, xmlHeader, strlen(xmlHeader));
    if (!p || (p - bytes) < 2) return nil;

    int length = (uint16_t) ((*(p-2) << 8) | *(p-1));
    NSRange range = NSMakeRange(p - bytes, length);
    NSData*plistData = [provisionData subdataWithRange:range];

    NSError *error = nil;
    NSPropertyListFormat format;
    NSDictionary* dictionary =
        [NSPropertyListSerialization propertyListWithData:plistData
            options:NSPropertyListImmutable
            format:&format
            error:&error];
    if (error) {
        BNCLogWarning(@"Can't read provisioning: %@.", error);
    }
    return dictionary;
}

@end
