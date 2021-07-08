//
//  AppDelegate.m
//  Branch-TestBed
//
//  Created by Alex Austin on 6/5/14.
//  Copyright (c) 2014 Branch Metrics. All rights reserved.
//

#import "AppDelegate.h"
#import "LogOutputViewController.h"
#import "NavigationController.h"
#import "ViewController.h"
#import "Branch.h"
#import "BNCEncodingUtils.h"

AppDelegate* appDelegate = nil;
void APPLogHookFunction(NSDate*_Nonnull timestamp, BNCLogLevel level, NSString*_Nullable message);

@implementation AppDelegate

- (BOOL)application:(UIApplication *)application
didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    
    appDelegate = self;
    BNCLogSetOutputFunction(APPLogHookFunction);
    BNCLogSetDisplayLevel(BNCLogLevelAll);

    /*
       Set Branch.useTestBranchKey = YES; to have Branch use the test key that's in the app's
       Info.plist file. This makes Branch test against your test environment (As shown in the Branch
       Dashboard) instead of the live environment.
    */

    // Branch.useTestBranchKey = YES;  // Make sure to comment this line out for production apps!!!
    Branch *branch = [Branch getInstance];
    
    // test pre init support
    //[self testDispatchToIsolationQueue:branch]

    // Comment out (for match guarantee testing) / or un-comment to toggle debugging:
    // Note: Unit tests will fail if 'setDebug' is set.
    // [branch setDebug];
     [branch enableLogging];
    
    // Comment out in production. Un-comment to test your Branch SDK Integration:
    //[branch validateSDKIntegration];

    // Check for Apple Search Ad attribution (trade-off: slows down app startup):
    //[branch delayInitToCheckForSearchAds];

    // partner parameter sample
    //[branch addFacebookPartnerParameterWithName:@"em" value:@"11234e56af071e9c79927651156bd7a10bca8ac34672aba121056e2698ee7088"];
    
    [branch checkPasteboardOnInstall];
    
    /*
     *    Required: Initialize Branch, passing a deep link handler block:
     */

    [self setLogFile:@"OpenNInstall"];
    // [branch setIdentity:@"Bobby Branch"];
    [branch initSessionWithLaunchOptions:launchOptions
        andRegisterDeepLinkHandlerUsingBranchUniversalObject:
        ^ (BranchUniversalObject * _Nullable universalObject, BranchLinkProperties * _Nullable linkProperties, NSError * _Nullable error) {
        [self setLogFile:nil];
            [self handleDeepLinkObject:universalObject linkProperties:linkProperties error:error];
    }];

    // Push notification support (Optional)
    [self registerForPushNotifications:application];

    return YES;
}

// pre init support is meant for extensions, for example, when Adobe axtension needs to pass in Adobe IDs
// before init session is called. This method will block the queue used by open/install requests until the
// the passsed in block completes
- (void)testDispatchToIsolationQueue:(Branch *)branch {
    [branch dispatchToIsolationQueue:^{
        dispatch_semaphore_t semaphore = dispatch_semaphore_create(0);
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(2 * NSEC_PER_SEC)),
                       dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            [branch setRequestMetadataKey:@"keykey" value:@"valuevalue"];
            dispatch_semaphore_signal(semaphore);
        });
        dispatch_semaphore_wait(semaphore, DISPATCH_TIME_FOREVER);
    }];
}

- (void) handleDeepLinkParams:(NSDictionary*)params error:(NSError*)error {
    if (error) {
        NSLog(@"Branch TestBed: Error deep linking: %@.", error.localizedDescription);
        return;
    }

    NSLog(@"Deep linked with params: %@", params);
    NSString *deeplinkText = [params objectForKey:@"deeplink_text"];
    if ([params[BRANCH_INIT_KEY_CLICKED_BRANCH_LINK] boolValue]) {

        UINavigationController *navigationController =
            (UINavigationController *)self.window.rootViewController;
        UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"Main" bundle:nil];
        LogOutputViewController *logOutputViewController =
            [storyboard instantiateViewControllerWithIdentifier:@"LogOutputViewController"];
        [navigationController pushViewController:logOutputViewController animated:YES];
        NSString *logOutput =
            [NSString stringWithFormat:@"Successfully Deeplinked:\n\n%@\nSession Details:\n\n%@",
                deeplinkText, [[[Branch getInstance] getLatestReferringParams] description]];
        logOutputViewController.logOutput = logOutput;

    } else {
        NSLog(@"Branch TestBed: Finished init with params\n%@", params.description);
    }
}

