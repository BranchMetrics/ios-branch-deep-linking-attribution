//
//  BranchScene.h
//  Branch
//
//  Created by Ernest Cho on 3/24/20.
//  Copyright © 2020 Branch, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

/**
 Provide  support for UIScene.  This is only supported on iOS 13.0+, iPadOS 13.0+
*/
API_AVAILABLE(ios(13.0), macCatalyst(13.1))
@interface BranchScene : NSObject

+ (BranchScene *)shared;

/**
 Initialize a Branch session with launch options (deprecated).

 @param options Launch options dictionary from UISceneDelegate
 @param callback Callback block invoked when initialization completes with deep link params, error, and scene

 @deprecated Use `initSessionWithSceneOptions:scene:registerDeepLinkHandler:` instead for better scene tracking.
 **/
- (void)initSessionWithLaunchOptions:(nullable NSDictionary *)options
             registerDeepLinkHandler:(void (^ _Nonnull)(NSDictionary * _Nullable params, NSError * _Nullable error, UIScene * _Nullable scene))callback __attribute__((deprecated(("Use `initSessionWithSceneOptions:scene:registerDeepLinkHandler:` instead."))));

/**
 Initialize a Branch session for a specific scene with proper scene identifier tracking.

 Call this method from your UISceneDelegate's `scene:willConnectToSession:options:` method to initialize
 Branch SDK for multi-scene environments (iPadOS, macOS Catalyst). This method properly extracts URLs and
 user activities from UISceneConnectionOptions and associates them with the correct scene.

 Example usage:
 @code
 - (void)scene:(UIScene *)scene willConnectToSession:(UISceneSession *)session options:(UISceneConnectionOptions *)connectionOptions {
     [[BranchScene shared] initSessionWithSceneOptions:connectionOptions scene:scene registerDeepLinkHandler:^(NSDictionary * params, NSError * error, UIScene * scene) {
         // Handle deep link params for this specific scene
         if (params) {
             NSLog(@"Branch params: %@", params);
         }
     }];
 }
 @endcode

 @param connectionOptions The connection options from `scene:willConnectToSession:options:` containing URLs and user activities
 @param scene The UIScene instance being connected
 @param callback Callback block invoked when initialization completes with deep link params, error, and the scene that triggered the deep link

 @note This method handles both initial scene connection and subsequent deep links for the scene.
 **/
- (void)initSessionWithSceneOptions:(nullable UISceneConnectionOptions *)connectionOptions
                              scene:(UIScene *)scene
             registerDeepLinkHandler:(void (^ _Nonnull)(NSDictionary * _Nullable params, NSError * _Nullable error, UIScene * _Nullable scene))callback;

/**
 Handle a user activity (universal link) for a specific scene.

 @param scene The UIScene receiving the user activity
 @param userActivity The NSUserActivity to handle (typically contains a universal link)
 **/
- (void)scene:(UIScene *)scene continueUserActivity:(NSUserActivity *)userActivity;

/**
 Handle URL contexts (custom URL schemes) for a specific scene.

 @param scene The UIScene receiving the URL
 @param URLContexts Set of UIOpenURLContext objects containing the URLs to open
 **/
- (void)scene:(UIScene *)scene openURLContexts:(NSSet<UIOpenURLContext *> *)URLContexts;

@end

NS_ASSUME_NONNULL_END
