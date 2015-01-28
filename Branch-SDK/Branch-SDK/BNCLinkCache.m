//
//  BNCLinkCache.m
//  Branch-SDK
//
//  Created by Qinwei Gong on 1/23/15.
//  Copyright (c) 2015 Branch Metrics. All rights reserved.
//

#import "BNCLinkCache.h"

@implementation BNCLinkCache

- (id)init {
    self = [super init];
    if (self) {
        self.cache = [[NSMutableDictionary alloc] init];
    }
    return self;
}

- (void)setObject:(NSString *)anObject forKey:(BNCLinkData *)aKey {
    [self.cache setObject:anObject forKey:[NSNumber numberWithUnsignedInteger:[aKey hash]]];
}

- (NSString *)objectForKey:(BNCLinkData *)aKey {
    return [self.cache objectForKey:[NSNumber numberWithUnsignedInteger:[aKey hash]]];
}

@end
