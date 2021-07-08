//
//  BNCPasteboard.m
//  Branch
//
//  Created by Ernest Cho on 6/24/21.
//  Copyright © 2021 Branch, Inc. All rights reserved.
//

#import <UIKit/UIKit.h>
#if !TARGET_OS_TV
#import "BNCPasteboard.h"
#endif

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
    
#if !TARGET_OS_TV
    if (@available(iOS 10.0, *)) {
        if ([UIPasteboard.generalPasteboard hasURLs]) {
            
            // triggers the end user toast message
            NSURL *tmp = UIPasteboard.generalPasteboard.URL;
            if ([self isProbableBranchLink:tmp]) {
                return tmp;
            }
        }
    }
#endif
    return nil;
}

- (BOOL)isProbableBranchLink:(NSURL *)url {
    // TODO: check against info.plist
    return YES;
}

@end
