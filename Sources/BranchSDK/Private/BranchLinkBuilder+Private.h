//
//  BranchLinkBuilder+Private.h
//  BranchSDK
//
//  Created by Brandon Boothe on 8/31/26.
//

#import "BranchLinkBuilder.h"
#import "Branch.h"

NS_ASSUME_NONNULL_BEGIN

@interface BranchLinkBuilder (Private)

/**
 The `Branch` instance the terminals draw their collaborators from — the isolation queue, link
 cache, request queue, preference helper and server interface exposed by
 `Branch (LinkGeneration)`.

 **Resolved lazily, on each read.** When no instance was injected this returns
 `+[Branch sharedInstance]`, which is nil until `+[Branch initialize:]` has run. Resolving in
 `-init` instead would mean that merely constructing a builder before initialization failed.
 Deferring to the terminal keeps the failure at the point of actual use.

 Nil here is not safe to pass on: the async terminals dispatch onto `branch.isolationQueue`, and
 `dispatch_async` with a nil queue crashes. Terminals resolve through
 `-resolvedBranchForTerminal:error:` instead of reading this directly.

 Tests inject a `Branch` whose `serverInterface` is a fake, so the short-URL terminals can be
 exercised without reaching the network.
 */
@property (nonatomic, strong, readonly, nullable) Branch *branch;

/**
 Designated initializer behind `-init`.

 @param branch The instance the terminals should use. Pass nil — as `-init` does — to resolve
        `+[Branch sharedInstance]` lazily on each `branch` read instead.
 */
- (instancetype)initWithBranch:(nullable Branch *)branch;

/**
 Builds the `BNCLinkData` that identifies this link on the wire and, via its `-hash`, in
 `BNCLinkCache`.

 Exposed so tests can pin the exact `setupX:` sequence — `-[BNCLinkData hash]` is the cache key, so
 a change to that sequence silently orphans every previously cached link.

 @param linkProperties The link's content and behavior. May be nil, in which case every option takes
        its default.
 @param ignoreUAString Passed through to `-setupIgnoreUAString:`. The async terminal hardcodes nil
        here, matching the funnel it replaces.
 */
- (BNCLinkData *)linkDataWithLinkProperties:(nullable BranchLinkProperties *)linkProperties
                             ignoreUAString:(nullable NSString *)ignoreUAString;

@end

NS_ASSUME_NONNULL_END
