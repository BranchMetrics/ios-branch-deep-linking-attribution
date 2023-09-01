//
//  BNCRequestFactory.h
//  Branch
//
//  Created by Ernest Cho on 8/16/23.
//  Copyright © 2023 Branch, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface BNCRequestFactory : NSObject

- (instancetype)init;

// Request JSON factory methods
- (NSDictionary *)dataForInstall;
- (NSDictionary *)dataForOpen;

// BNCServerInterface appends data to request payloads
- (NSMutableDictionary *)v1dictionary:(NSMutableDictionary *)json;
- (NSMutableDictionary *)v2dictionary:(NSMutableDictionary *)json;

@end

NS_ASSUME_NONNULL_END
