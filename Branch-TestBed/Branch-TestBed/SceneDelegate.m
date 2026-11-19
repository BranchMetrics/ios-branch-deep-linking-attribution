//
//  SceneDelegate.m
//  Branch-TestBed
//
//  Owns the window under the UIKit scene life cycle and receives the cold-launch
//  `connectionOptions` deep link data.
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

    // Only request deep link data when a URL or activity is present.
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
    // hot_uriScheme and warm_uriScheme count this marker
    // (scripts/check_foreground_markers.py).
    [appDelegate logLifecycleMarker:@"openURL"];
    [[Branch sharedInstance] requestDeepLinkDataWithScene:scene openURLContexts:URLContexts];
}

// Warm open via a Universal Link while the scene is already connected.
- (void)scene:(UIScene *)scene continueUserActivity:(NSUserActivity *)userActivity {
    // hot_https_foreground counts this marker (scripts/check_foreground_markers.py).
    [appDelegate logLifecycleMarker:@"continueUserActivity"];
    [[Branch sharedInstance] requestDeepLinkDataWithScene:scene continueUserActivity:userActivity];
}

// Scene callbacks forward to the app delegate methods, because the L1 marker
// checks count the markers those methods write.
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
