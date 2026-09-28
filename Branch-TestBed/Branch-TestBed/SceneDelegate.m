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
    [appDelegate logLifecycleMarker:@"openURL"];
    [[Branch sharedInstance] requestDeepLinkDataWithScene:scene openURLContexts:URLContexts];
}

// Warm open via a Universal Link while the scene is already connected.
- (void)scene:(UIScene *)scene continueUserActivity:(NSUserActivity *)userActivity {
    [[Branch sharedInstance] requestDeepLinkDataWithScene:scene continueUserActivity:userActivity];
}

- (void)sceneWillResignActive:(UIScene *)scene { [appDelegate logLifecycleMarker:@"applicationWillResignActive"]; }
- (void)sceneDidEnterBackground:(UIScene *)scene { [appDelegate logLifecycleMarker:@"applicationDidEnterBackground"]; }
- (void)sceneDidBecomeActive:(UIScene *)scene { [appDelegate logLifecycleMarker:@"applicationDidBecomeActive"]; }

@end
