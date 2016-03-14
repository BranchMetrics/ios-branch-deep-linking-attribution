//
//  BranchGetPromoCodeRequest.h
//  Branch-TestBed
//
//  Created by Graham Mueller on 5/26/15.
//  Copyright (c) 2015 Branch Metrics. All rights reserved.
//

#import "BNCServerRequest.h"
#import "Branch.h"

@interface BranchGetPromoCodeRequest : BNCServerRequest

- (id)initWithUsageType:(BranchPromoCodeUsageType)usageType rewardLocation:(BranchPromoCodeRewardLocation)rewardLocation amount:(NSInteger)amount bucket:(NSString *)bucket prefix:(NSString *)prefix expiration:(NSDate *)expiration useOld:(BOOL)useOld callback:(callbackWithParams)callback;

@end
