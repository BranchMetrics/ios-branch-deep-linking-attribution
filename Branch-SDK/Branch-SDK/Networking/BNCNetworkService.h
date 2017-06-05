//
//  BNCNetworkService.h
//  Branch-SDK
//
//  Created by Edward Smith on 5/30/17.
//  Copyright © 2017 Branch Metrics. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "BNCNetworkServiceProtocol.h"

#pragma mark BNCNetworkOperation

@interface BNCNetworkOperation : NSObject <BNCNetworkOperationProtocol>
@property (readonly, copy)   NSMutableURLRequest *request;
@property (readonly, copy)   NSHTTPURLResponse   *response;
@property (readonly, strong) NSData              *responseData;
@property (readonly, copy)   NSError             *error;
@property (readonly, copy)   NSDate              *startDate;
@property (copy)             NSDate              *timeoutDate;

@property (strong)           NSDictionary        *userInfo;

- (void) start;
- (void) cancel;
@end

#pragma mark - BNCNetworkService

@interface BNCNetworkService : NSObject <BNCNetworkServiceProtocol>
+ (id<BNCNetworkServiceProtocol>) new;
+ (id<BNCNetworkServiceProtocol>) networkServiceWithPinnedPublicKeys:(NSArray<NSData*>*/*_Nullable*/)keyArray;

- (void) cancelAllOperations;

- (BNCNetworkOperation*) networkOperationWithURLRequest:(NSMutableURLRequest*)request
                completion:(void (^)(BNCNetworkOperation*operation))completion;

@property (strong) NSDictionary *userInfo;
@end
