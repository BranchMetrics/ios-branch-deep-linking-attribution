//
//  BranchDeepLinkingController.h
//  Branch-TestBed
//
//  Created by Graham Mueller on 6/18/15.
//  Copyright (c) 2015 Branch Metrics. All rights reserved.
//

@protocol BranchDeepLinkingControllerCompletionDelegate <NSObject>

- (void)deepLinkingControllerCompleted;

@end

@protocol BranchDeepLinkingController <NSObject>

- (void)configureControlWithData:(NSDictionary *)data;
@property (weak, nonatomic) id <BranchDeepLinkingControllerCompletionDelegate> deepLinkingCompletionDelegate;

@end
