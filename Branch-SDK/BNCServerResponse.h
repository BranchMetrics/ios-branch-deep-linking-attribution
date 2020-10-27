//
//  BNCServerResponse.h
//  Branch-SDK
//
//  Created by Qinwei Gong on 10/10/14.
//  Copyright (c) 2014 Branch Metrics. All rights reserved.
//

#if __has_feature(modules)
@import Foundation;
#else
#import <Foundation/Foundation.h>
#endif

@interface BNCServerResponse : NSObject
// statusCode is always populated from an NSInteger argument, so will never be null.
@property (nonatomic, strong, nonnull) NSNumber *statusCode;
@property (nonatomic, strong, nullable) id data;
@property (nonatomic, copy, nullable) NSString *requestId;
@end
