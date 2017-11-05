//
//  CreditHistoryViewController.m
//  Branch-TestBed
//
//  Created by Qinwei Gong on 10/9/14.
//  Copyright (c) 2014 Branch Metrics. All rights reserved.
//

#import "CreditHistoryViewController.h"

@interface CreditHistoryViewController ()
@end

@implementation CreditHistoryViewController

- (void)viewDidLoad {
    [super viewDidLoad];
}

- (void)viewWillAppear:(BOOL)animated {
    self.navigationController.navigationBarHidden = NO;
    [super viewWillAppear:animated];
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.creditTransactions.count > 0 ? self.creditTransactions.count : 1;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"CreditTransactionRow" forIndexPath:indexPath];
    
    if (!cell) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:@"CreditTransactionRow"];
    }
    
    if (self.creditTransactions.count > 0) {
        
        if ([self.creditTransactions count] > 0) {
            NSDictionary *creditItem = [[self creditTransactions] objectAtIndex:indexPath.row];
            NSDictionary *transaction = [creditItem objectForKey:@"transaction"];
            int amount = (int) [[transaction objectForKey:@"amount"] integerValue];
            NSString *bucket = [transaction objectForKey:@"bucket"];
            
            NSString *amountAsString;
            if (amount >= 0) {
                amountAsString = [NSString stringWithFormat:@"+%d", amount];
            } else {
                amountAsString = [NSString stringWithFormat:@"%d", amount];
            }
            NSString *text = [NSString stringWithFormat:@"%@ to %@", amountAsString, bucket];
            
            if ([transaction objectForKey:@"referrer"]) {
                text = [NSString stringWithFormat:@"%@ - Referred by: %@", text, [transaction objectForKey:@"referrer"]];
            } if ([transaction objectForKey:@"referred"]) {
                text = [NSString stringWithFormat:@"%@ - User Referred: %@", text, [transaction objectForKey:@"referred"]];
            }
            [cell textLabel].text = text;
            
            NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
            [dateFormatter setDateFormat:@"yyyy-MM-dd'T'HH:mm:ss.SSSZ"];
            [dateFormatter setLocale:[NSLocale currentLocale]];
            NSString *dateString = transaction[@"date"];
            NSDate *date = [dateFormatter dateFromString:dateString];
            if (date) {
                [dateFormatter setDateStyle:NSDateFormatterMediumStyle];
                [dateFormatter setTimeStyle:NSDateFormatterMediumStyle];
                [cell detailTextLabel].text = [dateFormatter stringFromDate:date];
            }
            
            [cell detailTextLabel].text = [dateFormatter stringFromDate:date];
        }
        
        
    } else {
        cell.textLabel.text = @"None found";
        cell.detailTextLabel.text = nil;
    }
    
    return cell;
}


@end
