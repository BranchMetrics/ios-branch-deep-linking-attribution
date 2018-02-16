//
//  TBBranchViewController.h
//  Testbed-ObjC
//
//  Created by Edward Smith on 6/12/17.
//  Copyright © 2017 Branch. All rights reserved.
//

@import UIKit;

@interface TBBranchViewController : UIViewController

- (void) showDataViewControllerWithTitle:(NSString*)title
                                 message:(NSString*)message
                                  object:(id<NSObject>)dictionaryOrArray;

@end
