//
//  PreferenceHelper.m
//  Branch-SDK
//
//  Created by Alex Austin on 6/6/14.
//  Copyright (c) 2014 Branch Metrics. All rights reserved.
//

#import "PreferenceHelper.h"


static NSString *KEY_APP_KEY = @"bnc_app_key";

static NSString *KEY_USER_ID = @"bnc_user_id";
static NSString *KEY_DEVICE_ID = @"bnc_device_id";
static NSString *KEY_LINK_CLICK_ID = @"bnc_link_click_id";
static NSString *KEY_APP_INSTALL_ID = @"bnc_app_install_id";
static NSString *KEY_SESSION_PARAMS = @"bnc_session_params";
static NSString *KEY_USER_URL = @"bnc_user_url";

static NSString *KEY_CREDIT_BASE = @"bnc_credit_base_";
static NSString *KEY_TOTAL_BASE = @"bnc_total_base_";
static NSString *KEY_BALANCE_BASE = @"bnc_balance_base_";

@implementation PreferenceHelper

+ (NSString *)getAPIBaseURL {
    return @"http://api.branchmetrics.io/";
}

+ (NSString *)getShortUrl {
    return @"bnc.lt/";
}

// PREFERENCE STORAGE

+ (void)setAppKey:(NSString *)appKey {
    [PreferenceHelper writeObjectToDefaults:KEY_APP_KEY value:appKey];
}

+ (NSString *)getAppKey {
    NSString *ret = (NSString *)[PreferenceHelper readObjectFromDefaults:KEY_APP_KEY];
    if (!ret)
        ret = NO_STRING_VALUE;
    return ret;
}

+ (void)setUserID:(NSString *)userId {
    [PreferenceHelper writeObjectToDefaults:KEY_USER_ID value:userId];
}

+ (NSString *)getUserID {
    NSString *ret = (NSString *)[PreferenceHelper readObjectFromDefaults:KEY_USER_ID];
    if (!ret)
        ret = NO_STRING_VALUE;
    return ret;
}

+ (void)setAppInstallID:(NSString *)appInstallId {
    [PreferenceHelper writeObjectToDefaults:KEY_APP_INSTALL_ID value:appInstallId];
}

+ (NSString *)getAppInstallID {
    NSString *ret = (NSString *)[PreferenceHelper readObjectFromDefaults:KEY_APP_INSTALL_ID];
    if (!ret)
        ret = NO_STRING_VALUE;
    return ret;
}

+ (void)setDeviceID:(NSString *)deviceId {
    [PreferenceHelper writeObjectToDefaults:KEY_DEVICE_ID value:deviceId];
}

+ (NSString *)getDeviceID {
    NSString *ret = (NSString *)[PreferenceHelper readObjectFromDefaults:KEY_DEVICE_ID];
    if (!ret)
        ret = NO_STRING_VALUE;
    return ret;
}

+ (void)setLinkClickID:(NSString *)linkClickId {
    [PreferenceHelper writeObjectToDefaults:KEY_LINK_CLICK_ID value:linkClickId];
}

+ (NSString *)getLinkClickID {
    NSString *ret = (NSString *)[PreferenceHelper readObjectFromDefaults:KEY_LINK_CLICK_ID];
    if (!ret)
        ret = NO_STRING_VALUE;
    return ret;
}

+ (void)setSessionParams:(NSString *)sessionParams {
    [PreferenceHelper writeObjectToDefaults:KEY_SESSION_PARAMS value:sessionParams];
}

+ (NSString *)getSessionParams {
    NSString *ret = (NSString *)[PreferenceHelper readObjectFromDefaults:KEY_SESSION_PARAMS];
    if (!ret)
        ret = NO_STRING_VALUE;
    return ret;
}

+ (void)setUserURL:(NSString *)userUrl {
    [PreferenceHelper writeObjectToDefaults:KEY_USER_URL value:userUrl];
}

+ (NSString *)getUserURL {
    NSString *ret = (NSString *)[PreferenceHelper readObjectFromDefaults:KEY_USER_URL];
    if (!ret)
        ret = NO_STRING_VALUE;
    return ret;
}

// COUNT STORAGE


+ (void)setActionTotalCount:(NSString *)action withCount:(NSInteger)count {
    [PreferenceHelper writeIntegerToDefaults:[KEY_TOTAL_BASE stringByAppendingString:action] value:count];
}

+ (void)setActionBalanceCount:(NSString *)action withCount:(NSInteger)count {
    [PreferenceHelper writeIntegerToDefaults:[KEY_BALANCE_BASE stringByAppendingString:action] value:count];
}

+ (void)setActionCreditCount:(NSString *)action withCount:(NSInteger)count {
    [PreferenceHelper writeIntegerToDefaults:[KEY_CREDIT_BASE stringByAppendingString:action] value:count];
}

+ (NSInteger)getActionTotalCount:(NSString *)action {
    return [PreferenceHelper readIntegerFromDefaults:[KEY_TOTAL_BASE stringByAppendingString:action]];
}

+ (NSInteger)getActionBalanceCount:(NSString *)action {
    return [PreferenceHelper readIntegerFromDefaults:[KEY_BALANCE_BASE stringByAppendingString:action]];
}

+ (NSInteger)getActionCreditCount:(NSString *)action {
    return [PreferenceHelper readIntegerFromDefaults:[KEY_CREDIT_BASE stringByAppendingString:action]];
}

// GENERIC FUNCS

+ (void)writeIntegerToDefaults:(NSString *)key value:(NSInteger)value
{
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [defaults setInteger:value forKey:key];
    [defaults synchronize];
}

+ (void)writeBoolToDefaults:(NSString *)key value:(BOOL)value
{
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [defaults setBool:value forKey:key];
    [defaults synchronize];
}

+ (void)writeObjectToDefaults:(NSString *)key value:(NSObject *)value
{
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [defaults setObject:value forKey:key];
    [defaults synchronize];
}

+ (NSObject *)readObjectFromDefaults:(NSString *)key
{
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    NSObject *obj = [defaults objectForKey:key];
    return obj;
}

+ (BOOL)readBoolFromDefaults:(NSString *)key {
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    BOOL boo = [defaults boolForKey:key];
    return boo;
}

+ (NSInteger)readIntegerFromDefaults:(NSString *)key
{
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    NSInteger integ = [defaults integerForKey:key];
    return integ;
}


@end
