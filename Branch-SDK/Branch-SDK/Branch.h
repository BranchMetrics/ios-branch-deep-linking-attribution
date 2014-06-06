//
//  Branch_SDK.h
//  Branch-SDK
//
//  Created by Alex Austin on 6/5/14.
//  Copyright (c) 2014 Branch Metrics. All rights reserved.
//

#import <Foundation/Foundation.h>

@protocol BranchDelegate <NSObject>

@optional
- (void)onInitFinished;
- (void)onStateChanged;
- (void)onUrlCreate:(NSString *)url;
@end

@interface Branch : NSObject

+ (Branch *)getInstance:(NSString *)key;

@property (nonatomic, strong) id <BranchDelegate> delegate;


@end
