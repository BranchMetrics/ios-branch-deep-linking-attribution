//
//  BranchConnectDebugRequest.h
//  Branch-TestBed
//
//  Created by Graham Mueller on 6/3/15.
//  Copyright (c) 2015 Branch Metrics. All rights reserved.
//

#import "BNCDebugRequest.h"
#import "Branch.h"

@interface BranchConnectDebugRequest : BNCDebugRequest

- (id)initWithCallback:(callbackWithStatus)callback;

@end
