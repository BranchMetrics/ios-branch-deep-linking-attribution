//
//  BranchSessionCoordinator.h
//  Branch iOS SDK
//
//  Copyright © 2026 Branch Metrics. All rights reserved.
//  SPDX-License-Identifier: MIT
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@class BranchSession;

/**
 Coordinates session management with task coalescing support.

 This class provides the bridge between the modern Swift SessionManager
 and the legacy Objective-C SDK. It implements task coalescing to prevent
 the "Double Open" issue (INTENG-21106) during Universal Link cold starts.

 ## Thread Safety

 All methods are thread-safe and can be called from any thread.
 Completions are always called on the main thread.

 ## Usage

 ```objc
 // Initialize session (typically from didFinishLaunchingWithOptions)
 [[BranchSessionCoordinator shared] initializeSessionWithCompletion:^(BranchSession *session, NSError *error) {
     // Handle result
 }];

 // Handle Universal Link (from continueUserActivity)
 [[BranchSessionCoordinator shared] continueUserActivity:userActivity
                                              completion:^(BranchSession *session, NSError *error) {
     // Handle result
 }];
 ```

 ## Task Coalescing

 When multiple initialization calls are made concurrently (common during cold launch
 via Universal Links), they are automatically coalesced into a single network request.
 Any URL that arrives during initialization is queued and merged into the final session.
 */
@interface BranchSessionCoordinator : NSObject

/// Shared coordinator instance
@property (class, readonly) BranchSessionCoordinator *shared;

/// Whether the SDK is currently initializing
@property (nonatomic, readonly) BOOL isInitializing;

/// Whether the SDK is initialized
@property (nonatomic, readonly) BOOL isInitialized;

#pragma mark - Session Initialization

/**
 Initialize a session without a URL.

 @param completion Callback with the session result. Called on main thread.
 */
- (void)initializeSessionWithCompletion:(void (^)(BranchSession * _Nullable session, NSError * _Nullable error))completion;

/**
 Initialize a session with a URL.

 @param url Optional URL that opened the app
 @param completion Callback with the session result. Called on main thread.
 */
- (void)initializeSessionWithURL:(nullable NSURL *)url
                      completion:(void (^)(BranchSession * _Nullable session, NSError * _Nullable error))completion;

#pragma mark - Deep Link Handling

/**
 Handle a deep link URL.

 If initialization is in progress, the URL will be queued via task coalescing.

 @param url The deep link URL
 @param completion Callback with the updated session. Called on main thread.
 */
- (void)handleDeepLinkWithURL:(NSURL *)url
                   completion:(void (^)(BranchSession * _Nullable session, NSError * _Nullable error))completion;

/**
 Handle a Universal Link via NSUserActivity.

 @param userActivity The user activity containing the Universal Link
 @param completion Callback with the updated session. Called on main thread.
 */
- (void)continueUserActivity:(NSUserActivity *)userActivity
                  completion:(void (^)(BranchSession * _Nullable session, NSError * _Nullable error))completion;

#pragma mark - Session Control

/**
 Reset the session to uninitialized state.
 */
- (void)resetSession;

/**
 Set user identity.

 @param userId The user identifier
 @param completion Callback with result. Called on main thread.
 */
- (void)setIdentity:(NSString *)userId
         completion:(void (^)(NSError * _Nullable error))completion;

/**
 Clear user identity (logout).

 @param completion Callback with result. Called on main thread.
 */
- (void)logoutWithCompletion:(void (^)(NSError * _Nullable error))completion;

@end

#pragma mark - BranchSession

/**
 Represents an initialized Branch session.

 Contains all information about the current session including
 any deep link data that was used to open the app.
 */
@interface BranchSession : NSObject

/// The unique session identifier
@property (nonatomic, readonly) NSString *sessionId;

/// The Branch identity ID
@property (nonatomic, readonly) NSString *identityId;

/// The device fingerprint ID
@property (nonatomic, readonly) NSString *deviceFingerprintId;

/// Whether this is the first session (install)
@property (nonatomic, readonly) BOOL isFirstSession;

/// The user ID, if set
@property (nonatomic, readonly, nullable) NSString *userId;

/// The URL that opened the app, if any
@property (nonatomic, readonly, nullable) NSURL *linkUrl;

/// The deep link parameters, if any
@property (nonatomic, readonly) NSDictionary<NSString *, id> *linkData;

@end

NS_ASSUME_NONNULL_END
