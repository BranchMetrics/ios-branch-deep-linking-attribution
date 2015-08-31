//
//  BranchValidatePromoCodeRequest.h
//  Branch-TestBed
//
//  Created by Graham Mueller on 5/26/15.
//  Copyright (c) 2015 Branch Metrics. All rights reserved.
//

#import "BNCServerRequest.h"
#import "Branch.h"

@interface BranchValidatePromoCodeRequest : BNCServerRequest

- (id)initWithCode:(NSString *)code useOld:(BOOL)useOld callback:(callbackWithParams)callback;

@end
