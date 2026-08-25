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
/// Exercises the SDK's handling of a link, not the OS delivering one: an
/// unsigned simulator build has no route for real Universal Link handoff.
+ (void)installIfRequested:(UIApplication *)application;

@end

NS_ASSUME_NONNULL_END
