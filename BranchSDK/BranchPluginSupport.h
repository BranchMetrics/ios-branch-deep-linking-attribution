//
//  BranchPluginSupport.h
//  BranchSDK
//
//  Created by Nipun Singh on 1/6/22.
//  Copyright © 2022 Branch, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "BranchUniversalObject.h"

NS_ASSUME_NONNULL_BEGIN

@interface BranchPluginSupport : NSObject

+ (BranchPluginSupport *)instance;

#pragma mark - SDK entry points

- (void)initSessionWithLaunchOptions:(nullable NSDictionary *)options registerDeepLinkHandler:(void (^)(NSDictionary * _Nullable params, NSError * _Nullable error))callback;

- (void)initSessionWithLaunchOptions:(nullable NSDictionary *)options registerDeepLinkHandlerUsingBranchUniversalObject:(void (^)(BranchUniversalObject * _Nullable universalObject, BranchLinkProperties * _Nullable linkProperties, NSError * _Nullable error))callback;

- (BOOL)handleDeepLink:(nullable NSURL *)url;

- (BOOL)continueUserActivity:(nullable NSUserActivity *)userActivity;

- (void)notifyNativeToInit;

#pragma mark - Utility methods

- (NSDictionary<NSString *, NSString *> *)deviceDescription;

@end

NS_ASSUME_NONNULL_END
