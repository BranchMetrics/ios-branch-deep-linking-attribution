//
//  TBAppDelegate.m
//  Testbed-ObjC
//
//  Created by Edward Smith on 6/12/17.
//  Copyright © 2017 Branch. All rights reserved.
//

#import "TBAppDelegate.h"
#import "TBBranchViewController.h"
#import "TBDetailViewController.h"
#import "TBTextViewController.h"
@import Branch;

NSDate *global_previous_update_time = nil;
NSDate *next_previous_update_time = nil;

@interface TBAppDelegate () <UISplitViewControllerDelegate>
@property (nonatomic, strong) TBBranchViewController *branchViewController;
@end

#pragma mark - TBAppDelegate

@implementation TBAppDelegate

#pragma mark - Life Cycle Methods

- (BOOL)application:(UIApplication *)application
didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    BNCLogSetDisplayLevel(BNCLogLevelAll);

    #if 0
    // This simulates tracking opt-in, rather than tracking opt-out.
    if (![[NSUserDefaults standardUserDefaults] boolForKey:@"hasRunBefore"]) {
        [[NSUserDefaults standardUserDefaults] setBool:YES forKey:@"hasRunBefore"];
        [Branch setTrackingDisabled:YES];
    }
    #endif

    // Initialize Branch
    Branch *branch = [Branch getInstance];

    // This starts the Branch integration validation.  Remove for normal use.
    // [branch validateSDKIntegration];
    
    // Comment / un-comment to toggle debugging
    [branch setDebug];

    // Optionally check for Apple Search Ads attribution:
    //[branch delayInitToCheckForSearchAds];

    // Turn this on to debug Apple Search Ads.  Should not be included for production.
    // [branch setAppleSearchAdsDebugMode];

    // For testing app updates:
    next_previous_update_time = [BNCPreferenceHelper preferenceHelper].previousAppBuildDate;

    BNCLogSetDisplayLevel(BNCLogLevelAll);
    [branch setWhiteListedSchemes:@[@"branchuitest"]];

#if 1
    // [branch setIdentity:@"Bobby Branch"];
    [branch initSessionWithLaunchOptions:launchOptions
        andRegisterDeepLinkHandler:^(NSDictionary * _Nullable params, NSError * _Nullable error) {
            [self handleBranchDeepLinkParameters:params error:error];
            global_previous_update_time = next_previous_update_time;
            next_previous_update_time = [BNCPreferenceHelper preferenceHelper].previousAppBuildDate;
        }];
#else
    [branch initSessionWithLaunchOptions:launchOptions];
    branch.sessionInitWithParamsCallback = ^(NSDictionary *params, NSError *error) {
        [self handleBranchDeepLinkParameters:params error:error];
        global_previous_update_time = next_previous_update_time;
        next_previous_update_time = [BNCPreferenceHelper preferenceHelper].previousAppBuildDate;
    };
#endif

    [self initializeViewControllers];

    return YES;
}

- (BOOL)application:(UIApplication *)application
            openURL:(NSURL *)url
  sourceApplication:(NSString *)sourceApplication
         annotation:(id)annotation {

    NSLog(@"[branch.io] application:openURL:sourceApplication:annotation: invoked with URL: %@",
        [url description]);

    // Required. Returns YES if Branch link, else returns NO
    [[Branch getInstance]
        application:application
            openURL:url
  sourceApplication:sourceApplication
         annotation:annotation];

    // Process non-Branch URIs here...
    return YES;
}

#if !defined(__IPHONE_12_0) || __IPHONE_OS_VERSION_MAX_ALLOWED < __IPHONE_12_0

- (BOOL)application:(UIApplication *)application
continueUserActivity:(NSUserActivity *)userActivity
 restorationHandler:(void (^)(NSArray *))restorationHandler {
    NSLog(@"[branch.io] application:continueUserActivity:restorationHandler: invoked.\n"
          "ActivityType: %@ userActivity.webpageURL: %@",
          userActivity.activityType,
          userActivity.webpageURL.absoluteString);
    // Required. Returns YES if Branch Universal Link, else returns NO.
    // Add `branch_universal_link_domains` to .plist (String or Array) for custom domain(s).
    [[Branch getInstance] continueUserActivity:userActivity];

    // Process non-Branch userActivities here...
    return YES;
}

#else

- (BOOL)application:(UIApplication *)application
continueUserActivity:(NSUserActivity *)userActivity
 restorationHandler:(void(^)(NSArray<id<UIUserActivityRestoring>>*restorableObjects))restorationHandler {
    NSLog(@"[branch.io] application:continueUserActivity:restorationHandler: invoked.\n"
           "ActivityType: %@ userActivity.webpageURL: %@",
           userActivity.activityType,
           userActivity.webpageURL.absoluteString);
    // Required. Returns YES if Branch Universal Link, else returns NO.
    // Add `branch_universal_link_domains` to .plist (String or Array) for custom domain(s).
    [[Branch getInstance] userCompletedAction:@"Open Universal Link"];
    [[Branch getInstance] continueUserActivity:userActivity];

    // Process non-Branch userActivities here...
    return YES;
}

#endif

- (void)applicationWillResignActive:(UIApplication *)application {
    BNCLogMethodName();
}

