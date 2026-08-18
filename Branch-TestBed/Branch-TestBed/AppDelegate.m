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
@import BranchSDK;
#import <UserNotifications/UserNotifications.h>

@interface AppDelegate() <UNUserNotificationCenterDelegate>
@end

AppDelegate* appDelegate = nil;
void APPLogHookFunction(NSDate*_Nonnull timestamp, BranchLogLevel level, NSString*_Nullable message);

@implementation AppDelegate

- (BOOL)application:(UIApplication *)application
didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {

    [self setBranchLogFile];

    appDelegate = self;
    
    // Debug Branch Init example
    // BranchConfiguration *config = [BranchConfiguration debug:@"key_live_xxx"];
    
    // production Branch Init example
    // BranchConfiguration *config = [BranchConfiguration production:@"key_live_xxx"];
    
    // Compliance Branch Init example
    // BranchConfiguration *config = [BranchConfiguration compliance:@"key_live_xxx"];

    // Example: full BranchConfiguration setup, with every settable field changed from its default.
    // This is the iOS counterpart of the Android `BranchConfiguration.Builder` chain. Objective-C has no
    // chained builder, so create the config with the key, set the properties you care about, then pass it
    // to `+[Branch initialize:]`.

    // ── Build the configuration ──────────────────────────────────────────
    BranchConfiguration *config =
        [[BranchConfiguration alloc] initWithKey:@"key_live_hcnegAumkH7Kv18M8AOHhfgiohpXq5tB"];

    // Identity & environment  (defaults: testMode NO, apiUrl nil, safeTrackAPIUrl nil,
    //                          cdnBaseUrl nil, euEndpoint NO)
    config.testMode        = YES;                         // use the test key from Info.plist
    config.apiUrl          = @"https://api2.branch.io";   // optional API base-URL override
    config.safeTrackAPIUrl = @"https://api2.branch.io";   // optional safe-track base-URL override
    config.cdnBaseUrl      = @"https://cdn.example.com";   // optional CDN pattern-list override
    config.euEndpoint      = YES;                          // route to Branch's EU endpoints

    // Logging  (defaults: logLevel Error, callbacks nil)
    config.logLevel = BranchLogLevelDebug;
    config.loggingCallback = ^(NSString *message, BranchLogLevel level, NSError *error) {
        NSLog(@"[Branch] %@", message);                  // custom log sink
    };
    config.requestTracingCallback = ^(NSString *url,
                                      NSDictionary *request,
                                      NSDictionary *response,
                                      NSError *error,
                                      NSString *requestServiceURL) {
        NSLog(@"[Branch trace] %@ -> %@", url, response); // per-request debug hook
    };

    // Network  (defaults: networkTimeout 5.5s, retryCount 3, retryInterval 0s, thirdPartyAPIsWaitTime 0.5s)
    // NOTE: iOS uses SECONDS (NSTimeInterval), unlike Android's milliseconds.
    config.networkTimeout        = 10.0;                 // 10s   (Android 10_000ms)
    config.retryCount            = 5;
    config.retryInterval         = 1.0;                  // 1s    (Android 1_000ms)
    config.thirdPartyAPIsWaitTime = 2.0;                 // wait up to 2s for ODM / Apple attribution token
    // config.remoteInterface = [MyCustomNetworkService class]; // must conform to BNCNetworkServiceProtocol

    // Privacy & attribution  (defaults: attributionLevel nil, limitFacebookAttribution NO,
    //                          adNetworkCalloutsDisabled NO, DMA params unset)
    config.attributionLevel = BranchAttributionLevelFull;
    config.dmaParameters = [BranchDMAParameters eeaRegion:YES
                                adPersonalizationConsent:NO
                                  adUserDataUsageConsent:YES];
    config.limitFacebookAttribution  = YES;
    config.adNetworkCalloutsDisabled = YES;

    // URL collection  (default: allowedSchemes empty == all schemes allowed)
    [config addAllowedScheme:@"myapp"];                  // ← Android addWhitelistedScheme

    // Request metadata  (default: empty) — no direct Android builder analog
    [config addMetadataWithKey:@"store" value:@"app_store"];

    // Open tracking  (default: automaticOpenEvents YES)
    config.automaticOpenEvents = NO;   // you will call [[Branch getInstance] sendOpen] manually

    // Pasteboard  (default: checkPasteboardOnInstall NO)
    config.checkPasteboardOnInstall = YES;   // check the clipboard for a Branch Link on install

    // App Clip  (default: appClipAppGroup nil) — share data between an App Clip and the full app
    config.appClipAppGroup = @"group.com.example.myapp";

    // Debugging  (default: deepLinkDebugParams nil) — constant params merged into every deep-link response.
    // Not for production use.
    config.deepLinkDebugParams = @{ @"debug_key": @"debug_value" };

    // ── Initialize ───────────────────────────────────────────────────────
    Branch *branch = [Branch initialize:config];

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
            [NSString stringWithFormat:@"Successfully Deeplinked!\n\nCustom Metadata Deeplink Text: %@\n\nSession Details:\n\n%@",
                deeplinkText, [[[Branch getInstance] getLatestReferringParams] description]];
        logOutputViewController.logOutput = logOutput;
    }
}

