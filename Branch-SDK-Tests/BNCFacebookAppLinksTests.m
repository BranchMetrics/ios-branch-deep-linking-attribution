//
//  BNCFacebookAppLinksTests.m
//  Branch-SDK-Tests
//
//  Created by Ernest Cho on 10/24/19.
//  Copyright © 2019 Branch, Inc. All rights reserved.
//

#import <XCTest/XCTest.h>
#import "BNCFacebookMock.h"
#import "BNCFacebookAppLinks.h"
#import "Branch.h"

@interface BNCFacebookAppLinks()
- (BOOL)isDeepLinkingClassAvailable;
@end

@interface BNCFacebookAppLinksTests : XCTestCase
@property (nonatomic, strong, readwrite) BNCFacebookAppLinks *applinks;
@property (nonatomic, strong, readwrite) Branch *branch;
@property (nonatomic, strong, readwrite) BNCPreferenceHelper *preferenceHelper;
@end

@implementation BNCFacebookAppLinksTests

- (void)setUp {
    self.branch = [Branch getInstance];
    self.applinks = [BNCFacebookAppLinks new];
    self.preferenceHelper = [BNCPreferenceHelper preferenceHelper];
}

- (void)tearDown {

}

- (void)testIsDeepLinkingClassAvailable {
    XCTAssertFalse([self.applinks isDeepLinkingClassAvailable]);
}

- (void)testRegisterFacebookDeepLinkingClass_String {
    [self.applinks registerFacebookDeepLinkingClass:@"HelloWorld"];
    XCTAssertFalse([self.applinks isDeepLinkingClassAvailable]);
}

- (void)testRegisterFacebookDeepLinkingClass_Mock {
    [self.applinks registerFacebookDeepLinkingClass:[BNCFacebookMock new]];
    XCTAssertTrue([self.applinks isDeepLinkingClassAvailable]);
}

- (void)testFetchFacebookAppLink {
    __block XCTestExpectation *expectation = [self expectationWithDescription:@""];
    
    [self.applinks registerFacebookDeepLinkingClass:[BNCFacebookMock new]];
    [self.applinks fetchFacebookAppLinkWithCompletion:^(NSURL * _Nullable appLink, NSError * _Nullable error) {
        XCTAssertTrue([[appLink absoluteString] isEqualToString:@"https://branch.io"]);
        [expectation fulfill];
    }];
    
    [self waitForExpectationsWithTimeout:2 handler:^(NSError * _Nullable error) {
        NSLog(@"%@", error);
    }];
}

// check if FBSDKAppLinkUtility.fetchDeferredAppLink is called on the main thread
// https://developers.facebook.com/docs/reference/ios/current/class/FBSDKAppLinkUtility
- (void)testCheckFacebookAppLinks {
    __block XCTestExpectation *expectation = [self expectationWithDescription:@""];
    
    [self.branch registerFacebookDeepLinkingClass:[BNCFacebookMock new]];
    
    // checkFacebookAppLinks is not public, so use reflection to call it
    SEL selector = NSSelectorFromString(@"checkFacebookAppLinks");
    ((void (*)(id, SEL))[self.branch methodForSelector:selector])(self.branch, selector);
    
    // wait 2 secs, then fulfill expectation, if checkFacebookAppLinks succeeded in setting
    // BNCPreferenceHelper's property 'faceBookAppLink'
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(2 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        if ([self.preferenceHelper faceBookAppLink]) {
            XCTAssertTrue([[self.preferenceHelper faceBookAppLink].absoluteString isEqualToString:@"https://branch.io"]);
            [expectation fulfill];
        } else {
            XCTFail(@"BNCPreferenceHelper.faceBookAppLink is nil after 2 seconds");
        }
    });
    
    // wait 3 secs, then check if expectation's been fulfilled
    [self waitForExpectationsWithTimeout:3 handler:^(NSError * _Nullable error) {
        NSLog(@"%@", error);
    }];
}

@end
