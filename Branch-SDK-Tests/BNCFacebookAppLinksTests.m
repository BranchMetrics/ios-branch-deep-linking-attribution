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
        [expectation fulfill];
    }];
    
    [self waitForExpectationsWithTimeout:2 handler:^(NSError * _Nullable error) {
        
    }];
}

@end
