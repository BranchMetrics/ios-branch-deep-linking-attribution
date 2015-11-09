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

@end

#else

NSInteger const ABOUT_30_DAYS_TIME_IN_SECONDS = 60 * 60 * 24 * 30;

@interface BNCStrongMatchHelper ()

@property (strong, nonatomic) UIWindow *secondWindow;
@property (assign, nonatomic) BOOL requestInProgress;

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
    
    [self presentSafariVCWithBranchKey:branchKey];
}

- (void)presentSafariVCWithBranchKey:(NSString *)branchKey {
    NSMutableString *urlString = [[NSMutableString alloc] initWithFormat:@"%@/_strong_match?os=%@", BNC_LINK_URL, [BNCSystemObserver getOS]];
    
    BNCPreferenceHelper *preferenceHelper = [BNCPreferenceHelper preferenceHelper];
    BOOL isRealHardwareId;
    NSString *hardwareId = [BNCSystemObserver getUniqueHardwareId:&isRealHardwareId andIsDebug:preferenceHelper.isDebug];
    if (!hardwareId || !isRealHardwareId) {
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
        id safController = [[SFSafariViewControllerClass alloc] initWithURL:[NSURL URLWithString:urlString]];
        
        UIViewController *windowRootController = [[UIViewController alloc] init];
        
        self.secondWindow = [[UIWindow alloc] initWithFrame:CGRectZero];
        self.secondWindow.rootViewController = windowRootController;
        [self.secondWindow makeKeyAndVisible];
        [self.secondWindow setAlpha:0];
        
        [windowRootController presentViewController:safController animated:YES completion:^{
            [self.secondWindow.rootViewController dismissViewControllerAnimated:NO completion:NULL];
            [BNCPreferenceHelper preferenceHelper].lastStrongMatchDate = [NSDate date];
            self.requestInProgress = NO;
        }];
    }
    else {
        self.requestInProgress = NO;
    }
}

@end

#endif
