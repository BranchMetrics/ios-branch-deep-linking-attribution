//
//  BranchServerInterface.h
//  Branch-SDK
//
//  Created by Alex Austin on 6/6/14.
//  Copyright (c) 2014 Branch Metrics. All rights reserved.
//

#import "ServerInterface.h"

static NSString *REQ_TAG_REGISTER_INSTALL = @"t_register_install";
static NSString *REQ_TAG_REGISTER_OPEN = @"t_register_open";
static NSString *REQ_TAG_COMPLETE_ACTION = @"t_complete_action";
static NSString *REQ_TAG_GET_REFERRALS = @"t_get_referrals";
static NSString *REQ_TAG_GET_CUSTOM_URL = @"t_get_custom_url";
static NSString *REQ_TAG_CREDIT_ACTION = @"t_credit_action";

@interface BranchServerInterface : ServerInterface

- (void)registerInstall;
- (void)registerOpen;

@end
