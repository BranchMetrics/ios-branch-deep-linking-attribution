//
//  BranchPluginSupport.h
//  BranchSDK
//
//  Created by Nipun Singh on 1/6/22.
//  Copyright © 2022 Branch, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface BranchPluginSupport : NSObject

+ (BranchPluginSupport *)instance;

/**
Sets a custom base URL for all calls to the Branch API.
@param url  Base URL that the Branch API will use.
*/
+ (void)setAPIUrl:(NSString *)url;

/**
Sets a custom CDN base URL.
@param url Base URL for CDN endpoints.
*/
+ (void)setCDNBaseUrl:(NSString *)url;

- (NSDictionary<NSString *, NSString *> *)deviceDescription;

@end

NS_ASSUME_NONNULL_END
