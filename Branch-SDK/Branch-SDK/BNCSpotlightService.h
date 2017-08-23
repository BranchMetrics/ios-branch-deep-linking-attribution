//
//  BNCSpotlightService.h
//  Branch-SDK
//
//  Created by Parth Kalavadia on 8/10/17.
//  Copyright © 2017 Branch Metrics. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "BranchUniversalObject.h"

@interface BNCSpotlightService : NSObject

- (void)indexContentUsingUserActivityWithTitle:(NSString *)title
                                   description:(NSString *)description
                                   canonicalId:(NSString *)canonicalId
                                          type:(NSString *)type
                                  thumbnailUrl:(NSURL *)thumbnailUrl
                                      keywords:(NSSet *)keywords
                                      userInfo:(NSDictionary *)userInfo
                                expirationDate:(NSDate *)expirationDate
                                      callback:(callbackWithUrl)callback
                             spotlightCallback:(callbackWithUrlAndSpotlightIdentifier)spotlightCallback;

- (void)indexContentUsingCSSearchableItemWithTitle:(NSString *)title
                                       CanonicalId:(NSString *)canonicalId
                                       description:(NSString *)description
                                              type:(NSString *)type
                                      thumbnailUrl:(NSURL *)thumbnailUrl
                                          userInfo:(NSDictionary *)userInfo
                                          keywords:(NSSet *)keywords
                                    linkProperties:(BranchLinkProperties*)linkProperties
                                          callback:(callbackWithUrl)callback
                                 spotlightCallback:(callbackWithUrlAndSpotlightIdentifier)spotlightCallback;

- (void)removeSearchableItemsWithIdentifier:(NSString *)identifier completionHandler:(completion)completion;
- (void)removeSearchableItemsWithIdentifiers:(NSArray<NSString *> *)identifiers completionHandler:(completion)completion;
- (void)removeSearchableItemsByBranchSpotlightDomainWithCompletionHandler:(completion)completion;
@end
