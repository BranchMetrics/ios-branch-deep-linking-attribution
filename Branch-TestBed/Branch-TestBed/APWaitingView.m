//
//  APWaitingView.m
//  Blitz
//
//  Created by Edward Smith on 11/29/13.
//  Copyright (c) 2013 Edward Smith. All rights reserved.
//


#import "APWaitingView.h"


static APWaitingView *globalWaitingView = nil;
NSTimeInterval const APWaitingViewDefaultHangTime = 2.3f;

static inline CGRect ZCenterRectOverRect(CGRect rectToCenter, CGRect overRect) {
    return CGRectMake(overRect.origin.x + ((overRect.size.width - rectToCenter.size.width) / 2.0),
                      overRect.origin.y + ((overRect.size.height - rectToCenter.size.height) / 2.0),
                      rectToCenter.size.width,
                      rectToCenter.size.height);
}

static inline dispatch_time_t ZDispatchSeconds(NSTimeInterval seconds) {
    return dispatch_time(DISPATCH_TIME_NOW, seconds * NSEC_PER_SEC);
}

static inline void ZAfterSecondsPerformBlock(NSTimeInterval seconds, dispatch_block_t block) {
    dispatch_after(ZDispatchSeconds(seconds), dispatch_get_main_queue(), block);
}


@interface APWaitingView ()
@property (strong, nonatomic) IBOutlet UILabel *label;
@property (strong, nonatomic) IBOutlet UIActivityIndicatorView *activityView;
@property (strong) UIView *backgroundView;
@property (assign) CGRect maxLabelRect;
@property (strong) UIView *parentView;
@property (assign) CGAffineTransform parentTransform;
@end


@implementation APWaitingView

- (id)init {
    self = [super initWithNibName:@"APWaitingView" bundle:nil];
    self.parentTransform = CGAffineTransformIdentity;
    return self;
}

- (void)dealloc {
    [self.view removeFromSuperview];
    [self.backgroundView removeFromSuperview];
}


#pragma mark - View Lifecycle


- (void)viewDidLoad {
    [super viewDidLoad];
    self.maxLabelRect = self.label.bounds;
}

- (void)viewDidUnload {
    [self.backgroundView removeFromSuperview];
    self.backgroundView = nil;
    self.activityView = nil;
    self.label = nil;
    [super viewDidUnload];
}

static const CGFloat kScale = 0.9950;

- (void)showWithParent:(UIView *)parentView
               message:(NSString *)message
     activityIndicator:(BOOL)showActivity
        disableTouches:(BOOL)disableTouches {
    self.parentView.transform = self.parentTransform;
    self.parentView = parentView;

    // Force the view to load
    CGRect frame = self.view.frame;
    self.view.frame = frame;
    
    CGRect activityRect = CGRectZero;
    CGRect labelRect = CGRectZero;

    if (showActivity) {
        self.activityView.hidden = NO;
        [self.activityView startAnimating];
        activityRect = self.activityView.bounds;
    } else {
        self.activityView.hidden = YES;
        [self.activityView stopAnimating];
    }

    const CGFloat kIndent = 40.0f;

    if (message.length > 0) {
        self.label.text = message;
        labelRect.size = [self.label sizeThatFits:self.maxLabelRect.size];
        labelRect.size.width += 2.0 * kIndent;
    }

    CGRect viewRect;
    if (showActivity) {
        labelRect = ZCenterRectOverRect(labelRect, activityRect);
        labelRect.origin.y = activityRect.origin.y + activityRect.size.height;
        viewRect = CGRectUnion(activityRect, labelRect);
    } else {
        viewRect = labelRect;
    }
    viewRect = CGRectInset(viewRect, -kIndent, -kIndent);

    CGRect screenRect = [[UIScreen mainScreen] applicationFrame];
    self.view.frame = ZCenterRectOverRect(viewRect, screenRect);
    self.view.layer.cornerRadius = 5.0f;
    self.view.layer.borderWidth = 0.5f;
    self.view.layer.borderColor = [UIColor grayColor].CGColor;
    self.view.alpha = 1.0;

    self.activityView.frame = CGRectOffset(activityRect, -viewRect.origin.x, -viewRect.origin.y);
    self.label.frame = CGRectOffset(labelRect, -viewRect.origin.x, -viewRect.origin.y);

    [self.backgroundView removeFromSuperview];
    self.backgroundView = nil;

    if (disableTouches) {
        self.backgroundView = [[UIView alloc] initWithFrame:parentView.bounds];
        self.backgroundView.backgroundColor = [[UIColor blackColor] colorWithAlphaComponent:0.5];
        [self.backgroundView addSubview:self.view];
        [parentView addSubview:self.backgroundView];
    } else {
        self.view.frame = ZCenterRectOverRect(viewRect, parentView.bounds);
        [parentView addSubview:self.view];
    }

    [UIView setAnimationsEnabled:NO];
    self.backgroundView.alpha = 0.0;
    [UIView setAnimationsEnabled:YES];

    [self.view setNeedsLayout];
    [self.view setNeedsDisplay];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    self.parentTransform = self.parentView.transform;
    self.view.transform = CGAffineTransformMakeScale(0.90, 0.90);
    [UIView animateWithDuration:0.4
                          delay:0.01
                        options:UIViewAnimationOptionCurveEaseInOut
                     animations:^{
                         self.parentView.transform =
                             CGAffineTransformScale(self.parentView.transform, kScale, kScale);
                         self.view.transform =
                             CGAffineTransformMakeScale(1.0 / kScale, 1.0 / kScale);
                         self.backgroundView.alpha = 1.0;
                     }
                     completion:nil];
}

