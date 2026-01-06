//
//  NavigationController.m
//  Branch-TestBed
//
//  Created by David Westgate on 5/22/16.
//  Copyright © 2016 Branch Metrics. All rights reserved.
//

#import "NavigationController.h"
#import "LogOutputViewController.h"
#import "ViewController.h"

@interface NavigationController ()
@end

@implementation NavigationController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@synthesize deepLinkingCompletionDelegate;
- (void)configureControlWithData:(NSDictionary *)data {
    LogOutputViewController *logOutputViewController = [[UIStoryboard storyboardWithName:@"Main" bundle:[NSBundle mainBundle]] instantiateViewControllerWithIdentifier:@"LogOutputViewController"];
    [self pushViewController:logOutputViewController animated:YES];
    NSString *deeplinkText = [data objectForKey:@"deeplink_text"];
    if (deeplinkText) {
        NSString *logOutput = [NSString stringWithFormat:@"Successfully Deeplinked:\n\n%@\nSession Details:\n\n%@", deeplinkText, data.description];
        logOutputViewController.logOutput = logOutput;
    }
}


@end
