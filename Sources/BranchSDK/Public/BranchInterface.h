//
//  BranchInterface.h
//  Branch-SDK
//
//  Copyright (c) 2026 Branch Metrics. All rights reserved.
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

NS_ASSUME_NONNULL_BEGIN

// Redeclared here (identical to the declaration in Branch.h) so this header does not
// need to import Branch.h, which would be circular once Branch adopts this protocol.
#ifndef BRANCH_ATTRIBUTION_LEVEL_DEFINED
#define BRANCH_ATTRIBUTION_LEVEL_DEFINED
typedef NSString * BranchAttributionLevel NS_STRING_ENUM;
#endif

/**
 An injectable abstraction over the public `Branch` API.

 `Branch` conforms to `BranchInterface`, so production code can depend on
 `id<BranchInterface>` instead of the `Branch` singleton and inject a mock in unit tests.
 This protocol is additive: it mirrors the existing `Branch` method signatures exactly and
 introduces no new behavior.
 */
@protocol BranchInterface <NSObject>

#pragma mark - Deep link resolution

- (void)requestDeepLinkData:(nullable NSString *)branchLink callback:(nullable callbackWithParams)callback
    NS_SWIFT_ASYNC_NAME(requestDeepLinkData(_:));

- (void)requestDeepLinkDataWithLaunchOptions:(nullable NSDictionary *)options
                                    callback:(nullable callbackWithParams)callback
    NS_SWIFT_ASYNC_NAME(requestDeepLinkData(withLaunchOptions:));

#if !TARGET_OS_TV
- (void)requestDeepLinkDataWithSceneOptions:(nullable UISceneConnectionOptions *)connectionOptions
                                      scene:(UIScene *)scene
                                   callback:(nullable callbackWithParams)callback
    NS_SWIFT_ASYNC_NAME(requestDeepLinkData(withSceneOptions:scene:))
    API_AVAILABLE(ios(13.0), macCatalyst(13.1));
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
- (void)logoutWithCallback:(nullable callbackWithStatus)callback;

#pragma mark - Consumer protection

- (void)setConsumerProtectionAttributionLevel:(BranchAttributionLevel)level;

#pragma mark - Partner parameters

- (void)addFacebookPartnerParameterWithName:(NSString *)name value:(NSString *)value;
- (void)addSnapPartnerParameterWithName:(NSString *)name value:(NSString *)value;
- (void)clearPartnerParameters;

@end

NS_ASSUME_NONNULL_END
