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
/// `-testDeepLinkURL <url>`, and does nothing otherwise.
///
/// The URL is wrapped in an `NSUserActivity` of type
/// `NSUserActivityTypeBrowsingWeb` and handed to the application delegate's
/// `application:continueUserActivity:restorationHandler:` — the same callback
/// iOS uses for a real Universal Link.
///
/// This exercises the SDK's handling of a link, NOT the OS delivering one.
/// Measured 2026-08-17: `xcrun simctl openurl` delivers nothing to this app on
/// an unsigned simulator build — https reaches Safari instead, and the
/// `branchtest` scheme launches nothing — so there is no OS-delivery route to
/// use here on either iOS 18.4 or 26.3.1.
+ (void)installIfRequested:(UIApplication *)application;

@end

NS_ASSUME_NONNULL_END
