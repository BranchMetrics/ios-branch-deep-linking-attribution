//
//  BranchLifecycleTestIsolation.m
//  BranchSDKTests
//
//  Copyright © 2026 Branch, Inc. All rights reserved.
//

#import "BranchLifecycleTestIsolation.h"
#import <UIKit/UIKit.h>
#import "Branch.h"
#import "BNCServerRequestQueue.h"

@interface BNCServerRequestQueue (LifecycleIsolation)
@property (strong, nonatomic) NSOperationQueue *operationQueue;
@end

@implementation XCTestCase (BranchLifecycleIsolation)

- (void)detachLifecycleObserversFromBranch:(Branch *)branch {
    NSNotificationCenter *center = [NSNotificationCenter defaultCenter];
    [center removeObserver:branch name:UIApplicationWillResignActiveNotification object:nil];
    [center removeObserver:branch name:UIApplicationDidEnterBackgroundNotification object:nil];
    [center removeObserver:branch name:UIApplicationDidBecomeActiveNotification object:nil];
}

// Mirrors -[Branch initWithInterface:queue:cache:preferenceHelper:key:], which runs once per process.
- (void)reattachLifecycleObserversToBranch:(Branch *)branch {
    NSNotificationCenter *center = [NSNotificationCenter defaultCenter];
    [center addObserver:branch
               selector:NSSelectorFromString(@"applicationWillResignActive")
                   name:UIApplicationWillResignActiveNotification
                 object:nil];
    [center addObserver:branch
               selector:NSSelectorFromString(@"applicationDidEnterBackground")
                   name:UIApplicationDidEnterBackgroundNotification
                 object:nil];
    [center addObserver:branch
               selector:NSSelectorFromString(@"applicationDidBecomeActive")
                   name:UIApplicationDidBecomeActiveNotification
                 object:nil];
}

// A pending block reads branch.requestQueue when it runs, so it would otherwise enqueue into the
// queue under test. Polls a sentinel rather than blocking main, since isolation work can wait on main.
- (void)absorbPendingIsolationQueueWorkForBranch:(Branch *)branch {
    BNCServerRequestQueue *absorbingQueue = [BNCServerRequestQueue new];
    absorbingQueue.operationQueue.suspended = YES;
    [branch setValue:absorbingQueue forKey:@"requestQueue"];

    NSObject *lock = [NSObject new];
    __block BOOL drained = NO;
    dispatch_async([branch valueForKey:@"isolationQueue"], ^{
        @synchronized (lock) { drained = YES; }
    });
    NSPredicate *predicate = [NSPredicate predicateWithBlock:^BOOL(id object, NSDictionary *bindings) {
        @synchronized (lock) { return drained; }
    }];
    XCTNSPredicateExpectation *expectation = [[XCTNSPredicateExpectation alloc] initWithPredicate:predicate object:self];
    XCTWaiterResult result = [XCTWaiter waitForExpectations:@[expectation] timeout:15.0];
    XCTAssertEqual(result, XCTWaiterResultCompleted, @"Timed out absorbing pending isolation queue work.");

    [absorbingQueue.operationQueue cancelAllOperations];
}

@end
