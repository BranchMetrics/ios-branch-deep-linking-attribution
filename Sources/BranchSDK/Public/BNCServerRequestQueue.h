//
//  BNCServerRequestQueue.h
//  Branch-SDK
//
//  Created by Qinwei Gong on 9/6/14.
//  Copyright (c) 2014 Branch Metrics. All rights reserved.
//

#import "BNCServerRequest.h"
#import <Foundation/Foundation.h>

@class BranchOpenRequest;

@interface BNCServerRequestQueue : NSObject

+ (instancetype)getInstance;

- (void)configureWithServerInterface:(BNCServerInterface *)serverInterface
                           branchKey:(NSString *)branchKey
                    preferenceHelper:(BNCPreferenceHelper *)preferenceHelper;
- (void)enqueue:(BNCServerRequest *)request;
- (void)enqueue:(BNCServerRequest *)request withPriority:(NSOperationQueuePriority)priority;
- (void)enqueueRetry:(BNCServerRequest *)request withRetryCount:(NSInteger)retryCount;
- (void)clearQueue;
- (BOOL)containsInstallOrOpen;
- (BranchOpenRequest *)findExistingInstallOrOpen;

@end
