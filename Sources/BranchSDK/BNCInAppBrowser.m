//
//  BNCInAppBrowser.m
//  Branch
//
//  Created by Nidhi Dixit on 5/12/25.
//  Copyright © 2025 Branch, Inc. All rights reserved.
//

#if !TARGET_OS_TV

#import "BNCInAppBrowser.h"
#import "UIViewController+Branch.h"
#import "Branch.h"

NS_ASSUME_NONNULL_BEGIN

@implementation BNCInAppBrowser

+ (instancetype)sharedInstance {
    static BNCInAppBrowser *sharedInstance = nil;
    static dispatch_once_t onceToken;
    
    if (NSClassFromString(@"SFSafariViewController") == nil) {
        [[BranchLogger shared] logDebug:@"[Branch SDK] SafariServices.framework is not linked. BNCInAppBrowser will not be available." error:nil];
        return nil;
    }
    
    dispatch_once(&onceToken, ^{
        sharedInstance = [[BNCInAppBrowser alloc] init];
    });
    return sharedInstance;
}

- (void)openURLInSafariVC:(NSURL *) url {
    
    UIViewController *topVC = [UIViewController bnc_currentViewController];
    if (!topVC) {
        [[BranchLogger shared] logDebug:@"SDK: Cannot present SafariViewController – no top view controller found." error:nil];
        return;
    }
    [self openURLInSafariVC:url overViewController:topVC];
}

+ (BOOL)isSafariServicesFrameworkLinked {
    return (NSClassFromString(@"SFSafariViewController") != nil);
}

- (void)openURLInSafariVC:(NSURL *)url overViewController:(UIViewController *)topVC {
    
    Class safariClass = NSClassFromString(@"SFSafariViewController");
    if (!safariClass) {
        [[BranchLogger shared] logDebug:@"SDK: SFSafariViewController not available or not linked. Falling back." error:nil];
        return;
    }

    id safariVC = [[safariClass alloc] initWithURL:url];

    if ([safariVC respondsToSelector:@selector(setDelegate:)]) {
        [safariVC performSelector:@selector(setDelegate:) withObject:self];
    }

    if (@available(iOS 11.0, *)) {
        if ([safariVC respondsToSelector:@selector(setDismissButtonStyle:)]) {
            [safariVC setValue:@(1) forKey:@"dismissButtonStyle"]; // SFSafariViewControllerDismissButtonStyleClose
        }
    }

    if (@available(iOS 13.0, *)) {
        if ([safariVC respondsToSelector:@selector(setPreferredBarTintColor:)]) {
            [safariVC setValue:[UIColor systemBackgroundColor] forKey:@"preferredBarTintColor"];
        }
        if ([safariVC respondsToSelector:@selector(setPreferredControlTintColor:)]) {
            [safariVC setValue:[UIColor systemBlueColor] forKey:@"preferredControlTintColor"];
        }
    }
    [topVC presentViewController:safariVC animated:YES completion:nil];
}

- (void)safariViewControllerDidFinish:(SFSafariViewController *)controller {
    [[Branch getInstance] initUserSessionAndCallCallback:YES sceneIdentifier:nil urlString:nil reset:YES];
}

@end

NS_ASSUME_NONNULL_END
#endif
