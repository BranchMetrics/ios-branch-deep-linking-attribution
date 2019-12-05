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

@interface BNCFacebookAppLinks()
- (BOOL)isDeepLinkingClassAvailable;
@end

@interface BNCFacebookAppLinksTests : XCTestCase
@property (nonatomic, strong, readwrite) BNCFacebookAppLinks *applinks;
@end

@implementation BNCFacebookAppLinksTests

- (void)setUp {
    self.applinks = [BNCFacebookAppLinks new];
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
        XCTAssertTrue([NSThread isMainThread]);
        [expectation fulfill];
    }];
    
    [self waitForExpectationsWithTimeout:2 handler:^(NSError * _Nullable error) {
        NSLog(@"%@", error);
    }];
}

// check if FBSDKAppLinkUtility.fetchDeferredAppLink is called on the main thread
// https://developers.facebook.com/docs/reference/ios/current/class/FBSDKAppLinkUtility
- (void)testFetchFacebookAppLink_BackgroundThead {
    __block XCTestExpectation *expectation = [self expectationWithDescription:@""];
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        [self.applinks registerFacebookDeepLinkingClass:[BNCFacebookMock new]];
        [self.applinks fetchFacebookAppLinkWithCompletion:^(NSURL * _Nullable appLink, NSError * _Nullable error) {
            XCTAssertTrue([[appLink absoluteString] isEqualToString:@"https://branch.io"]);
            XCTAssertTrue([NSThread isMainThread]);
            [expectation fulfill];
        }];
    });
    
    [self waitForExpectationsWithTimeout:2 handler:^(NSError * _Nullable error) {
        NSLog(@"%@", error);
    }];
}

@end
