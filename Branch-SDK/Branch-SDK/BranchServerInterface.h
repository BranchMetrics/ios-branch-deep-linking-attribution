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
static NSString *REQ_TAG_REGISTER_CLOSE = @"t_register_close";
static NSString *REQ_TAG_COMPLETE_ACTION = @"t_complete_action";
static NSString *REQ_TAG_GET_REFERRAL_COUNTS = @"t_get_referral_counts";
static NSString *REQ_TAG_GET_REWARDS = @"t_get_rewards";
static NSString *REQ_TAG_REDEEM_REWARDS = @"t_redeem_rewards";
static NSString *REQ_TAG_GET_CUSTOM_URL = @"t_get_custom_url";
static NSString *REQ_TAG_IDENTIFY = @"t_identify_user";
static NSString *REQ_TAG_LOGOUT = @"t_logout";
static NSString *REQ_TAG_PROFILE_DATA = @"t_profile_data";

@interface BranchServerInterface : ServerInterface

- (void)registerInstall;
- (void)registerOpen;
- (void)registerClose;
- (void)getReferralCounts;
- (void)userCompletedAction:(NSDictionary *)post;
- (void)getRewards;
- (void)redeemRewards:(NSDictionary *)post;
- (void)createCustomUrl:(NSDictionary *)post;
- (void)identifyUser:(NSDictionary *)post;
- (void)logoutUser:(NSDictionary *)post;
- (void)addProfileParams:(NSDictionary *)post withParams:(NSDictionary *)params;
- (void)setProfileParams:(NSDictionary *)post withParams:(NSDictionary *)params;
- (void)appendProfileParams:(NSDictionary *)post withParams:(NSDictionary *)params;
- (void)unionProfileParams:(NSDictionary *)post withParams:(NSDictionary *)params;

@end
