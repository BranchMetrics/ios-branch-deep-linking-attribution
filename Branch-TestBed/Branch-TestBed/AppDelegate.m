//
//  AppDelegate.m
//  Branch-TestBed
//
//  Created by Alex Austin on 6/5/14.
//  Copyright (c) 2014 Branch Metrics. All rights reserved.
//
#import "Branch.h"
#import "AppDelegate.h"
#import "ExampleDeepLinkingController.h"

@implementation AppDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    ExampleDeepLinkingController *controller = [[UIStoryboard storyboardWithName:@"Main" bundle:[NSBundle mainBundle]] instantiateViewControllerWithIdentifier:@"DeepLinkingController"];
    
    
    //APNS support: different between ios7 and ios8+
    if ([[[UIDevice currentDevice] systemVersion] floatValue] >= 8.0)
    {
        [application registerUserNotificationSettings:[UIUserNotificationSettings settingsForTypes:(UIUserNotificationTypeSound | UIUserNotificationTypeAlert | UIUserNotificationTypeBadge) categories:nil]];
        
        [application registerForRemoteNotifications];
    }
    else
    {
        [application registerForRemoteNotificationTypes: (UIRemoteNotificationTypeNewsstandContentAvailability| UIRemoteNotificationTypeBadge | UIRemoteNotificationTypeSound | UIRemoteNotificationTypeAlert)];
    }
    //end APNS support
    
    
    Branch *branch = [Branch getInstance];
    [branch setDebug];
    
    [branch registerDeepLinkController:controller forKey:@"gravatar_email"];
    
    [branch initSessionWithLaunchOptions:launchOptions automaticallyDisplayDeepLinkController:YES deepLinkHandler:^(NSDictionary *params, NSError *error) {
        if (!error) {
            NSLog(@"finished init with params = %@", [params description]);
        }
        else {
            NSLog(@"failed init: %@", error);
        }
    }];
    
    return YES;
}


//APNS support
- (void)application:(UIApplication *)application didRegisterForRemoteNotificationsWithDeviceToken:(NSData *)deviceToken {
    NSLog(@"APN device token: %@", deviceToken);
}

- (void)application:(UIApplication *)application didReceiveRemoteNotification:(NSDictionary *)userInfo {
    NSLog(@"Push received: %@", userInfo);
    //check a branch shortlink in the payload (shortlink because iOS7 only supports 256 bytes)
    NSString *urlStr = [userInfo objectForKey:@"branchURL"];
    if (urlStr) {
        NSURL *branchURL = [NSURL URLWithString:urlStr];
        [[Branch getInstance] handleDeepLink:branchURL];
    }
    
    //process your other payload items...
}

-(void)application:(UIApplication *)application didFailToRegisterForRemoteNotificationsWithError:(NSError *)error
{
    NSLog(@"Error registering for remote notifications:%@",error);
}
//end APNS support



- (BOOL)application:(UIApplication *)application openURL:(NSURL *)url sourceApplication:(NSString *)sourceApplication annotation:(id)annotation {
    NSLog(@"opened app from URL %@", [url description]);
    
    return [[Branch getInstance] handleDeepLink:url];
}

- (BOOL)application:(UIApplication *)application continueUserActivity:(NSUserActivity *)userActivity restorationHandler:(void (^)(NSArray *))restorationHandler {
    BOOL handledByBranch = [[Branch getInstance] continueUserActivity:userActivity];
    
    return handledByBranch;
}


@end
