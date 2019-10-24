//
//  BNCFacebookMock.m
//  Branch-SDK-Tests
//
//  Created by Ernest Cho on 10/24/19.
//  Copyright © 2019 Branch, Inc. All rights reserved.
//

#import "BNCFacebookMock.h"

@implementation BNCFacebookMock

- (void)fetchDeferredAppLink:(void (^_Nullable)(NSURL *__nullable appLink, NSError * __nullable error))completion {
    if (completion) {
        NSURL *url = [NSURL URLWithString:@"https://branch.io"];
        completion(url, nil);
    }
}

@end