- (void)applicationDidEnterBackground:(UIApplication *)application {
    BNCLogMethodName();
}

- (void)applicationWillEnterForeground:(UIApplication *)application {
    BNCLogMethodName();
}

- (void)applicationDidBecomeActive:(UIApplication *)application {
    BNCLogMethodName();
}

- (void)applicationWillTerminate:(UIApplication *)application {
    BNCLogMethodName();
}

#pragma mark - View Controllers

- (void)initializeViewControllers {

    // Set the split view delegate
    UISplitViewController *splitViewController = (UISplitViewController *)self.window.rootViewController;

    self.branchViewController = [TBBranchViewController new];
    UINavigationController *masterViewController =
        [[UINavigationController alloc]
            initWithRootViewController:self.branchViewController];
    masterViewController.title = @"Branch";

    TBDetailViewController *detailViewController = [TBDetailViewController new];
    UINavigationController *detailNavigationViewController =
        [[UINavigationController alloc] initWithRootViewController:detailViewController];

    splitViewController.viewControllers = @[masterViewController, detailNavigationViewController];

    // Set up the navigation controller button
    detailNavigationViewController.topViewController.navigationItem.leftBarButtonItem =
        splitViewController.displayModeButtonItem;

    splitViewController.preferredDisplayMode = UISplitViewControllerDisplayModeAllVisible;
    splitViewController.delegate = self;
}

- (void)handleBranchDeepLinkParameters:(NSDictionary*)params error:(NSError*)error {
    UIViewController *viewController = nil;
    if (error) {
        NSLog(@"Error handling deep link! Error: %@.", error);
        TBTextViewController *tvc = [[TBTextViewController alloc] initWithText:error.description];
        tvc.title = @"Error";
        tvc.message = @"Link Open Error";
        viewController = tvc;
    } else {
        NSLog(@"Received deeplink with params: %@", params);
        TBDetailViewController *dataViewController =
            [[TBDetailViewController alloc] initWithData:params];
        dataViewController.title = @"Link Opened";
        dataViewController.message = params[@"~referring_link"];
        if (!dataViewController.message.length)
            dataViewController.message = params[@"+non_branch_link"];
        if (dataViewController.message.length == 0)
            dataViewController.message = @"< No URL >";
        viewController = dataViewController;
     }

    UINavigationController *nav =
        [[UINavigationController alloc] initWithRootViewController:viewController];
    nav.navigationBar.topItem.title = viewController.title;
    nav.navigationBar.topItem.rightBarButtonItem =
        [[UIBarButtonItem alloc]
            initWithBarButtonSystemItem:UIBarButtonSystemItemDone
            target:self
            action:@selector(dismissLinkViewAction:)];

    [self presentModalViewController:nav];
}

static inline dispatch_time_t BNCDispatchTimeFromSeconds(NSTimeInterval seconds) {
    return dispatch_time(DISPATCH_TIME_NOW, seconds * NSEC_PER_SEC);
}

static inline void BNCAfterSecondsPerformBlock(NSTimeInterval seconds, dispatch_block_t block) {
    dispatch_after(BNCDispatchTimeFromSeconds(seconds), dispatch_get_main_queue(), block);
}

- (void) presentModalViewController:(UIViewController*)viewController {
    UIWindow *window = [[UIWindow alloc] initWithFrame:[UIScreen mainScreen].bounds];
    window.rootViewController = [[UIViewController alloc] initWithNibName:nil bundle:nil];
    window.backgroundColor = [UIColor clearColor];

    id<UIApplicationDelegate> delegate = [UIApplication sharedApplication].delegate;
    // Applications that does not load with UIMainStoryboardFile might not have a window property:
    if ([delegate respondsToSelector:@selector(window)]) {
        // Inherit the main window's tintColor
        window.tintColor = delegate.window.tintColor;
    }

    // Window level is above the top window (this makes the alert, if it's a sheet, show over the keyboard)
    UIWindow *topWindow = [UIApplication sharedApplication].windows.lastObject;
    window.windowLevel = topWindow.windowLevel + 1;

    [window makeKeyAndVisible];
    BNCAfterSecondsPerformBlock(0.10, ^{
        [window.rootViewController presentViewController:viewController animated:YES completion:nil];
    });
}

- (void) dismissLastModalViewController {
    UIWindow *window = [[UIApplication sharedApplication] keyWindow];
    [window.rootViewController dismissViewControllerAnimated:YES completion:^ {
        window.rootViewController = nil;
        window.hidden = YES;
    }];
}

- (IBAction)dismissLinkViewAction:(id)sender {
    [self dismissLastModalViewController];
}

- (BOOL)splitViewController:(UISplitViewController *)splitViewController
collapseSecondaryViewController:(UIViewController *)secondaryViewController
      ontoPrimaryViewController:(UIViewController *)primaryViewController {

    UINavigationController *navigationController = nil;
    TBDetailViewController *detailViewController = nil;

    if ([secondaryViewController isKindOfClass:[UINavigationController class]])
        navigationController = (id) secondaryViewController;

    if ([[navigationController topViewController] isKindOfClass:[TBDetailViewController class]])
        detailViewController = (id) [navigationController topViewController];

    if (detailViewController && detailViewController.dictionaryOrArray == nil)
        return YES;

    return NO;
}

@end
