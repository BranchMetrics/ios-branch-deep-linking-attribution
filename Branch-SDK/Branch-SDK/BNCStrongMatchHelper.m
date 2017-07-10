//
//  BNCStrongMatchHelper.m
//  Branch-TestBed
//
//  Created by Derrick Staten on 8/26/15.
//  Copyright © 2015 Branch Metrics. All rights reserved.
//


#import "BNCStrongMatchHelper.h"
#import <objc/runtime.h>
#import "BNCConfig.h"
#import "BNCPreferenceHelper.h"
#import "BNCSystemObserver.h"
#import "BranchConstants.h"
#import "BNCLog.h"


#pragma mark BNCStrongMatchHelper iOS 8.0


// This is a stub the class for older Xcode versions. These methods don't do anything.
#if defined(__IPHONE_OS_VERSION_MAX_ALLOWED) && __IPHONE_OS_VERSION_MAX_ALLOWED < 90000 // iOS < 9.0

@implementation BNCStrongMatchHelper

+ (BNCStrongMatchHelper *)strongMatchHelper {
    return nil;
}

- (void)createStrongMatchWithBranchKey:(NSString *)branchKey {
}

- (BOOL)shouldDelayInstallRequest {
    return NO;
}

+ (NSURL *)getUrlForCookieBasedMatchingWithBranchKey:(NSString *)branchKey
                                         redirectUrl:(NSString *)redirectUrl {
    return nil;
}

@end


#else   // ------------------------------------------------------------------------------ iOS >= 9.0
#import <SafariServices/SafariServices.h>


#pragma mark - BNCMatchView


@interface BNCMatchView : UIView
@end


@implementation BNCMatchView

- (instancetype) initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    self.alpha = 0.0;
    return self;
}

- (void) setAlpha:(CGFloat)alpha {
    [super setAlpha:0.0];
}

- (CGFloat) alpha {
    return 1.0;
}

@end


#pragma mark - BNCMatchViewController


// This is a class interface that will be dynamically subclassed from SFSafariViewController
@interface BNCMatchViewController : UIViewController
@end


@implementation BNCMatchViewController

- (instancetype) initWithURL:(NSURL*)URL {
    self = [super init];
    return self;
}

- (BOOL) canBecomeFirstResponder {
    return NO;
}

- (BOOL) becomeFirstResponder {
    return NO;
}

- (UIResponder*) nextResponder {
    return nil;
}

- (void) setDelegate:(id)delegate {
}

@end


#pragma mark - BNCStrongMatchHelper iOS 9.0


@interface BNCStrongMatchHelper ()
@property (assign, nonatomic) BOOL requestInProgress;
@property (assign, nonatomic) BOOL shouldDelayInstallRequest;
@property (strong, nonatomic) UIWindow *primaryWindow;
@property (strong, nonatomic) BNCMatchView *matchView;
@property (strong, nonatomic) BNCMatchViewController *matchViewController;
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

