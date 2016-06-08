//
//  BNCFabricAnswers.h
//  Branch-TestBed
//
//  Created by Ahmed Nawar on 6/2/16.
//  Copyright © 2016 Branch Metrics. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "BranchUniversalObject.h"
#import "BranchLinkProperties.h"

@interface BNCFabricAnswers : NSObject

+ (void)sendEventWithName:(NSString*)name andAttributes:(NSDictionary*)attributes;
+ (void)prepareBranchDataForEvent:(NSString *)name andData:(NSDictionary *)dictionary;
+ (void)prepareBranchDataForEvent:(NSString *)name andBUO:(BranchUniversalObject *)buo andLP:(BranchLinkProperties *)lp;


@end
