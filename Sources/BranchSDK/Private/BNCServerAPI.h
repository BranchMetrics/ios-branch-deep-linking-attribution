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

- (NSString *)installServiceURL;
- (NSString *)openServiceURL;
- (NSString *)standardEventServiceURL;
- (NSString *)customEventServiceURL;
- (NSString *)linkServiceURL;
- (NSString *)qrcodeServiceURL;
- (NSString *)latdServiceURL;
- (NSString *)validationServiceURL;

@property (nonatomic, assign, readwrite) BOOL useTrackingDomain;
@property (nonatomic, assign, readwrite) BOOL useEUServers;

// Enable tracking domains based on IDFA authorization. YES by default
// Used to enable unit tests without regard for ATT authorization status
@property (nonatomic, assign, readwrite) BOOL automaticallyEnableTrackingDomain;

@property (nonatomic, copy, readwrite, nullable) NSString *customAPIURL;
@property (nonatomic, copy, readwrite, nullable) NSString *customSafeTrackAPIURL;

@end

NS_ASSUME_NONNULL_END



