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
        // This is a one layer deep copy
        NSDictionary *deepCopy = [[NSDictionary alloc] initWithDictionary:otherDictionary copyItems:YES];
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

#pragma mark BNCFieldDefinesObjectFromDictionary replacement methods

// checks for NSNumber or NSString representations of an int
- (int)bnc_getIntForKey:(NSString *)key {
    int returnValue = 0;
    
    id tmp = [self objectForKey:key];
    if ([tmp isKindOfClass:[NSNumber class]]) {
        NSNumber *number = (NSNumber *)tmp;
        returnValue = [number intValue];
    } else if ([tmp isKindOfClass:[NSString class]]) {
        NSString *numberAsString = (NSString *)tmp;
        returnValue = [numberAsString intValue];
    }
    
    return returnValue;
}

// checks for NSNumber or NSString representations of a double
- (double)bnc_getDoubleForKey:(NSString *)key {
    double returnValue = 0;
    
    id tmp = [self objectForKey:key];
    if ([tmp isKindOfClass:[NSNumber class]]) {
        NSNumber *number = (NSNumber *)tmp;
        returnValue = [number doubleValue];
    } else if ([tmp isKindOfClass:[NSString class]]) {
        NSString *numberAsString = (NSString *)tmp;
        returnValue = [numberAsString doubleValue];
    }
    
    return returnValue;
}

- (NSString *)bnc_getStringForKey:(NSString *)key {
    NSString *returnValue = nil;
    
    id tmp = [self objectForKey:key];
    if ([tmp isKindOfClass:[NSString class]]) {
        returnValue = (NSString *)tmp;
    }
    
    return returnValue;
}

// checks for NSNumber or NSString representations of the date
- (NSDate *)bnc_getDateForKey:(NSString *)key {
    NSDate *returnValue = nil;
    NSTimeInterval timeInterval = [self bnc_getDoubleForKey:key];
    if (timeInterval > 0) {
        returnValue = [NSDate dateWithTimeIntervalSince1970:timeInterval/1000.0];
    }
    return returnValue;
}

// checks for NSNumber or NSString representations of the decimal
- (NSDecimalNumber *)bnc_getDecimalForKey:(NSString *)key {
    NSDecimalNumber *returnValue = nil;
    
    id tmp = [self objectForKey:key];
    if ([tmp isKindOfClass:[NSNumber class]]) {
        NSNumber *number = (NSNumber *)tmp;
        
        // previous implementation converts the NSNumber to a string then to a NSDecimalNumber. lets maintain that behavior
        returnValue = [NSDecimalNumber decimalNumberWithString:[number description]];
    } else if ([tmp isKindOfClass:[NSString class]]) {
        NSString *numberAsString = (NSString *)tmp;
        returnValue = [NSDecimalNumber decimalNumberWithString:numberAsString];
    }
    
    return returnValue;
}

// checks for NSArray or NSString,
- (NSMutableArray *)bnc_getArrayForKey:(NSString *)key {
    NSMutableArray *returnValue = nil;
    
    id tmp = [self objectForKey:key];
    if ([tmp isKindOfClass:[NSArray class]]) {
        returnValue = [NSMutableArray new];
        
        NSArray *array = (NSArray *)tmp;
        for (id item in array) {
            if ([item isKindOfClass:[NSString class]]) {
                [returnValue addObject:item];
            }
        }
        
    } else if ([tmp isKindOfClass:[NSString class]]) {
        returnValue = [NSMutableArray arrayWithObject:tmp];
    } else {
        returnValue = [NSMutableArray new];
    }
    
    return returnValue;
}

// checks for NSNumber or NSString representations of the boolean
- (BOOL)bnc_getBooleanForKey:(NSString *)key {
    BOOL returnValue = NO;
    
    id tmp = [self objectForKey:key];
    if ([tmp isKindOfClass:[NSNumber class]]) {
        NSNumber *number = (NSNumber *)tmp;
        returnValue = [number boolValue];
    } else if ([tmp isKindOfClass:[NSString class]]) {
        NSString *numberAsString = (NSString *)tmp;
        returnValue = [numberAsString boolValue];
    }
    
    return returnValue;
}

@end

__attribute__((constructor)) void BNCForceNSMutableDictionaryCategoryToLoad(void) {
    //  Does nothing.  But will force the linker to include this category.
}
