//
//  BNCSKAdNetwork.h
//  Branch
//
//  Created by Ernest Cho on 8/12/20.
//  Copyright © 2020 Branch, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

typedef NS_ENUM(NSInteger, BranchSkanWindow) {
    BranchSkanWindowInvalid = 0,
    BranchSkanWindowFirst = 1,
    BranchSkanWindowSecond = 2,
    BranchSkanWindowThird = 3
};

@interface BNCSKAdNetwork : NSObject

@property (nonatomic, assign, readwrite) NSTimeInterval maxTimeSinceInstall;

+ (BNCSKAdNetwork *)sharedInstance;

- (void)registerAppForAdNetworkAttribution;

- (void)updateConversionValue:(NSInteger)conversionValue;

- (void)updatePostbackConversionValue:(NSInteger)conversionValue
                    completionHandler:(void (^)(NSError *error))completion;

- (void)updatePostbackConversionValue:(NSInteger)fineValue
                          coarseValue:(NSString *) coarseValue
                           lockWindow:(BOOL)lockWindow
                    completionHandler:(void (^)(NSError *error))completion API_AVAILABLE(ios(16.1), macCatalyst(16.1));

- (int) calculateSKANWindowForTime:(NSDate *) currentTime;

- (NSString *) getCoarseConversionValueFromDataResponse:(NSDictionary *) dataResponseDictionary;

- (BOOL) getLockedStatusFromDataResponse:(NSDictionary *) dataResponseDictionary;

- (BOOL) getAscendingOnlyFromDataResponse:(NSDictionary *) dataResponseDictionary;

- (BOOL) shouldCallPostbackForDataResponse:(NSDictionary *) dataResponseDictionary;

@end

NS_ASSUME_NONNULL_END
