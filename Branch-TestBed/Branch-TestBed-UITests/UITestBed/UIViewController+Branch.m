//
//  UIViewController+Branch.m
//  UITestBed
//
//  Created by Edward Smith on 11/16/17.
//  Copyright © 2017 Branch. All rights reserved.
//

#import "UIViewController+Branch.h"

@implementation UIViewController (Branch)

+ (UIViewController*) bnc_currentViewController {
    UIViewController *rootViewController =
        [UIApplication sharedApplication].keyWindow.rootViewController;
    return [rootViewController bnc_currentViewController];
}

- (UIViewController *) bnc_currentViewController {
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
