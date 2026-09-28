//
//  SceneDelegate.m
//  Branch-TestBed
//
//  Owns the window under the UIKit scene life cycle (Xcode 27 / iOS 27 require
//  UIApplicationSceneManifest). Cold-launch deep link data arrives in
//  `connectionOptions` here, not in AppDelegate's `didFinishLaunchingWithOptions:`.
//

#import "SceneDelegate.h"
@import BranchSDK;

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

    // Resolves any URL/user-activity carried in connectionOptions (cold launch),
    // and is a no-op that still starts the session when there is none.
    [[Branch sharedInstance] requestDeepLinkDataWithSceneOptions:connectionOptions
                                                            scene:scene
                                                         callback:nil];
}

// Warm open via a custom URL scheme, e.g. `xcrun simctl openurl <udid> "branchtest://..."`
// while the scene is already connected.
- (void)scene:(UIScene *)scene openURLContexts:(NSSet<UIOpenURLContext *> *)URLContexts {
    [[Branch sharedInstance] requestDeepLinkDataWithScene:scene openURLContexts:URLContexts];
}

// Warm open via a Universal Link while the scene is already connected.
- (void)scene:(UIScene *)scene continueUserActivity:(NSUserActivity *)userActivity {
    [[Branch sharedInstance] requestDeepLinkDataWithScene:scene continueUserActivity:userActivity];
}

@end
