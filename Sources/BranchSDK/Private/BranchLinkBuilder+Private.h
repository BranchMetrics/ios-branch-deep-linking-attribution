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
 `+[Branch sharedInstance]`, which raises if `+[Branch initialize:]` has not run yet. Resolving in
 `-init` instead would mean that merely constructing a builder before initialization throws, which
 none of the overloads this builder replaces ever did — they were messages to an instance the caller
 already held. Deferring to the terminal keeps the failure at the point of actual use.

 Tests inject a `Branch` whose `serverInterface` is a fake, so the short-URL terminals can be
 exercised without reaching the network.
 */
@property (nonatomic, strong, readonly) Branch *branch;

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

 @param ignoreUAString Passed through to `-setupIgnoreUAString:`. The async terminal hardcodes nil
        here, matching the funnel it replaces.
 */
- (BNCLinkData *)linkDataWithIgnoreUAString:(nullable NSString *)ignoreUAString;

@end

NS_ASSUME_NONNULL_END
