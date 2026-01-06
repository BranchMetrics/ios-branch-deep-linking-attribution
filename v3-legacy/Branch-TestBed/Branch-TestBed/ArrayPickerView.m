//
//  ArrayPickerView.m
//  Branch-TestBed
//
//  Created by edward on 11/6/17.
//  Copyright © 2017 Branch, Inc. All rights reserved.
//

#import "ArrayPickerView.h"

@interface ArrayPickerView () <UIPickerViewDelegate, UIPickerViewDataSource>
@property (nonatomic, copy) NSArray<NSString*> *pickerArray;
@property (nonatomic, strong) UITextField *dummyTextField;
@property (nonatomic, copy) void (^completionBlock)(NSString*);
@end

@implementation ArrayPickerView

- (instancetype _Nonnull) initWithArray:(NSArray<NSString*> *_Nonnull)array {
    self = [super init];
    self.pickerArray = array;
    self.delegate = self;
    self.dataSource = self;
    self.doneButtonTitle = @"Done";
    return self;
}

- (void) presentFromViewController:(UIViewController*_Nonnull)viewController
                    withCompletion:(void (^_Nullable)(NSString*_Nullable result))completion {
    self.completionBlock = completion;
    self.dummyTextField = [[UITextField alloc] initWithFrame:CGRectZero];
    [viewController.view addSubview:self.dummyTextField];
    self.dummyTextField.inputView = self;
    UIToolbar *toolBar = [[UIToolbar alloc] initWithFrame:CGRectMake(0,0,320,44)];
    toolBar.items = @[
        [[UIBarButtonItem alloc] initWithTitle:@"Cancel" style:UIBarButtonItemStylePlain target:self action:@selector(cancelAction:)],
        [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil],
        [[UIBarButtonItem alloc] initWithTitle:self.doneButtonTitle style:UIBarButtonItemStyleDone target:self action:@selector(doneAction:)]
    ];
    self.dummyTextField.inputAccessoryView = toolBar;
    [self.dummyTextField becomeFirstResponder];
}

#pragma mark - Picker View Delegates

- (NSInteger)numberOfComponentsInPickerView:(UIPickerView *)pickerView {
    return 1;
}

- (NSInteger)pickerView:(UIPickerView *)pickerView numberOfRowsInComponent:(NSInteger)component {
    return self.pickerArray.count;
}

- (NSString *)pickerView:(UIPickerView *)pickerView titleForRow:(NSInteger)row forComponent:(NSInteger)component {
    return self.pickerArray[row];
}

#pragma mark - Done Actions

- (IBAction) cancelAction:(id)sender {
    [self dismissWithIndex:-1];
}

- (IBAction) doneAction:(id)sender {
    [self dismissWithIndex:[self selectedRowInComponent:0]];
}

- (void) dismissWithIndex:(NSInteger)index {
    NSString *selection = nil;
    if (index >= 0) selection = self.pickerArray[index];
    if (self.completionBlock) self.completionBlock(selection);
    [self.dummyTextField removeFromSuperview];
    self.dummyTextField = nil;
}

@end
