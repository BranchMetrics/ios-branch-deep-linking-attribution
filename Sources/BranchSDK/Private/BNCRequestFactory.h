//
//  BNCRequestFactory.h
//  Branch
//
//  Created by Ernest Cho on 8/16/23.
//  Copyright © 2023 Branch, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

/*
 BNCRequestFactory
 
 Collates general device and app data for request JSONs.
 Enforces privacy controls on data within request JSONs.
 
 Endpoint specific data is passed in and not edited by this class.
 */
@interface BNCRequestFactory : NSObject

- (instancetype)initWithBranchKey:(NSString *)key UUID:(NSString *)requestUUID TimeStamp:(NSNumber *)requestTimeStamp NS_DESIGNATED_INITIALIZER;
- (instancetype)init NS_UNAVAILABLE;

- (NSDictionary *)dataForInstallWithURLString:(nullable NSString *)urlString;
- (NSDictionary *)dataForOpenWithURLString:(nullable NSString *)urlString;

// Event data is passed in
- (NSDictionary *)dataForEventWithEventDictionary:(NSMutableDictionary *)dictionary;

// Link payload is passed in
- (NSDictionary *)dataForShortURLWithLinkDataDictionary:(NSMutableDictionary *)dictionary isSpotlightRequest:(BOOL)isSpotlightRequest;

// LATD attribution window is passed in
- (NSDictionary *)dataForLATDWithDataDictionary:(NSMutableDictionary *)dictionary;

@end

NS_ASSUME_NONNULL_END
