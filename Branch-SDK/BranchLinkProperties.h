//
//  BranchLinkProperties.h
//  Branch-TestBed
//
//  Created by Derrick Staten on 10/16/15.
//  Copyright © 2015 Branch Metrics. All rights reserved.
//

#if __has_feature(modules)
@import Foundation;
#else
#import <Foundation/Foundation.h>
#endif

@interface BranchLinkProperties : NSObject

@property (nonatomic, strong) NSArray *tags;
@property (nonatomic, copy) NSString *feature;
@property (nonatomic, copy) NSString *alias;
@property (nonatomic, copy) NSString *channel;
@property (nonatomic, copy) NSString *stage;
@property (nonatomic, copy) NSString *campaign;
@property (nonatomic, assign) NSUInteger matchDuration;
@property (nonatomic, strong) NSDictionary *controlParams;

- (void)addControlParam:(NSString *)controlParam withValue:(NSString *)value;
+ (BranchLinkProperties *)getBranchLinkPropertiesFromDictionary:(NSDictionary *)dictionary;

- (NSString *)description;

@end
