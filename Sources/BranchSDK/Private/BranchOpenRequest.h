//
//  BranchOpenRequest.h
//  Branch-TestBed
//
//  Created by Graham Mueller on 5/26/15.
//  Copyright (c) 2015 Branch Metrics. All rights reserved.
//

#import "BNCServerRequest.h"
#import "BNCCallbacks.h"

@interface BranchOpenRequestLinkParams : NSObject <NSSecureCoding>
@property (copy, nonatomic) NSString *linkClickIdentifier;
@property (copy, nonatomic) NSString *spotlightIdentifier;
@property (copy, nonatomic) NSString *referringURL; // URL that triggered this install or open event
@property (assign, nonatomic) BOOL dropURLOpen;
@end

@interface BranchOpenRequest : BNCServerRequest


@property (nonatomic, copy) callbackWithStatus callback;
@property (nonatomic, strong, readwrite) BranchOpenRequestLinkParams *linkParams;

+ (void) waitForOpenResponseLock;
+ (void) releaseOpenResponseLock;
+ (void) setWaitNeededForOpenResponseLock;

- (id)initWithCallback:(callbackWithStatus)callback;
- (id)initWithCallback:(callbackWithStatus)callback isInstall:(BOOL)isInstall;

@end
