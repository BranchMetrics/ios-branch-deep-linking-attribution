//
//  BNCServerRequestOperation.h
//  BranchSDK
//
//  Created by Nidhi Dixit on 7/22/25.
//


#import <Foundation/Foundation.h>
#import "BNCServerRequest.h"
#import "BNCCallbacks.h"

@class BNCServerRequestQueue;

@interface BNCServerRequestOperation : NSOperation

@property (nonatomic, strong, readonly) BNCServerRequest *request;

@property (nonatomic, strong) BNCServerInterface *serverInterface;
@property (nonatomic, copy) NSString *branchKey;
@property (nonatomic, strong) BNCPreferenceHelper *preferenceHelper;
@property (nonatomic, weak) BNCServerRequestQueue *requestQueue;
@property (nonatomic, assign) NSInteger retryCount;

- (instancetype)initWithRequest:(BNCServerRequest *)request NS_DESIGNATED_INITIALIZER;
- (instancetype)init NS_UNAVAILABLE;

@end
