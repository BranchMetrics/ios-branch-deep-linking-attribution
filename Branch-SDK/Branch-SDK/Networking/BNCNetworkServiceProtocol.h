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
@property (readonly, copy)   NSMutableURLRequest *request;

/// The response from the server.
@property (readonly, copy)   NSHTTPURLResponse   *response;

/// The data from the server.
@property (readonly, strong) NSData              *responseData;

/// Any errors that occured during the request.
@property (readonly, copy)   NSError             *error;

/// The timeout date for the operation.
@property (strong)           NSDate              *timeoutDate;

/// The start date of the operation.
@property (readonly, copy)   NSDate              *dateStart;

/// The date the operation actually finished.
@property (readonly, copy)   NSDate              *dateFinish;

/// Starts the network operation.
- (void) start;

/// Cancels a queued or in progress network operation.
- (void) cancel;
@end

#pragma mark - BNCNetworkServiceProtocol

/** 
    The `BNCNetworkServiceProtocol` defines a network service that handles a queue of network
    operations.
*/
@protocol BNCNetworkServiceProtocol <NSObject>

/// Creates and returns a new network service.
+ (id<BNCNetworkServiceProtocol>) new;

/// Sets the maximum number of concurrent network operations.
@property (assign) NSInteger maximumConcurrentOperations;

/// Temporarily suspend network operations. In-flight network operations may continue.
@property (assign, getter=operationsAreSuspended) BOOL suspendOperations;

/// Cancel all current and queued network operations.
- (void) cancelAllOperations;


/// Create a new network operation object. The network operation is not started until
/// `[operation start]` is called.
- (id<BNCNetworkOperationProtocol>) networkOperationWithURLRequest:(NSMutableURLRequest*)request
                completion:(void (^)(id<BNCNetworkOperationProtocol>operation))completion;

@end
