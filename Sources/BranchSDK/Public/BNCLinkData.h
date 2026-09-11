//
//  BNCLinkData.h
//  Branch-SDK
//
//  Created by Qinwei Gong on 1/22/15.
//  Copyright (c) 2015 Branch Metrics. All rights reserved.
//

#if __has_feature(modules)
@import Foundation;
#else
#import <Foundation/Foundation.h>
#endif

typedef NS_ENUM(NSUInteger, BranchLinkType) {
    BranchLinkTypeUnlimitedUse = 0,
    BranchLinkTypeOneTimeUse = 1
};

@class BranchLinkProperties;

@interface BNCLinkData : NSObject <NSSecureCoding>

@property (strong, nonatomic) NSMutableDictionary *data;

/**
 Builds the link data a link with these properties sends, and by whose `-hash` `BNCLinkCache` keys
 it — so this is also how a link is looked up in that cache.

 @param linkProperties The link's content and behavior. May be nil, in which case every option takes
        its default.
 @param ignoreUAString A User-Agent string the Branch backend should ignore. Not part of the cache
        key.
 */
+ (instancetype)linkDataWithLinkProperties:(BranchLinkProperties *)linkProperties
                            ignoreUAString:(NSString *)ignoreUAString;

- (void)setupTags:(NSArray *)tags;
- (void)setupAlias:(NSString *)alias;
- (void)setupType:(BranchLinkType)type;
- (void)setupChannel:(NSString *)channel;
- (void)setupFeature:(NSString *)feature;
- (void)setupStage:(NSString *)stage;
- (void)setupCampaign:(NSString *)campaign;
- (void)setupParams:(NSDictionary *)params;
- (void)setupMatchDuration:(NSUInteger)duration;
- (void)setupIgnoreUAString:(NSString *)ignoreUAString;

@end
