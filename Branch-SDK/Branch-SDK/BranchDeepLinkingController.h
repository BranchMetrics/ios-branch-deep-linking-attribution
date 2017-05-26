//
//  BranchDeepLinkingController.h
//  Branch-TestBed
//
//  Created by Graham Mueller on 6/18/15.
//  Copyright (c) 2015 Branch Metrics. All rights reserved.
//
#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
@protocol BranchDeepLinkingControllerCompletionDelegate <NSObject>

- (void)deepLinkingControllerCompleted;

@end

typedef NS_ENUM(NSInteger, BNCViewControllerOption) {
    BNCViewControllerOptionShow,
    BNCViewControllerOptionPush,
    BNCViewControllerOptionPresent
};

@protocol BranchDeepLinkingController <NSObject>

- (void)configureControlWithData:(NSDictionary *)data;
@property (weak, nonatomic) id <BranchDeepLinkingControllerCompletionDelegate> deepLinkingCompletionDelegate;

@end
