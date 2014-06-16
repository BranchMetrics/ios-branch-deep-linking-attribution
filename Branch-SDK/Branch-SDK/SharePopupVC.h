//
//  SharePopupVC.h
//  Branch Metrics
//
//  Created by Alex Austin on 1/8/14.
//  Copyright (c) 2014 Branch Metrics, Inc. All rights reserved.
//

#import <UIKit/UIKit.h>

@protocol SharePopupDelegate <NSObject>


@required
- (void)requestHide;
@end

@interface SharePopupVC : UIViewController

@property (nonatomic, assign) id <SharePopupDelegate> delegate;

@end
