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
    ANSLogCustomEvent(name, attributes);
//    Class answersClass = NSClassFromString(@"Answers");
//    SEL logEventSlector = NSSelectorFromString(@"logCustomEventWithName:customAttributes:");
//    if (answersClass && [answersClass respondsToSelector:logEventSlector]) {
//        void (*sendEventToAnswers)(id, SEL, NSString*, NSDictionary*) = (void*)[answersClass methodForSelector:logEventSlector];
//        sendEventToAnswers(answersClass, logEventSlector, name, attributes);
//    }
}

+ (void)prepareBranchDataForAnswers:(NSDictionary *)dictionary {
    NSMutableDictionary *temp = [[NSMutableDictionary alloc] init];
    
    for (NSString *key in dictionary.allKeys) {
        // Branch-specific keys
        if ([key hasPrefix:@"$"] || [key hasPrefix:@"~"]) {
            temp[key] = dictionary[key];
        } else if ([key hasPrefix:@"+"]) {
            // ignore because this data is not found when sharing
            continue;
        } else {
            // custom metadata
            temp[[NSString stringWithFormat:@"data.%@", key]] = dictionary[key];
        }
    }
    NSLog(@"prepared dict %@", temp);
}

+ (void)prepareBranchDataForEvent:(NSString *)name andBUO:(BranchUniversalObject *)buo andLP:(BranchLinkProperties *)lp {
//
    
}

@end
