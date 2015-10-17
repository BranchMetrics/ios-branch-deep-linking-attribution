//
//  BranchLinkProperties.m
//  Branch-TestBed
//
//  Created by Derrick Staten on 10/16/15.
//  Copyright © 2015 Branch Metrics. All rights reserved.
//

#import "BranchLinkProperties.h"

@implementation BranchLinkProperties

- (NSDictionary *)controlParams {
    if (!_controlParams) {
        _controlParams = [[NSDictionary alloc] init];
    }
    return _controlParams;
}

- (void)addControlParam:(NSString *)controlParam withValue:(NSString *)value {
    if (!controlParam || ! value) {
        return;
    }
    NSMutableDictionary *temp = [_controlParams mutableCopy];
    temp[controlParam] = value;
    _controlParams = [temp copy];
}

@end
