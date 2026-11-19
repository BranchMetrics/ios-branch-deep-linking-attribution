//
//  TestBedSpotlightSceneTestHook.h
//  Branch-TestBed
//
//  DEBUG-only wire-check hooks for a Spotlight NSUserActivity carrying a Branch link identifier,
//  delivered through two different entry points so each can be captured on the wire
//  (branchlogs.txt).
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface TestBedSpotlightSceneTestHook : NSObject

/// Delivers a synthetic `CSSearchableItemActionType` activity, carrying `<url>` as its
/// `CSSearchableItemActivityIdentifier`, if the app was launched with `-testSpotlightWarmURL
/// <url>` and/or `-testSpotlightColdURL <url>`; does nothing for either that is absent. Both
/// launch arguments can be set in the same launch and are delivered independently.
///
///  - `-testSpotlightWarmURL`: delivers through the connected scene delegate's real
///    `-scene:continueUserActivity:` (UIKit's own warm-continuation entry point), which calls
///    `-[Branch requestDeepLinkDataWithScene:continueUserActivity:]`. Realistic delivery: the
///    same delegate method UIKit would call for an app already running.
///  - `-testSpotlightColdURL`: calls `-[Branch requestDeepLinkDataWithSceneOptions:scene:callback:]`
///    directly against the connected scene, with a synthetic `UISceneConnectionOptions` double
///    carrying the activity. `UISceneConnectionOptions` has no public initializer, so the double
///    is a subclass built with `+alloc` alone (never `-init`), overriding `-userActivities` to
///    stand in for the value `-scene:willConnectToSession:options:` would have delivered on a
///    real cold launch.
///
/// Delivery waits for `BranchDidStartSessionNotification` so a synthetic activity always lands
/// after the launch-time automatic open, never racing it, with a ten-second fallback --
/// matching `TestBedDeepLinkTestHook`.
///
/// Exercises the SDK's handling of a Spotlight activity, not the OS delivering one: an unsigned
/// simulator build has no route for a real Spotlight-tap handoff. The cold call also runs after
/// the launch session has already started, so it exercises the open path the SDK takes once
/// initialized, not an install, and it says nothing about ordering against a real cold
/// connection -- `-scene:willConnectToSession:options:` itself is never invoked here.
+ (void)installIfRequested:(UIApplication *)application;

@end

NS_ASSUME_NONNULL_END
