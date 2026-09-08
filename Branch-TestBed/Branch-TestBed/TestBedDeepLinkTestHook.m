//
//  TestBedDeepLinkTestHook.m
//  Branch-TestBed
//

#import "TestBedDeepLinkTestHook.h"
@import BranchSDK;

@implementation TestBedDeepLinkTestHook

+ (void)installIfRequested:(UIApplication *)application {
#if DEBUG
    NSString *testDeepLinkURL =
        [[NSUserDefaults standardUserDefaults] stringForKey:@"testDeepLinkURL"];
    if (testDeepLinkURL.length == 0) {
        return;
    }

    NSURL *url = [NSURL URLWithString:testDeepLinkURL];
    if (url == nil) {
        NSLog(@"[TestHook] -testDeepLinkURL is not a valid URL: %@", testDeepLinkURL);
        return;
    }

    NSLog(@"[TestHook] -testDeepLinkURL received: %@", testDeepLinkURL);

    // Deliver once the launch session has started, never on a timer. A fixed
    // delay makes the order machine-dependent: on a slow first install the
    // link wins, the queue already holds a request, and `installOrOpenInQueue`
    // suppresses the launch open. The capture then differs from a fast machine's.
    __block BOOL delivered = NO;
    __block id observer = nil;
    dispatch_block_t deliver = ^{
        if (delivered) {
            return;
        }
        delivered = YES;
        if (observer) {
            [[NSNotificationCenter defaultCenter] removeObserver:observer];
            observer = nil;
        }

        NSUserActivity *activity =
            [[NSUserActivity alloc] initWithActivityType:NSUserActivityTypeBrowsingWeb];
        activity.webpageURL = url;

        NSLog(@"[TestHook] Delivering synthetic continueUserActivity: %@", url);
        [application.delegate application:application
                    continueUserActivity:activity
                      restorationHandler:^(NSArray<id<UIUserActivityRestoring>> *_Nullable restorableObjects) {
                          NSLog(@"[TestHook] Synthetic continueUserActivity restorationHandler called");
                      }];
    };

    observer = [[NSNotificationCenter defaultCenter]
        addObserverForName:BranchDidStartSessionNotification
                    object:nil
                     queue:[NSOperationQueue mainQueue]
                usingBlock:^(NSNotification *note) {
                    NSLog(@"[TestHook] Session started; delivering the link");
                    deliver();
                }];

    // A session that never starts must not hang the test. Ten seconds is well
    // past a healthy launch and still inside the driver's settle window.
    dispatch_after(
        dispatch_time(DISPATCH_TIME_NOW, (int64_t)(10.0 * NSEC_PER_SEC)),
        dispatch_get_main_queue(),
        ^{
            if (!delivered) {
                NSLog(@"[TestHook] No session start within 10s; delivering anyway");
                deliver();
            }
        });
#endif
}

@end
