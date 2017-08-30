//
//  BranchDelegate.h
//  Branch-SDK
//
//  Created by Edward Smith on 6/30/17.
//  Copyright © 2017 Branch Metrics. All rights reserved.
//

#import <Foundation/Foundation.h>
@class Branch, BranchUniversalObject, BranchLinkProperties;

#pragma mark BranchDelegate Protocol

@protocol BranchDelegate <NSObject>

@optional
- (void) branch:(Branch*)branch willStartSessionWithURL:(NSURL*)branch;

@optional
- (void) branch:(Branch*)branch
     didStartSessionWithURL:(NSURL*)url
            universalObject:(BranchUniversalObject*)univseralObject
             linkProperties:(BranchLinkProperties*)linkParameters;

@optional
- (void) branch:(Branch*)branch
didStartSessionWithURL:(NSURL*)url
                 error:(NSError*)error;
@end

#pragma mark - Branch Notifications

FOUNDATION_EXPORT NSString* const BranchWillStartSessionNotification;
FOUNDATION_EXPORT NSString* const BranchDidStartSessionNotification;

FOUNDATION_EXPORT NSString* const BranchErrorKey;
FOUNDATION_EXPORT NSString* const BranchOriginalURLKey;
FOUNDATION_EXPORT NSString* const BranchUniversalObjectKey;
FOUNDATION_EXPORT NSString* const BranchLinkPropertiesKey;
