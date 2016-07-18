//
//  SimulateReferralsViewController.m
//  Branch-TestBed
//
//  Created by David Westgate on 5/4/16.
//  Copyright © 2016 Branch Metrics. All rights reserved.
//

#import "Branch.h"
#import "BranchGetPromoCodeRequest.h"
#import "SimulateReferralsViewController.h"
#import "BranchConstants.h"
#import "LogOutputViewController.h"

@interface SimulateReferralsViewController ()

@property (weak, nonatomic) IBOutlet UITextField *promoCodeTextField;
@property (weak, nonatomic) IBOutlet UITextField *amountTextField;
@property (weak, nonatomic) IBOutlet UITextField *promoCodePrefixTextField;

@end

@implementation SimulateReferralsViewController

NSDate *expirationDate;
NSDictionary *pickers;


- (void)viewDidLoad {
    [super viewDidLoad];

    UITapGestureRecognizer *gestureRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(hideKeyboard)];
    [self.tableView addGestureRecognizer:gestureRecognizer];
    
    expirationDate = nil;
    
    pickers = @{@"rewardTypes": @[@"Unlimited use", @"Single use"],
                @"rewardRecipients": @[@"Referred user",@"Referring user",@"Both users"],
                @"datePicker": @[@""]};
    
    [_selectRewardTypeTextField setInputView:[self createPicker]];
    [_selectRewardTypeTextField setInputAccessoryView:[self createToolbar:NO]];
    
    [_selectRewardRecipientTextField setInputView:[self createPicker]];
    [_selectRewardRecipientTextField setInputAccessoryView:[self createToolbar:NO]];
    
    datePicker = [[UIDatePicker alloc] init];
    datePicker.datePickerMode = UIDatePickerModeDate;
    [_expirationDateTextField setInputView:datePicker];
    [_expirationDateTextField setInputAccessoryView:[self createToolbar:YES]];
    
}


- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}


- (IBAction)getButtonTouchUpInside:(id)sender {
    Branch *branch = [Branch getInstance];
    NSString *prefix = _promoCodePrefixTextField.text;
    int amount = [_amountTextField.text intValue];
    int rewardType = (int) [rewardTypes indexOfObject: _selectRewardTypeTextField.text];
    int rewardRecipient = (int) [rewardRecipients indexOfObject:_selectRewardRecipientTextField.text];
    
    [branch getPromoCodeWithPrefix:prefix amount:amount expiration:expirationDate bucket:@"default" usageType:rewardType rewardLocation:rewardRecipient callback:^(NSDictionary *params, NSError *error) {
        if (!error) {
            _promoCodeTextField.text = [params valueForKey:BRANCH_RESPONSE_KEY_PROMO_CODE];
            NSLog(@"Branch TestBed: Get promo code results:\n%@", params);
            [self performSegueWithIdentifier:@"SimulateReferralsToLogOutput" sender:[NSString stringWithFormat:@"Promo Code Generated: %@\n\n%@", [params valueForKey:BRANCH_RESPONSE_KEY_PROMO_CODE], params.description]];
        } else {
            NSLog(@"Branch TestBed: Error retreiving promo code: \n%@", [error localizedDescription]);
            [self showAlert:@"Promo Code Generation Failed" withDescription:error.localizedDescription];
        }
    }];
    
}


- (IBAction)validateButtonTouchUpInside:(id)sender {
    
    if (_promoCodeTextField.text.length > 0) {
        Branch *branch = [Branch getInstance];
        NSString *promoCode = _promoCodeTextField.text;
        
        [branch validateReferralCode:promoCode andCallback:^(NSDictionary *params, NSError *error) {
            
            if (!error) {
                if ([params objectForKey:@"error_message"] == nil) {
                    NSLog(@"Branch TestBed: Promo code %@ is valid.", [params valueForKey:BRANCH_RESPONSE_KEY_PROMO_CODE]);
                    NSLog(@"Branch TestBed: Parameters returned from Branch:\n%@", params);
                    [self showAlert:@"Validation Succeeded" withDescription:params.description];
                } else {
                    NSLog(@"Branch TestBed: Promo code %@ is invalid.", promoCode);
                    NSLog(@"Branch TestBed: Parameters returned from Branch:\n%@", params);
                    [self showAlert:@"Validation Failed" withDescription:params.description];
                }
            } else {
                NSLog(@"Branch TestBed: Unavle to validate promo code: %@", promoCode);
                [self showAlert:@"Validation Failed" withDescription:[NSString stringWithFormat:@"Unable to validate promo code %@", promoCode]];
            }
        }];
        
    } else {
        NSLog(@"Branch TestBed: No promo code to validate\n");
        [self showAlert:@"No promo code!" withDescription:@"Please enter a promo code to validate"];
    }
}


