//
//  LogOutputViewController.m
//  Branch-TestBed
//
//  Created by David Westgate on 5/11/16.
//  Copyright © 2016 Branch Metrics. All rights reserved.
//

#import "LogOutputViewController.h"

@interface LogOutputViewController ()
@property (weak, nonatomic) IBOutlet UITextView *logOutputTextView;
@end

@implementation LogOutputViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.logOutputTextView.text = _logOutput;
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
