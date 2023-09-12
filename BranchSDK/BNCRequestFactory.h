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

// TODO: describe privacy settings
@property (nonatomic, assign, readwrite) BOOL trackingDisabled;
@property (nonatomic, assign, readwrite) BOOL trackingDomainEnabled;

- (instancetype)init;

- (NSDictionary *)dataForInstall;
- (NSDictionary *)dataForOpen;
- (NSDictionary *)dataForEventWithEventDictionary:(NSMutableDictionary *)dictionary;

// BranchShortUrlRequest, BranchShortUrlSyncRequest and BranchSpotlightUrlRequest
- (NSDictionary *)dataForShortURLWithLinkDataDictionary:(NSMutableDictionary *)dictionary isSpotlightRequest:(BOOL)isSpotlightRequest;

// TODO: implement these
- (NSDictionary *)dataForCPID;
- (NSDictionary *)dataForLATD;
- (NSDictionary *)dataForClose;

// Methods used by BNCServerInterface to maintain existing behavior
- (NSMutableDictionary *)v1dictionary:(NSMutableDictionary *)json;
- (NSMutableDictionary *)v2dictionary:(NSMutableDictionary *)json;

// TODO: pull logic from BNCServerInterface prepareParamDict here

// TODO: implement this
- (NSMutableDictionary *)addPerformanceMetrics:(NSMutableDictionary *)json;

@end

NS_ASSUME_NONNULL_END
