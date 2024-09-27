//
//  BranchPasteControl.h
//  Branch
//
//  Created by Nidhi Dixit on 9/26/22.
//  Copyright © 2022 Branch, Inc. All rights reserved.
//

#if !TARGET_OS_TV
#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

API_AVAILABLE(ios(16.0), macCatalyst(16.0))
@interface BranchPasteControl : UIView <UIPasteConfigurationSupporting>

- (instancetype)initWithFrame:(CGRect)frame AndConfiguration:( UIPasteControlConfiguration * _Nullable) config NS_DESIGNATED_INITIALIZER;
- (instancetype)init NS_UNAVAILABLE;
- (instancetype)initWithFrame:(CGRect)frame NS_UNAVAILABLE;
- (instancetype)initWithCoder:(NSCoder *)coder NS_UNAVAILABLE;

@end
NS_ASSUME_NONNULL_END
#endif
