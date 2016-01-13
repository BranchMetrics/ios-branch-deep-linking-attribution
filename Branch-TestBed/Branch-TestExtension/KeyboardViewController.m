//
//  KeyboardViewController.m
//  Branch-TestExtension
//
//  Created by Nikita Medvedev on 12/01/16.
//  Copyright © 2016 Branch Metrics. All rights reserved.
//

#import "KeyboardViewController.h"
#import "Branch.h"
#import "BranchUniversalObject.h"

@interface KeyboardViewController ()

@property (nonatomic, strong) IBOutlet UIButton *nextKeyboardButton;
@property (nonatomic, strong) IBOutlet UIButton *branchKeyboardButton;

@end

@implementation KeyboardViewController

- (void)updateViewConstraints {
    [super updateViewConstraints];
}

- (void)viewDidLoad {
    [super viewDidLoad];
	
	[[NSBundle mainBundle] loadNibNamed:@"KeyboardView" owner:self options:nil];
}

- (IBAction)next:(id)sender {
	[self advanceToNextInputMode];
}

- (IBAction)insertShortLink:(id)sender {
	BranchUniversalObject *branchUniversalObject = [[BranchUniversalObject alloc] initWithCanonicalIdentifier:@"item/12345"];
	branchUniversalObject.title = @"My Content Title";
	branchUniversalObject.contentDescription = @"My Content Description";
	
	BranchLinkProperties *linkProperties = [[BranchLinkProperties alloc] init];
	
	[branchUniversalObject getShortUrlWithLinkProperties:linkProperties andCallback:^(NSString *url, NSError *err) {
		if (!err) {
			[self.textDocumentProxy insertText:url];
		}
		else {
			NSLog(@"%@", err);
		}
	}];
}

- (void)textWillChange:(id<UITextInput>)textInput {

}

- (void)textDidChange:(id<UITextInput>)textInput {

}

@end
