//
//  BranchScene.m
//  Branch
//
//  Created by Ernest Cho on 3/24/20.
//  Copyright © 2020 Branch, Inc. All rights reserved.
//

#import "BranchScene.h"
#import "Branch.h"
#import "BranchLogger.h"

@implementation BranchScene

+ (BranchScene *)shared NS_EXTENSION_UNAVAILABLE("BranchScene does not support Extensions") {
    static BranchScene *bscene = nil;
    static dispatch_once_t onceToken = 0;
    dispatch_once(&onceToken, ^{
        bscene = [BranchScene new];
    });
    return bscene;
}

- (void)scene:(UIScene *)scene continueUserActivity:(NSUserActivity *)userActivity NS_EXTENSION_UNAVAILABLE("BranchScene does not support Extensions") {
    [[BranchLogger shared] logVerbose:@"BranchScene continueUserActivity" error:nil];
    [[Branch sharedInstance] requestDeepLinkDataWithScene:scene continueUserActivity:userActivity];
}

- (void)scene:(UIScene *)scene openURLContexts:(NSSet<UIOpenURLContext *> *)URLContexts NS_EXTENSION_UNAVAILABLE("BranchScene does not support Extensions") {
    [[BranchLogger shared] logVerbose:@"BranchScene openURLContexts" error:nil];

    if (URLContexts.count != 1) {
        [[BranchLogger shared] logWarning:@"Branch only supports a single URLContext" error:nil];
    }

    [[Branch sharedInstance] requestDeepLinkDataWithScene:scene openURLContexts:URLContexts];
}

@end
