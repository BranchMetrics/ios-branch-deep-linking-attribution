//
//  BNCPasteboard.m
//  Branch
//
//  Created by Ernest Cho on 6/24/21.
//  Copyright © 2021 Branch, Inc. All rights reserved.
//

#import "BNCPasteboard.h"
#import "Branch.h"
#import <UIKit/UIKit.h>

@implementation BNCPasteboard

+ (BNCPasteboard *)sharedInstance {
    static BNCPasteboard *pasteboard;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        pasteboard = [BNCPasteboard new];
    });
    return pasteboard;
}

- (instancetype)init {
    self = [super init];
    if (self) {
        self.checkOnInstall = NO;
    }
    return self;
}

- (nullable NSURL *)checkForBranchLink {
    // consider limiting this check to iOS 15+
    if (@available(iOS 10.0, *)) {
        if ([UIPasteboard.generalPasteboard hasURLs]) {
            
            // triggers the end user toast message
            NSURL *tmp = UIPasteboard.generalPasteboard.URL;
            if ([Branch isBranchLink:tmp.absoluteString]) {
                return tmp;
            }
        }
    }
    return nil;
}

@end
