//
//  BNCViewControllerManager.h
//  Branch
//
//  Created by Jimmy Dee on 10/30/17.
//

@import UIKit;

/**
 * Utility class to find the current view controller for use with presentViewController:animated:completion:.
 */
@interface BNCViewControllerManager : NSObject

/**
 * The current view controller to use.
 *
 * This can be nil in an extension, when UIApplication is not defined, if UIApplication.sharedApplication.keyWindow is nil
 * or if the current view controller does not respond to presentViewController:animated:completion:.
 */
@property (readonly, nullable, nonatomic) UIViewController *currentViewController;

/**
 * Convenience method to present a view controller from the currentViewController.
 * @param viewControllerToPresent an instance of UIViewController to present
 * @param flag whether the presentation should be animated
 * @param completion an optional completion block called once the presentation is complete
 */
- (void)presentViewController:(UIViewController * _Nonnull)viewControllerToPresent animated: (BOOL)flag completion:(void (^ __nullable)(void))completion;

@end
