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

// Replacement methods for BNCFieldDefinesDictionaryFromSelf

- (void) bnc_safeSetObject:(id)anObject forKey:(id<NSCopying>)aKey;
- (void) bnc_safeAddEntriesFromDictionary:(NSDictionary<id<NSCopying>,id> *)otherDictionary;

- (void)bnc_addString:(NSString *)string forKey:(NSString *)key;

- (void)bnc_addDate:(NSDate *)date forKey:(NSString *)key;

- (void)bnc_addDouble:(double)number forKey:(NSString *)key;

- (void)bnc_addBoolean:(BOOL)boolean forKey:(NSString *)key;

- (void)bnc_addDecimal:(NSDecimalNumber *)decimal forKey:(NSString *)key;

- (void)bnc_addInteger:(NSInteger)integer forKey:(NSString *)key;

- (void)bnc_addDictionary:(NSDictionary *)dict forKey:(NSString *)key;

- (void)bnc_addStringArray:(NSArray<NSString*> *)array forKey:(NSString *)key;

// Replacement methods for BNCFieldDefinesObjectFromDictionary
// These are not 1 to 1, as the previous C defines had access to the calling object

- (int)bnc_getIntForKey:(NSString *)key;

- (double)bnc_getDoubleForKey:(NSString *)key;

- (NSString *)bnc_getStringForKey:(NSString *)key;

- (NSDate *)bnc_getDateForKey:(NSString *)key;

- (NSDecimalNumber *)bnc_getDecimalForKey:(NSString *)key;

- (NSMutableArray *)bnc_getArrayForKey:(NSString *)key;

- (BOOL)bnc_getBooleanForKey:(NSString *)key;

@end
