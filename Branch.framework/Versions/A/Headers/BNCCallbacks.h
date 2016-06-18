//
//  BNCCallbacks.h
//  Branch-TestBed
//
//  Created by Ahmed Nawar on 6/18/16.
//  Copyright © 2016 Branch Metrics. All rights reserved.
//

#ifndef BNCCallbacks_h
#define BNCCallbacks_h

@class BranchUniversalObject, BranchLinkProperties;

typedef void (^callbackWithParams) (NSDictionary *params, NSError *error);
typedef void (^callbackWithUrl) (NSString *url, NSError *error);
typedef void (^callbackWithStatus) (BOOL changed, NSError *error);
typedef void (^callbackWithList) (NSArray *list, NSError *error);
typedef void (^callbackWithUrlAndSpotlightIdentifier) (NSString *url, NSString *spotlightIdentifier, NSError *error);
typedef void (^callbackWithBranchUniversalObject) (BranchUniversalObject *universalObject, BranchLinkProperties *linkProperties, NSError *error);

#endif /* BNCCallbacks_h */
