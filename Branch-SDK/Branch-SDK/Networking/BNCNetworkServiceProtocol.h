//
//  BNCNetworkServiceProtocol.h
//  Branch-SDK
//
//  Created by Edward Smith on 5/30/17.
//  Copyright © 2017 Branch Metrics. All rights reserved.
//

#import <Foundation/Foundation.h>

#pragma mark BNCNetworkOperationProtocol

@protocol BNCNetworkOperationProtocol <NSObject>
@property (readonly, copy)   NSURLRequest       *request;
@property (readonly, copy)   NSHTTPURLResponse  *response;
@property (readonly, strong) NSData             *responseData;
@property (readonly, copy)   NSError            *error;
@property (strong)           NSDate             *timeoutDate;

- (void) start;
- (void) cancel;
@end

#pragma mark - BNCNetworkServiceProtocol

@protocol BNCNetworkServiceProtocol <NSObject>

+ (id<BNCNetworkServiceProtocol>) new;

@property (assign) NSInteger maximumConcurrentOperations;
@property (assign, getter=operationsAreSuspended) BOOL suspendOperations;

- (void) cancelAllOperations;

- (id<BNCNetworkOperationProtocol>) networkOperationWithURLRequest:(NSURLRequest*)request
                completion:(void (^)(id<BNCNetworkOperationProtocol>operation))completion;

@end