- (BOOL)application:(UIApplication *)application
            openURL:(NSURL *)url
  sourceApplication:(NSString *)sourceApplication
         annotation:(id)annotation {

    NSLog(@"application:openURL:sourceApplication:annotation: invoked with URL: %@", [url description]);
    Branch *branch = [Branch getInstance];
    [branch requestDeepLinkData:[url absoluteString] callback:^(NSDictionary *params, NSError *error) {
        if (error == nil) {
            if (params != nil) {
                NSLog(@"Deep Link Params: %@", params);

                // Access specific values
                NSString *campaign = params[@"~campaign"];
                NSLog(@"Campaign name: %@", campaign);
            }
        } else {
            NSLog(@"Deep Link Error: %@ (Code: %ld)", [error localizedDescription], (long)[error code]);
        }
    }];

    // Process non-Branch URIs here...
    return YES;
}

- (BOOL)application:(UIApplication *)application
continueUserActivity:(NSUserActivity *)userActivity
 restorationHandler:(void(^)(NSArray<id<UIUserActivityRestoring>>*restorableObjects))restorationHandler {
 
    NSLog(@"application:continueUserActivity:restorationHandler: invoked.\n"
           "ActivityType: %@ userActivity.webpageURL: %@",
           userActivity.activityType,
           userActivity.webpageURL.absoluteString);
    
    // Required. Returns YES if Branch Universal Link, else returns NO.
    // Add `branch_universal_link_domains` to .plist (String or Array) for custom domain(s).
    
    
    Branch *branch = [Branch getInstance];
    [branch requestDeepLinkData:userActivity.webpageURL.absoluteString callback:^(NSDictionary *params, NSError *error) {
        if (error == nil) {
            if (params != nil) {
                NSLog(@"Deep Link Params: %@", params);

                // Access specific values
                NSString *campaign = params[@"~campaign"];
                NSLog(@"Campaign name: %@", campaign);
            }
        } else {
            NSLog(@"Deep Link Error: %@ (Code: %ld)", [error localizedDescription], (long)[error code]);
        }
    }];
    
    // Process non-Branch userActivities here...
    return YES;
}

- (void)setBranchLogFile {
    NSString *documentsDirectory = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) firstObject];
    NSString *logFilePath = [documentsDirectory stringByAppendingPathComponent:@"branchlogs.txt"];
    
    // If the log file already exists, remove it to start fresh
    if ([[NSFileManager defaultManager] fileExistsAtPath:logFilePath]) {
        [[NSFileManager defaultManager] removeItemAtPath:logFilePath error:nil];
    }
    
    self.logFileName = logFilePath;
}


#pragma mark - Push Notifications (Optional)
/*
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
 */

// hook Function for SDK - Its for taking control of Logging messages.
void APPLogHookFunction(NSDate*_Nonnull timestamp, BranchLogLevel level, NSString*_Nullable message) {
    NSString *formattedMessage = [NSString stringWithFormat:@"%@ [%lu] %@", timestamp, (unsigned long)level, message];
    [appDelegate processLogMessage:formattedMessage];
}

// Writes message to Log File.
- (void) processLogMessage:(NSString *)message {
    
    if (!self.logFileName)
        return;

    @synchronized (self) {
        NSFileHandle *fileHandle = [NSFileHandle fileHandleForWritingAtPath:self.logFileName];
        if (fileHandle){
            [fileHandle seekToEndOfFile];
            [fileHandle writeData:[message dataUsingEncoding:NSUTF8StringEncoding]];
            [fileHandle closeFile];
        } else {
            [message writeToFile:self.logFileName
                      atomically:NO
                        encoding:NSStringEncodingConversionAllowLossy
                           error:nil];
        }
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

#pragma mark - UNUserNotificationCenterDelegate

- (void)userNotificationCenter:(UNUserNotificationCenter *)center
       willPresentNotification:(UNNotification *)notification
         withCompletionHandler:(void (^)(UNNotificationPresentationOptions options))completionHandler {
    completionHandler(UNNotificationPresentationOptionAlert | UNNotificationPresentationOptionSound);
}

- (void)userNotificationCenter:(UNUserNotificationCenter *)center
didReceiveNotificationResponse:(UNNotificationResponse *)response
         withCompletionHandler:(void (^)(void))completionHandler {
    [[Branch getInstance] handlePushNotification:response.notification.request.content.userInfo];
    completionHandler();
}

@end
