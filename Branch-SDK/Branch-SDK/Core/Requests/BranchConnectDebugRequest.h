//
//  BranchConnectDebugRequest.h
//  Branch-TestBed
//
//  Created by Graham Mueller on 6/3/15.
//  Copyright (c) 2015 Branch Metrics. All rights reserved.
//

#import "BNCServerRequest.h"
#import "Branch.h"

@interface BranchConnectDebugRequest : BNCServerRequest

- (id)initWithCallback:(callbackWithStatus)callback;

@end
