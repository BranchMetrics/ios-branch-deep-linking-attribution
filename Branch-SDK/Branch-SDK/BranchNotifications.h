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
- (void) branch:(Branch*)branch didOpenURL:(NSURL*)url withError:(NSError*)error;
- (void) branch:(Branch*)branch didOpenURL:(NSURL*)url withUniversalObject:(BranchUniversalObject*)branchUniversalObject;

- (void) branch:(Branch*)branch willMakeShortURLWithURL:(NSURL*)url;
- (void) branch:(Branch*)branch didMakeShortURLWithURL:(NSURL*)url error:(NSError*)error;
- (void) branch:(Branch*)branch didMakeShortURL:(NSURL*)shortURL fromURL:(NSURL*)longURL;

@end


extern NSString* const BNCBranchWillOpenURLNotification;
extern NSString* const BNCBranchDidOpenURLNotification;

extern NSString* const BNCBranchWillMakeShortURLNotification;
extern NSString* const BNCBranchDidMakeShortURLNotification;

extern NSString* const BNCErrorKey;
extern NSString* const BNCOriginalURLKey;
extern NSString* const BNCDeepLinkParametersKey;
extern NSString* const BNCShortURLKey;
