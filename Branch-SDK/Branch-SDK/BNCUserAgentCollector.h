//
//  BNCUserAgentCollector.h
//  Branch
//
//  Created by Ernest Cho on 8/29/19.
//  Copyright © 2019 Branch, Inc. All rights reserved.
//

@import Foundation;

NS_ASSUME_NONNULL_BEGIN

@interface BNCUserAgentCollector : NSObject

+ (BNCUserAgentCollector *)instance;

- (void)collectUserAgentWithCompletion:(void (^)(NSString * _Nullable useragent))completion;

@end

NS_ASSUME_NONNULL_END
