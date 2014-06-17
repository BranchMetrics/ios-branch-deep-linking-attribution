//
//  Branch_SDK.h
//  Branch-SDK
//
//  Created by Alex Austin on 6/5/14.
//  Copyright (c) 2014 Branch Metrics. All rights reserved.
//
#if ! __has_feature(objc_arc)
#error This file must be compiled with ARC. Either turn on ARC for the project or use -fobjc-arc flag on this file.
#endif

#import <Foundation/Foundation.h>


typedef void (^callbackWithParams) (NSDictionary *params);
typedef void (^callbackWithUrl) (NSString *url);
typedef void (^callbackWithStatus) (BOOL changed);

@interface Branch : NSObject

+ (Branch *)getInstance:(NSString *)key;
+ (Branch *)getInstance;


- (void)initUserSession;
- (void)initUserSessionWithCallback:(callbackWithParams)callback;
- (NSDictionary *)getReferringParams;
- (void)resetUserSession;

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
