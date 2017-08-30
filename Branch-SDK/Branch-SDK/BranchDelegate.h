//
//  BranchDelegate.h
//  Branch-SDK
//
//  Created by edward on 6/30/17.
//  Copyright © 2017 Branch Metrics. All rights reserved.
//

#import <Foundation/Foundation.h>
@class Branch, BranchUniversalObject, BranchLinkProperties;

@protocol BranchDelegate <NSObject>

@optional
- (void) branch:(Branch*)branch willOpenURL:(NSURL*)url;

@optional
- (void) branch:(Branch*)branch
     didOpenURL:(NSURL*)url
withUniversalObject:(BranchUniversalObject*)univseralObject
 linkProperties:(BranchLinkProperties*)linkParameters;

@optional
- (void) branch:(Branch*)branch
     didOpenURL:(NSURL*)url
      withError:(NSError*)error;

@end


FOUNDATION_EXPORT NSString* const BranchWillOpenURLNotification;
FOUNDATION_EXPORT NSString* const BranchDidOpenURLNotification;

FOUNDATION_EXPORT NSString* const BranchErrorKey;
FOUNDATION_EXPORT NSString* const BranchOriginalURLKey;
FOUNDATION_EXPORT NSString* const BranchUniversalObjectKey;
FOUNDATION_EXPORT NSString* const BranchLinkPropertiesKey;
