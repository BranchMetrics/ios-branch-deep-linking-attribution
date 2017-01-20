//
//  NSMutableDictionary+Branch.m
//  Branch
//
//  Created by Edward Smith on 1/11/17.
//  Copyright © 2017 Branch Metrics. All rights reserved.
//


#import "NSMutableDictionary+Branch.h"


@implementation NSMutableDictionary (Branch)

- (void) bnc_safeSetObject:(id)anObject forKey:(id<NSCopying>)aKey {
	if (anObject) {
		[self setObject:anObject forKey:aKey];
	}
}

- (void) bnc_safeAddEntriesFromDictionary:(NSDictionary<id<NSCopying>,id> *)otherDictionary {
    if ([otherDictionary isKindOfClass:[NSDictionary class]]) {
        [self addEntriesFromDictionary:otherDictionary];
    }
}

@end


void ForceNSMutableDictionaryToLoad() {
    //  Does nothing.  But will force the linker to include this category.
}
