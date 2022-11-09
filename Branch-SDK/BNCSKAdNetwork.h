//
//  BNCSKAdNetwork.h
//  Branch
//
//  Created by Ernest Cho on 8/12/20.
//  Copyright © 2020 Branch, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <StoreKit/StoreKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface BNCSKAdNetwork : NSObject

@property (nonatomic, assign, readwrite) NSTimeInterval maxTimeSinceInstall;

+ (BNCSKAdNetwork *)sharedInstance;

- (void)registerAppForAdNetworkAttribution;

- (void)updateConversionValue:(NSInteger)conversionValue;

- (void)updatePostbackConversionValue:(NSInteger)conversionValue
                    completionHandler:(void (^)(NSError *error))completion;

- (void)updatePostbackConversionValue:(NSInteger)fineValue
                          coarseValue:(SKAdNetworkCoarseConversionValue) coarseValue
                           lockWindow:(BOOL)lockWindow
                    completionHandler:(void (^)(NSError *error))completion API_AVAILABLE(ios(16.1));

- (int) calculateSKANWindowForTime:(NSDate *) currentTime;

- (SKAdNetworkCoarseConversionValue) getCoarseConversionValueFromDataResponse:(NSDictionary *) dataResponseDictionary API_AVAILABLE(ios(16.1));

- (BOOL) getLockedStatusFromDataResponse:(NSDictionary *) dataResponseDictionary;

- (BOOL) getEnforceHighestConversionValueFromDataResponse:(NSDictionary *) dataResponseDictionary;

- (BOOL) shouldCallPostbackForDataResponse:(NSDictionary *) dataResponseDictionary;

@end

NS_ASSUME_NONNULL_END
