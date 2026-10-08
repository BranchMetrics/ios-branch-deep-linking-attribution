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
 leaving no way to undo a prior EU routing choice. A configuration that never touches
 `euEndpoint` leaves `BNCServerAPI.useEUServers` alone.
 */
@property (nonatomic, assign, readonly) BOOL euEndpointWasSet;

/// YES once the matching property has been assigned through its setter, including an assignment of
/// its default value. `+[Branch updateConfiguration:]` applies only the assigned values.
@property (nonatomic, assign, readonly) BOOL testModeWasSet;
@property (nonatomic, assign, readonly) BOOL networkTimeoutWasSet;
@property (nonatomic, assign, readonly) BOOL retryCountWasSet;
@property (nonatomic, assign, readonly) BOOL retryIntervalWasSet;
@property (nonatomic, assign, readonly) BOOL thirdPartyAPIsWaitTimeWasSet;
@property (nonatomic, assign, readonly) BOOL limitFacebookAttributionWasSet;
@property (nonatomic, assign, readonly) BOOL adNetworkCalloutsDisabledWasSet;
@property (nonatomic, assign, readonly) BOOL automaticOpenEventsWasSet;

/// Each returns nil when the field is valid, otherwise the message `-validate:` reports for it.
- (nullable NSString *)networkTimeoutValidationMessage;
- (nullable NSString *)retryCountValidationMessage;
- (nullable NSString *)retryIntervalValidationMessage;
- (nullable NSString *)thirdPartyAPIsWaitTimeValidationMessage;
- (nullable NSString *)apiUrlValidationMessage;
- (nullable NSString *)safeTrackAPIUrlValidationMessage;

@end

NS_ASSUME_NONNULL_END
