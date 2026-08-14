//
//  BNCServerRequestOperation.h
//  BranchSDK
//
//  Created by Nidhi Dixit on 7/22/25.
//


#import <Foundation/Foundation.h>
#import "BNCServerRequest.h"
#import "BNCCallbacks.h"

@interface BNCServerRequestOperation : NSOperation

@property (nonatomic, strong, readonly) BNCServerRequest *request;

@property (nonatomic, strong) BNCServerInterface *serverInterface;
@property (nonatomic, copy) NSString *branchKey;
@property (nonatomic, strong) BNCPreferenceHelper *preferenceHelper;

- (instancetype)initWithRequest:(BNCServerRequest *)request NS_DESIGNATED_INITIALIZER;
- (instancetype)init NS_UNAVAILABLE;

// Returns NO for the requests that establish a session (install, open, deep link).
// Every other request requires an initialized session to carry valid tokens.
+ (BOOL)requestRequiresSession:(BNCServerRequest *)request;

@end
