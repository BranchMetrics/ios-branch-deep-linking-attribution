//
//  BranchLifecycleTestIsolation.h
//  BranchSDKTests
//
//  Copyright © 2026 Branch, Inc. All rights reserved.
//

#import <XCTest/XCTest.h>

@class Branch;

NS_ASSUME_NONNULL_BEGIN

// Isolates a test that drives Branch's lifecycle handlers by hand from the shared singleton.
@interface XCTestCase (BranchLifecycleIsolation)

// Removes the lifecycle observers Branch registers, so a real app transition cannot run mid-test.
- (void)detachLifecycleObserversFromBranch:(Branch *)branch;

// Restores exactly the registrations Branch makes once per process.
- (void)reattachLifecycleObserversToBranch:(Branch *)branch;

// Runs isolation-queue work left by earlier tests against a throwaway suspended request queue.
- (void)absorbPendingIsolationQueueWorkForBranch:(Branch *)branch;

@end

NS_ASSUME_NONNULL_END
