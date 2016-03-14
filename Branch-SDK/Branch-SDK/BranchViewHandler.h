//
//  BNCViewHandler.h
//  Branch-TestBed
//
//  Created by Sojan P.R. on 3/3/16.
//  Copyright © 2016 Branch Metrics. All rights reserved.
//

#ifndef BranchViewHandler_h
#define BranchViewHandler_h


#endif /* BranchViewHandler_h */
#import "BranchView.h"


@protocol BranchViewControllerDelegate <NSObject>

- (void)branchViewVisible:(NSString *)actionName withID:(NSString *)branchViewID;
- (void)branchViewAccepted:(NSString *)actionName withID:(NSString *)branchViewID;
- (void)branchViewCancelled:(NSString *)actionName withID:(NSString *)branchViewID;

@end

@interface BranchViewHandler : NSObject
//---- Properties---------------//
/**
 Callback for Branch View events
 */
@property (nonatomic, assign) id  <BranchViewControllerDelegate> branchViewCallback;
/**
 Cache for saving Branch views locally
 */
@property (strong, nonatomic) NSMutableArray *branchViewCache;


//-- Methods--------------------//
/**
 Gets the global instance for BranchViewHandler.
 */
+ (BranchViewHandler *)getInstance;
/**
 Shows a Branch view for the given action if available
 */
- (BOOL)showBranchView:(NSString *)actionName withDelegate:(id)callback;
/**
  Adds a given list of Branch views to cache
 */
- (void)saveBranchViews:(NSArray *)branchViewList;

@end
