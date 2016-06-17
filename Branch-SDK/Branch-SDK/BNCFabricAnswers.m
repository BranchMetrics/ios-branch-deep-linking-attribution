//
//  BNCFabricAnswers.m
//  Branch-TestBed
//
//  Created by Ahmed Nawar on 6/2/16.
//  Copyright © 2016 Branch Metrics. All rights reserved.
//

#import "BNCFabricAnswers.h"
#import "BNCPreferenceHelper.h"
#import "../Fabric/Answers.h"

@implementation BNCFabricAnswers

+ (void)sendEventWithName:(NSString *)name andAttributes:(NSDictionary *)attributes {
    ANSLogCustomEvent(name, [self prepareBranchDataForAnswers:attributes]);
}

+ (NSDictionary *)prepareBranchDataForAnswers:(NSDictionary *)dictionary {
    NSMutableDictionary *temp = [[NSMutableDictionary alloc] init];
    
    for (NSString *key in dictionary.allKeys) {
        if ([key hasPrefix:@"+"] || ([key hasPrefix:@"$"] && ![key isEqualToString:@"$identity_id"])) {
            // ignore because this data is not found on the ShareSheet
            continue;
        } else if ([dictionary[key] isKindOfClass:[NSArray class]]) {
            // flatten arrays, special treatement for ~tags
            NSString *aKey;
            if ([key hasPrefix:@"~"])
                aKey = [key substringFromIndex:1];
            else
                aKey = key;
            NSArray *valuesArray = dictionary[key];
            for (NSUInteger i = 0; i < valuesArray.count; ++i) {
                temp[[NSString stringWithFormat:@"%@.%lu", aKey, (unsigned long)i]] = valuesArray[i];
            }
        } else if ([key hasPrefix:@"~"]) {
            // strip tildes ~
            temp[[key substringFromIndex:1]] = dictionary[key];
        } else if ([key isEqualToString:@"$identity_id"]) {
            temp[@"referring_branch_identity"] = dictionary[key];
        }
    }
    
    BNCPreferenceHelper *preferenceHelper = [BNCPreferenceHelper preferenceHelper];
    temp[@"branch_identity"] = preferenceHelper.identityID;
    
    return temp;
}

@end