+ (NSURL *)getUrlForCookieBasedMatchingWithBranchKey:(NSString *)branchKey
                                         redirectUrl:(NSString *)redirectUrl {
    if (!branchKey) {
        return nil;
    }
    
    NSString *appDomainLinkURL;
    id ret = [[[NSBundle mainBundle] infoDictionary] objectForKey:@"branch_app_domain"];
    if (ret) {
        if ([ret isKindOfClass:[NSString class]])
            appDomainLinkURL = [NSString stringWithFormat:@"https://%@", ret];
    } else {
        appDomainLinkURL = BNC_LINK_URL;
    }
    NSMutableString *urlString =
        [[NSMutableString alloc] initWithFormat:@"%@/_strong_match?os=%@",
            appDomainLinkURL, [BNCSystemObserver getOS]];
    
    BNCPreferenceHelper *preferenceHelper = [BNCPreferenceHelper preferenceHelper];
    BOOL isRealHardwareId;
    NSString *hardwareIdType;
    NSString *hardwareId =
        [BNCSystemObserver getUniqueHardwareId:&isRealHardwareId
            isDebug:preferenceHelper.isDebug andType:&hardwareIdType];
    if (!hardwareId || !isRealHardwareId) {
        BNCLogWarning(@"Cannot use cookie-based matching while setDebug is enabled.");
        return nil;
    }
    
    [urlString appendFormat:@"&%@=%@", BRANCH_REQUEST_KEY_HARDWARE_ID, hardwareId];

    if (preferenceHelper.deviceFingerprintID) {
        [urlString appendFormat:@"&%@=%@",
            BRANCH_REQUEST_KEY_DEVICE_FINGERPRINT_ID,
            preferenceHelper.deviceFingerprintID];
    }

    if ([BNCSystemObserver getAppVersion]) {
        [urlString appendFormat:@"&%@=%@",
            BRANCH_REQUEST_KEY_APP_VERSION,
            [BNCSystemObserver getAppVersion]];
    }
    
    [urlString appendFormat:@"&branch_key=%@", branchKey];
    [urlString appendFormat:@"&sdk=ios%@", BNC_SDK_VERSION];

    #pragma clang diagnostic push
    #pragma clang diagnostic ignored "-Wdeprecated-declarations"
    
    if (redirectUrl) {
        [urlString appendFormat:@"&redirect_url=%@",
            [redirectUrl stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]];
    }

    NSString *escapedURL =
        [urlString stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
    return [NSURL URLWithString:escapedURL];

    #pragma clang diagnostic pop
}

- (void)createStrongMatchWithBranchKey:(NSString *)branchKey {
    @synchronized (self) {
        if (self.requestInProgress) return;

        NSInteger const ABOUT_30_DAYS_TIME_IN_SECONDS = 60 * 60 * 24 * 30;
        NSDate *thirtyDaysAgo = [NSDate dateWithTimeIntervalSinceNow:-ABOUT_30_DAYS_TIME_IN_SECONDS];
        NSDate *lastCheck = [BNCPreferenceHelper preferenceHelper].lastStrongMatchDate;
        if ([lastCheck compare:thirtyDaysAgo] == NSOrderedDescending) return;

        NSURL *strongMatchUrl =
            [BNCStrongMatchHelper
                getUrlForCookieBasedMatchingWithBranchKey:branchKey
                redirectUrl:nil];
        if (!strongMatchUrl) return;

        self.requestInProgress = YES;
        self.shouldDelayInstallRequest = YES;

        // Must be on next run loop to avoid a warning
        dispatch_async(dispatch_get_main_queue(), ^{

            if (![self willLoadViewControllerWithURL:strongMatchUrl]) {
                self.shouldDelayInstallRequest = NO;
                self.requestInProgress = NO;
                return;
            }

            // Give enough time for Safari to load the request (optimized for 3G)
            dispatch_after(
                dispatch_time(DISPATCH_TIME_NOW, (int64_t)(3 * NSEC_PER_SEC)),
                dispatch_get_main_queue(),
                ^{ [self unloadViewController]; }
            );
        });
    }
}

- (BOOL) subclass:(Class)subclass selector:(SEL)selector {
    Class templateClass = objc_getClass("BNCMatchViewController");
    if (!templateClass) return NO;

    Method method = class_getInstanceMethod(templateClass, selector);
    if (!method) return NO;

    const char * typeEncoding = method_getTypeEncoding(method);
    if (!typeEncoding) return NO;

    IMP implementation = class_getMethodImplementation(templateClass, selector);
    if (!implementation) return NO;

    class_addMethod(subclass, selector, implementation, typeEncoding);
    return YES;
}

- (UIWindow*) keyWindow {
    Class UIApplicationClass = NSClassFromString(@"UIApplication");
    UIWindow *keyWindow = [UIApplicationClass sharedApplication].keyWindow;
    if (keyWindow) return keyWindow;
	// ToDo: Put different code for extensions here.
    return nil;
}

/**
  Find the top view controller that is not of type UINavigationController, UITabBarController, UISplitViewController
 */
- (UIViewController *)topViewController:(UIViewController *)baseViewController {
    if ([baseViewController isKindOfClass:[UINavigationController class]]) {
        return [self topViewController: ((UINavigationController *)baseViewController).visibleViewController];
    }

    if ([baseViewController isKindOfClass:[UITabBarController class]]) {
        return [self topViewController: ((UITabBarController *)baseViewController).selectedViewController];
    }

    if ([baseViewController isKindOfClass:[UISplitViewController class]]) {
        return [self topViewController: ((UISplitViewController *)baseViewController).viewControllers.firstObject];
    }

    if ([baseViewController presentedViewController] != nil) {
        return [self topViewController: [baseViewController presentedViewController]];
    }

    return baseViewController;
}

- (BOOL) willLoadViewControllerWithURL:(NSURL*)matchURL {
    if (self.primaryWindow) return NO;

    //  Dynamically subclass the SFSafariViewController if available.
    //  This allows us to compile and link to an app that doesn't
    //  include SafariServices, but is also able to compile and link
    //  when it is.

    Class SFSafariViewControllerClass = NSClassFromString(@"SFSafariViewController");
    if (!SFSafariViewControllerClass) {
        BNCLogWarning(@"cookieBasedMatching is enabled but SafariServices framework is not available.");
        return NO;
    }

    Class BNCMatchViewControllerSubclass = NSClassFromString(@"BNCMatchViewController_Safari");
    if (!BNCMatchViewControllerSubclass) {
        //  The class isn't registered.  Create it:

        BNCMatchViewControllerSubclass =
            objc_allocateClassPair(SFSafariViewControllerClass, "BNCMatchViewController_Safari", 0);
        if (!BNCMatchViewControllerSubclass) return NO;

        BOOL fail = NO;
        fail |= ![self subclass:BNCMatchViewControllerSubclass selector:@selector(becomeFirstResponder)];
        fail |= ![self subclass:BNCMatchViewControllerSubclass selector:@selector(canBecomeFirstResponder)];
        fail |= ![self subclass:BNCMatchViewControllerSubclass selector:@selector(nextResponder)];
        if (fail) {
            objc_disposeClassPair(BNCMatchViewControllerSubclass);
            return NO;
        }
        objc_registerClassPair(BNCMatchViewControllerSubclass);
    }

    BNCLogDebugSDK(@"Safari is initializing.");
    self.primaryWindow = [self keyWindow];

    self.matchViewController = [[BNCMatchViewControllerSubclass alloc] initWithURL:matchURL];
    if (!self.matchViewController) return NO;
    
    self.matchViewController.delegate = self;
    self.matchViewController.view.frame = self.primaryWindow.bounds;

    self.matchView = [[BNCMatchView alloc] initWithFrame:self.primaryWindow.bounds];
    self.matchView.alpha = 1.0;
    [self.matchView addSubview:self.matchViewController.view];

    UIViewController *rootViewController = [self topViewController:self.primaryWindow.rootViewController];

    [rootViewController addChildViewController:self.matchViewController];
    UIView *parentView = rootViewController.view ?: self.primaryWindow;
    [parentView insertSubview:self.matchView atIndex:0];

    [self.matchViewController didMoveToParentViewController:rootViewController];

    return YES;
}

- (void) unloadViewController {
    BNCLogDebugSDK(@"Safari unloadViewController called.");
    
    [self.matchViewController willMoveToParentViewController:nil];
    [self.matchViewController.view removeFromSuperview];
    [self.matchViewController removeFromParentViewController];
     self.matchViewController.delegate = nil;
     self.matchViewController = nil;

    [self.matchView removeFromSuperview];
     self.matchView = nil;

     self.primaryWindow = nil;

    [BNCPreferenceHelper preferenceHelper].lastStrongMatchDate = [NSDate date];
    self.shouldDelayInstallRequest = NO;
    self.requestInProgress = NO;
}

- (void)safariViewController:(SFSafariViewController *)controller
      didCompleteInitialLoad:(BOOL)didLoadSuccessfully {
    BNCLogDebugSDK(@"Safari did load. Success: %d.", didLoadSuccessfully);
    [self unloadViewController];
}

@end

#endif  // ------------------------------------------------------------------------------ iOS >= 9.0
