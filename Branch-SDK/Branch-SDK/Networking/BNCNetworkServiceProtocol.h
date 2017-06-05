//
//  BNCNetworkServiceProtocol.h
//  Branch-SDK
//
//  Created by Edward Smith on 5/30/17.
//  Copyright © 2017 Branch Metrics. All rights reserved.
//

#import <Foundation/Foundation.h>

#pragma mark BNCNetworkOperationProtocol

/**
    The `BNCNetworkServiceProtocol` and `BNCNetworkOperationProtocol` define protocols for 
    a drop in replacement for the standard Branch SDK networking.

    To use your own networking class, it must conforms to these network protocols. Set your
    networking class at run time by calling:
        
        `BranchSetNetworkServiceClass(Class networkServiceClass)`

    with your class as a parameter before any other Branch methods are called.
*/
@protocol BNCNetworkOperationProtocol <NSObject>

/// The initial NSMutableURLRequest.
@required
@property (readonly, copy)   NSMutableURLRequest *request;

/// The response from the server.
@required
@property (readonly, copy)   NSHTTPURLResponse   *response;

/// The data from the server.
@required
@property (readonly, strong) NSData              *responseData;

/// Any errors that occured during the request.
@required
@property (readonly, copy)   NSError             *error;

/// The original start date of the operation. This should be set by the network service provider
/// when the operation is started.
@required
@property (readonly, copy)   NSDate              *startDate;

/// The timeout date for the operation.  This is calculated and set by the underlying network service
/// provider by taking the original start date and adding the timeout interval of the URL request.
/// It should be set once (and not recalculated for each retry) by the network service.
@required
@property (readonly, copy)   NSDate              *timeoutDate;

/// A dictionary for the Branch SDK to store operation user info.
@required
@property (strong)          NSDictionary         *userInfo;

/// Starts the network operation.
@required
- (void) start;

/// Cancels a queued or in progress network operation.
@required
- (void) cancel;
@end

#pragma mark - BNCNetworkServiceProtocol

/** 
    The `BNCNetworkServiceProtocol` defines a network service that handles a queue of network
    operations.
*/
@protocol BNCNetworkServiceProtocol <NSObject>

/// Creates and returns a new network service.
@optional
+ (id<BNCNetworkServiceProtocol>) new;

/// Creates and returns a new network service pinned to an array of public keys.
@optional
+ (id<BNCNetworkServiceProtocol>) networkServiceWithPinnedPublicKeys:(NSArray<NSData*>*/*_Nullable*/)keyArray;

/// Cancel all current and queued network operations.
@required
- (void) cancelAllOperations;

/// Create and return a new network operation object. The network operation is not started until
/// `[operation start]` is called.
@required
- (id<BNCNetworkOperationProtocol>) networkOperationWithURLRequest:(NSMutableURLRequest*)request
                completion:(void (^)(id<BNCNetworkOperationProtocol>operation))completion;

/// A dictionary for the Branch SDK to store operation user info.
@required
@property (strong)          NSDictionary         *userInfo;
@end
