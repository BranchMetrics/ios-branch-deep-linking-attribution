//
//  Branch_SDK.h
//  Branch-SDK
//
//  Created by Alex Austin on 6/5/14.
//  Copyright (c) 2014 Branch Metrics. All rights reserved.
//
#import <Foundation/Foundation.h>


typedef void (^callbackWithParams) (NSDictionary *params);
typedef void (^callbackWithUrl) (NSString *url);
typedef void (^callbackWithStatus) (BOOL changed);

@interface Branch : NSObject

+ (Branch *)getInstance:(NSString *)key;
+ (Branch *)getInstance;

- (void)initUserSession;
- (void)initUserSessionWithCallback:(callbackWithParams)callback;
- (NSDictionary *)getInstallReferringParams;
- (NSDictionary *)getReferringParams;
- (void)resetUserSession;

- (void)identifyUser:(NSString *)userId;
- (void)identifyUser:(NSString *)userId withCallback:(callbackWithParams)callback;
- (void)clearUser;

- (void)loadPointsWithCallback:(callbackWithStatus)callback;
- (void)creditUserForReferralAction:(NSString *)action withCredits:(NSInteger)credits;
- (void)userCompletedAction:(NSString *)action;
- (NSInteger)getTotalPointsForAction:(NSString *)action;
- (NSInteger)getCreditsForAction:(NSString *)action;
- (NSInteger)getBalanceOfPointsForAction:(NSString *)action;

- (NSString *)getLongURL;
- (NSString *)getLongURLWithParams:(NSDictionary *)params;
- (NSString *)getLongURLWithTag:(NSString *)tag;
- (NSString *)getLongURLWithParams:(NSDictionary *)params andTag:(NSString *)tag;

- (void)getShortURLWithCallback:(callbackWithUrl)callback;
- (void)getShortURLWithParams:(NSDictionary *)params andCallback:(callbackWithUrl)callback;
- (void)getShortURLWithTag:(NSString *)tag andCallback:(callbackWithUrl)callback;
- (void)getShortURLWithParams:(NSDictionary *)params andTag:(NSString *)tag andCallback:(callbackWithUrl)callback;

@end
