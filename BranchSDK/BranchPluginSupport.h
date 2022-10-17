//
//  BranchPluginSupport.h
//  BranchSDK
//
//  Created by Nipun Singh on 1/6/22.
//  Copyright © 2022 Branch, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface BranchPluginSupport : NSObject

+ (BranchPluginSupport *)instance;
- (NSDictionary<NSString *, NSString *> *)deviceDescription;

@end

NS_ASSUME_NONNULL_END
