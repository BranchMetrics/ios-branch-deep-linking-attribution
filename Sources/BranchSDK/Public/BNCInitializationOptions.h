//
//  BNCInitializationOptions.h
//  BranchSDK
//
//  Created by Branch SDK Team
//  Copyright © 2026 Branch Metrics. All rights reserved.
//

#if __has_feature(modules)
@import Foundation;
#else
#import <Foundation/Foundation.h>
#endif

#if !TARGET_OS_TV
#if __has_feature(modules)
@import UIKit;
#else
#import <UIKit/UIKit.h>
#endif
#endif

NS_ASSUME_NONNULL_BEGIN

/**
 Options for SDK initialization.

 This class consolidates the various parameters that can be passed
 during initialization, replacing the legacy methods with a
 single, composable options class.

 Example usage:
 @code
 BNCInitializationOptions *options = [[BNCInitializationOptions alloc] init];
 options.url = incomingURL;
 options.delayInitialization = NO;
 @endcode
 */
@interface BNCInitializationOptions : NSObject

/// URL that opened the app (deep link or universal link)
@property (nonatomic, strong, nullable) NSURL *url;

/// Scene identifier (iOS 13+ multi-window support)
@property (nonatomic, copy, nullable) NSString *sceneIdentifier;

/// Whether to delay network requests (default: NO)
@property (nonatomic, assign) BOOL delayInitialization;

/// Whether to disable automatic session tracking (default: NO)
@property (nonatomic, assign) BOOL disableAutomaticSessionTracking;

/// Whether to check for deferred deep links (default: YES)
@property (nonatomic, assign) BOOL checkPasteboardOnInstall;

/// Custom referral parameters
@property (nonatomic, copy, nullable) NSDictionary<NSString *, NSString *> *referralParams;

/// Source application bundle ID
@property (nonatomic, copy, nullable) NSString *sourceApplication;

#if !TARGET_OS_TV
/**
 Configure from launch options.

 @param launchOptions The launch options dictionary from application:didFinishLaunchingWithOptions:
 */
- (void)configureWithLaunchOptions:(nullable NSDictionary<UIApplicationLaunchOptionsKey, id> *)launchOptions;
#endif

@end

NS_ASSUME_NONNULL_END
