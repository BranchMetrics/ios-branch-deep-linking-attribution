//
//  BNCFabricAnswers.m
//  Branch-TestBed
//
//  Created by Ahmed Nawar on 6/2/16.
//  Copyright © 2016 Branch Metrics. All rights reserved.
//

#import "BNCFabricAnswers.h"

@implementation BNCFabricAnswers

+ (void)sendEventWithName:(NSString*)name andAttributes:(NSDictionary*)attributes {
    Class answersClass = NSClassFromString(@"Answers");
    SEL logEventSlector = NSSelectorFromString(@"logCustomEventWithName:customAttributes:");
    if (answersClass && [answersClass respondsToSelector:logEventSlector]) {
        void (*sendEventToAnswers)(id, SEL, NSString*, NSDictionary*) = (void*)[answersClass methodForSelector:logEventSlector];
        sendEventToAnswers(answersClass, logEventSlector, name, attributes);
    }
}

@end
