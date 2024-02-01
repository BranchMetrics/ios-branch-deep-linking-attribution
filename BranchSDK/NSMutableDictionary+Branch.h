//
//  NSMutableDictionary+Branch.h
//  Branch
//
//  Created by Edward Smith on 1/11/17.
//  Copyright © 2017 Branch Metrics. All rights reserved.
//

#if __has_feature(modules)
@import Foundation;
#else
#import <Foundation/Foundation.h>
#endif

void BNCForceNSMutableDictionaryCategoryToLoad(void) __attribute__((constructor));

@interface NSMutableDictionary (Branch)

- (void) bnc_safeSetObject:(id)anObject forKey:(id<NSCopying>)aKey;
- (void) bnc_safeAddEntriesFromDictionary:(NSDictionary<id<NSCopying>,id> *)otherDictionary;

// replacement methods for BNCFieldDefinesDictionaryFromSelf
- (void)bnc_addString:(NSString *)string forKey:(NSString *)key;

- (void)bnc_addDate:(NSDate *)date forKey:(NSString *)key;

- (void)bnc_addDouble:(double)number forKey:(NSString *)key;

// omits false/NO
- (void)bnc_addBoolean:(BOOL)boolean forKey:(NSString *)key;

- (void)bnc_addDecimal:(NSDecimalNumber *)decimal forKey:(NSString *)key;

// omits 0
- (void)bnc_addInteger:(NSInteger)integer forKey:(NSString *)key;

// omits empty dictionaries
- (void)bnc_addDictionary:(NSDictionary *)dict forKey:(NSString *)key;

// omits empty string array
- (void)bnc_addStringArray:(NSArray<NSString*> *)array forKey:(NSString *)key;

@end
