//
//  BranchGetAppListRequest.h
//  Branch-TestBed
//
//  Created by Graham Mueller on 5/26/15.
//  Copyright (c) 2015 Branch Metrics. All rights reserved.
//

#import "BNCServerRequest.h"
#import "Branch.h"

@interface BranchGetAppListRequest : BNCServerRequest

- (id)initWithCallback:(callbackWithList)callback;

@end
