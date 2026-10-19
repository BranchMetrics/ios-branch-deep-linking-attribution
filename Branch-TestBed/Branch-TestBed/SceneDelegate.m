//
//  SceneDelegate.m
//  Branch-TestBed
//
//  Owns the window under the UIKit scene life cycle. Cold-launch deep link
//  data arrives in `connectionOptions` here, not in AppDelegate's
//  `didFinishLaunchingWithOptions:`. The `[TestBedLifecycle]` markers are still
//  written by AppDelegate's `logLifecycleMarker:`; the scene callbacks forward to it.
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
    [[Branch sharedInstance] requestDeepLinkDataWithScene:scene continueUserActivity:userActivity];
}

// Under the scene life cycle UIKit calls these instead of the app delegate's
// `applicationWillResignActive:`, `applicationDidEnterBackground:` and
// `applicationDidBecomeActive:`. The SDK still observes the UIApplication
// notifications for those transitions (Branch.m), not the scene callbacks, and
// the L1 marker checks count the markers those app delegate methods write. So
// the scene callbacks only forward to the app delegate methods, which stay.
- (void)sceneWillResignActive:(UIScene *)scene {
    [appDelegate applicationWillResignActive:[UIApplication sharedApplication]];
}

- (void)sceneDidEnterBackground:(UIScene *)scene {
    [appDelegate applicationDidEnterBackground:[UIApplication sharedApplication]];
}

- (void)sceneDidBecomeActive:(UIScene *)scene {
    [appDelegate applicationDidBecomeActive:[UIApplication sharedApplication]];
}

@end
