//
//  TBWaitingView.h
//  Blitz
//
//  Created by Edward Smith on 11/29/13.
//  Copyright (c) 2013 Edward Smith. All rights reserved.
//

@import UIKit;

@interface TBWaitingView : UIViewController

+ (void)showWithMessage:(NSString*)message
      activityIndicator:(BOOL)showActivity
         disableTouches:(BOOL)disable;
+ (void)show;
+ (void)hide;
+ (void)hideWithMessage:(NSString*)message;
+ (void)showWithMessage:(NSString*)message forSeconds:(NSTimeInterval)time;

+ (NSTimeInterval) defaultHangTime;
+ (void) setDefaultHangTime:(NSTimeInterval)timeInterval;
@end
