//
//  TBTextViewController.m
//  UITestBed
//
//  Created by Edward on 3/8/18.
//  Copyright © 2018 Branch. All rights reserved.
//

#import "TBTextViewController.h"

@interface TBTextViewController ()
@property (weak, nonatomic) IBOutlet UILabel *messageLabel;
@property (weak, nonatomic) IBOutlet UITextView *textView;
@end

@implementation TBTextViewController

- (instancetype) initWithText:(NSString*)text {
    self = [super initWithNibName:NSStringFromClass(self.class) bundle:nil];
    if (!self) return self;
    _text = text;
    return self;
}

- (void) setText:(NSString *)text {
    _text = text;
    self.textView.text = _text;
    [self.textView sizeToFit];
}

- (void) setMessage:(NSString *)message {
    _message = message;
    self.messageLabel.text = [_message uppercaseString];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.textView.layer.borderColor = [UIColor lightGrayColor].CGColor;
    self.textView.layer.borderWidth = 1.0;
    self.text = _text;
    self.message = _message;
}

@end
