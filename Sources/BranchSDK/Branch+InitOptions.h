//
//  Branch+InitOptions.h
//  BranchSDK
//
//  Private header exposing BNCInitializationOptions-based APIs for internal testing.
//  These APIs are not in alpha release scope and should NOT be made public yet.
//

#import "Branch.h"
#import "BNCInitializationOptions.h"

@interface Branch (InitOptions)

- (void)initSessionWithOptions:(BNCInitializationOptions *)options;
- (void)handleDeepLinkWithOptions:(BNCInitializationOptions *)options;

@end
