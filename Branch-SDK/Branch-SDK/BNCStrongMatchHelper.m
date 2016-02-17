//
//  BNCStrongMatchHelper.m
//  Branch-TestBed
//
//  Created by Derrick Staten on 8/26/15.
//  Copyright © 2015 Branch Metrics. All rights reserved.
//

#import "BNCStrongMatchHelper.h"
#import "BNCConfig.h"
#import "BNCPreferenceHelper.h"
#import "BNCSystemObserver.h"
#import "BranchConstants.h"

// Stub the class for older Xcode versions, methods don't actually do anything.
#if defined(__IPHONE_OS_VERSION_MAX_ALLOWED) && __IPHONE_OS_VERSION_MAX_ALLOWED < 90000

@implementation BNCStrongMatchHelper

+ (BNCStrongMatchHelper *)strongMatchHelper { return nil; }
- (void)createStrongMatchWithBranchKey:(NSString *)branchKey { }
- (BOOL)shouldDelayInstallRequest { return NO; }

@end

#else

NSInteger const ABOUT_30_DAYS_TIME_IN_SECONDS = 60 * 60 * 24 * 30;

@interface BNCStrongMatchHelper ()

@property (strong, nonatomic) UIWindow *secondWindow;
@property (assign, nonatomic) BOOL requestInProgress;
@property (assign, nonatomic) BOOL shouldDelayInstallRequest;

@end

@implementation BNCStrongMatchHelper

+ (BNCStrongMatchHelper *)strongMatchHelper {
    static BNCStrongMatchHelper *strongMatchHelper;
    static dispatch_once_t onceToken;
    
    dispatch_once(&onceToken, ^{
        strongMatchHelper = [[BNCStrongMatchHelper alloc] init];
    });
    
    return strongMatchHelper;
}

- (void)createStrongMatchWithBranchKey:(NSString *)branchKey {
    if (self.requestInProgress) {
        return;
    }

    self.requestInProgress = YES;
    
    NSDate *thirtyDaysAgo = [NSDate dateWithTimeIntervalSinceNow:-ABOUT_30_DAYS_TIME_IN_SECONDS];
    NSDate *lastCheck = [BNCPreferenceHelper preferenceHelper].lastStrongMatchDate;
    if ([lastCheck compare:thirtyDaysAgo] == NSOrderedDescending) {
        self.requestInProgress = NO;
        return;
    }
    
    self.shouldDelayInstallRequest = YES;
    [self presentSafariVCWithBranchKey:branchKey];
}

- (void)presentSafariVCWithBranchKey:(NSString *)branchKey {
    NSMutableString *urlString = [[NSMutableString alloc] initWithFormat:@"%@/_strong_match?os=%@", BNC_LINK_URL, [BNCSystemObserver getOS]];
    
    BNCPreferenceHelper *preferenceHelper = [BNCPreferenceHelper preferenceHelper];
    BOOL isRealHardwareId;
    NSString *hardwareId = [BNCSystemObserver getUniqueHardwareId:&isRealHardwareId andIsDebug:preferenceHelper.isDebug];
    if (!hardwareId || !isRealHardwareId) {
        NSLog(@"[Branch Warning] Cannot use cookie-based matching while setDebug is enabled");
        self.shouldDelayInstallRequest = NO;
        self.requestInProgress = NO;
        return;
    }
    
    [urlString appendFormat:@"&%@=%@", BRANCH_REQUEST_KEY_HARDWARE_ID, hardwareId];

    if (preferenceHelper.deviceFingerprintID) {
        [urlString appendFormat:@"&%@=%@", BRANCH_REQUEST_KEY_DEVICE_FINGERPRINT_ID, preferenceHelper.deviceFingerprintID];
    }

    if ([BNCSystemObserver getAppVersion]) {
        [urlString appendFormat:@"&%@=%@", BRANCH_REQUEST_KEY_APP_VERSION, [BNCSystemObserver getAppVersion]];
    }

    if (branchKey) {
        if ([branchKey hasPrefix:@"key_"]) {
            [urlString appendFormat:@"&branch_key=%@", branchKey];
        }
        else {
            [urlString appendFormat:@"&app_id=%@", branchKey];
        }
    }

    [urlString appendFormat:@"&sdk=ios%@", SDK_VERSION];
    
    Class SFSafariViewControllerClass = NSClassFromString(@"SFSafariViewController");
    if (SFSafariViewControllerClass) {
        UIViewController * safController = [[SFSafariViewControllerClass alloc] initWithURL:[NSURL URLWithString:urlString]];
        
        self.secondWindow = [[UIWindow alloc] initWithFrame:[[[[UIApplication sharedApplication] delegate] window] bounds]];
        UIViewController *windowRootController = [[UIViewController alloc] init];
        self.secondWindow.rootViewController = windowRootController;
        self.secondWindow.windowLevel = UIWindowLevelNormal - 1;
        [self.secondWindow setHidden:NO];
        [self.secondWindow setAlpha:0];
        
        // Must be on next run loop to avoid a warning
        dispatch_async(dispatch_get_main_queue(), ^{
            // Add the safari view controller using view controller containment
            [windowRootController addChildViewController:safController];
            [windowRootController.view addSubview:safController.view];
            [safController didMoveToParentViewController:windowRootController];
            
            // Give a little bit of time for safari to load the request.
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(10 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                // Remove the safari view controller from view controller containment
                [safController willMoveToParentViewController:nil];
                [safController.view removeFromSuperview];
                [safController removeFromParentViewController];
                
                // Remove the window and release it's strong reference. This is important to ensure that
                // applications using view controller based status bar appearance are restored.
                [self.secondWindow removeFromSuperview];
                self.secondWindow = nil;
                
                [BNCPreferenceHelper preferenceHelper].lastStrongMatchDate = [NSDate date];
                self.requestInProgress = NO;
            });
        });
    }
    else {
        self.requestInProgress = NO;
    }
}

- (BOOL)shouldDelayInstallRequest {
    return _shouldDelayInstallRequest;
}


@end

#endif
