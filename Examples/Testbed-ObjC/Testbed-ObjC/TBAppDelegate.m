//
//  TBAppDelegate.m
//  Testbed-ObjC
//
//  Created by edward on 6/12/17.
//  Copyright © 2017 Branch. All rights reserved.
//

#import "TBAppDelegate.h"
#import "TBBranchViewController.h"
#import "TBDataViewController.h"
#import "Branch.h"

@interface TBAppDelegate () <UISplitViewControllerDelegate>
@end

@implementation TBAppDelegate

- (BOOL)application:(UIApplication *)application
didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {

    [self initializeViewControllers];

    // Initialize Branch
    Branch *branch = [Branch getInstance];
    
    // Comment / un-comment to toggle debugging
    [branch setDebug];

    // For Apple Search Ads
    [branch delayInitToCheckForSearchAds];

    // Turn this on to debug Apple Search Ads.  Should not be included for production.
    // [branch setAppleSearchAdsDebugMode];
    [branch setWhiteListedSchemes:@[@"branchtest"]];

    /**
     * // Optional. Use if presenting SFSafariViewController as part of onboarding. Cannot use with setDebug.
     * [self onboardUserOnInstall];
     */
    [branch initSessionWithLaunchOptions:launchOptions
        andRegisterDeepLinkHandler:^(NSDictionary * _Nullable params, NSError * _Nullable error) {
            [self handleBranchDeepLinkParameters:params error:error];
        }];

    return YES;
}

- (void)initializeViewControllers {

    // Set the split view delegate
    UISplitViewController *splitViewController = (UISplitViewController *)self.window.rootViewController;
    splitViewController.delegate = self;

    UINavigationController *masterViewController =
        [[UINavigationController alloc]
            initWithRootViewController:[TBBranchViewController new]];
    masterViewController.title = @"Branch";
    
    UINavigationController *detailViewController =
        [[UINavigationController alloc]
            initWithRootViewController:[TBDataViewController new]];

    splitViewController.viewControllers = @[masterViewController, detailViewController];

    // Set up the navigation controller
    UINavigationController *navigationController = [splitViewController.viewControllers lastObject];
    navigationController.topViewController.navigationItem.leftBarButtonItem =
        splitViewController.displayModeButtonItem;
}

- (void)handleBranchDeepLinkParameters:(NSDictionary*)params error:(NSError*)error {
    if (error) {
        NSLog(@"Error handling deep link! Error: %@.", error);
        return;
    }

    NSLog(@"Received deeplink with params: %@", params);

    NSString *deeplinkText = [params objectForKey:@"deeplink_text"];
    if (params[BRANCH_INIT_KEY_CLICKED_BRANCH_LINK] && deeplinkText) {
        
//        UINavigationController *navigationController = (UINavigationController *)self.window.rootViewController;
//        UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"Main" bundle:nil];
//        LogOutputViewController *logOutputViewController = [storyboard instantiateViewControllerWithIdentifier:@"LogOutputViewController"];
//        
//        [navigationController pushViewController:logOutputViewController animated:YES];
//        NSString *logOutput = [NSString stringWithFormat:@"Successfully Deeplinked:\n\n%@\nSession Details:\n\n%@", deeplinkText, [[branch getLatestReferringParams] description]];
//        logOutputViewController.logOutput = logOutput;
    }
}

- (void)applicationWillResignActive:(UIApplication *)application {
    // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
    // Use this method to pause ongoing tasks, disable timers, and invalidate graphics rendering callbacks. Games should use this method to pause the game.
}

- (void)applicationDidEnterBackground:(UIApplication *)application {
    // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
    // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
}

- (void)applicationWillEnterForeground:(UIApplication *)application {
    // Called as part of the transition from the background to the active state; here you can undo many of the changes made on entering the background.
}

- (void)applicationDidBecomeActive:(UIApplication *)application {
    // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
}

- (void)applicationWillTerminate:(UIApplication *)application {
    // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
}

#pragma mark - Split view

- (BOOL)splitViewController:(UISplitViewController *)splitViewController
collapseSecondaryViewController:(UIViewController *)secondaryViewController
      ontoPrimaryViewController:(UIViewController *)primaryViewController {

    if ([secondaryViewController isKindOfClass:[UINavigationController class]]) {
        UINavigationController *navigationController = (id) secondaryViewController;
        if ([[navigationController topViewController] isKindOfClass:[TBDataViewController class]] &&
            ([(TBDataViewController *)[navigationController topViewController] dictionaryOrArray] == nil)) {
            return YES;
        }
    }
    return NO;
}

@end
