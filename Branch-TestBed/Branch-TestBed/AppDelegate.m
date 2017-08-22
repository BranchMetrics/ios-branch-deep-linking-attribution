//
//  AppDelegate.m
//  Branch-TestBed
//
//  Created by Alex Austin on 6/5/14.
//  Copyright (c) 2014 Branch Metrics. All rights reserved.
//
#import "Branch.h"
#import "AppDelegate.h"
#import "LogOutputViewController.h"
#import "NavigationController.h"
#import "ViewController.h"
#import <SafariServices/SafariServices.h>

@interface AppDelegate() <SFSafariViewControllerDelegate>
@property (nonatomic, strong) SFSafariViewController *onboardingVC;
@end

@implementation AppDelegate

- (BOOL)application:(UIApplication *)application
didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    BNCLogSetDisplayLevel(BNCLogLevelAll);

    // Set Branch.useTestBranchKey = YES; to have Branch use the test key that's in the app's
    // Info.plist file. This makes Branch test against your test environment (As shown in the Branch
    // Dashboard) instead of the live environment.
    //
    // Branch.useTestBranchKey = YES;  // Make sure to comment this line out for production apps!!!
    Branch *branch = [Branch getInstance];

    // Comment out (for match guarantee testing) / or un-comment to toggle debugging:
    [branch setDebug];

    // Check for Apple Search Ad attribution:
    // [branch delayInitToCheckForSearchAds];
    
    // Turn this on to debug Apple Search Ads.  Should not be included for production.
    // [branch setAppleSearchAdsDebugMode];
    
    /**
     * // Optional. Use if presenting SFSafariViewController as part of onboarding. Cannot use with setDebug.
     * [self onboardUserOnInstall];
     */

    [branch initSessionWithLaunchOptions:launchOptions
        andRegisterDeepLinkHandler:^(NSDictionary * _Nullable params, NSError * _Nullable error) {
        if (!error) {
            
            NSLog(@"initSession succeeded with params: %@", params);
            
            NSString *deeplinkText = [params objectForKey:@"deeplink_text"];
            if (params[BRANCH_INIT_KEY_CLICKED_BRANCH_LINK] && deeplinkText) {
                
                UINavigationController *navigationController = (UINavigationController *)self.window.rootViewController;
                UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"Main" bundle:nil];
                LogOutputViewController *logOutputViewController = [storyboard instantiateViewControllerWithIdentifier:@"LogOutputViewController"];
                
                [navigationController pushViewController:logOutputViewController animated:YES];
                NSString *logOutput = [NSString stringWithFormat:@"Successfully Deeplinked:\n\n%@\nSession Details:\n\n%@", deeplinkText, [[branch getLatestReferringParams] description]];
                logOutputViewController.logOutput = logOutput;
                
            } else {
                NSLog(@"Branch TestBed: Finished init with params\n%@", params.description);
            }
            
        } else {
            NSLog(@"Branch TestBed: Initialization failed\n%@", error.localizedDescription);
        }
        
    }];

    /**
     * // Push notification support (Optional)
     * [self registerForPushNotifications:application];
     */

    return YES;
}


- (void)onboardUserOnInstall {
    NSURL *urlForOnboarding = [NSURL URLWithString:@"http://example.com"]; // Put your onboarding link here
    
    id notInstall = [[NSUserDefaults standardUserDefaults] objectForKey:@"notInstall"];
    if (!notInstall) {
        [[NSUserDefaults standardUserDefaults] setObject:@YES forKey:@"notInstall"];
        [[NSUserDefaults standardUserDefaults] synchronize];

        Branch *branch = [Branch getInstance];

        // Note that this must be invoked *before* initSession
        [branch enableDelayedInit];

        NSURL *updatedUrlForOnboarding = [branch getUrlForOnboardingWithRedirectUrl:urlForOnboarding.absoluteString];
        if (updatedUrlForOnboarding) {
            // replace url for onboarding with the URL provided by Branch
            urlForOnboarding = updatedUrlForOnboarding;
        }
        else {
            // do not replace url for onboarding
            NSLog(@"Was unable to get onboarding URL from Branch SDK, so proceeding with normal onboarding URL.");
            [branch disableDelayedInit];
        }

        self.onboardingVC = [[SFSafariViewController alloc] initWithURL:urlForOnboarding];
        self.onboardingVC.delegate = self;
        dispatch_async(dispatch_get_main_queue(), ^{
            [[[[UIApplication sharedApplication].delegate window] rootViewController] presentViewController:self.onboardingVC animated:YES completion:NULL];
        });
    }
}

- (void)safariViewControllerDidFinish:(SFSafariViewController *)controller {
    [[Branch getInstance] resumeInit];
}

- (BOOL)application:(UIApplication *)application
            openURL:(NSURL *)url
  sourceApplication:(NSString *)sourceApplication
         annotation:(id)annotation {

    NSLog(@"application:openURL:sourceApplication:annotation: invoked with URL: %@", [url description]);
    
    // Required. Returns YES if Branch link, else returns NO
    [[Branch getInstance]
        application:application
            openURL:url
  sourceApplication:sourceApplication
         annotation:annotation];

    // Process non-Branch URIs here...
    return YES;
}

- (BOOL)application:(UIApplication *)application
continueUserActivity:(NSUserActivity *)userActivity
 restorationHandler:(void (^)(NSArray *))restorationHandler {

    NSLog(@"application:continueUserActivity:restorationHandler: invoked.\n"
           "ActivityType: %@ userActivity.webpageURL: %@",
           userActivity.activityType,
           userActivity.webpageURL.absoluteString);
    
    // Required. Returns YES if Branch Universal Link, else returns NO.
    // Add `branch_universal_link_domains` to .plist (String or Array) for custom domain(s).
    [[Branch getInstance] continueUserActivity:userActivity];
    
    // Process non-Branch userActivities here...
    return YES;
}

#pragma mark - Push Notifications (Optional)

// Helper method
- (void)registerForPushNotifications:(UIApplication *)application {
    if ([[[UIDevice currentDevice] systemVersion] floatValue] >= 8.0) {
        [application registerUserNotificationSettings:[UIUserNotificationSettings settingsForTypes:
            (UIUserNotificationTypeSound | UIUserNotificationTypeAlert | UIUserNotificationTypeBadge)
                categories:nil]];
        [application registerForRemoteNotifications];
    } else {
        #pragma clang diagnostic push
        #pragma clang diagnostic ignored "-Wdeprecated-declarations"
        [application registerForRemoteNotificationTypes:
            (UIRemoteNotificationTypeNewsstandContentAvailability| UIRemoteNotificationTypeBadge |
                UIRemoteNotificationTypeSound | UIRemoteNotificationTypeAlert)];
        #pragma clang diagnostic pop
    }
}

- (void)application:(UIApplication *)application
didRegisterForRemoteNotificationsWithDeviceToken:(NSData *)deviceToken {
    NSLog(@"Registered for remote notifications with APN device token: %@", deviceToken);
}

- (void)application:(UIApplication *)application didReceiveRemoteNotification:(NSDictionary *)userInfo {
    [[Branch getInstance] handlePushNotification:userInfo];
    // process your non-Branch notification payload items here...
}

-(void)application:(UIApplication *)application
didFailToRegisterForRemoteNotificationsWithError:(NSError *)error {
    NSLog(@"Error registering for remote notifications: %@", error);
}


@end
