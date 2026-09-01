//
//  BranchConfiguration+Private.h
//  BranchSDK
//
//  Created by Brandon Boothe on 8/31/26.
//

#import "BranchConfiguration.h"

NS_ASSUME_NONNULL_BEGIN

@interface BranchConfiguration (Private)

/**
 YES once `logLevel` has been assigned through its setter — including an assignment to
 `BranchLogLevelVerbose`, which is 0 and so indistinguishable from "unset" by value alone.

 `+[Branch initialize:]` uses this to decide whether the caller asked for logging at all. A
 configuration whose `logLevel` was never touched leaves the logger untouched, so `branch.json`'s
 `enableLogging` and an explicit `+[Branch enableLogging]` still control it.
 */
@property (nonatomic, assign, readonly) BOOL logLevelWasSet;

/**
 YES once `euEndpoint` has been assigned through its setter, including an assignment to NO.

 `+[Branch initialize:]` uses this so that `euEndpoint = NO` reads as "route to the default
 endpoints" rather than "no opinion". Without it a configuration could only ever turn EU routing on,
 leaving no way to undo a prior `-[Branch useEUEndpoints]` call. A configuration that never touches
 `euEndpoint` leaves `BNCServerAPI.useEUServers` alone.
 */
@property (nonatomic, assign, readonly) BOOL euEndpointWasSet;

@end

NS_ASSUME_NONNULL_END
