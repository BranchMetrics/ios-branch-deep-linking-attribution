//
//  TBBranchViewController.h
//  Testbed-ObjC
//
//  Created by edward on 6/12/17.
//  Copyright © 2017 Branch. All rights reserved.
//

@import UIKit;

@interface TBBranchViewController : UIViewController

- (void) showDataViewControllerWithObject:(id<NSObject>)dictionaryOrArray
                                    title:(NSString*)title
                                  message:(NSString*)message;

@end
