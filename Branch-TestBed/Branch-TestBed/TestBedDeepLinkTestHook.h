//
//  TestBedDeepLinkTestHook.h
//  Branch-TestBed
//
//  Test-only hook that simulates a Universal Link arrival, so the
//  DeepLink*HybridTest cases can drive a deep link from XCUITest.
//  DEBUG builds only.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface TestBedDeepLinkTestHook : NSObject

/// Returns `launchOptions` carrying the `-testDeepLinkURL` link as a user
/// activity, the way iOS does on a cold Universal Link launch. Returns the
/// input unchanged when the argument is absent or not a valid URL.
///
/// Pass the result to `requestDeepLinkDataWithLaunchOptions:callback:`. With
/// a link in the launch options the SDK sends no nil-URL deferred lookup, so
/// the link is the only `/v3/deeplink` of the launch.
+ (nullable NSDictionary *)launchOptionsByAddingTestLink:(nullable NSDictionary *)launchOptions;

/// Delivers a synthetic Universal Link if the app was launched with
/// `-testDeepLinkURL <url>`, and does nothing otherwise. The URL is wrapped in
/// an `NSUserActivity` and passed to the delegate's
/// `application:continueUserActivity:restorationHandler:`.
///
/// Delivery is queued on the main queue right after launch, the same moment
/// iOS calls `continueUserActivity:` on a cold Universal Link launch.
///
/// Exercises the SDK's handling of a link, not the OS delivering one: an
/// unsigned simulator build has no route for real Universal Link handoff.
+ (void)installIfRequested:(UIApplication *)application;

@end

NS_ASSUME_NONNULL_END
