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

@interface BNCPreferenceHelper : NSObject

@property (strong, nonatomic) NSString *branchKey;
@property (strong, nonatomic) NSString *appKey;
@property (strong, nonatomic) NSString *lastRunBranchKey;
@property (strong, nonatomic) NSDate *lastStrongMatchDate;
@property (strong, nonatomic) NSString *appVersion;
@property (strong, nonatomic) NSString *deviceFingerprintID;
@property (strong, nonatomic) NSString *sessionID;
@property (strong, nonatomic) NSString *identityID;
@property (strong, nonatomic) NSString *linkClickIdentifier;
@property (strong, nonatomic) NSString *spotlightIdentifier;
@property (strong, nonatomic) NSString *universalLinkUrl;
@property (strong, nonatomic) NSString *userUrl;
@property (strong, nonatomic) NSString *userIdentity;
@property (strong, nonatomic) NSString *sessionParams;
@property (strong, nonatomic) NSString *installParams;
@property (assign, nonatomic) BOOL explicitlyRequestedReferrable;
@property (assign, nonatomic) BOOL isReferrable;
@property (assign, nonatomic) BOOL isDebug;
@property (assign, nonatomic) BOOL isConnectedToRemoteDebug;
@property (assign, nonatomic) BOOL isContinuingUserActivity;
@property (assign, nonatomic) NSInteger retryCount;
@property (assign, nonatomic) NSTimeInterval retryInterval;
@property (assign, nonatomic) NSTimeInterval timeout;

+ (BNCPreferenceHelper *)preferenceHelper;

- (NSString *)getAPIBaseURL;
- (NSString *)getAPIURL:(NSString *)endpoint;
- (NSString *)getBranchKey:(BOOL)isLive;

- (void)clearUserCreditsAndCounts;
- (void)clearUserCredits;

- (id)getBranchUniversalLinkDomains;

- (void)setCreditCount:(NSInteger)count;
- (void)setCreditCount:(NSInteger)count forBucket:(NSString *)bucket;
- (void)removeCreditCountForBucket:(NSString *)bucket;
- (NSDictionary *)getCreditDictionary;
- (NSInteger)getCreditCount;
- (NSInteger)getCreditCountForBucket:(NSString *)bucket;

- (void)setActionTotalCount:(NSString *)action withCount:(NSInteger)count;
- (void)setActionUniqueCount:(NSString *)action withCount:(NSInteger)count;
- (NSInteger)getActionTotalCount:(NSString *)action;
- (NSInteger)getActionUniqueCount:(NSString *)action;

- (void)log:(NSString *)filename line:(int)line message:(NSString *)format, ...;

@end
