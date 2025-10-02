//
//  BNCConfig.h
//  Branch-SDK
//
//  Created by Qinwei Gong on 10/6/14.
//  Copyright (c) 2014 Branch Metrics. All rights reserved.
//

#if __has_feature(modules)
@import Foundation;
#else
#import <Foundation/Foundation.h>
#endif


FOUNDATION_EXPORT NSString * _Nonnull const BNC_SDK_VERSION;
FOUNDATION_EXPORT NSString * _Nonnull const BNC_LINK_URL;
FOUNDATION_EXPORT NSString * _Nonnull const BNC_CDN_URL;

FOUNDATION_EXPORT NSString * _Nonnull const BNC_API_URL;
FOUNDATION_EXPORT NSString * _Nonnull const BNC_SAFETRACK_API_URL;
FOUNDATION_EXPORT NSString * _Nonnull const BNC_EU_API_URL;
FOUNDATION_EXPORT NSString * _Nonnull const BNC_SAFETRACK_EU_API_URL;
