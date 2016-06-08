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
            // ignore because this data is not found when sharing
            continue;
        } else if ([key hasPrefix:@"$"] || [key hasPrefix:@"~"]) {
            // Branch-specific keys
            temp[key] = dictionary[key];
        } else {
            // custom metadata
            temp[[NSString stringWithFormat:@"data.%@", key]] = dictionary[key];
        }
    }
    return temp;
}

@end
