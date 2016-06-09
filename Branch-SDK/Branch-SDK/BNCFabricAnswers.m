//
//  BNCFabricAnswers.m
//  Branch-TestBed
//
//  Created by Ahmed Nawar on 6/2/16.
//  Copyright © 2016 Branch Metrics. All rights reserved.
//

#import "BNCFabricAnswers.h"
#import "Answers.h"

@implementation BNCFabricAnswers

+ (void)sendEventWithName:(NSString *)name andAttributes:(NSDictionary *)attributes {
    ANSLogCustomEvent(name, [self prepareBranchDataForAnswers:attributes]);
    
}

+ (NSDictionary *)prepareBranchDataForAnswers:(NSDictionary *)dictionary {
    NSMutableDictionary *temp = [[NSMutableDictionary alloc] init];
    
    for (NSString *key in dictionary.allKeys) {
        if ([key hasPrefix:@"+"]) {
            // ignore because this data is not found on the ShareSheet
            continue;
        } else if ([key hasPrefix:@"~"]) {
            // strip tildes ~
            temp[[key substringFromIndex:1]] = dictionary[key];
        } else {
            // link data
            temp[[NSString stringWithFormat:@"data.%@", key]] = dictionary[key];
        }
        
        //flatten arrays, separate if statement because they are caught in one of the prefix conditionals
        if ([dictionary[key] isKindOfClass:[NSArray class]]) {
            // special treatement for ~tags
            NSString *aKey;
            if ([key hasPrefix:@"~"])
                aKey = [key substringFromIndex:1];
            else
                aKey = key;
            NSArray *valuesArray = dictionary[key];
            for (NSUInteger i = 0; i < valuesArray.count; ++i) {
                temp[[NSString stringWithFormat:@"%@.%lu", aKey, i + 1]] = valuesArray[i];
            }
        }
    }
    return temp;
}

@end
