/**
 @file          BNCApplication.m
 @package       Branch-SDK
 @brief         Current application and extension info.

 @author        Edward Smith
 @date          January 8, 2018
 @copyright     Copyright © 2018 Branch. All rights reserved.
*/

#import "BNCApplication.h"
#import "BranchLogger.h"
#import "BNCKeyChain.h"

static NSString*const kBranchKeychainService          = @"BranchKeychainService";
static NSString*const kBranchKeychainFirstBuildKey    = @"BranchKeychainFirstBuild";
static NSString*const kBranchKeychainFirstInstalldKey = @"BranchKeychainFirstInstall";

#pragma mark - BNCApplication

@implementation BNCApplication

// BNCApplication checks a few values in keychain
// Checking keychain from main thread early in the app lifecycle can deadlock. INTENG-7291
+ (void)loadCurrentApplicationWithCompletion:(void (^)(BNCApplication *application))completion {
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        BNCApplication *tmp = [BNCApplication currentApplication];
        if (completion) {
            completion(tmp);
        }
    });
}

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
    if (!application) return application;
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

    NSString*group =  [BNCKeyChain securityAccessGroup];
    if (group) {
        NSRange range = [group rangeOfString:@"."];
        if (range.location != NSNotFound) {
            application->_teamID = [[group substringToIndex:range.location] copy];
        }
    }

    return application;
}

+ (NSDate *)currentBuildDate {
    NSURL *appURL = nil;
    NSURL *bundleURL = [NSBundle mainBundle].bundleURL;
    NSDictionary *info = [NSBundle mainBundle].infoDictionary;
    NSString *appName = info[(__bridge NSString *)kCFBundleExecutableKey];
    if (appName.length > 0 && bundleURL) {
        // path to the app on device. file:///private/var/containers/Bundle/Application/GUID
        appURL = [bundleURL URLByAppendingPathComponent:appName];
    } else {
        // TODO: Why is this fallback necessary? The NSBundle approach has been available since iOS 2.0
        // path to old app location, this symlinks to the new location. file:///var/containers/Bundle/Application/GUID
        NSString *path = [[NSProcessInfo processInfo].arguments firstObject];
        if (path) {
            appURL = [NSURL fileURLWithPath:path];
        }
    }
    if (appURL == nil) {
        [[BranchLogger shared] logError:@"Failed to get build date, app path is nil" error:nil];
        return nil;
    }

    NSError *error = nil;
    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSDictionary *attributes = [fileManager attributesOfItemAtPath:appURL.path error:&error];
    if (error) {
        [[BranchLogger shared] logError:@"Failed to get build date" error:error];
        return nil;
    }
    NSDate *buildDate = [attributes fileCreationDate];
    if (buildDate == nil || [buildDate timeIntervalSince1970] <= 0.0) {
        [[BranchLogger shared] logError:[NSString stringWithFormat:@"Invalid build date: %@", buildDate] error:nil];
    }
    return buildDate;
}

+ (NSDate *)firstInstallBuildDate {
    // check for stored build date
    NSError *error = nil;
    NSDate *firstBuildDate = [BNCKeyChain retrieveDateForService:kBranchKeychainService key:kBranchKeychainFirstBuildKey error:&error];
    if (firstBuildDate) {
        return firstBuildDate;
    }
    
    // get current build date and store it
    firstBuildDate = [self currentBuildDate];
    error = [BNCKeyChain storeDate:firstBuildDate forService:kBranchKeychainService key:kBranchKeychainFirstBuildKey cloudAccessGroup:nil];
    if (error) {
        [[BranchLogger shared] logError:@"Error saving build date" error:error];
    }
    return firstBuildDate;
}

+ (NSDate *)currentInstallDate {
    NSDate *installDate = [NSDate date];
    
    #if !TARGET_OS_TV
    // tvOS always returns a creation date of Unix epoch 0 on device
    installDate = [self creationDateForLibraryDirectory];
    if (installDate == nil || [installDate timeIntervalSince1970] <= 0.0) {
        [[BranchLogger shared] logError:@"Invalid install date, using [NSDate date]" error:nil];
    }
    #else
    [[BranchLogger shared] logWarning:@"File system creation date not supported on tvOS, using [NSDate date]" error:nil];
    #endif

    return installDate;
}

+ (NSDate *)creationDateForLibraryDirectory {
    NSError *error = nil;
    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSURL *directoryURL = [[fileManager URLsForDirectory:NSLibraryDirectory inDomains:NSUserDomainMask] firstObject];
    NSDictionary *attributes = [fileManager attributesOfItemAtPath:directoryURL.path error:&error];
    if (error) {
        [[BranchLogger shared] logWarning:@"Failed to get creation date for NSLibraryDirectory" error:error];
        return nil;
    }
    return [attributes fileCreationDate];
}

+ (NSDate *)firstInstallDate {
    // check keychain for stored install date, on iOS this is lost on app deletion.
    NSError *error = nil;
    NSDate* firstInstallDate = [BNCKeyChain retrieveDateForService:kBranchKeychainService key:kBranchKeychainFirstInstalldKey error:&error];
    if (firstInstallDate) {
        return firstInstallDate;
    }
    
    // check filesytem for creation date
    firstInstallDate = [self currentInstallDate];
    
    // save filesystem time to keychain
    error = [BNCKeyChain storeDate:firstInstallDate forService:kBranchKeychainService key:kBranchKeychainFirstInstalldKey cloudAccessGroup:nil];
    if (error) {
        [[BranchLogger shared] logWarning:@"Error while saving install date" error:error];
    }
    return firstInstallDate;
}

@end
