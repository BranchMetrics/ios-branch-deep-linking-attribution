//
//  Branch+LinkGeneration.h
//  BranchSDK
//
//  Created by Brandon Boothe on 8/31/26.
//

#import "Branch.h"

NS_ASSUME_NONNULL_BEGIN

/**
 The collaborators `BranchLinkBuilder` needs in order to generate links.

 All five live in the file-private class extension in `Branch.m`. Link generation used to be a set
 of methods on `Branch` itself, so it reached them directly; now that it lives in
 `BranchLinkBuilder`, they have to be visible outside that file. This category is the narrowest way
 to do that — readonly, private header, no promotion to `Public/`.
 */
@interface Branch (LinkGeneration)

/// Serializes link generation against the rest of the SDK's work. The async short-URL and
/// spotlight terminals do their whole body inside a `dispatch_async` onto this queue.
@property (nonatomic, strong, readonly) dispatch_queue_t isolationQueue;

/// Short-URL response cache, keyed by `BNCLinkData`. Read and written by both short-URL terminals.
@property (nonatomic, strong, readonly) BNCLinkCache *linkCache;

/// Where the async short-URL and spotlight requests are enqueued.
@property (nonatomic, strong, readonly) BNCServerRequestQueue *requestQueue;

/// Supplies `sanitizedMutableBaseURL:` and `userUrl` to the long-URL terminal.
@property (nonatomic, strong, readonly) BNCPreferenceHelper *preferenceHelper;

/// The blocking short-URL terminal hands this to `BranchShortUrlSyncRequest makeRequest:key:`.
/// Also the injection seam the builder's network tests use.
@property (nonatomic, strong, readonly) BNCServerInterface *serverInterface;

@end

NS_ASSUME_NONNULL_END
