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

@interface Branch : NSObject

+ (Branch *)getInstance:(NSString *)key;
+ (Branch *)getInstance;

- (void)initUserSession;
- (void)initUserSession:(BOOL)isReferrable;
- (void)initUserSessionWithCallback:(callbackWithParams)callback;
- (void) initUserSessionWithCallback:(callbackWithParams)callback andIsReferrable:(BOOL)isReferrable;
- (NSDictionary *)getInstallReferringParams;
- (NSDictionary *)getReferringParams;
- (void)resetUserSession;

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
- (NSString *)getLongURLWithTag:(NSString *)tag;
- (NSString *)getLongURLWithParams:(NSDictionary *)params andTag:(NSString *)tag;

- (void)getShortURLWithCallback:(callbackWithUrl)callback;
- (void)getShortURLWithParams:(NSDictionary *)params andCallback:(callbackWithUrl)callback;
- (void)getShortURLWithTag:(NSString *)tag andCallback:(callbackWithUrl)callback;
- (void)getShortURLWithParams:(NSDictionary *)params andTag:(NSString *)tag andCallback:(callbackWithUrl)callback;

@end
