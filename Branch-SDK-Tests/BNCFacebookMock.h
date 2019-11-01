//
//  BNCFacebookMock.h
//  Branch-SDK-Tests
//
//  Created by Ernest Cho on 10/24/19.
//  Copyright © 2019 Branch, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface BNCFacebookMock : NSObject

- (void)fetchDeferredAppLink:(void (^_Nullable)(NSURL *__nullable appLink, NSError * __nullable error))completion;

@end

NS_ASSUME_NONNULL_END
