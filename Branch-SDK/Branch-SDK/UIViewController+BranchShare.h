//
//  UIViewController+BranchShare.h
//  Branch-TestBed
//
//  Created by Derrick Staten on 4/25/15.
//  Copyright (c) 2015 Branch Metrics. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface UIViewController (BranchShare)

- (void)shareText:(NSString *)text;
- (void)shareText:(NSString *)text andParams:(NSDictionary *)params;

@end
