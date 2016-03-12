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
    
    [branch setDeepLinkDebugMode:@{@"example_debug_param" : @"foo"}];
    
    NSString *webViewHtml = @"<!DOCTYPE html><html><body><h1>Branch View Test</h1><p>Branch View Test.</p>\n\n\n <a class=\"accept_btn\" href=\"branch-cta://accept\">Accept</a>\n\n<a class=\"cancel_btn\" href=\"branch-cta://cancel\">Cancel</a></body></html>";
    
    NSMutableArray * branchViewArray = [[NSMutableArray alloc] init];
    NSDictionary * branchViewItem1 = [NSDictionary dictionaryWithObjectsAndKeys:
                                     @"branch_view_id_01", @"branch_view_id",
                                     @"open", @"branch_view_action",
                                     @"1", @"num_of_use",
                                     webViewHtml, @"branch_view_html",
                                     @"1489176401000", @"expiry",
                                     @"true", @"debug",
                                     nil];
    NSDictionary * branchViewItem2 = [NSDictionary dictionaryWithObjectsAndKeys:
                                     @"branch_view_id_02", @"branch_view_id",
                                     @"buy", @"branch_view_action",
                                     @"3", @"num_of_use",
                                     webViewHtml, @"branch_view_html",
                                     @"1489176401000", @"expiry",
                                     @"true", @"debug",
                                     nil];
  
    [branchViewArray addObject:branchViewItem1];
    [branchViewArray addObject:branchViewItem2];
    [branch setDeepLinkDebugMode:@{@"branch_view_data" : branchViewArray }];
    
    
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
    [[Branch getInstance] handlePushNotification:userInfo];
    
    //process your other notification payload items...
}

-(void)application:(UIApplication *)application didFailToRegisterForRemoteNotificationsWithError:(NSError *)error {
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
