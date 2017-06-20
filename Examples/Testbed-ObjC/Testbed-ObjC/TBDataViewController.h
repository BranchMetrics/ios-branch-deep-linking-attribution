//
//  TBDataViewController.h
//  Testbed-ObjC
//
//  Created by edward on 6/19/17.
//  Copyright © 2017 Branch. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface TBDataViewController : UIViewController
- (instancetype) initWithData:(id<NSObject>)dictionaryOrArray;
@property (nonatomic, strong) id<NSObject> dictionaryOrArray;
@end
