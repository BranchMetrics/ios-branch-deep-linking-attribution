//
//  BranchRequestOpen.h
//  BranchSDK
//
//  Created by Brandon Boothe on 5/6/26.
//

#import "BNCServerRequest.h"
#import "BNCCallbacks.h"

@interface BranchRequestOpen : BNCServerRequest

// URL that triggered this install or open event
@property (nonatomic, copy, readwrite) NSString *urlString;
@property (assign, nonatomic) BOOL isFromArchivedQueue;
@property (nonatomic, copy) callbackWithStatus callback;
@property (nonatomic, copy) callbackForTracingRequests traceCallback;
@property (strong, nonatomic) NSDictionary *requestParams;
@property (nonatomic, copy, readwrite) NSString *requestServiceURL;
@property (nonatomic, copy, readwrite, nullable) NSDictionary *linkData;

// When set, -makeRequest: calls this once and assigns the result to linkData before reading it, so
// the link data can depend on state that is only known once an earlier request has finished.
@property (nonatomic, copy, nullable) NSDictionary * _Nullable (^linkDataResolver)(void);

+ (void) waitForOpenResponseLock;
+ (void) releaseOpenResponseLock;
+ (void) setWaitNeededForOpenResponseLock;

- (id)initWithCallback:(callbackWithStatus)callback;
- (id)initWithCallback:(callbackWithStatus)callback isInstall:(BOOL)isInstall;

@end
