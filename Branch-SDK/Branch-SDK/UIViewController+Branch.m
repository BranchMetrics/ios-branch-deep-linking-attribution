//
//  UIViewController+Branch.m
//  Branch-SDK
//
//  Created by Edward Smith on 11/16/17.
//  Copyright © 2017 Branch. All rights reserved.
//

#import "UIViewController+Branch.h"

@implementation UIViewController (Branch)

+ (UIViewController*_Nullable) bnc_currentViewController {
    Class UIApplicationClass = NSClassFromString(@"UIApplication");
    if (UIApplicationClass) {
        UIViewController *rootViewController =
            [UIApplicationClass sharedApplication].delegate.window.rootViewController;
        if (!rootViewController) {
            rootViewController = [UIApplicationClass sharedApplication].keyWindow.rootViewController;
        }
        if (!rootViewController) {
            rootViewController = [[UIApplicationClass sharedApplication].windows firstObject].rootViewController;
        }
        return [rootViewController bnc_currentViewController];
    }
    return nil;
}

- (UIViewController*_Nonnull) bnc_currentViewController {
    if ([self isKindOfClass:[UINavigationController class]]) {
        return [((UINavigationController *)self).visibleViewController bnc_currentViewController];
    }

    if ([self isKindOfClass:[UITabBarController class]]) {
        return [((UITabBarController *)self).selectedViewController bnc_currentViewController];
    }

    if ([self isKindOfClass:[UISplitViewController class]]) {
        return [((UISplitViewController *)self).viewControllers.firstObject bnc_currentViewController];
    }

    if ([self isKindOfClass:[UIPageViewController class]]) {
        return [((UIPageViewController*)self).viewControllers.lastObject bnc_currentViewController];
    }

    if (self.presentedViewController != nil && !self.presentedViewController.isBeingDismissed) {
        return [self.presentedViewController bnc_currentViewController];
    }

    return self;
}

@end

__attribute__((constructor)) void BNCForceUIViewControllerCategoryToLoad() {
    //  Nothing here, but forces linker to load the category.
}
