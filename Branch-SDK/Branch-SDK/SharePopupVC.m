//
//  SharePopupVC.m
//  Branch Metrics
//
//  Created by Alex Austin on 1/8/14.
//  Copyright (c) 2014 Pawprint Labs, Inc. All rights reserved.
//

#import "SharePopupVC.h"

@interface SharePopupVC ()

@property (weak, nonatomic) IBOutlet UIButton *cmdChange;
@property (weak, nonatomic) IBOutlet UIButton *cmdKeep;
@property (weak, nonatomic) IBOutlet UIView *viewBottomYellow;
@property (weak, nonatomic) IBOutlet UIView *viewTopWhite;
@property (weak, nonatomic) IBOutlet UIView *containerView;

@property (weak, nonatomic) IBOutlet UIButton *cmdFix;
@property (weak, nonatomic) IBOutlet UILabel *txtDetail;
@property (weak, nonatomic) IBOutlet UILabel *txtTItle;

@end

@implementation SharePopupVC

- (void)viewDidLoad
{
    [super viewDidLoad];
	UIBezierPath *topMaskPath = [UIBezierPath bezierPathWithRoundedRect:self.viewTopWhite.bounds
                                                      byRoundingCorners:UIRectCornerTopLeft|UIRectCornerTopRight
                                                            cornerRadii:CGSizeMake(10.0, 10.0)];
    
    CAShapeLayer *topMask = [CAShapeLayer layer];
    topMask.frame = self.viewTopWhite.bounds;
    topMask.path = topMaskPath.CGPath;
    self.viewTopWhite.layer.mask = topMask;
    
    UIBezierPath *botMaskPath = [UIBezierPath bezierPathWithRoundedRect:self.viewBottomYellow.bounds
                                                      byRoundingCorners:UIRectCornerBottomLeft|UIRectCornerBottomRight
                                                            cornerRadii:CGSizeMake(10.0, 10.0)];
    UITapGestureRecognizer *singleFingerTap = [[UITapGestureRecognizer alloc] initWithTarget:self
                                                                                      action:@selector(hideController)];
    [self.containerView addGestureRecognizer:singleFingerTap];
    
    CAShapeLayer *botMask = [CAShapeLayer layer];
    botMask.frame = self.viewBottomYellow.bounds;
    botMask.path = botMaskPath.CGPath;
    self.viewBottomYellow.layer.mask = botMask;
    
    [self attachPopUpAnimation];
}

- (void) hideController {
    [self detachPopUpAnimation];
}

- (IBAction)cmdChangeClick:(id)sender {
    [self hideController];
}
- (IBAction)cmdKeepClick:(id)sender {
    [self hideController];
}


- (void) detachPopUpAnimation {
    [UIView beginAnimations:nil context:NULL];
    [UIView setAnimationDuration:0.3];
    [self.view setAlpha:0.0];
    [UIView commitAnimations];
    
    CAKeyframeAnimation *animation = [CAKeyframeAnimation
                                      animationWithKeyPath:@"transform"];
    
    CATransform3D scale4 = CATransform3DMakeScale(0.0, 0.0, 1);
    CATransform3D scale3 = CATransform3DMakeScale(0.7, 0.7, 1);
    CATransform3D scale2 = CATransform3DMakeScale(0.9, 0.9, 1);
    CATransform3D scale1 = CATransform3DMakeScale(1.0, 1.0, 1);
    
    NSArray *frameValues = [NSArray arrayWithObjects:
                            [NSValue valueWithCATransform3D:scale1],
                            [NSValue valueWithCATransform3D:scale2],
                            [NSValue valueWithCATransform3D:scale3],
                            [NSValue valueWithCATransform3D:scale4],
                            nil];
    [animation setValues:frameValues];
    
    NSArray *frameTimes = [NSArray arrayWithObjects:
                           [NSNumber numberWithFloat:0.0],
                           [NSNumber numberWithFloat:0.3],
                           [NSNumber numberWithFloat:0.5],
                           [NSNumber numberWithFloat:1.0],
                           nil];
    [animation setKeyTimes:frameTimes];
    
    animation.fillMode = kCAFillModeForwards;
    animation.removedOnCompletion = NO;
    animation.duration = .3;
    
    animation.delegate = self;
    
    [self.containerView.layer addAnimation:animation forKey:@"popdown"];
    
}

- (void)animationDidStop:(CAAnimation *)anim finished:(BOOL)flag {
    [self dismissViewControllerAnimated:NO completion:nil];
}


- (void) attachPopUpAnimation
{
    [self.view setAlpha:0.0];
    [UIView beginAnimations:nil context:NULL];
    [UIView setAnimationDuration:0.4];
    [self.view setAlpha:1.0];
    [UIView commitAnimations];
    
    
    CAKeyframeAnimation *animation = [CAKeyframeAnimation
                                      animationWithKeyPath:@"transform"];
    
    CATransform3D scale1 = CATransform3DMakeScale(0.0, 0.0, 1);
    CATransform3D scale2 = CATransform3DMakeScale(0.7, 0.7, 1);
    CATransform3D scale3 = CATransform3DMakeScale(0.9, 0.9, 1);
    CATransform3D scale4 = CATransform3DMakeScale(1.0, 1.0, 1);
    
    NSArray *frameValues = [NSArray arrayWithObjects:
                            [NSValue valueWithCATransform3D:scale1],
                            [NSValue valueWithCATransform3D:scale2],
                            [NSValue valueWithCATransform3D:scale3],
                            [NSValue valueWithCATransform3D:scale4],
                            nil];
    [animation setValues:frameValues];
    
    NSArray *frameTimes = [NSArray arrayWithObjects:
                           [NSNumber numberWithFloat:0.0],
                           [NSNumber numberWithFloat:0.5],
                           [NSNumber numberWithFloat:0.7],
                           [NSNumber numberWithFloat:1.0],
                           nil];
    [animation setKeyTimes:frameTimes];
    
    animation.fillMode = kCAFillModeForwards;
    animation.removedOnCompletion = NO;
    animation.duration = .3;
    
    [self.containerView.layer addAnimation:animation forKey:@"popup"];
}


@end
