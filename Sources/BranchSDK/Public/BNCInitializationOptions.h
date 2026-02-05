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

@class BNCInitSessionResponse;

/**
 Callback type for initialization completion.

 @param response The session response containing params, universal object, and link properties.
 @param error An error if initialization failed, nil otherwise.
 */
typedef void (^BNCInitializationCallback)(BNCInitSessionResponse * _Nullable response, NSError * _Nullable error);

/**
 Options for SDK initialization.

 This class consolidates the various parameters that can be passed
 during initialization, providing a cleaner API and better state management.

 Example usage:
 @code
 BNCInitializationOptions *options = [[BNCInitializationOptions alloc] init];
 options.url = incomingURL;
 options.callback = ^(BNCInitSessionResponse *response, NSError *error) {
     if (error) {
         NSLog(@"Branch init failed: %@", error);
     } else {
         NSLog(@"Branch init succeeded with params: %@", response.params);
     }
 };
 [[Branch getInstance] initSessionWithOptions:options];
 @endcode
 */
@interface BNCInitializationOptions : NSObject <NSCopying>

#pragma mark - URL and Source

/// URL that opened the app (deep link or universal link)
@property (nonatomic, copy, nullable) NSURL *url;

/// Scene identifier (iOS 13+ multi-window support)
@property (nonatomic, copy, nullable) NSString *sceneIdentifier;

/// Source application bundle ID
@property (nonatomic, copy, nullable) NSString *sourceApplication;

#pragma mark - Callbacks

/// Callback invoked when initialization completes
@property (nonatomic, copy, nullable) BNCInitializationCallback callback;

#pragma mark - Behavior Flags

/// Whether this is a referrable session (affects attribution). Default: YES
@property (nonatomic, assign) BOOL isReferrable;

/// Whether to automatically display deep link controller. Default: NO
@property (nonatomic, assign) BOOL automaticallyDisplayController;

/// Whether to delay network requests until explicitly triggered. Default: NO
@property (nonatomic, assign) BOOL delayInitialization;

/// Whether to disable automatic session tracking. Default: NO
@property (nonatomic, assign) BOOL disableAutomaticSessionTracking;

/// Whether to check pasteboard for deferred deep links on install. Default: YES
@property (nonatomic, assign) BOOL checkPasteboardOnInstall;

#pragma mark - Advanced Options

/// Custom referral parameters to include in the session
@property (nonatomic, copy, nullable) NSDictionary<NSString *, id> *referralParams;

/// Whether to reset the session (force new open request). Default: NO
@property (nonatomic, assign) BOOL resetSession;

#pragma mark - Convenience Initializers

#if !TARGET_OS_TV
/**
 Create options configured from launch options.

 @param launchOptions The launch options dictionary from application:didFinishLaunchingWithOptions:
 @return A new BNCInitializationOptions instance configured with the launch options.
 */
+ (instancetype)optionsWithLaunchOptions:(nullable NSDictionary<UIApplicationLaunchOptionsKey, id> *)launchOptions;

/**
 Configure from launch options.

 @param launchOptions The launch options dictionary from application:didFinishLaunchingWithOptions:
 */
- (void)configureWithLaunchOptions:(nullable NSDictionary<UIApplicationLaunchOptionsKey, id> *)launchOptions;
#endif

/**
 Create options for handling a deep link URL.

 @param url The deep link URL to handle.
 @return A new BNCInitializationOptions instance configured for the URL.
 */
+ (instancetype)optionsWithURL:(NSURL *)url;

/**
 Create options for handling a deep link URL with scene support.

 @param url The deep link URL to handle.
 @param sceneIdentifier The scene identifier for multi-window support.
 @return A new BNCInitializationOptions instance configured for the URL and scene.
 */
+ (instancetype)optionsWithURL:(NSURL *)url sceneIdentifier:(nullable NSString *)sceneIdentifier;

/**
 Create options for handling a universal link user activity.

 @param userActivity The user activity from universal link handling.
 @return A new BNCInitializationOptions instance configured for the user activity, or nil if not a web activity.
 */
+ (nullable instancetype)optionsWithUserActivity:(NSUserActivity *)userActivity;

@end

NS_ASSUME_NONNULL_END
