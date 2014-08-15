//
//  BranchServerInterface.m
//  Branch-SDK
//
//  Created by Alex Austin on 6/6/14.
//  Copyright (c) 2014 Branch Metrics. All rights reserved.
//

#import "BranchServerInterface.h"
#import "SystemObserver.h"
#import "PreferenceHelper.h"

@implementation BranchServerInterface

- (void)registerInstall {
    NSMutableDictionary *post = [[NSMutableDictionary alloc] init];
    
    [post setObject:[PreferenceHelper getAppKey] forKey:@"app_id"];
    if (![[PreferenceHelper getLinkClickID] isEqualToString:NO_STRING_VALUE])
        [post setObject:@"link_click_id" forKey:[PreferenceHelper getLinkClickID]];
    if ([SystemObserver getUniqueHardwareId]) [post setObject:[SystemObserver getUniqueHardwareId] forKey:@"hardware_id"];
    if ([SystemObserver getAppVersion]) [post setObject:[SystemObserver getAppVersion] forKey:@"app_version"];
    if ([SystemObserver getCarrier]) [post setObject:[SystemObserver getCarrier] forKey:@"carrier"];
    if ([SystemObserver getBrand]) [post setObject:[SystemObserver getBrand] forKey:@"brand"];
    if ([SystemObserver getModel]) [post setObject:[SystemObserver getModel] forKey:@"model"];
    if ([SystemObserver getOS]) [post setObject:[SystemObserver getOS] forKey:@"os"];
    if ([SystemObserver getOSVersion]) [post setObject:[SystemObserver getOSVersion] forKey:@"os_version"];
    if ([SystemObserver getScreenWidth]) [post setObject:[SystemObserver getScreenWidth] forKey:@"screen_width"];
    if ([SystemObserver getScreenHeight]) [post setObject:[SystemObserver getScreenHeight] forKey:@"screen_height"];
    if ([SystemObserver getURIScheme]) [post setObject:[SystemObserver getURIScheme] forKey:@"uri_scheme"];
    if (![[PreferenceHelper getLinkClickIdentifier] isEqualToString:NO_STRING_VALUE]) [post setObject:[PreferenceHelper getLinkClickIdentifier] forKey:@"link_identifier"];
    [post setObject:[NSNumber numberWithInteger:[PreferenceHelper getIsReferrable]] forKey:@"is_referrable"];
    
    [self postRequestAsync:post url:[[PreferenceHelper getAPIBaseURL] stringByAppendingString:@"v1/install"] andTag:REQ_TAG_REGISTER_INSTALL];
}

- (void)registerOpen {
    NSMutableDictionary *post = [[NSMutableDictionary alloc] init];
    
    [post setObject:[PreferenceHelper getAppKey] forKey:@"app_id"];
    [post setObject:[PreferenceHelper getDeviceFingerprintID] forKey:@"device_fingerprint_id"];
    [post setObject:[PreferenceHelper getIdentityID] forKey:@"identity_id"];
    if ([SystemObserver getAppVersion]) [post setObject:[SystemObserver getAppVersion] forKey:@"app_version"];
    if ([SystemObserver getOS]) [post setObject:[SystemObserver getOS] forKey:@"os"];
    if ([SystemObserver getOSVersion]) [post setObject:[SystemObserver getOSVersion] forKey:@"os_version"];
    if ([SystemObserver getURIScheme]) [post setObject:[SystemObserver getURIScheme] forKey:@"uri_scheme"];
    [post setObject:[NSNumber numberWithInteger:[PreferenceHelper getIsReferrable]] forKey:@"is_referrable"];
    if (![[PreferenceHelper getLinkClickIdentifier] isEqualToString:NO_STRING_VALUE]) [post setObject:[PreferenceHelper getLinkClickIdentifier] forKey:@"link_identifier"];
    
    [self postRequestAsync:post url:[[PreferenceHelper getAPIBaseURL] stringByAppendingString:@"v1/open"] andTag:REQ_TAG_REGISTER_OPEN];
}

- (void)registerClose {
    NSMutableDictionary *post = [[NSMutableDictionary alloc] init];
    
    [post setObject:[PreferenceHelper getAppKey] forKey:@"app_id"];
    [post setObject:[PreferenceHelper getSessionID] forKey:@"session_id"];
    
    [self postRequestAsync:post url:[[PreferenceHelper getAPIBaseURL] stringByAppendingString:@"v1/close"] andTag:REQ_TAG_REGISTER_CLOSE];
}

- (void)userCompletedAction:(NSDictionary *)post {
    [self postRequestAsync:post url:[[PreferenceHelper getAPIBaseURL] stringByAppendingString:@"v1/event"] andTag:REQ_TAG_COMPLETE_ACTION];
}

- (void)getReferralCounts {
    [self getRequestAsync:[[NSDictionary alloc] init] url:[[[PreferenceHelper getAPIBaseURL] stringByAppendingString:@"v1/referrals/"] stringByAppendingString:[PreferenceHelper getIdentityID]] andTag:REQ_TAG_GET_REFERRAL_COUNTS];
}

- (void)getRewards {
    [self getRequestAsync:[[NSDictionary alloc] init] url:[[[PreferenceHelper getAPIBaseURL] stringByAppendingString:@"v1/credits/"] stringByAppendingString:[PreferenceHelper getIdentityID]] andTag:REQ_TAG_GET_REWARDS];
}

- (void)redeemRewards:(NSDictionary *)post {
    [self postRequestAsync:post url:[[PreferenceHelper getAPIBaseURL] stringByAppendingString:@"v1/redeem"] andTag:REQ_TAG_REDEEM_REWARDS];
}

- (void)createCustomUrl:(NSDictionary *)post {
    [self postRequestAsync:post url:[[PreferenceHelper getAPIBaseURL] stringByAppendingString:@"v1/url"] andTag:REQ_TAG_GET_CUSTOM_URL];
}

- (void)identifyUser:(NSDictionary *)post {
    [self postRequestAsync:post url:[[PreferenceHelper getAPIBaseURL] stringByAppendingString:@"v1/profile"] andTag:REQ_TAG_IDENTIFY];
}

- (void)logoutUser:(NSDictionary *)post {
    [self postRequestAsync:post url:[[PreferenceHelper getAPIBaseURL] stringByAppendingString:@"v1/logout"] andTag:REQ_TAG_LOGOUT];
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
    [self postRequestAsync:post url:[[PreferenceHelper getAPIBaseURL] stringByAppendingString:@"v1/profile"] andTag:REQ_TAG_PROFILE_DATA];
}

@end
