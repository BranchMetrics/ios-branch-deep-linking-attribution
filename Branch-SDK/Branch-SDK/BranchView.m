//
//  BranchView.m
//  Branch-TestBed
//
//  Created by Sojan P.R. on 3/4/16.
//  Copyright © 2016 Branch Metrics. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "BranchView.h"

NSInteger const BRANCH_VIEW_USAGE_UNLIMITED = -1;
NSString * const BRANCH_VIEW_ID = @"branch_view_id";
NSString * const BRANCH_VIEW_ACTION = @"branch_view_action";
NSString * const BRANCH_VIEW_NUM_USE = @"num_of_use";
NSString * const BRANCH_VIEW_EXPIRY = @"expiry";
NSString * const BRANCH_VIEW_WEBURL = @"branch_view_url";
NSString * const BRANCH_VIEW_WEBHTML = @"branch_view_html";

@interface BranchView()
@end

@implementation BranchView

- (id)initWithBranchView:(NSDictionary *)branchViewDict {
    if (self = [super init]) {
        self.branchViewID = [branchViewDict objectForKey:BRANCH_VIEW_ID];
        self.branchViewAction = [branchViewDict objectForKey:BRANCH_VIEW_ACTION];
        self.numOfUse = [[branchViewDict objectForKey:BRANCH_VIEW_NUM_USE] integerValue];
        self.expirationDate = [NSDate dateWithTimeIntervalSince1970:[[branchViewDict objectForKey:BRANCH_VIEW_EXPIRY] doubleValue]/1000];
        self.webUrl = [branchViewDict objectForKey:BRANCH_VIEW_WEBURL];
        self.webHtml = [branchViewDict objectForKey:BRANCH_VIEW_WEBHTML];
    }
    return self;
}

- (BOOL)isAvailable {
    return (self.expirationDate.timeIntervalSinceNow > 0
             && (self.numOfUse > 0 || self.numOfUse == BRANCH_VIEW_USAGE_UNLIMITED));
}

- (void)updateUsageCount {
    if (self.numOfUse > 0) {
        self.numOfUse--;
    }
}

@end

