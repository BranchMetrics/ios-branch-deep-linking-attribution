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

typedef void (^callbackWithParams) (NSDictionary * _Nonnull params, NSError * _Nullable error);
typedef void (^callbackWithUrl) (NSString * _Nonnull url, NSError * _Nullable error);
typedef void (^callbackWithStatus) (BOOL changed, NSError * _Nullable error);
typedef void (^callbackWithList) (NSArray * _Nullable list, NSError * _Nullable error);
typedef void (^callbackWithUrlAndSpotlightIdentifier) (NSString * _Nullable url, NSString * _Nullable spotlightIdentifier, NSError * _Nullable error);
typedef void (^callbackWithBranchUniversalObject) (BranchUniversalObject * _Nonnull universalObject, BranchLinkProperties * _Nonnull linkProperties, NSError * _Nullable error);

#endif /* BNCCallbacks_h */
