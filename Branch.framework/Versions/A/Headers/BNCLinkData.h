//
//  BNCLinkData.h
//  Branch-SDK
//
//  Created by Qinwei Gong on 1/22/15.
//  Copyright (c) 2015 Branch Metrics. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef NS_ENUM(NSUInteger, BranchLinkType) {
    BranchLinkTypeUnlimitedUse = 0,
    BranchLinkTypeOneTimeUse = 1
};

@interface BNCLinkData : NSObject

@property (strong, nonatomic) NSMutableDictionary *data;

- (void)setupTags:(NSArray *)tags;
- (void)setupAlias:(NSString *)alias;
- (void)setupType:(BranchLinkType)type;
- (void)setupChannel:(NSString *)channel;
- (void)setupFeature:(NSString *)feature;
- (void)setupStage:(NSString *)stage;
- (void)setupParams:(NSDictionary *)params;
- (void)setupMatchDuration:(NSUInteger)duration;
- (void)setupIgnoreUAString:(NSString *)ignoreUAString;

@end
