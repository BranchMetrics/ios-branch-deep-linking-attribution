//
//  NSMutableDictionary+Branch.m
//  Branch
//
//  Created by Edward Smith on 1/11/17.
//  Copyright © 2017 Branch Metrics. All rights reserved.
//


#import "NSMutableDictionary+Branch.h"


@implementation NSMutableDictionary (Branch)

- (void)bnc_safeSetObject:(id)anObject forKey:(id<NSCopying>)aKey {
	if (anObject && aKey) {
		[self setObject:anObject forKey:aKey];
	}
}

- (void)bnc_safeAddEntriesFromDictionary:(NSDictionary<id<NSCopying>,id> *)otherDictionary {
    if ([otherDictionary isKindOfClass:[NSDictionary class]]) {
        NSDictionary *deepCopy =
            [[NSDictionary alloc]
                initWithDictionary:otherDictionary
                copyItems:YES];
        [self addEntriesFromDictionary:deepCopy];
    }
}

#pragma mark BNCFieldDefinesDictionaryFromSelf replacement methods

- (void)bnc_addString:(NSString *)string forKey:(NSString *)key {
    if (string && string.length && key) {
        [self setObject:string forKey:key];
    }
}

- (void)bnc_addDate:(NSDate *)date forKey:(NSString *)key {
    if (date && key) {
        NSTimeInterval t = date.timeIntervalSince1970;
        NSNumber *tmp = [NSNumber numberWithLongLong:(long long)(t*1000.0)];
        [self setObject:tmp forKey:key];
    }
}

- (void)bnc_addDouble:(double)number forKey:(NSString *)key {
    if (number != 0.0 && key) {
        NSNumber *tmp = [NSNumber numberWithDouble:number];
        [self setObject:tmp forKey:key];
    }
}

// omits false/NO
- (void)bnc_addBoolean:(BOOL)boolean forKey:(NSString *)key {
    if (boolean && key) {
        NSNumber *tmp = [NSNumber numberWithBool:boolean];
        [self setObject:tmp forKey:key];
    }
}

- (void)bnc_addDecimal:(NSDecimalNumber *)decimal forKey:(NSString *)key {
    if (decimal && key) {
        [self setObject:decimal forKey:key];
    }
}

// omits 0
- (void)bnc_addInteger:(NSInteger)integer forKey:(NSString *)key {
    if (integer != 0) {
        NSNumber *tmp = [NSNumber numberWithInteger:integer];
        [self setObject:tmp forKey:key];
    }
}

// omits empty dictionaries
- (void)bnc_addDictionary:(NSDictionary *)dict forKey:(NSString *)key {
    if (dict.count) {
        [self setObject:dict forKey:key];
    }
}

// omits empty string array
- (void)bnc_addStringArray:(NSArray<NSString*> *)array forKey:(NSString *)key {
    if (array.count) {
        [self setObject:array forKey:key];
    }
}

@end


__attribute__((constructor)) void BNCForceNSMutableDictionaryCategoryToLoad(void) {
    //  Does nothing.  But will force the linker to include this category.
}
