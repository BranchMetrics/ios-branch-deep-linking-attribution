//
//  BNCFacebookMock.m
//  Branch-SDK-Tests
//
//  Created by Ernest Cho on 10/24/19.
//  Copyright © 2019 Branch, Inc. All rights reserved.
//

#import "BNCFacebookMock.h"
#import "NSError+Branch.h"

@implementation BNCFacebookMock

- (void)fetchDeferredAppLink:(void (^_Nullable)(NSURL *__nullable appLink, NSError * __nullable error))completion {
    if (completion) {
        if (![NSThread isMainThread]) {
            // fetchDeferredAppLink must be called from main thread
            // https://developers.facebook.com/docs/reference/ios/current/class/FBSDKAppLinkUtility
            completion(nil, [NSError branchErrorWithCode:BNCGeneralError localizedMessage:@"fetchDeferredAppLink must be called from main thread"]);
        } else {
            completion([NSURL URLWithString:@"https://branch.io"], nil);
        }
    }
}

@end
