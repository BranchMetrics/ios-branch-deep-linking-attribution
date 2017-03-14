//
//  BranchShareActionSheet.h
//  Branch-TestBed
//
//  Created by Edward Smith on 3/13/17.
//  Copyright © 2017 Branch Metrics. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "BranchUniversalObject.h"
@class BranchShareActionSheet;

@protocol BranchShareActionSheetDelegate <NSObject>

/// discusion
///
///         This delegate method is called during the course of user interaction while sharing a
///         Branch link. The linkProperties, such as channel, or the share text parameters can be
///         altered as appropriate for the particular user-chosen activityType.
///
///         This delegate method will be called multiple times during a share interaction and may be
///         called on a background thread.
///
/// param   shareSheet  The calling BranchShareActionSheet that is currently sharing.
@optional
- (void) branchShareSheetWillShare:(BranchShareActionSheet*_Nonnull)shareSheet;

/// discussion
///
///         This delegate method is called when sharing has completed.
///
/// param   shareSheet  The Branch share action sheet that has just completed.
/// param   completed   This parameter is YES if sharing completed successfully and the user did not
///                     cancel.
/// param   error       This parameter contains any errors that occured will attempting to share.
@optional
- (void) branchShareSheet:(BranchShareActionSheet*_Nonnull)shareSheet
              didComplete:(BOOL)completed
                withError:(NSError*_Nullable)error;

@end

#pragma mark - BranchShareActionSheet

@interface BranchShareActionSheet : NSObject

- (instancetype _Nullable) initWithUniversalObject:(BranchUniversalObject*_Nonnull)universalObject
                                    linkProperties:(BranchLinkProperties*_Nonnull)linkProperties;

- (void) showFromViewController:(UIViewController*_Nullable)viewController
                         anchor:(UIBarButtonItem*_Nullable)anchor;

@property (nonatomic, strong) NSString*_Nullable title;
@property (nonatomic, strong) NSString*_Nullable message;
@property (nonatomic, strong) NSString*_Nullable shareText;
@property (nonatomic, strong) id _Nullable shareOther;
@property (nonatomic, strong, readonly) NSURL*_Nullable shareURL;
@property (nonatomic, strong, readonly) NSString*_Nullable activityType;
@property (nonatomic, strong) NSMutableDictionary*_Nullable serverParameters;

@property (nonatomic, strong) BranchUniversalObject*_Nonnull universalObject;
@property (nonatomic, strong) BranchLinkProperties*_Nonnull  linkProperties;
@property (nonatomic, weak)   id<BranchShareActionSheetDelegate>_Nullable delegate;
@end
