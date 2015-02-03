//
//  BNCLinkCache.h
//  Branch-SDK
//
//  Created by Qinwei Gong on 1/23/15.
//  Copyright (c) 2015 Branch Metrics. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "BNCLinkData.h"

@interface BNCLinkCache : NSObject

@property (nonatomic, strong) NSMutableDictionary *cache;

- (void)setObject:(NSString *)anObject forKey:(id <NSCopying>)aKey;
- (NSString *)objectForKey:(id)aKey;

@end
