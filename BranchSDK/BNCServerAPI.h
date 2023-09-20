//
//  BNCServerAPI.h
//  BranchSDK
//
//  Created by Nidhi Dixit on 8/29/23.
//

#if __has_feature(modules)
@import Foundation;
#else
#import <Foundation/Foundation.h>
#endif

NS_ASSUME_NONNULL_BEGIN

@interface BNCServerAPI : NSObject

+ (BNCServerAPI *)sharedInstance;

// retrieves appropriate service URL
- (NSURL *)installServiceURL;
- (NSURL *)openServiceURL;
- (NSURL *)eventServiceURL;
- (NSURL *)linkServiceURL;

// initially set when IDFA is allowed
- (BOOL)useTrackingDomain;

// TODO : Add a config or public API to expose this to clients
// Enable/Disable EU domains
- (void)setUseEUServers:(BOOL)useEUServers;

- (BOOL)useEUServers;

- (NSString *) getBaseURLWithVersion;
@end

NS_ASSUME_NONNULL_END



