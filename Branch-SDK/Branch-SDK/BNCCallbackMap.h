//
//  BNCCallbackMap.h
//  Branch
//
//  Created by Ernest Cho on 2/25/20.
//  Copyright © 2020 Branch, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "BNCServerRequest.h"

NS_ASSUME_NONNULL_BEGIN

@interface BNCCallbackMap : NSObject

+ (instancetype)shared;

- (void)storeRequest:(BNCServerRequest *)request withCompletion:(void (^_Nullable)(BOOL success, NSString *statusMessage))completion;

- (BOOL)containsRequest:(BNCServerRequest *)request;

- (void)callCompletionForRequest:(BNCServerRequest *)request withSuccessStatus:(BOOL)status message:(NSString *)statusMessage;

@end

NS_ASSUME_NONNULL_END
