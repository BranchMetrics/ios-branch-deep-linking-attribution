//
//  BNCPreferenceHelper.h
//  Branch-SDK
//
//  Created by Alex Austin on 6/6/14.
//  Copyright (c) 2014 Branch Metrics. All rights reserved.
//

#import <Foundation/Foundation.h>

#define FILE_NAME   [[NSString stringWithUTF8String:__FILE__] lastPathComponent]
#define LINE_NUM    __LINE__

static NSString *KEY_BRANCH_KEY = @"branch_key";
static NSString *NO_STRING_VALUE = @"bnc_no_value";

@protocol BNCDebugConnectionDelegate <NSObject>

- (void)bnc_debugConnectionEstablished;

@end

@protocol BNCTestDelegate <NSObject>

- (void)simulateInitFinished;

@end

@interface BNCPreferenceHelper : NSObject

@property (assign, nonatomic) NSInteger retryCount;
@property (assign, nonatomic) NSInteger retryInterval;
@property (assign, nonatomic) NSInteger timeout;

+ (NSString *)getAPIBaseURL;
+ (NSString *)getAPIURL:(NSString *) endpoint;

+ (void)setTimeout:(NSInteger)timeout;
+ (NSInteger)getTimeout;

+ (void)setRetryInterval:(NSInteger)retryInterval;
+ (NSInteger)getRetryInterval;

+ (void)setRetryCount:(NSInteger)retryCount;
+ (NSInteger)getRetryCount;

+ (NSString *)getAppKey;
+ (void)setAppKey:(NSString *)appKey;

+ (NSString *)getBranchKey;
+ (NSString *)getBranchKey:(BOOL)isLive;
+ (void)setBranchKey:(NSString *)branchKey;

+ (NSString *)getAppVersion;
+ (void)setAppVersion:(NSString *)appVersion;

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

+ (void)setAppListCheckDone;
+ (BOOL)getNeedAppListCheck;

+ (BOOL)getIsReferrable;
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

+ (void)setDevDebug;
+ (BOOL)getDevDebug;
+ (void)setDebug;
+ (void)clearDebug;
+ (BOOL)isDebug;
+ (void)log:(NSString *)filename line:(int)line message:(NSString *)format, ...;
+ (void)sendScreenshot:(NSData *)data;
+ (void)setDebugConnectionDelegate:(id<BNCDebugConnectionDelegate>) debugConnectionDelegate;
+ (void)keepDebugAlive;
+ (void)setTestDelegate:(id<BNCTestDelegate>) testDelegate;
+ (void)simulateInitFinished;
+ (BOOL)isRemoteDebug;

@end
