//
//  BNCEventUtils.m
//  BranchSDK
//
//  Created by Nipun Singh on 1/31/23.
//  Copyright © 2023 Branch, Inc. All rights reserved.
//

#import "BNCEventUtils.h"

@interface BNCEventUtils()
@property (nonatomic, strong, readwrite) NSMutableSet *events;
@end

@implementation BNCEventUtils

+ (instancetype)shared {
    static BNCEventUtils *set = nil;
    static dispatch_once_t onceToken = 0;
    dispatch_once(&onceToken, ^{
        set = [BNCEventUtils new];
    });
    return set;
}

- (instancetype)init {
    self = [super init];
    if (self) {
        self.events = [NSMutableSet set];
    }
    return self;
}

- (void)storeEvent:(BranchEvent *)event {
    [self.events addObject:event];
}

- (void)removeEvent:(BranchEvent *)event {
    [self.events removeObject:event];
}

@end
