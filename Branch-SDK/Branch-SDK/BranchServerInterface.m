//
//  BranchServerInterface.m
//  Branch-SDK
//
//  Created by Alex Austin on 6/6/14.
//  Copyright (c) 2014 Branch Metrics. All rights reserved.
//

#import "BranchServerInterface.h"
#import "BNCSystemObserver.h"
#import "BNCPreferenceHelper.h"

@implementation BranchServerInterface

- (void)registerInstall:(BOOL)debug {
    NSMutableDictionary *post = [[NSMutableDictionary alloc] init];
    
    [post setObject:[BNCPreferenceHelper getAppKey] forKey:@"app_id"];
    BOOL isRealHardwareId;
    NSString *hardwareId = [BNCSystemObserver getUniqueHardwareId:&isRealHardwareId];
    if (hardwareId) {
        [post setObject:hardwareId forKey:@"hardware_id"];
        [post setObject:[NSNumber numberWithBool:isRealHardwareId] forKey:@"is_hardware_id_real"];
    }
    if ([BNCSystemObserver getAppVersion]) [post setObject:[BNCSystemObserver getAppVersion] forKey:@"app_version"];
    if ([BNCSystemObserver getCarrier]) [post setObject:[BNCSystemObserver getCarrier] forKey:@"carrier"];
    if ([BNCSystemObserver getBrand]) [post setObject:[BNCSystemObserver getBrand] forKey:@"brand"];
    if ([BNCSystemObserver getModel]) [post setObject:[BNCSystemObserver getModel] forKey:@"model"];
    if ([BNCSystemObserver getOS]) [post setObject:[BNCSystemObserver getOS] forKey:@"os"];
    if ([BNCSystemObserver getOSVersion]) [post setObject:[BNCSystemObserver getOSVersion] forKey:@"os_version"];
    if ([BNCSystemObserver getScreenWidth]) [post setObject:[BNCSystemObserver getScreenWidth] forKey:@"screen_width"];
    if ([BNCSystemObserver getScreenHeight]) [post setObject:[BNCSystemObserver getScreenHeight] forKey:@"screen_height"];
    if ([BNCSystemObserver getURIScheme]) [post setObject:[BNCSystemObserver getURIScheme] forKey:@"uri_scheme"];
    if ([BNCSystemObserver getUpdateState]) [post setObject:[BNCSystemObserver getUpdateState] forKeyedSubscript:@"update"];
    if (![[BNCPreferenceHelper getLinkClickIdentifier] isEqualToString:NO_STRING_VALUE]) [post setObject:[BNCPreferenceHelper getLinkClickIdentifier] forKey:@"link_identifier"];
    [post setObject:[NSNumber numberWithInteger:[BNCPreferenceHelper getIsReferrable]] forKey:@"is_referrable"];
    [post setObject:[NSNumber numberWithBool:debug] forKey:@"debug"];
    
    [self postRequestAsync:post url:[[BNCPreferenceHelper getAPIURL] stringByAppendingString:@"install"] andTag:REQ_TAG_REGISTER_INSTALL];
}

- (void)registerOpen:(BOOL)debug {
    NSMutableDictionary *post = [[NSMutableDictionary alloc] init];
    
    [post setObject:[BNCPreferenceHelper getAppKey] forKey:@"app_id"];
    [post setObject:[BNCPreferenceHelper getDeviceFingerprintID] forKey:@"device_fingerprint_id"];
    [post setObject:[BNCPreferenceHelper getIdentityID] forKey:@"identity_id"];
    if ([BNCSystemObserver getAppVersion]) [post setObject:[BNCSystemObserver getAppVersion] forKey:@"app_version"];
    if ([BNCSystemObserver getOS]) [post setObject:[BNCSystemObserver getOS] forKey:@"os"];
    if ([BNCSystemObserver getOSVersion]) [post setObject:[BNCSystemObserver getOSVersion] forKey:@"os_version"];
    if ([BNCSystemObserver getURIScheme]) [post setObject:[BNCSystemObserver getURIScheme] forKey:@"uri_scheme"];
    [post setObject:[NSNumber numberWithInteger:[BNCPreferenceHelper getIsReferrable]] forKey:@"is_referrable"];
    [post setObject:[NSNumber numberWithBool:debug] forKey:@"debug"];
    if (![[BNCPreferenceHelper getLinkClickIdentifier] isEqualToString:NO_STRING_VALUE]) [post setObject:[BNCPreferenceHelper getLinkClickIdentifier] forKey:@"link_identifier"];
    
    [self postRequestAsync:post url:[[BNCPreferenceHelper getAPIURL] stringByAppendingString:@"open"] andTag:REQ_TAG_REGISTER_OPEN];
}

