//
//  SceneDelegate.m
//  Branch-TestBed
//
//  Owns the window under the UIKit scene life cycle. Cold-launch deep link
//  data arrives in `connectionOptions` here, not in AppDelegate's
//  `didFinishLaunchingWithOptions:`. Emits the same `[TestBedLifecycle]`
//  markers AppDelegate used to write, via `appDelegate`'s `logLifecycleMarker:`.
//

#import "SceneDelegate.h"
#import "AppDelegate.h"
@import BranchSDK;

extern AppDelegate *appDelegate;

@implementation SceneDelegate

- (void)scene:(UIScene *)scene
willConnectToSession:(UISceneSession *)session
      options:(UISceneConnectionOptions *)connectionOptions {

    if (![scene isKindOfClass:[UIWindowScene class]]) {
        return;
    }
    UIWindowScene *windowScene = (UIWindowScene *)scene;

    UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"Main" bundle:nil];
    UIViewController *rootViewController = [storyboard instantiateInitialViewController];

    self.window = [[UIWindow alloc] initWithWindowScene:windowScene];
    self.window.rootViewController = rootViewController;
    [self.window makeKeyAndVisible];

    // Reaches the scene API only when a URL or activity is present, so a
    // no-link cold start makes no deep-link request.
    if (connectionOptions.URLContexts.count) {
        [appDelegate logLifecycleMarker:@"openURL"];
    }
    if (connectionOptions.userActivities.count || connectionOptions.URLContexts.count) {
        [[Branch sharedInstance] requestDeepLinkDataWithSceneOptions:connectionOptions
                                                                scene:scene
                                                             callback:nil];
    }
}

// Warm open via a custom URL scheme, e.g. `xcrun simctl openurl <udid> "branchtest://..."`
// while the scene is already connected.
- (void)scene:(UIScene *)scene openURLContexts:(NSSet<UIOpenURLContext *> *)URLContexts {
    // hot_uriScheme and warm_uriScheme count this marker (scripts/check_foreground_markers.py); move it with any new URL entry point.
    [appDelegate logLifecycleMarker:@"openURL"];
    [[Branch sharedInstance] requestDeepLinkDataWithScene:scene openURLContexts:URLContexts];
}

// Warm open via a Universal Link while the scene is already connected.
- (void)scene:(UIScene *)scene continueUserActivity:(NSUserActivity *)userActivity {
    // hot_https_foreground counts this marker (scripts/check_foreground_markers.py).
    [appDelegate logLifecycleMarker:@"continueUserActivity"];
    [[Branch sharedInstance] requestDeepLinkDataWithScene:scene continueUserActivity:userActivity];
}

- (void)sceneWillResignActive:(UIScene *)scene { [appDelegate logLifecycleMarker:@"applicationWillResignActive"]; }
- (void)sceneDidEnterBackground:(UIScene *)scene {
    [appDelegate logLifecycleMarker:@"applicationDidEnterBackground"];
    // Two main-queue hops land after the SDK's background clear, so the report reads the cleared value (scripts/check_no_stickiness.py).
    dispatch_async(dispatch_get_main_queue(), ^{
        dispatch_async(dispatch_get_main_queue(), ^{
            [appDelegate logLatestReferringParams];
        });
    });
}
- (void)sceneDidBecomeActive:(UIScene *)scene {
    [appDelegate logLifecycleMarker:@"applicationDidBecomeActive"];
    [appDelegate logLatestReferringParams];
}

@end
