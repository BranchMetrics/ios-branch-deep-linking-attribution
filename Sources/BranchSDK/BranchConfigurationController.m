//
//  BranchConfigurationController.m
//  BranchSDK
//
//  Created by Nidhi Dixit on 6/2/25.
//

#import "BranchConfigurationController.h"
#import "BNCPreferenceHelper.h"
#import "BranchLogger.h"
#import "BranchConstants.h"

NS_ASSUME_NONNULL_BEGIN

@implementation BranchConfigurationController

+ (instancetype)sharedInstance {
    static BranchConfigurationController *sharedInstance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedInstance = [[BranchConfigurationController alloc] init];
    });
    return sharedInstance;
}

- (NSDictionary *) branchKeyInfo {
    return @{
        BRANCH_REQUEST_KEY_BRANCH_KEY_SOURCE : self.branchKeySource ? self.branchKeySource: @"Unknown",
    };
}

- (NSDictionary *)featureFlagsInfo {
    return @{
        BRANCH_REQUEST_KEY_CHECK_PASTEBOARD_ON_INSTALL: @(self.checkPasteboardOnInstall),
        BRANCH_REQUEST_KEY_DEFER_INIT_FOR_PLUGIN_RUNTIME: @(self.deferInitForPluginRuntime)
    };
}

- (NSDictionary *)frameworkIntegrationInfo {
    NSMutableDictionary *info = [NSMutableDictionary new];

    info[BRANCH_REQUEST_KEY_LINKED_FRAMEORKS] = @{
        FRAMEWORK_AD_SUPPORT: @([self isClassAvailable:@"ASIdentifierManager"]),
        FRAMEWORK_ATT_TRACKING_MANAGER: @([self isClassAvailable:@"ATTrackingManager"]),
        FRAMEWORK_AD_FIREBASE_CRASHLYTICS: @([self isClassAvailable:@"FIRCrashlytics"]),
        FRAMEWORK_AD_SAFARI_SERVICES: @([self isClassAvailable:@"SFSafariViewController"]),
        FRAMEWORK_AD_APP_ADS_ONDEVICE_CONVERSION: @([self isClassAvailable:@"ODCConversionManager"]),
    };
    
    return [info copy];
}

- (NSDictionary *) getConfiguration {
    NSMutableDictionary *config = [NSMutableDictionary new];
    [config addEntriesFromDictionary:[self branchKeyInfo]];
    [config addEntriesFromDictionary:[self featureFlagsInfo]];
    [config addEntriesFromDictionary:[self frameworkIntegrationInfo]];
    return [config copy];
}

// helper methods
- (BOOL)isClassAvailable:(NSString *)className {
    return NSClassFromString(className) != nil;
}

@end

NS_ASSUME_NONNULL_END