- (void)registerClose {
    NSMutableDictionary *post = [[NSMutableDictionary alloc] init];
    
    [post setObject:[BNCPreferenceHelper getAppKey] forKey:@"app_id"];
    [post setObject:[BNCPreferenceHelper getSessionID] forKey:@"session_id"];
    
    [self postRequestAsync:post url:[[BNCPreferenceHelper getAPIURL] stringByAppendingString:@"close"] andTag:REQ_TAG_REGISTER_CLOSE];
}

- (void)userCompletedAction:(NSDictionary *)post {
    [self postRequestAsync:post url:[[BNCPreferenceHelper getAPIURL] stringByAppendingString:@"event"] andTag:REQ_TAG_COMPLETE_ACTION];
}

- (void)getReferralCounts {
    [self getRequestAsync:nil url:[[[BNCPreferenceHelper getAPIURL] stringByAppendingString:@"referrals/"] stringByAppendingString:[BNCPreferenceHelper getIdentityID]] andTag:REQ_TAG_GET_REFERRAL_COUNTS];
}

- (void)getRewards {
    [self getRequestAsync:nil url:[[[BNCPreferenceHelper getAPIURL] stringByAppendingString:@"credits/"] stringByAppendingString:[BNCPreferenceHelper getIdentityID]] andTag:REQ_TAG_GET_REWARDS];
}

- (void)redeemRewards:(NSDictionary *)post {
    [self postRequestAsync:post url:[[BNCPreferenceHelper getAPIURL] stringByAppendingString:@"redeem"] andTag:REQ_TAG_REDEEM_REWARDS];
}

- (void)getCreditHistory:(NSDictionary *)post {
    [self postRequestAsync:post url:[[BNCPreferenceHelper getAPIURL] stringByAppendingString:@"credithistory"] andTag:REQ_TAG_GET_REWARD_HISTORY];
}

- (void)createCustomUrl:(NSDictionary *)post {
    [self postRequestAsync:post url:[[BNCPreferenceHelper getAPIURL] stringByAppendingString:@"url"] andTag:REQ_TAG_GET_CUSTOM_URL];
}

- (void)identifyUser:(NSDictionary *)post {
    [self postRequestAsync:post url:[[BNCPreferenceHelper getAPIURL] stringByAppendingString:@"profile"] andTag:REQ_TAG_IDENTIFY];
}

- (void)logoutUser:(NSDictionary *)post {
    [self postRequestAsync:post url:[[BNCPreferenceHelper getAPIURL] stringByAppendingString:@"logout"] andTag:REQ_TAG_LOGOUT];
}

- (void)addProfileParams:(NSDictionary *)post withParams:(NSDictionary *)params {
    NSMutableDictionary *newPost = [post mutableCopy];
    [newPost setObject:params forKey:@"add"];
    [self updateProfileParams:newPost];
}

- (void)setProfileParams:(NSDictionary *)post withParams:(NSDictionary *)params {
    NSMutableDictionary *newPost = [post mutableCopy];
    [newPost setObject:params forKey:@"set"];
    [self updateProfileParams:newPost];
}

- (void)appendProfileParams:(NSDictionary *)post withParams:(NSDictionary *)params {
    NSMutableDictionary *newPost = [post mutableCopy];
    [newPost setObject:params forKey:@"append"];
    [self updateProfileParams:newPost];
}

- (void)unionProfileParams:(NSDictionary *)post withParams:(NSDictionary *)params {
    NSMutableDictionary *newPost = [post mutableCopy];
    [newPost setObject:params forKey:@"union"];
    [self updateProfileParams:newPost];
}
- (void)updateProfileParams:(NSDictionary *)post {
    [self postRequestAsync:post url:[[BNCPreferenceHelper getAPIURL] stringByAppendingString:@"profile"] andTag:REQ_TAG_PROFILE_DATA];
}

@end