- (void) handleDeepLinkObject:(BranchUniversalObject*)object
               linkProperties:(BranchLinkProperties*)linkProperties
                        error:(NSError*)error {
    if (error) {
        NSLog(@"Branch TestBed: Error deep linking: %@.", error.localizedDescription);
        return;
    }

    NSLog(@"Deep linked with object: %@.", object);
    NSString *deeplinkText = object.contentMetadata.customMetadata[@"deeplink_text"];
    if (object.contentMetadata.customMetadata[BRANCH_INIT_KEY_CLICKED_BRANCH_LINK].boolValue) {
        UINavigationController *navigationController =
            (UINavigationController *)self.window.rootViewController;
        UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"Main" bundle:nil];
        LogOutputViewController *logOutputViewController =
            [storyboard instantiateViewControllerWithIdentifier:@"LogOutputViewController"];
        [navigationController pushViewController:logOutputViewController animated:YES];
        NSString *logOutput =
            [NSString stringWithFormat:@"Successfully Deeplinked:\n\n%@\nSession Details:\n\n%@",
                deeplinkText, [[[Branch getInstance] getLatestReferringParams] description]];
        logOutputViewController.logOutput = logOutput;
    }
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

#if !defined(__IPHONE_12_0) || __IPHONE_OS_VERSION_MAX_ALLOWED < __IPHONE_12_0

- (BOOL)application:(UIApplication *)application
continueUserActivity:(NSUserActivity *)userActivity
 restorationHandler:(void(^)(NSArray*restorableObjects))restorationHandler {

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

#else

- (BOOL)application:(UIApplication *)application
continueUserActivity:(NSUserActivity *)userActivity
 restorationHandler:(void(^)(NSArray<id<UIUserActivityRestoring>>*restorableObjects))restorationHandler {
 
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

#endif

#pragma mark - Push Notifications (Optional)

// Helper method
- (void)registerForPushNotifications:(UIApplication *)application {
    if ([[[UIDevice currentDevice] systemVersion] doubleValue] >= 8.0) {
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
didRegisterForRemoteNotificationsWithDeviceToken:(NSData*)deviceToken {
    NSString *tokenString = [BNCEncodingUtils hexStringFromData:deviceToken];
    NSLog(@"Registered for remote notifications with APN device token: '%@'.", tokenString);
}

- (void)application:(UIApplication *)application didReceiveRemoteNotification:(NSDictionary *)userInfo {
    [[Branch getInstance] handlePushNotification:userInfo];
    // process your non-Branch notification payload items here...
}

-(void)application:(UIApplication *)application
didFailToRegisterForRemoteNotificationsWithError:(NSError *)error {
    NSLog(@"Error registering for remote notifications: %@", error);
}

// Hook Fucntion for SDK - Its for taking control of Logging messages.
void APPLogHookFunction(NSDate*_Nonnull timestamp, BNCLogLevel level, NSString*_Nullable message) {
    [appDelegate processLogMessage:message];
}

// Writes message to log File.
- (void) processLogMessage:(NSString *)message {
    
    if (!self.logFileName)
        return;

    @synchronized (self) {
        NSFileHandle *fileHandle = [NSFileHandle fileHandleForWritingAtPath:self.logFileName];
        if (fileHandle){
            [fileHandle seekToEndOfFile];
            [fileHandle writeData:[message dataUsingEncoding:NSUTF8StringEncoding]];
            [fileHandle closeFile];
        } else { // Create file if it doesnt exist
            [message writeToFile:self.logFileName
                      atomically:NO
                        encoding:NSStringEncodingConversionAllowLossy
                           error:nil];
        }
        NSLog(@"%@", message); // Log mmessages to console - remove if required.
    }
}

// Set log File. If another file with the same name exits, delete it,
// Different log files can be set for each command. This will make parsing of log files(for Test Automation) easier
- (void) setLogFile:(NSString*)fileName {
    
    if (!fileName) {
        self.logFileName = nil;
        return;
    }
    
    NSString *documentsDirectory = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) objectAtIndex:0];
    NSString *pathForLog =  [[NSString alloc] initWithFormat:@"%@/%@.txt" , documentsDirectory, fileName];
    
    if ( [[NSFileManager defaultManager] fileExistsAtPath:pathForLog]) {
        [[NSFileManager defaultManager] removeItemAtPath:pathForLog error:nil];
    }
    if (!self.logFileName) {
        self.PrevCommandLogFileName = self.logFileName = pathForLog;
    } else {
        self.PrevCommandLogFileName = self.logFileName;
        self.logFileName = pathForLog;
    }
}

@end
