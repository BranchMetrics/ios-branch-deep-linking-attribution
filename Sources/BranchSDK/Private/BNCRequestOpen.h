//
//  BNCRequestOpen.h
//  Branch-SDK
//
//  Created by Brandon Boothe on 4/30/26.
//  Copyright © 2026 Branch Metrics. All rights reserved.
//

#import "BranchLogger.h"

@protocol BranchReferralInitListener;
@class Context;

@interface BNCRequestOpen : ServerRequestInitSession

@property (nonatomic, strong) id<BranchReferralInitListener> callback;
@property (nonatomic, assign) BOOL constructError;

- (instancetype)initWithContext:(Context *)context callback:(id<BranchReferralInitListener>)callback isAutoInitialization:(BOOL)isAutoInitialization;

@end