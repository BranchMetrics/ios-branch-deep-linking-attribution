//
//  Branch_SDK.h
//  Branch-SDK
//
//  Created by Alex Austin on 6/5/14.
//  Copyright (c) 2014 Branch Metrics. All rights reserved.
//
#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

typedef void (^callbackWithParams) (NSDictionary *params);
typedef void (^callbackWithUrl) (NSString *url);
typedef void (^callbackWithStatus) (BOOL changed);

static NSString *BRANCH_FEATURE_TAG_SHARE = @"share";
static NSString *BRANCH_FEATURE_TAG_REFERRAL = @"referral";
static NSString *BRANCH_FEATURE_TAG_INVITE = @"invite";
static NSString *BRANCH_FEATURE_TAG_DEAL = @"deal";
static NSString *BRANCH_FEATURE_TAG_GIFT = @"gift";

@interface Branch : NSObject

+ (Branch *)getInstance:(NSString *)key;
+ (Branch *)getInstance;

- (void)initUserSession;
- (void)initUserSessionWithLaunchOptions:(NSDictionary *)options;
- (void)initUserSession:(BOOL)isReferrable;
- (void)initUserSessionWithLaunchOptions:(NSDictionary *)options andIsReferrable:(BOOL)isReferrable;
- (void)initUserSessionWithCallback:(callbackWithParams)callback;
- (void)initUserSessionWithCallback:(callbackWithParams)callback withLaunchOptions:(NSDictionary *)options;
- (void)initUserSessionWithCallback:(callbackWithParams)callback andIsReferrable:(BOOL)isReferrable;
- (void)initUserSessionWithCallback:(callbackWithParams)callback andIsReferrable:(BOOL)isReferrable withLaunchOptions:(NSDictionary *)options;
- (NSDictionary *)getInstallReferringParams;
- (NSDictionary *)getReferringParams;
- (void)resetUserSession;

- (BOOL)handleDeepLink:(NSURL *)url;

- (BOOL)hasIdentity;
- (void)identifyUser:(NSString *)userId;
- (void)identifyUser:(NSString *)userId withCallback:(callbackWithParams)callback;
- (void)clearUser;

- (void)loadRewardsWithCallback:(callbackWithStatus)callback;
- (void)loadActionCountsWithCallback:(callbackWithStatus)callback;
- (NSInteger)getCredits;
- (void)redeemRewards:(NSInteger)count;
- (NSInteger)getCreditsForBucket:(NSString *)bucket;
- (void)redeemRewards:(NSInteger)count forBucket:(NSString *)bucket;
- (void)userCompletedAction:(NSString *)action;
- (void)userCompletedAction:(NSString *)action withState:(NSDictionary *)state;
- (NSInteger)getTotalCountsForAction:(NSString *)action;
- (NSInteger)getUniqueCountsForAction:(NSString *)action;

- (NSString *)getLongURL;
- (NSString *)getLongURLWithParams:(NSDictionary *)params;

- (void)getShortURLWithCallback:(callbackWithUrl)callback;
- (void)getShortURLWithParams:(NSDictionary *)params andCallback:(callbackWithUrl)callback;
- (void)getContentUrlWithParams:(NSDictionary *)params andChannel:(NSString *)channel andCallback:(callbackWithUrl)callback;
- (void)getContentUrlWithParams:(NSDictionary *)params andTags:(NSArray *)tags andChannel:(NSString *)channel andCallback:(callbackWithUrl)callback;
- (void)getReferralUrlWithParams:(NSDictionary *)params andTags:(NSArray *)tags andChannel:(NSString *)channel andCallback:(callbackWithUrl)callback;
- (void)getReferralUrlWithParams:(NSDictionary *)params andChannel:(NSString *)channel andCallback:(callbackWithUrl)callback;
- (void)getShortURLWithParams:(NSDictionary *)params andTags:(NSArray *)tags andChannel:(NSString *)channel andFeature:(NSString *)feature andStage:(NSString *)stage andCallback:(callbackWithUrl)callback;
- (void)getShortURLWithParams:(NSDictionary *)params andChannel:(NSString *)channel andFeature:(NSString *)feature andStage:(NSString *)stage andCallback:(callbackWithUrl)callback;
- (void)getShortURLWithParams:(NSDictionary *)params andChannel:(NSString *)channel andFeature:(NSString *)feature andCallback:(callbackWithUrl)callback;

@end
