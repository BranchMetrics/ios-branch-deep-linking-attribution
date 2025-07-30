//
//  BNCServerRequestOperation.h
//  BranchSDK
//
//  Created by Nidhi Dixit on 7/22/25.
//


// BNCServerRequestOperation.h
#import <Foundation/Foundation.h>
#import "BNCServerRequest.h" // For the wrapped request
#import "BNCCallbacks.h"     // For BNCServerCallback and callbackWithStatus


@interface BNCServerRequestOperation : NSOperation

// The BNCServerRequest this operation will execute
@property (nonatomic, strong, readonly) BNCServerRequest *request;

// Dependencies to be injected (e.g., from BNCServerRequestQueue)
@property (nonatomic, strong) BNCServerInterface *serverInterface;
@property (nonatomic, copy) NSString *branchKey;
@property (nonatomic, strong) BNCPreferenceHelper *preferenceHelper;

// Designated initializer
- (instancetype)initWithRequest:(BNCServerRequest *)request NS_DESIGNATED_INITIALIZER;
- (instancetype)init NS_UNAVAILABLE; // Prevent calling default init

@end