- (IBAction)redeemButtonTouchUpInside:(id)sender {
    

    if (_promoCodeTextField.text.length > 0) {
        Branch *branch = [Branch getInstance];
        NSString *promoCode = _promoCodeTextField.text;
        
        [branch applyReferralCode:promoCode andCallback:^(NSDictionary *params, NSError *error) {
            if (!error) {
                if ([params objectForKey:@"error_message"] == nil) {
                    NSLog(@"Branch TestBed: Promo code %@ has been successfully applied", [params valueForKey:BRANCH_RESPONSE_KEY_PROMO_CODE]);
                    NSLog(@"Branch TestBed: Parameters returned from Branch:\n%@", params);
                    [self showAlert:@"Promo Code Applied" withDescription:params.description];
                } else {
                    NSLog(@"Branch TestBed: Promo code %@ is invalid.", promoCode);
                    NSLog(@"Branch TestBed: Parameters returned from Branch:\n%@", params);
                    [self showAlert:@"Promo Code Invalid" withDescription:params.description];
                }
            } else {
                NSLog(@"Branch TestBed: Error retreiving promo code: \n%@", promoCode);
                [self showAlert:@"Validation Failed" withDescription:[NSString stringWithFormat:@"Unable to validate promo code %@", promoCode]];
            }
        }];
        
    } else {
        NSLog(@"Branch TestBed: No promo code to redeem\n");
        [self showAlert:@"No promo code!" withDescription:@"Please enter a promo code to validate"];
    }
}


//MARK: Resign First Responder
- (void)hideKeyboard {
    if ([self.promoCodeTextField isFirstResponder]) {
        [self.promoCodeTextField resignFirstResponder];
    } else if ([self.amountTextField isFirstResponder]) {
        [self.amountTextField resignFirstResponder];
    } else if ([self.promoCodePrefixTextField isFirstResponder]) {
        [self.promoCodePrefixTextField resignFirstResponder];
    }
}


//MARK: Data Sources
- (UIToolbar *)createToolbar:(BOOL)withCancelButton {
    UIToolbar *toolbar = [[UIToolbar alloc] initWithFrame:CGRectMake(0,0,self.view.frame.size.width,44)];
    [toolbar setTintColor:[UIColor grayColor]];
    UIBarButtonItem *emptySpace = [[UIBarButtonItem alloc]initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil];
    UIBarButtonItem *donePickingButton = [[UIBarButtonItem alloc]initWithTitle:@"Done" style:UIBarButtonItemStyleBordered target:self action:@selector(donePicking)];
    if (withCancelButton) {
        UIBarButtonItem *cancelPickingButton = [[UIBarButtonItem alloc]initWithTitle:@"Cancel" style:UIBarButtonItemStyleBordered target:self action:@selector(donePicking)];
        [toolbar setItems:[NSArray arrayWithObjects: cancelPickingButton, emptySpace, donePickingButton, nil]];
    } else {
        [toolbar setItems:[NSArray arrayWithObjects: emptySpace, donePickingButton, nil]];
    }
    
    return toolbar;
}


- (UIPickerView *)createPicker {
    UIPickerView *picker = [[UIPickerView alloc] init];
    picker.dataSource = self;
    picker.delegate = self;
    picker.showsSelectionIndicator = true;
    
    return picker;
}


- (void)donePicking {
    if ([[self pickerType]  isEqualToString:@"rewardRecipients"]) {
        [_selectRewardRecipientTextField resignFirstResponder];
    } else if ([[self pickerType]  isEqualToString:@"rewardTypes"]) {
        [_selectRewardTypeTextField resignFirstResponder];
    } else {
        NSDateFormatter *dateFormatter=[[NSDateFormatter alloc] init];
        [dateFormatter setDateFormat:@"YYYY-MM-dd"];
        expirationDate = datePicker.date;
        _expirationDateTextField.text = [NSString stringWithFormat:@"%@", [dateFormatter stringFromDate: expirationDate]];
        [_expirationDateTextField resignFirstResponder];
    }
}


- (NSInteger)numberOfComponentsInPickerView:(UIPickerView *)pickerView {
    return 1;
}


- (NSInteger)pickerView:(UIPickerView *)pickerView numberOfRowsInComponent:(NSInteger)component {
    return [pickers[[self pickerType]] count];
}


- (NSString *)pickerView:(UIPickerView *)pickerView titleForRow:(NSInteger)row forComponent:(NSInteger)component {
    return [pickers[[self pickerType]] objectAtIndex:row];
}


- (void)pickerView:(UIPickerView *)pickerView didSelectRow:(NSInteger)row inComponent:(NSInteger)component {
    if ([[self pickerType]  isEqual: @"rewardRecipients"]) {
        _selectRewardRecipientTextField.text = [pickers objectForKey:[self pickerType]][row];
    } else if ([[self pickerType]  isEqual: @"rewardTypes"]) {
        _selectRewardTypeTextField.text = [pickers objectForKey:[self pickerType]][row];
    }
}


- (NSString *)pickerType {
    if ([self selectRewardRecipientTextField].isEditing) {
        return @"rewardRecipients";
    } else if ([self selectRewardTypeTextField].isEditing) {
        return @"rewardTypes";
    } else {
        return @"datePicker";
    }
}


- (void)showAlert: (NSString *)title withDescription:(NSString *) message {
    UIAlertController* alert = [UIAlertController alertControllerWithTitle:title message:message preferredStyle:UIAlertControllerStyleAlert];
    [alert addAction:[UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleCancel handler:nil]];
    [self presentViewController:alert animated:YES completion:nil];
}


- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    if ([segue.identifier isEqualToString:@"SimulateReferralsToLogOutput"]) {
        ((LogOutputViewController *)segue.destinationViewController).logOutput = sender;
    }
}


@end
