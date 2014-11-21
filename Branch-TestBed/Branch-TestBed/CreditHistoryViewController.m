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
    
    // Uncomment the following line to preserve selection between presentations.
    // self.clearsSelectionOnViewWillAppear = NO;
    
    // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
    // self.navigationItem.rightBarButtonItem = self.editButtonItem;
}

- (void)viewWillAppear:(BOOL)animated {
    self.navigationController.navigationBarHidden = NO;
    [super viewWillAppear:animated];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
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
        NSDictionary *creditItem = self.creditTransactions[indexPath.row];
        NSDictionary *transaction = [creditItem objectForKey:@"transaction"];
        NSMutableString *text = [NSMutableString stringWithFormat:@"%@ : %@", [transaction objectForKey:@"bucket"], [transaction objectForKey:@"amount"]];

        if ([creditItem objectForKey:@"referrer"] || [creditItem objectForKey:@"referree"]) {
            BOOL hasReferrer = NO;
            [text appendString:@"\t("];
            if ([creditItem objectForKey:@"referrer"]) {
                hasReferrer = YES;
                [text appendFormat:@"referrer: %@)", [creditItem objectForKey:@"referrer"]];
            }
            if ([creditItem objectForKey:@"referree"]) {
                if (hasReferrer) {
                    [text appendString:@" -> "];
                }
                [text appendFormat:@"referree: %@)", [creditItem objectForKey:@"referree"]];
            }
            [text appendString:@")"];
        }
        cell.textLabel.text = text;
        cell.detailTextLabel.text = [transaction objectForKey:@"date"];
    } else {
        cell.textLabel.text = @"None found";
        cell.detailTextLabel.text = nil;
    }
    
    return cell;
}


@end
