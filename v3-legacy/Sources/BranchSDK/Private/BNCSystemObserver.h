//
//  BNCSystemObserver.h
//  BranchSDK
//
//  A collection of simple utility methods to get system information.
//
//  Created by Alex Austin on 6/5/14.
//  Copyright (c) 2014 Branch Metrics. All rights reserved.
//

#if __has_feature(modules)
@import Foundation;
#else
#import <Foundation/Foundation.h>
#endif

@interface BNCSystemObserver : NSObject

+ (NSString *)defaultURIScheme;
+ (NSString *)applicationVersion;
+ (NSString *)bundleIdentifier;
+ (NSString *)teamIdentifier;
+ (NSString *)brand;
+ (NSString *)model;
+ (NSString *)osName;
+ (NSString *)osVersion;
+ (NSNumber *)screenWidth;
+ (NSNumber *)screenHeight;
+ (NSNumber *)screenScale;
+ (BOOL)isSimulator;
+ (NSString *)advertiserIdentifier;
+ (NSString *)attOptedInStatus;
+ (NSString *)appleAttributionToken;
+ (NSString *)environment;
+ (BOOL)isAppClip;
+ (BOOL)compareUriSchemes:(NSString *) serverUriScheme;
+ (BOOL)compareLinkDomain:(NSString*) serverLinkDomain;

@end
