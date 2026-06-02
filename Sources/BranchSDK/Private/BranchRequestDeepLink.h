//
//  BranchRequestDeepLink.h
//  BranchSDK
//
//  Created by Brandon Boothe on 5/6/26.
//

#import "BNCServerRequest.h"
#import "BNCCallbacks.h"

@interface BranchRequestDeepLink : BNCServerRequest

// URL that triggered this install or open event
@property (nonatomic, copy, readwrite) NSString *urlString;
@property (assign, nonatomic) BOOL isFromArchivedQueue;
@property (nonatomic, copy) callbackWithStatus callback;
@property (nonatomic, copy) callbackForTracingRequests traceCallback;
@property (strong, nonatomic) NSDictionary *requestParams;
@property (nonatomic, copy, readwrite) NSString *requestServiceURL;
@property (nonatomic, copy, readwrite) NSString *uri;

+ (void) waitForDeepLinkResponseLock;
+ (void) releaseDeepLinkResponseLock;
+ (void) setWaitNeededForDeepLinkResponseLock;

- (id)initWithCallback:(callbackWithStatus)callback;
- (id)initWithCallback:(callbackWithStatus)callback isInstall:(BOOL)isInstall;

@end
