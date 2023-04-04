//
//  BNCUrlQueryParameter.h
//  Branch
//
//  Created by Nipun Singh on 3/15/23.
//  Copyright © 2023 Branch, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface BNCUrlQueryParameter : NSObject

@property (readwrite, copy, nonatomic) NSString *name;
@property (readwrite, copy, nonatomic) NSString *value;
@property (readwrite, strong, nonatomic) NSDate *timestamp;
@property (readwrite, assign, nonatomic) BOOL isDeepLink;

@property (readwrite, assign, nonatomic) NSTimeInterval validityWindow;

// YES - [NSDate date] is within validity window
- (BOOL)isWithinValidityWindow;

@end

NS_ASSUME_NONNULL_END
