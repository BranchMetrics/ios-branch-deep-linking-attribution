//
//  TBDetailViewController.h
//  Testbed-ObjC
//
//  Created by Edward Smith on 6/19/17.
//  Copyright © 2017 Branch. All rights reserved.
//

@import UIKit;

@interface TBDetailViewController : UIViewController
- (instancetype) initWithData:(id<NSObject>)dictionaryOrArray;
@property (nonatomic, strong) id<NSObject> dictionaryOrArray;
@property (nonatomic, strong) NSString *message;
@end
