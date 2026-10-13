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

/// Delivers a synthetic Universal Link if the app was launched with
/// `-testDeepLinkURL <url>`, and does nothing otherwise. The URL is wrapped in
/// an `NSUserActivity` and passed to the delegate's
/// `application:continueUserActivity:restorationHandler:`.
///
/// Delivery waits for `BranchDidStartSessionNotification` so the link always
/// follows the launch open, with a ten-second fallback.
///
/// Exercises the SDK's handling of a link, not the OS delivering one (no
/// LaunchServices or associated-domains routing). The argument is read only at
/// launch, so a running process must be relaunched to receive a link.
+ (void)installIfRequested:(UIApplication *)application;

@end

NS_ASSUME_NONNULL_END
