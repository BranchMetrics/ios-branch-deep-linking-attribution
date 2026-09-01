//
//  BranchInterface.h
//  BranchSDK
//
//  Created by Brandon Boothe on 8/4/26.
//

#if __has_feature(modules)
@import Foundation;
#else
#import <Foundation/Foundation.h>
#endif

#if !TARGET_OS_TV
#import <UIKit/UIKit.h>
#endif

#import "BNCCallbacks.h"
#import "BranchAttributionLevel.h"

NS_ASSUME_NONNULL_BEGIN

/**
 An injectable abstraction over the public `Branch` API.

 `Branch` conforms to `BranchInterface`, so production code can depend on
 `id<BranchInterface>` instead of the `Branch` singleton and inject a mock in unit tests.
 This protocol is additive: it mirrors the existing `Branch` method signatures exactly and
 introduces no new behavior.
 */
@protocol BranchInterface <NSObject>

#pragma mark - Deep link resolution

// The Swift-name annotations below must stay identical to the ones on the same selectors in
// Branch.h. `Branch` adopts this protocol, so a divergent NS_SWIFT_NAME / NS_SWIFT_ASYNC_NAME
// here renames the method for every Swift caller of `Branch`, not just for `id<BranchInterface>`.
- (void)requestDeepLinkData:(nullable NSString *)branchLink callback:(nullable callbackWithParams)callback
    NS_SWIFT_NAME(requestDeepLinkData(branchLink:callback:))
    NS_SWIFT_ASYNC_NAME(requestDeepLinkData(branchLink:));

- (void)requestDeepLinkDataWithLaunchOptions:(nullable NSDictionary *)options
                                    callback:(nullable callbackWithParams)callback
    NS_SWIFT_NAME(requestDeepLinkData(launchOptions:callback:))
    NS_SWIFT_ASYNC_NAME(requestDeepLinkData(launchOptions:));

- (void)requestDeepLinkDataWithURL:(nullable NSURL *)url
    NS_SWIFT_NAME(requestDeepLinkData(openURL:));

- (void)requestDeepLinkDataWithURL:(nullable NSURL *)url
                 sourceApplication:(nullable NSString *)sourceApplication
                        annotation:(nullable id)annotation
    NS_SWIFT_NAME(requestDeepLinkData(openURL:sourceApplication:annotation:));

- (void)requestDeepLinkDataWithUserActivity:(nullable NSUserActivity *)userActivity
    NS_SWIFT_NAME(requestDeepLinkData(userActivity:));

- (void)requestDeepLinkDataWithUserInfo:(nullable NSDictionary *)userInfo
    NS_SWIFT_NAME(requestDeepLinkData(userInfo:));

#if !TARGET_OS_TV
- (void)requestDeepLinkDataWithSceneOptions:(nullable UISceneConnectionOptions *)connectionOptions
                                      scene:(UIScene *)scene
                                   callback:(nullable callbackWithParams)callback
    API_AVAILABLE(ios(13.0), macCatalyst(13.1))
    NS_SWIFT_NAME(requestDeepLinkData(sceneOptions:scene:callback:))
    NS_SWIFT_ASYNC_NAME(requestDeepLinkData(sceneOptions:scene:));

- (void)requestDeepLinkDataWithScene:(UIScene *)scene
                      openURLContexts:(NSSet<UIOpenURLContext *> *)urlContexts
    API_AVAILABLE(ios(13.0))
    NS_SWIFT_NAME(requestDeepLinkData(scene:openURLContexts:));

- (void)requestDeepLinkDataWithScene:(UIScene *)scene
                continueUserActivity:(NSUserActivity *)userActivity
    API_AVAILABLE(ios(13.0))
    NS_SWIFT_NAME(requestDeepLinkData(scene:userActivity:));
#endif

#pragma mark - Attribution open

- (void)sendOpen;

#pragma mark - Referring params

- (nullable NSDictionary *)getLatestReferringParams;
- (nullable NSDictionary *)getFirstReferringParams;

#pragma mark - Identity

- (void)setUserAlias:(nullable NSString *)userAlias completion:(nullable callbackWithParams)completion
    NS_SWIFT_ASYNC_NAME(setUserAlias(_:));
- (void)logout;
- (void)logoutWithCallback:(nullable callbackWithStatus)callback
    NS_SWIFT_ASYNC_NAME(logoutAsync());

#pragma mark - Consumer protection

- (void)setConsumerProtectionAttributionLevel:(BranchAttributionLevel)level;

#pragma mark - Partner parameters

- (void)addFacebookPartnerParameterWithName:(NSString *)name value:(NSString *)value;
- (void)addSnapPartnerParameterWithName:(NSString *)name value:(NSString *)value;
- (void)clearPartnerParameters;

@end

NS_ASSUME_NONNULL_END
