//
//  BNCNetworkService.h
//  Branch-SDK
//
//  Created by Edward Smith on 5/30/17.
//  Copyright © 2017 Branch Metrics. All rights reserved.
//

#import "BNCNetworkServiceProtocol.h"

/**
 BNCNetworkService and BNCNetworkOperation

 The BNCNetworkService and BNCNetworkOperation classes are concrete implementations of the
 BNCNetworkServiceProtocol and BNCNetworkOperationProtocol protocols.
*/

#pragma mark BNCNetworkOperation

@interface BNCNetworkOperation : NSObject <BNCNetworkOperationProtocol>
@property (nonatomic, readonly, copy)   NSURLRequest       *request;
@property (nonatomic, readonly, copy)   NSHTTPURLResponse  *response;
@property (nonatomic, readonly, strong) NSData             *responseData;
@property (nonatomic, readonly, copy)   NSError            *error;
@property (nonatomic, readonly, copy)   NSDate             *startDate;
@property (nonatomic, readonly, copy)   NSDate             *timeoutDate;
@property (nonatomic, strong)           NSDictionary       *userInfo;

- (void) start;
- (void) cancel;
@end

#pragma mark - BNCNetworkService

@interface BNCNetworkService : NSObject <BNCNetworkServiceProtocol, NSURLSessionDelegate>
+ (instancetype) new;

- (void) cancelAllOperations;

- (BNCNetworkOperation*) networkOperationWithURLRequest:(NSMutableURLRequest*)request
                completion:(void (^)(id<BNCNetworkOperationProtocol>operation))completion;

@property (strong, nonatomic) NSDictionary *userInfo;
@end
