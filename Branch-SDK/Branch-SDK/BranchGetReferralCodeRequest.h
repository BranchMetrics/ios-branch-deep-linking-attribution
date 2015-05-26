//
//  BranchGetReferralCodeRequest.h
//  Branch-TestBed
//
//  Created by Graham Mueller on 5/26/15.
//  Copyright (c) 2015 Branch Metrics. All rights reserved.
//

#import "BNCServerRequest.h"
#import "Branch.h"

@interface BranchGetReferralCodeRequest : BNCServerRequest

- (id)initWithCalcType:(BranchReferralCodeCalculation)calcType location:(BranchReferralCodeLocation)location amount:(NSInteger)amount bucket:(NSString *)bucket prefix:(NSString *)prefix expiration:(NSDate *)expiration callback:(callbackWithParams)callback;

@end
