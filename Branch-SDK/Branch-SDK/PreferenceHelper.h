//
//  PreferenceHelper.h
//  Branch-SDK
//
//  Created by Alex Austin on 6/6/14.
//  Copyright (c) 2014 Branch Metrics. All rights reserved.
//

#import <Foundation/Foundation.h>

static const BOOL LOG = NO;
static NSString *NO_STRING_VALUE = @"bnc_no_value";

@interface PreferenceHelper : NSObject

+ (NSString *)getAPIBaseURL;

+ (void)setAppKey:(NSString *)appKey;
+ (NSString *)getAppKey;

+ (void)setDeviceFingerprintID:(NSString *)deviceID;
+ (NSString *)getDeviceFingerprintID;

+ (void)setSessionID:(NSString *)sessionID;
+ (NSString *)getSessionID;

+ (void)setIdentityID:(NSString *)identityID;
+ (NSString *)getIdentityID;

+ (void)setLinkClickIdentifier:(NSString *)linkClickIdentifier;
+ (NSString *)getLinkClickIdentifier;

+ (void)setLinkClickID:(NSString *)linkClickId;
+ (NSString *)getLinkClickID;

+ (void)setSessionParams:(NSString *)sessionParams;
+ (NSString *)getSessionParams;

+ (void)setInstallParams:(NSString *)installParams;
+ (NSString *)getInstallParams;

+ (void)setUserURL:(NSString *)userUrl;
+ (NSString *)getUserURL;

+ (void)setUserIdentity:(NSString *)userIdentity;
+ (NSString *)getUserIdentity;

+ (NSInteger)getIsReferrable;
+ (void)setIsReferrable;
+ (void)clearIsReferrable;

+ (void)clearUserCreditsAndCounts;

+ (void)setCreditCount:(NSInteger)count;
+ (void)setCreditCount:(NSInteger)count forBucket:(NSString *)bucket;
+ (NSInteger)getCreditCount;
+ (NSInteger)getCreditCountForBucket:(NSString *)bucket;

+ (void)setActionTotalCount:(NSString *)action withCount:(NSInteger)count;
+ (void)setActionUniqueCount:(NSString *)action withCount:(NSInteger)count;
+ (NSInteger)getActionTotalCount:(NSString *)action;
+ (NSInteger)getActionUniqueCount:(NSString *)action;

+ (NSString *)base64EncodeStringToString:(NSString *)strData;
+ (NSString *)base64DecodeStringToString:(NSString *)strData;

@end
