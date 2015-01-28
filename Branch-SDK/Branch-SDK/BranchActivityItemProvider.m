//
//  BranchActivityItemProvider.m
//  Branch-TestBed
//
//  Created by Scott Hasbrouck on 1/28/15.
//  Copyright (c) 2015 Branch Metrics. All rights reserved.
//

#import "BranchActivityItemProvider.h"
#import "Branch.h"

@implementation BranchActivityItemProvider

- (id)initWithDefaultURL:(NSString *)url {
    self = [super initWithPlaceholderItem:url];
    if (self) {
        self.branchURL = url;
        self.semaphore = dispatch_semaphore_create(0);
    }
    return self;
}

- (id) item {
    NSLog(@"%@", self.activityType);
    if ([self.placeholderItem isKindOfClass:[NSString class]]) {
        __weak BranchActivityItemProvider *weakSelf = self;
        [[Branch getInstance] getShortURLWithCallback:^(NSString *url, NSError *err) {
            if (!err) {
                self.branchURL = url;
            }
            dispatch_semaphore_signal(weakSelf.semaphore);
        }];
        dispatch_semaphore_wait(self.semaphore, DISPATCH_TIME_FOREVER);
        return self.branchURL;
    }
    return self.placeholderItem;
}

- (id)activityViewController:(UIActivityViewController *)activityViewController itemForActivityType:(NSString *)activityType {
    
    return nil;
}

@end
