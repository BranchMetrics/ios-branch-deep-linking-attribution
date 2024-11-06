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
    
    UIBarButtonItem *clearButton = [[UIBarButtonItem alloc] initWithTitle:@"Clear Logs"
                                                                    style:UIBarButtonItemStylePlain
                                                                   target:self
                                                                   action:@selector(clearLogs)];
    self.navigationItem.rightBarButtonItem = clearButton;
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)clearLogs {
    NSString *documentsDirectory = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) firstObject];
    NSString *logFilePath = [documentsDirectory stringByAppendingPathComponent:@"branchlogs.txt"];
    
    NSError *error = nil;
    [[NSFileManager defaultManager] removeItemAtPath:logFilePath error:&error];
    
    if (error) {
        NSLog(@"Error clearing log file: %@", error.localizedDescription);
    } else {
        self.logOutputTextView.text = @"Logs cleared.";
        NSLog(@"Log file cleared successfully.");
        
        [self.navigationController popViewControllerAnimated:YES];

    }
}


@end
