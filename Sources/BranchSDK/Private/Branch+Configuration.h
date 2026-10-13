//
//  Branch+Configuration.h
//  BranchSDK
//
//  Created by Brandon Boothe on 9/9/26.
//
//  Copyright © 2026 Branch, Inc. All rights reserved.
//

#import "Branch.h"

NS_ASSUME_NONNULL_BEGIN

/**
 Settings that are applied from a `BranchConfiguration` by `+[Branch initialize:]`.

 The implementations live in the main `@implementation Branch` in `Branch.m`. They are declared
 here rather than in `Branch.h` so they are reachable from inside the SDK and its tests without
 being part of the public API.
 */
@interface Branch (Configuration)

/**
 Sets a custom base URL for all calls to the Branch API.

 @param url  Base URL that the Branch API will use.
 */
+ (void)setAPIUrl:(NSString *)url;

/**
 Sets a custom base safetrack URL for non-linking calls to the Branch API.

 @param url  Base safetrack URL that the Branch API will use.
 */
+ (void)setSafetrackAPIURL:(NSString *)url;

/**
 Sets an array of regex patterns that match URLs for Branch to ignore.

 These are ICU standard regular expressions.

 @param urlsToIgnore  Regex patterns matching URLs that must not be transmitted to Branch.
 */
- (void)setUrlPatternsToIgnore:(NSArray<NSString *> *)urlsToIgnore;

/**
 Checks the pasteboard (clipboard) for a Branch Link on App Install. If found, the Branch Link is
 used to provide deferred deeplink data.

 Note, this may display a toast message to the end user.
 */
- (void)checkPasteboardOnInstall;

/**
 Sets the AppGroup used to share data between the App Clip and the Full App.

 @param appGroup  The app group identifier shared by the App Clip and the full app.
 */
- (void)setAppClipAppGroup:(NSString *)appGroup;

/**
 Sets the time to wait in seconds between retries in the case of a Branch server error.

 @param retryInterval  Number of seconds to wait between retries.
 */
- (void)setRetryInterval:(NSTimeInterval)retryInterval;

/**
 Sets the amount of time before a request should be considered "timed out".

 @param timeout  Number of seconds before a request is considered timed out.
 */
- (void)setNetworkTimeout:(NSTimeInterval)timeout;

@end

NS_ASSUME_NONNULL_END
