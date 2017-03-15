//
//  BranchShareActivitySheet.h
//  Branch-SDK
//
//  Created by Edward Smith on 3/13/17.
//  Copyright © 2017 Branch Metrics. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "BranchUniversalObject.h"
@class BranchShareActivitySheet;

@protocol BranchShareActivitySheetDelegate <NSObject>

@optional

/**
This delegate method is called during the course of user interaction while sharing a
Branch link. The linkProperties, such as channel, or the share text parameters can be
altered as appropriate for the particular user-chosen activityType.

This delegate method will be called multiple times during a share interaction and may be
called on a background thread.

@param  shareSheet  The calling BranchShareActionSheet that is currently sharing.
*/
- (void) branchActivitySheetWillShare:(BranchShareActivitySheet*_Nonnull)activitySheet;

/**
This delegate method is called when sharing has completed.

@param shareSheet   The Branch share action sheet that has just completed.
@param completed    This parameter is YES if sharing completed successfully and the user did not cancel.
@param error        This parameter contains any errors that occured will attempting to share.
*/
- (void) branchShareSheet:(BranchShareActivitySheet*_Nonnull)shareSheet
              didComplete:(BOOL)completed
                withError:(NSError*_Nullable)error;

@end

#pragma mark - BranchShareActivitySheet

/**
The `BranchShareActivitySheet` class facilitates sharing Branch links using a `UIActivityViewController` user experience.

The `BranchShareActivitySheet` is a new class that is similiar to but has more functionality than the old `[BranchUniversalObject showShareSheetWithLinkProperties:...]` methods.

The `BranchShareActivitySheet` is initialized with the `BranchUniversalObject` and `BranchLinkProperties` objects that will be used to generate the Branch link.

After the `BranchShareActivitySheet` object is created, set any configuration properties on the activity sheet object, and then call `showFromViewController:anchor:` to show the activity sheet.

A delegate on the BranchShareActivitySheet can further configure the share experience. For instance the link parameters can be changed depending on the activity that the user selects.
*/

@interface BranchShareActivitySheet : NSObject

/**
Creates a BranchShareActivitySheet object.

@oaram universalObject  The Branch Universal Object the will be shared.
@param linkProperties   The link properties that the link will have.
*/
- (instancetype _Nullable) initWithUniversalObject:(BranchUniversalObject*_Nonnull)universalObject
                                    linkProperties:(BranchLinkProperties*_Nonnull)linkProperties;


/**
Presents a share activity sheet for the Branch link.

@oaram viewController   The parent view controller from which to present the the activity sheet.
@param anchor           The anchor point for the activity sheet. Used for iPad form factors.
*/
- (void) showFromViewController:(UIViewController*_Nullable)viewController
                         anchor:(UIBarButtonItem*_Nullable)anchor;

///The title for the share sheet.
@property (nonatomic, strong) NSString*_Nullable title;

///Share text for the item.  This text can be changed later when the `branchShareSheetWillShare:`
///delegate method is called.
@property (nonatomic, strong) NSString*_Nullable shareText;

///An additional, user defined, non-typed, object to be shared.
@property (nonatomic, strong) id _Nullable shareObject;

///The resulting Branch URL that was shared.
@property (nonatomic, strong, readonly) NSURL*_Nullable shareURL;

///The activity type that the user chose.
@property (nonatomic, strong, readonly) NSString*_Nullable activityType;

///Extra server parameters that should be included with the link data.
@property (nonatomic, strong) NSMutableDictionary*_Nullable serverParameters;

///The Branch Universal Object that will be shared.
@property (nonatomic, strong) BranchUniversalObject*_Nonnull universalObject;

///The link properties for the created URL.
@property (nonatomic, strong) BranchLinkProperties*_Nonnull  linkProperties;

///The delegate. See 'BranchShareActionSheetDelegate' above for a description.
@property (nonatomic, weak)   id<BranchShareActivitySheetDelegate>_Nullable delegate;
@end
