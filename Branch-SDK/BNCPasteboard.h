//
//  BNCPasteboard.h
//  Branch
//
//  Created by Ernest Cho on 6/24/21.
//  Copyright © 2021 Branch, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface BNCPasteboard : NSObject

// For v1, we only allow check on install requests
@property (nonatomic,assign) BOOL checkOnInstall;

- (nullable NSURL *)checkForBranchLink;

+ (BNCPasteboard *)sharedInstance;

@end

NS_ASSUME_NONNULL_END
