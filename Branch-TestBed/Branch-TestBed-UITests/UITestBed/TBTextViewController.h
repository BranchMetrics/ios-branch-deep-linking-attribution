//
//  TBTextViewController.h
//  UITestBed
//
//  Created by Edward on 3/8/18.
//  Copyright © 2018 Branch. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface TBTextViewController : UIViewController
- (instancetype) initWithText:(NSString*)text;
@property (nonatomic, strong) NSString* text;
@property (nonatomic, strong) NSString *message;
@end
