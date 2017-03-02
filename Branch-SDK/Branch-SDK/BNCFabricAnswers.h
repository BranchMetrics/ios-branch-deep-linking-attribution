//
//  BNCFabricAnswers.h
//  Branch-TestBed
//
//  Created by Ahmed Nawar on 6/2/16.
//  Copyright © 2016 Branch Metrics. All rights reserved.
//

@import Foundation;

@interface BNCFabricAnswers : NSObject

+ (void)sendEventWithName:(NSString*)name andAttributes:(NSDictionary*)attributes;
+ (NSDictionary *)prepareBranchDataForAnswers:(NSDictionary *)dictionary;

@end
