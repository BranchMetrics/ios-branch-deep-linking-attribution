//
//  PreferenceHelper.h
//  Branch-SDK
//
//  Created by Alex Austin on 6/6/14.
//  Copyright (c) 2014 Branch Metrics. All rights reserved.
//

#import <Foundation/Foundation.h>

static const BOOL LOG = YES;
static NSString *NO_STRING_VALUE = @"bnc_no_value";

@interface PreferenceHelper : NSObject

+ (NSString *)getAPIBaseURL;

+ (void)setAppKey:(NSString *)appKey;
+ (NSString *)getAppKey;

+ (void)setUserID:(NSString *)userId;
+ (NSString *)getUserID;

+ (void)setDeviceID:(NSString *)deviceId;
+ (NSString *)getDeviceID;

+ (void)setLinkClickID:(NSString *)linkClickId;
+ (NSString *)getLinkClickID;

+ (void)setSessionParams:(NSString *)sessionParams;
+ (NSString *)getSessionParams;

+ (void)setUserURL:(NSString *)userUrl;
+ (NSString *)getUserURL;

+ (void)setActionTotalCount:(NSString *)action withCount:(NSInteger)count;
+ (void)setActionBalanceCount:(NSString *)action withCount:(NSInteger)count;
+ (void)setActionCreditCount:(NSString *)action withCount:(NSInteger)count;
+ (NSInteger)getActionTotalCount:(NSString *)action;
+ (NSInteger)getActionBalanceCount:(NSString *)action;
+ (NSInteger)getActionCreditCount:(NSString *)action;


+ (NSString *)base64EncodeStringToString:(NSString *)strData;
+ (NSString *)base64DecodeStringToString:(NSString *)strData;

@end
