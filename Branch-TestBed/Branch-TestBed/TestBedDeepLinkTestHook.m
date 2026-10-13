//
//  TestBedDeepLinkTestHook.m
//  Branch-TestBed
//

#import "TestBedDeepLinkTestHook.h"

@implementation TestBedDeepLinkTestHook

#if DEBUG
/// The `-testDeepLinkURL` launch argument as a URL, or nil when it is absent or invalid.
+ (nullable NSURL *)testLinkURL {
    NSString *testDeepLinkURL =
        [[NSUserDefaults standardUserDefaults] stringForKey:@"testDeepLinkURL"];
    if (testDeepLinkURL.length == 0) {
        return nil;
    }

    NSURL *url = [NSURL URLWithString:testDeepLinkURL];
    if (url == nil) {
        NSLog(@"[TestHook] -testDeepLinkURL is not a valid URL: %@", testDeepLinkURL);
    }
    return url;
}
#endif

+ (nullable NSDictionary *)launchOptionsByAddingTestLink:(nullable NSDictionary *)launchOptions {
#if DEBUG
    NSURL *url = [self testLinkURL];
    if (url == nil) {
        return launchOptions;
    }

    // On a real cold Universal Link launch iOS puts the activity in the launch
    // options, and the SDK reads that key to skip the nil-URL deferred lookup.
    // The test link arrives later through continueUserActivity:, so without
    // this the launch would send a lookup of its own ahead of the link's.
    NSMutableDictionary *options = [launchOptions mutableCopy] ?: [NSMutableDictionary dictionary];
    NSUserActivity *activity =
        [[NSUserActivity alloc] initWithActivityType:NSUserActivityTypeBrowsingWeb];
    activity.webpageURL = url;
    options[UIApplicationLaunchOptionsUserActivityDictionaryKey] = @{
        UIApplicationLaunchOptionsUserActivityTypeKey: NSUserActivityTypeBrowsingWeb,
        @"UIApplicationLaunchOptionsUserActivityKey": activity,
    };
    return options;
#else
    return launchOptions;
#endif
}

+ (void)installIfRequested:(UIApplication *)application {
#if DEBUG
    NSURL *url = [self testLinkURL];
    if (url == nil) {
        return;
    }

    NSLog(@"[TestHook] -testDeepLinkURL received: %@", url);

    // Approximates a cold Universal Link launch: delivered after launch returns,
    // with the activity already in launchOptions (see
    // launchOptionsByAddingTestLink:). Nothing is queued ahead of the link, so
    // there is no session start to wait for.
    dispatch_async(dispatch_get_main_queue(), ^{
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
