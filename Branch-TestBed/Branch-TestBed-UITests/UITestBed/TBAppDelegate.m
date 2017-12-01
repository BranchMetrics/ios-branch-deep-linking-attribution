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
@import Branch;

@interface TBAppDelegate () <UISplitViewControllerDelegate>
@property (nonatomic, strong) TBBranchViewController *branchViewController;
@end

@implementation TBAppDelegate

- (BOOL)application:(UIApplication *)application
didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    BNCLogSetDisplayLevel(BNCLogLevelAll);
    
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
    [branch initSessionWithLaunchOptions:launchOptions
        andRegisterDeepLinkHandler:^(NSDictionary * _Nullable params, NSError * _Nullable error) {
            [self handleBranchDeepLinkParameters:params error:error];
        }];

    return YES;
}

- (void)initializeViewControllers {

    // Set the split view delegate
    UISplitViewController *splitViewController = (UISplitViewController *)self.window.rootViewController;
    splitViewController.preferredDisplayMode = UISplitViewControllerDisplayModeAllVisible;
    splitViewController.delegate = self;

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
}

- (void)handleBranchDeepLinkParameters:(NSDictionary*)params error:(NSError*)error {
    if (error) {
        NSLog(@"Error handling deep link! Error: %@.", error);
        [self.branchViewController showDataViewControllerWithObject:@{
            @"Error": [NSString stringWithFormat:@"%@", error]
            }
            title:@"Deep Link Error"
            message:nil];
    } else {
        NSLog(@"Received deeplink with params: %@", params);
        [self.branchViewController showDataViewControllerWithObject:params
             title:@"Deep Link Opened" message:nil];
     }
}

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

#pragma mark - Split view

- (BOOL)splitViewController:(UISplitViewController *)splitViewController
collapseSecondaryViewController:(UIViewController *)secondaryViewController
      ontoPrimaryViewController:(UIViewController *)primaryViewController {

    if ([secondaryViewController isKindOfClass:[UINavigationController class]]) {
        UINavigationController *navigationController = (id) secondaryViewController;
        if ([[navigationController topViewController] isKindOfClass:[TBDetailViewController class]] &&
            ([(TBDetailViewController *)[navigationController topViewController] dictionaryOrArray] == nil)) {
            return YES;
        }
    }
    return NO;
}

@end
