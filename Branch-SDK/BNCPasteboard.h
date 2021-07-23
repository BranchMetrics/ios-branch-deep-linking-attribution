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

/*
 Indicates if the client wishes to check for Branch links on install. By default, this is NO.
 
 Set via Branch.checkPasteboardOnInstall
 Checked by BranchInstallRequest.makeRequest before checking the pasteboard for a Branch link.
 */
@property (nonatomic, assign) BOOL checkOnInstall;

- (BOOL)isUrlOnPasteboard;
- (nullable NSURL *)checkForBranchLink;

+ (BNCPasteboard *)sharedInstance;

@end

NS_ASSUME_NONNULL_END