- (void)viewDidDisappear:(BOOL)animated {
    self.parentView.transform = self.parentTransform;
    self.view.transform = CGAffineTransformIdentity;
    [super viewDidDisappear:animated];
}

- (void)tapGoAway:(UIGestureRecognizer *)gesture {
    [APWaitingView hide];
}

+ (void)showWithMessage:(NSString *)message
      activityIndicator:(BOOL)showActivity
         disableTouches:(BOOL)disable {
    if (!globalWaitingView) globalWaitingView = [[APWaitingView alloc] init];

    // UIWindow *appWindow = [UIApplication topApplicationWindow];
    UIWindow *appWindow = [UIApplication sharedApplication].keyWindow;

    [globalWaitingView showWithParent:appWindow
                              message:message
                    activityIndicator:showActivity
                       disableTouches:disable];
}

- (void)hide {
    if (self.isViewLoaded) {
        [self.view removeFromSuperview];
        [self.backgroundView removeFromSuperview];
        [UIView animateWithDuration:0.6
            delay:0.010
            options:UIViewAnimationOptionCurveEaseInOut
            animations:^{ self.parentView.transform = self.parentTransform; }
            completion:^(BOOL done) { self.parentView = nil; }];
    }
}

+ (void)hide {
    [globalWaitingView hide];
    globalWaitingView = nil;
}

+ (void)show {
    [APWaitingView showWithMessage:nil activityIndicator:YES disableTouches:YES];
}

+ (void)hideWithMessage:(NSString *)message {
    [APWaitingView showWithMessage:message activityIndicator:NO disableTouches:NO];
    ZAfterSecondsPerformBlock(APWaitingViewDefaultHangTime, ^{
        [UIView animateWithDuration:1.0
            animations:^{ globalWaitingView.view.alpha = 0.0; }
            completion:^(BOOL finished) { [APWaitingView hide]; }];
    });
}

+ (void)showWithMessage:(NSString *)message forSeconds:(NSTimeInterval)time {
    [APWaitingView showWithMessage:message activityIndicator:NO disableTouches:NO];
    if (time <= 0.0) time = APWaitingViewDefaultHangTime;
    ZAfterSecondsPerformBlock(time, ^{
        [UIView animateWithDuration:time
            animations:^{ globalWaitingView.view.alpha = 0.0; }
            completion:^(BOOL finished) { [APWaitingView hide]; }];
    });
}

@end
