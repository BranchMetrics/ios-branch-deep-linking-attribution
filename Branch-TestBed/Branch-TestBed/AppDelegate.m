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

// ============================================================================
// BNCInitializationOptions - Forward declarations for internal testing.
// These APIs are NOT in alpha release scope. The class and methods are private
// in the SDK (not in Public/). We declare them here to test the implementation.
// See: Sources/BranchSDK/BNCInitializationOptions.h
//      Sources/BranchSDK/Branch+InitOptions.h
// ============================================================================

@class BNCInitSessionResponse;

typedef void (^BNCInitializationCallback)(BNCInitSessionResponse * _Nullable response, NSError * _Nullable error);

@interface BNCInitializationOptions : NSObject
@property (nonatomic, copy, nullable) NSURL *url;
@property (nonatomic, copy, nullable) NSString *sceneIdentifier;
@property (nonatomic, copy, nullable) NSString *sourceApplication;
@property (nonatomic, copy, nullable) BNCInitializationCallback callback;
@property (nonatomic, assign) BOOL isReferrable;
@property (nonatomic, assign) BOOL automaticallyDisplayController;
@property (nonatomic, assign) BOOL delayInitialization;
@property (nonatomic, assign) BOOL checkPasteboardOnInstall;
@property (nonatomic, assign) BOOL resetSession;
+ (instancetype)optionsWithURL:(NSURL *)url;
+ (nullable instancetype)optionsWithUserActivity:(NSUserActivity *)userActivity;
#if !TARGET_OS_TV
- (void)configureWithLaunchOptions:(nullable NSDictionary<UIApplicationLaunchOptionsKey, id> *)launchOptions;
#endif
@end

@interface Branch (InitOptions)
- (void)initSessionWithOptions:(BNCInitializationOptions *)options;
- (void)handleDeepLinkWithOptions:(BNCInitializationOptions *)options;
@end

AppDelegate* appDelegate = nil;
void APPLogHookFunction(NSDate*_Nonnull timestamp, BranchLogLevel level, NSString*_Nullable message);

@implementation AppDelegate

- (BOOL)application:(UIApplication *)application
didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    
    [self setBranchLogFile];

    appDelegate = self;

    /*
       Set Branch.useTestBranchKey = YES; to have Branch use the test key that's in the app's
       Info.plist file. This makes Branch test against your test environment (As shown in the Branch
       Dashboard) instead of the live environment.
    */

    // Branch.useTestBranchKey = YES;  // Make sure to comment this line out for production apps!!!
    Branch *branch = [Branch getInstance];

    // Change the Branch base API URL
    //[Branch setAPIUrl:@"https://api3.branch.io"];
    
    // test pre init support
    //[self testDispatchToIsolationQueue:branch]
    
    [Branch enableLoggingAtLevel:BranchLogLevelVerbose withAdvancedCallback:^(NSString * _Nonnull message, BranchLogLevel logLevel, NSError * _Nullable error, NSMutableURLRequest * _Nullable request, BNCServerResponse * _Nullable response) {
        // Handle the log message and error here. For example, printing to the console:
        if (error) {
            NSLog(@"[BranchLog] Level: %lu, Message: %@, Error: %@", (unsigned long)logLevel, message, error.localizedDescription);
        } else {
            NSLog(@"[BranchLog] Level: %lu, Message: %@", (unsigned long)logLevel, message);
        }
        
        if (request) {
            NSString *jsonString = [[NSString alloc] initWithData:request.HTTPBody encoding:NSUTF8StringEncoding];
            NSLog(@"[BranchLog] Got %@ Request: %@", request.URL , jsonString);
        }
        
        if (response) {
            NSLog(@"[BranchLog] Got Response for request (%@): %@", response.requestId, response.data);
        }
        
        NSString *logEntry = error ? [NSString stringWithFormat:@"Level: %lu, Message: %@, Error: %@", (unsigned long)logLevel, message, error.localizedDescription]
                                   : [NSString stringWithFormat:@"Level: %lu, Message: %@", (unsigned long)logLevel, message];
        APPLogHookFunction([NSDate date], logLevel, logEntry);
    }];
    
    
    // Comment out in production. Un-comment to test your Branch SDK Integration:
    //[branch validateSDKIntegration];

    // partner parameter sample
    //[branch addFacebookPartnerParameterWithName:@"em" value:@"11234e56af071e9c79927651156bd7a10bca8ac34672aba121056e2698ee7088"];
    
    [branch setIdentity:@"Bobby Branch"];

    //[[Branch getInstance] setConsumerProtectionAttributionLevel:BranchAttributionLevelReduced];

    /*
     *    Initialize Branch using BNCInitializationOptions (new API, private for alpha).
     *    This replaces the legacy initSessionWithLaunchOptions: call.
     */
    BNCInitializationOptions *options = [[BNCInitializationOptions alloc] init];
    options.checkPasteboardOnInstall = YES;
    options.callback = ^(BNCInitSessionResponse * _Nullable response, NSError * _Nullable error) {
        if (error) {
            NSLog(@"Branch TestBed: initSessionWithOptions error: %@", error.localizedDescription);
        } else {
            dispatch_async(dispatch_get_main_queue(), ^{
                NSLog(@"Branch TestBed: initSessionWithOptions succeeded with params: %@", response.params);
                [self handleDeepLinkObject:response.universalObject linkProperties:response.linkProperties error:nil];
            });
        }
    };

#if !TARGET_OS_TV
    [options configureWithLaunchOptions:launchOptions];
#endif

    [branch initSessionWithOptions:options];

    
    BranchEvent *earlyEvent = [BranchEvent standardEvent:BNCAddToCartEvent];
    NSLog(@"Logging Early Event: %@", earlyEvent);
    [earlyEvent logEvent];

    
    // Push notification support (Optional)
    // [self registerForPushNotifications:application];

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

    // Handle deep link using BNCInitializationOptions (new API, private for alpha)
    BNCInitializationOptions *options = [BNCInitializationOptions optionsWithURL:url];
    options.sourceApplication = sourceApplication;
    options.callback = ^(BNCInitSessionResponse * _Nullable response, NSError * _Nullable error) {
        if (error) {
            NSLog(@"Branch TestBed: handleDeepLinkWithOptions error: %@", error.localizedDescription);
        } else {
            NSLog(@"Branch TestBed: handleDeepLinkWithOptions succeeded with params: %@", response.params);
            [self handleDeepLinkObject:response.universalObject linkProperties:response.linkProperties error:nil];
        }
    };
    [[Branch getInstance] handleDeepLinkWithOptions:options];

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

    // Handle universal link using BNCInitializationOptions (new API, private for alpha)
    BNCInitializationOptions *options = [BNCInitializationOptions optionsWithUserActivity:userActivity];
    if (options) {
        options.callback = ^(BNCInitSessionResponse * _Nullable response, NSError * _Nullable error) {
            if (error) {
                NSLog(@"Branch TestBed: handleDeepLinkWithOptions (universal link) error: %@", error.localizedDescription);
            } else {
                NSLog(@"Branch TestBed: handleDeepLinkWithOptions (universal link) succeeded with params: %@", response.params);
                [self handleDeepLinkObject:response.universalObject linkProperties:response.linkProperties error:nil];
            }
        };
        [[Branch getInstance] handleDeepLinkWithOptions:options];
    }

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

@end
