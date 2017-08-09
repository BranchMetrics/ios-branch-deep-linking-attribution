//
//  BranchNotifications.h
//  Branch-TestBed
//
//  Created by edward on 6/30/17.
//  Copyright © 2017 Branch Metrics. All rights reserved.
//

#import <Foundation/Foundation.h>
@class Branch, BranchUniversalObject;

@protocol BranchDelegate <NSObject>

@optional
- (void) branch:(Branch*)branch willOpenURL:(NSURL*)url;

@optional
- (void) branch:(Branch*)branch
     didOpenURL:(NSURL*)url
universalObject:(BranchUniversalObject*)branchUniversalObject
          error:(NSError*)error;

@end


extern NSString* const BNCBranchWillOpenURLNotification;
extern NSString* const BNCBranchDidOpenURLNotification;

extern NSString* const BNCErrorKey;
extern NSString* const BNCOriginalURLKey;
extern NSString* const BNCDeepLinkParametersKey;
