//
//  BNCRequestDeepLink.h
//  Branch-SDK
//
//  Created by Brandon Boothe on 4/30/26.
//  Copyright © 2026 Branch Metrics. All rights reserved.
//

#import "BNCServerRequest.h"
#import "BNCCallbacks.h"

@interface BNCRequestDeepLink : BNCServerRequest

// URL that triggered this install or open event
@property (nonatomic, copy, readwrite) NSString *urlString;
@property (assign, nonatomic) BOOL isFromArchivedQueue;
@property (nonatomic, copy) callbackWithStatus callback;
@property (nonatomic, copy) callbackForTracingRequests traceCallback;
@property (strong, nonatomic) NSDictionary *requestParams;
@property (nonatomic, copy, readwrite) NSString *requestServiceURL;

+ (void) waitForOpenResponseLock;
+ (void) releaseOpenResponseLock;
+ (void) setWaitNeededForOpenResponseLock;

- (id)initWithCallback:(callbackWithStatus)callback;
- (id)initWithCallback:(callbackWithStatus)callback isInstall:(BOOL)isInstall;

@end
