//
//  UIViewController+Branch.h
//  UITestBed
//
//  Created by Edward Smith on 11/16/17.
//  Copyright © 2017 Branch. All rights reserved.
//

@import UIKit;

@interface UIViewController (Branch)
- (UIViewController*) bnc_currentViewController;
+ (UIViewController*) bnc_currentViewController;
@end
