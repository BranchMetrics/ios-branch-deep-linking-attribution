//
//  TestBedDeepLinkTestHook.m
//  Branch-TestBed
//

#import "TestBedDeepLinkTestHook.h"

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

    // Delay so the launch open is not still in flight when the activity
    // arrives. Same 1.5s master uses, for a different reason: this line
    // resolves links through requestDeepLinkData:, not initSession.
    dispatch_after(
        dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1.5 * NSEC_PER_SEC)),
        dispatch_get_main_queue(),
        ^{
            NSUserActivity *activity =
                [[NSUserActivity alloc] initWithActivityType:NSUserActivityTypeBrowsingWeb];
            activity.webpageURL = url;

            NSLog(@"[TestHook] Delivering synthetic continueUserActivity: %@", url);
            [application.delegate application:application
                        continueUserActivity:activity
                          restorationHandler:^(NSArray<id<UIUserActivityRestoring>> *_Nullable restorableObjects) {
                              NSLog(@"[TestHook] Synthetic continueUserActivity restorationHandler called");
                          }];
        });
#endif
}

@end
