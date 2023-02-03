//
//  BranchPasteControl.h
//  Branch
//
//  Created by Nidhi Dixit on 9/26/22.
//  Copyright © 2022 Branch, Inc. All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

#if __IPHONE_OS_VERSION_MAX_ALLOWED >= 160000
API_AVAILABLE(ios(16.0))
@interface BranchPasteControl : UIView <UIPasteConfigurationSupporting>

// This is designated initializer. All other initializers are blocked.
- (instancetype)initWithFrame:(CGRect)frame AndConfiguration:( UIPasteControlConfiguration * _Nullable) config NS_DESIGNATED_INITIALIZER;
- (instancetype)init NS_UNAVAILABLE;
- (instancetype)initWithFrame:(CGRect)frame NS_UNAVAILABLE;
- (instancetype)initWithCoder:(NSCoder *)coder NS_UNAVAILABLE;

@end
#endif
NS_ASSUME_NONNULL_END
