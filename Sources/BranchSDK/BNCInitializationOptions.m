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
        _delayInitialization = NO;
        _disableAutomaticSessionTracking = NO;
        _checkPasteboardOnInstall = YES;
        _referralParams = nil;
        _sourceApplication = nil;
    }
    return self;
}

#if !TARGET_OS_TV
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

- (NSString *)description {
    return [NSString stringWithFormat:@"<BNCInitializationOptions: url=%@, sceneIdentifier=%@, delayInitialization=%@, disableAutomaticSessionTracking=%@>",
            self.url,
            self.sceneIdentifier,
            self.delayInitialization ? @"YES" : @"NO",
            self.disableAutomaticSessionTracking ? @"YES" : @"NO"];
}

@end
