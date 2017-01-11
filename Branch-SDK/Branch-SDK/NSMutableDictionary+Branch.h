//
//  NSMutableDictionary+Branch.h
//  Branch
//
//  Created by Edward Smith on 1/11/17.
//  Copyright © 2017 Branch Metrics. All rights reserved.
//


#import <Foundation/Foundation.h>


@interface NSMutableDictionary (Branch)

- (void) bnc_safeSetObject:(id)anObject forKey:(id<NSCopying>)aKey;

@end
