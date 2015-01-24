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
    for (id key in [self.cache allKeys]) {
        BNCLinkData *data = (BNCLinkData *)key;
        if ([data hash] == [aKey hash]) {
            return;
        }
    }
    [self.cache setObject:anObject forKey:aKey];
}

- (NSString *)objectForKey:(BNCLinkData *)aKey {
    for (id key in [self.cache allKeys]) {
        BNCLinkData *data = (BNCLinkData *)key;
        if ([data hash] == [aKey hash]) {
            return [self.cache objectForKey:data];
        }
    }
    return nil;
}

@end
