//
//  UniversalObjectViewController.h
//  Branch-TestBed
//
//  Created by Derrick Staten on 10/22/15.
//  Copyright © 2015 Branch Metrics. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface UniversalObjectViewController : UIViewController

@property (weak, nonatomic) IBOutlet UITextField *shortUrlTextField;
@property (weak, nonatomic) IBOutlet UITextField *canonicalIdentifierTextField;
@property (weak, nonatomic) IBOutlet UITextField *titleTextField;
@property (weak, nonatomic) IBOutlet UISegmentedControl *expires;
@end
