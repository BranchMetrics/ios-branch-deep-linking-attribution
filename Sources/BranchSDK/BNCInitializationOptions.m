//
//  BNCInitializationOptions.m
//  BranchSDK
//
//  Created by Branch SDK Team
//  Copyright © 2026 Branch Metrics. All rights reserved.
//

#import "BNCInitializationOptions.h"

@implementation BNCInitializationOptions

- (instancetype)init {
    self = [super init];
    if (self) {
        _url = nil;
        _sceneIdentifier = nil;
        _sourceApplication = nil;
        _callback = nil;
        _isReferrable = YES;
        _automaticallyDisplayController = NO;
        _delayInitialization = NO;
        _disableAutomaticSessionTracking = NO;
        _checkPasteboardOnInstall = YES;
        _referralParams = nil;
        _resetSession = NO;
    }
    return self;
}

#pragma mark - NSCopying

- (instancetype)copyWithZone:(NSZone *)zone {
    BNCInitializationOptions *copy = [[BNCInitializationOptions allocWithZone:zone] init];
    copy.url = self.url;
    copy.sceneIdentifier = self.sceneIdentifier;
    copy.sourceApplication = self.sourceApplication;
    copy.callback = self.callback;
    copy.isReferrable = self.isReferrable;
    copy.automaticallyDisplayController = self.automaticallyDisplayController;
    copy.delayInitialization = self.delayInitialization;
    copy.disableAutomaticSessionTracking = self.disableAutomaticSessionTracking;
    copy.checkPasteboardOnInstall = self.checkPasteboardOnInstall;
    copy.referralParams = [self.referralParams copy];
    copy.resetSession = self.resetSession;
    return copy;
}

#pragma mark - Convenience Initializers

#if !TARGET_OS_TV
+ (instancetype)optionsWithLaunchOptions:(NSDictionary<UIApplicationLaunchOptionsKey, id> *)launchOptions {
    BNCInitializationOptions *options = [[BNCInitializationOptions alloc] init];
    [options configureWithLaunchOptions:launchOptions];
    return options;
}

- (void)configureWithLaunchOptions:(NSDictionary<UIApplicationLaunchOptionsKey, id> *)launchOptions {
    if (!launchOptions) {
        return;
    }

    // Extract URL from launch options
    NSURL *launchURL = launchOptions[UIApplicationLaunchOptionsURLKey];
    if (launchURL) {
        self.url = launchURL;
    }

    // Extract source application
    NSString *sourceApp = launchOptions[UIApplicationLaunchOptionsSourceApplicationKey];
    if (sourceApp) {
        self.sourceApplication = sourceApp;
    }
}
#endif

+ (instancetype)optionsWithURL:(NSURL *)url {
    return [self optionsWithURL:url sceneIdentifier:nil];
}

+ (instancetype)optionsWithURL:(NSURL *)url sceneIdentifier:(NSString *)sceneIdentifier {
    BNCInitializationOptions *options = [[BNCInitializationOptions alloc] init];
    options.url = url;
    options.sceneIdentifier = sceneIdentifier;
    options.resetSession = YES; // New URL typically means reset session
    return options;
}

+ (instancetype)optionsWithUserActivity:(NSUserActivity *)userActivity {
    if (![userActivity.activityType isEqualToString:NSUserActivityTypeBrowsingWeb]) {
        return nil;
    }

    NSURL *url = userActivity.webpageURL;
    if (!url) {
        return nil;
    }

    return [self optionsWithURL:url sceneIdentifier:nil];
}

#pragma mark - Description

- (NSString *)description {
    return [NSString stringWithFormat:@"<BNCInitializationOptions: url=%@, sceneIdentifier=%@, isReferrable=%@, resetSession=%@, delayInitialization=%@>",
            self.url,
            self.sceneIdentifier,
            self.isReferrable ? @"YES" : @"NO",
            self.resetSession ? @"YES" : @"NO",
            self.delayInitialization ? @"YES" : @"NO"];
}

@end
