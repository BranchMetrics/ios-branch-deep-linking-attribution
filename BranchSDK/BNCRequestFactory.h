//
//  BNCRequestFactory.h
//  Branch
//
//  Created by Ernest Cho on 8/16/23.
//  Copyright © 2023 Branch, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface BNCRequestFactory : NSObject

- (instancetype)initWithBranchKey:(NSString *)key NS_DESIGNATED_INITIALIZER;
- (instancetype)init NS_UNAVAILABLE;

- (NSDictionary *)dataForInstall;
- (NSDictionary *)dataForOpen;
- (NSDictionary *)dataForEventWithEventDictionary:(NSMutableDictionary *)dictionary;

// BranchShortUrlRequest, BranchShortUrlSyncRequest and BranchSpotlightUrlRequest
- (NSDictionary *)dataForShortURLWithLinkDataDictionary:(NSMutableDictionary *)dictionary isSpotlightRequest:(BOOL)isSpotlightRequest;

- (NSDictionary *)dataForLATDWithDataDictionary:(NSMutableDictionary *)dictionary;

// TODO: can we finish deprecating close?
//- (NSDictionary *)dataForClose;

@end

NS_ASSUME_NONNULL_END
