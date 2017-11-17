//
//  UIViewController+Branch.h
//  Branch-SDK
//
//  Created by Edward Smith on 11/16/17.
//  Copyright © 2017 Branch. All rights reserved.
//

#if __has_feature(modules)
@import UIKit;
#else
#import <UIKit/UIKit.h>
#endif

@interface UIViewController (Branch)
- (UIViewController*_Nonnull)  bnc_currentViewController;
+ (UIViewController*_Nullable) bnc_currentViewController;
@end

void BNCForceUIViewControllerCategoryToLoad(void) __attribute__((constructor));
