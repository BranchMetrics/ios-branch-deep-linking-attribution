//
//  ContentPathProperties.m
//  Branch-TestBed
//
//  Created by Sojan P.R. on 8/19/16.
//  Copyright © 2016 Branch Metrics. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "ContentPathProperties.h"
#import "BranchConstants.h"

@implementation ContentPathProperties


- (instancetype) init:(NSDictionary *)pathInfo
{
    self = [super init];
    if (self) {
        _pathInfo = pathInfo;
    }
    if([pathInfo objectForKey:HASH_MODE_KEY] != nil) {
        _isClearText = [pathInfo objectForKey:HASH_MODE_KEY];
    }
    return self;
}

- (NSArray *) getFilteredElements {
    NSArray * filteredKeys = nil;
    if([_pathInfo objectForKey:FILTERED_KEYS]) {
        filteredKeys = [_pathInfo objectForKey:FILTERED_KEYS];
    }
    return filteredKeys;
}

- (BOOL) isSkipContentDiscovery {
    NSArray *filteredElelments = [self getFilteredElements];
    return (filteredElelments != nil && filteredElelments.count == 0);
}

@end