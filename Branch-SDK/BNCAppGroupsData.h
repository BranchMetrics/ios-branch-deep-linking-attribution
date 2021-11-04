//
//  BNCAppGroupsData.h
//  Branch
//
//  Created by Ernest Cho on 9/27/20.
//  Copyright © 2020 Branch, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface BNCAppGroupsData : NSObject

// app group used to share data between the App Clip and the Full App
@property (nonatomic, readwrite, copy) NSString *appGroup;

// App Clip data
@property (nonatomic, readwrite, copy) NSString *bundleID;
@property (nonatomic, strong, readwrite) NSDate *installDate;
@property (nonatomic, readwrite, copy) NSString *url;
@property (nonatomic, readwrite, copy) NSString *branchToken;
@property (nonatomic, readwrite, copy) NSString *bundleToken;

+ (instancetype)shared;

// saves app clip data when appropriate
- (void)saveAppClipData;

// loads app clip data
- (BOOL)loadAppClipData;

@end

NS_ASSUME_NONNULL_END
