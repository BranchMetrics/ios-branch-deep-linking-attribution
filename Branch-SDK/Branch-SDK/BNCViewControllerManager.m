//
//  BNCViewControllerManager.m
//  Branch
//
//  Created by Jimmy Dee on 10/30/17.
//

#import "BNCViewControllerManager.h"

@implementation BNCViewControllerManager

- (UIViewController *)currentViewController {
    Class UIApplicationClass = NSClassFromString(@"UIApplication");
    UIViewController *current = [[[UIApplicationClass sharedApplication] keyWindow] rootViewController];

    if (@available(iOS 8.0, *)) {
        while (current.presentedViewController && ![current.presentedViewController isKindOfClass:UIAlertController.class]) {
            current = current.presentedViewController;
        }
    } else {
        while (current.presentedViewController) current = current.presentedViewController;
    }
    if ([current respondsToSelector:@selector(presentViewController:animated:completion:)]) return current;
    return nil;
}

- (void)presentViewController:(UIViewController *)viewControllerToPresent animated:(BOOL)flag completion:(void (^)(void))completion {
    [self.currentViewController presentViewController:viewControllerToPresent animated:flag completion:completion];
}

@end
