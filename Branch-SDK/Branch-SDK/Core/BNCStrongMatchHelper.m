//
//  BNCStrongMatchHelper.m
//  Branch-TestBed
//
//  Created by Derrick Staten on 8/26/15.
//  Copyright © 2015 Branch Metrics. All rights reserved.
//

#import "BNCStrongMatchHelper.h"
#import <SafariServices/SafariServices.h>
#import "BNCConfig.h"
#import "BNCPreferenceHelper.h"
#import "BNCSystemObserver.h"
#import "BranchConstants.h"

@interface BNCStrongMatchHelper () <SFSafariViewControllerDelegate>
@property (nonatomic, strong) UIWindow *secondWindow;
@property (nonatomic) BOOL requestInProgress;
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
#if defined(__IPHONE_OS_VERSION_MAX_ALLOWED) && __IPHONE_OS_VERSION_MAX_ALLOWED >= 90000
    if (_requestInProgress) {
        return;
    }
    _requestInProgress = YES;
    [self presentSafariVCWithBranchKey:branchKey];
#endif
}

- (void)presentSafariVCWithBranchKey:(NSString *)branchKey {
    NSString *urlString = [NSString stringWithFormat:@"%@/_strong_match?os=iOS", BNC_LINK_URL];
    
    BNCPreferenceHelper *preferenceHelper = [BNCPreferenceHelper preferenceHelper];
    BOOL isRealHardwareId;
    NSString *hardwareId = [BNCSystemObserver getUniqueHardwareId:&isRealHardwareId andIsDebug:preferenceHelper.isDebug];
    if (!hardwareId || !isRealHardwareId) {
        _requestInProgress = NO;
        return;
    }
    
    if (preferenceHelper.deviceFingerprintID) {
        urlString = [urlString stringByAppendingString:[NSString stringWithFormat:@"&%@=%@", BRANCH_REQUEST_KEY_DEVICE_FINGERPRINT_ID, preferenceHelper.deviceFingerprintID]];
        
    } else {
        urlString = [urlString stringByAppendingString:[NSString stringWithFormat:@"&%@=%@", BRANCH_REQUEST_KEY_HARDWARE_ID, hardwareId]];
    }
    
    if ([BNCSystemObserver getAppVersion]) {
        urlString = [urlString stringByAppendingString:[NSString stringWithFormat:@"&%@=%@", BRANCH_REQUEST_KEY_APP_VERSION, [BNCSystemObserver getAppVersion]]];
    }
    if (branchKey && branchKey.length >= 4) {
        NSLog(@"substring: %@", [branchKey substringToIndex:3]);
        if ([branchKey hasPrefix:@"key_"]) {
            urlString = [urlString stringByAppendingString:[NSString stringWithFormat:@"&branch_key=%@", branchKey]];
        } else {
            urlString = [urlString stringByAppendingString:[NSString stringWithFormat:@"&app_id=%@", branchKey]];
        }
    }
    urlString = [urlString stringByAppendingString:[NSString stringWithFormat:@"&sdk=ios%@", SDK_VERSION]];
    
    SFSafariViewController *vc = [[SFSafariViewController alloc] initWithURL:[NSURL URLWithString:urlString]];
    vc.delegate = self;
    
    _secondWindow = [[UIWindow alloc] initWithFrame:[[[[UIApplication sharedApplication] delegate] window] frame]];
    _secondWindow.rootViewController = [[UIViewController alloc] init];
    [_secondWindow makeKeyAndVisible];
    [_secondWindow setAlpha:0];
    
    [_secondWindow.rootViewController presentViewController:vc animated:NO completion:nil];
}

- (void)safariViewController:(SFSafariViewController *)controller didCompleteInitialLoad:(BOOL)didLoadSuccessfully {
    [[[[[UIApplication sharedApplication] delegate] window] rootViewController] dismissViewControllerAnimated:controller completion:nil];
    _requestInProgress = NO;
}


@end
