//
//  BNCPasteboard.m
//  Branch
//
//  Created by Ernest Cho on 6/24/21.
//  Copyright © 2021 Branch, Inc. All rights reserved.
//

#import "BNCPasteboard.h"
#import <UIKit/UIKit.h>
#import "Branch.h"

@implementation BNCPasteboard

+ (BNCPasteboard *)sharedInstance {
    static BNCPasteboard *pasteboard = nil;
    static dispatch_once_t onceToken = 0;
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

- (BOOL)isUrlOnPasteboard {
    #if !TARGET_OS_TV
    if ([UIPasteboard.generalPasteboard hasURLs]) {
        return YES;
    }
    #endif
    return NO;
}

- (nullable NSURL *)checkForBranchLink {
    if ([self isUrlOnPasteboard]) {
        #if !TARGET_OS_TV
        // triggers the end user toast message
        NSURL *tmp = UIPasteboard.generalPasteboard.URL;
        if ([Branch isBranchLink:tmp.absoluteString]) {
            return tmp;
        }
        #endif
    }
    return nil;
}

@end
