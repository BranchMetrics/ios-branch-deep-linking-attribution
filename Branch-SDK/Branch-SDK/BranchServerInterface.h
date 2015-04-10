//
//  BranchServerInterface.h
//  Branch-SDK
//
//  Created by Alex Austin on 6/6/14.
//  Copyright (c) 2014 Branch Metrics. All rights reserved.
//

#import "BNCServerInterface.h"
#import "BNCServerRequest.h"

static NSString *REQ_TAG_REGISTER_INSTALL = @"t_register_install";
static NSString *REQ_TAG_REGISTER_OPEN = @"t_register_open";
static NSString *REQ_TAG_REGISTER_CLOSE = @"t_register_close";
static NSString *REQ_TAG_COMPLETE_ACTION = @"t_complete_action";
static NSString *REQ_TAG_GET_REFERRAL_COUNTS = @"t_get_referral_counts";
static NSString *REQ_TAG_GET_REWARD_HISTORY = @"t_get_reward_history";
static NSString *REQ_TAG_GET_REWARDS = @"t_get_rewards";
static NSString *REQ_TAG_REDEEM_REWARDS = @"t_redeem_rewards";
static NSString *REQ_TAG_GET_CUSTOM_URL = @"t_get_custom_url";
static NSString *REQ_TAG_IDENTIFY = @"t_identify_user";
static NSString *REQ_TAG_LOGOUT = @"t_logout";
static NSString *REQ_TAG_PROFILE_DATA = @"t_profile_data";
static NSString *REQ_TAG_GET_REFERRAL_CODE = @"t_get_referral_code";
static NSString *REQ_TAG_VALIDATE_REFERRAL_CODE = @"t_validate_referral_code";
static NSString *REQ_TAG_APPLY_REFERRAL_CODE = @"t_apply_referral_code";
static NSString *REQ_TAG_UPLOAD_LIST_OF_APPS = @"t_upload_list_of_apps";
static NSString *REQ_TAG_GET_LIST_OF_APPS = @"t_get_list_of_apps";

@interface BranchServerInterface : BNCServerInterface

- (void)registerInstall:(BOOL)debug callback:(BNCServerCallback)callback;
- (void)registerOpen:(BOOL)debug callback:(BNCServerCallback)callback;
- (void)registerCloseWithCallback:(BNCServerCallback)callback;
- (void)getReferralCountsWithCallback:(BNCServerCallback)callback;
- (void)getCreditHistory:(NSDictionary *)query callback:(BNCServerCallback)callback;
- (void)userCompletedAction:(NSDictionary *)post callback:(BNCServerCallback)callback;
- (void)getRewardsWithCallback:(BNCServerCallback)callback;
- (void)redeemRewards:(NSDictionary *)post callback:(BNCServerCallback)callback;
- (void)createCustomUrl:(BNCServerRequest *)post callback:(BNCServerCallback)callback;
- (void)identifyUser:(NSDictionary *)post callback:(BNCServerCallback)callback;
- (void)logoutUser:(NSDictionary *)post callback:(BNCServerCallback)callback;
- (void)addProfileParams:(NSDictionary *)post withParams:(NSDictionary *)params callback:(BNCServerCallback)callback;
- (void)setProfileParams:(NSDictionary *)post withParams:(NSDictionary *)params callback:(BNCServerCallback)callback;
- (void)appendProfileParams:(NSDictionary *)post withParams:(NSDictionary *)params callback:(BNCServerCallback)callback;
- (void)unionProfileParams:(NSDictionary *)post withParams:(NSDictionary *)params callback:(BNCServerCallback)callback;
- (void)getReferralCode:(NSDictionary *)post callback:(BNCServerCallback)callback;
- (void)validateReferralCode:(NSDictionary *)post callback:(BNCServerCallback)callback;
- (void)applyReferralCode:(NSDictionary *)post callback:(BNCServerCallback)callback;
- (void)uploadListOfApps:(NSDictionary *)post callback:(BNCServerCallback)callback;
- (void)retrieveAppsToCheckWithCallback:(BNCServerCallback)callback;

- (void)connectToDebugWithCallback:(BNCServerCallback)callback;
- (void)sendLog:(NSString *)log callback:(BNCServerCallback)callback;
- (void)sendScreenshot:(NSData *)data callback:(BNCServerCallback)callback;
- (void)disconnectFromDebugWithCallback:(BNCServerCallback)callback;

- (BNCServerResponse *)createCustomUrl:(BNCServerRequest *)req;

@end
