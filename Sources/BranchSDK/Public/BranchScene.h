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
 Initialize Branch session with launch options from AppDelegate.

 @param options The launch options dictionary from `application:didFinishLaunchingWithOptions:`.
 @param callback Callback invoked when session initialization completes.

 @warning For Scene-based apps (iOS 13+), prefer using `initSessionWithSceneConnectionOptions:registerDeepLinkHandler:`
          to prevent duplicate OPEN requests on cold launch via deep links.
 */
- (void)initSessionWithLaunchOptions:(nullable NSDictionary *)options
             registerDeepLinkHandler:(void (^ _Nonnull)(NSDictionary * _Nullable params, NSError * _Nullable error, UIScene * _Nullable scene))callback;

/**
 Initialize Branch session with scene connection options.

 This is the recommended initialization method for Scene-based apps (iOS 13+).
 It correctly detects deep link launches to prevent duplicate OPEN requests.

 Call this method from your SceneDelegate's `scene:willConnectToSession:options:` method.

 @param connectionOptions The connection options from `scene:willConnectToSession:options:`.
 @param callback Callback invoked when session initialization completes.

 @code
 func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {
     BranchScene.shared().initSession(with: connectionOptions) { params, error, scene in
         // Handle deep link params
     }
 }
 @endcode
 */
- (void)initSessionWithSceneConnectionOptions:(nullable UISceneConnectionOptions *)connectionOptions
                      registerDeepLinkHandler:(void (^ _Nonnull)(NSDictionary * _Nullable params, NSError * _Nullable error, UIScene * _Nullable scene))callback;

- (void)scene:(UIScene *)scene continueUserActivity:(NSUserActivity *)userActivity;

- (void)scene:(UIScene *)scene openURLContexts:(NSSet<UIOpenURLContext *> *)URLContexts;

@end

NS_ASSUME_NONNULL_END
