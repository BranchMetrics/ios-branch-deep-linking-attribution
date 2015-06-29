//
//  CreateDeepLinkController.m
//  Branch-TestBed
//
//  Created by Graham Mueller on 6/19/15.
//  Copyright (c) 2015 Branch Metrics. All rights reserved.
//

#import "CreateDeepLinkController.h"
#import "Branch.h"

@interface CreateDeepLinkController () <UITextFieldDelegate>

@property (weak, nonatomic) IBOutlet UITextField *emailField;

@end

@implementation CreateDeepLinkController

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    self.navigationController.navigationBarHidden = NO;
}

- (IBAction)sendLinkPressed:(id)sender {
    UIActivityItemProvider *provider = [Branch getBranchActivityItemWithParams:@{ @"gravatar_email": self.emailField.text }];

    UIActivityViewController *shareViewController = [[UIActivityViewController alloc] initWithActivityItems:@[ provider ] applicationActivities:nil];

    [self presentViewController:shareViewController animated:YES completion:NULL];
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField {
    [textField resignFirstResponder];
    
    return NO;
}

@end
