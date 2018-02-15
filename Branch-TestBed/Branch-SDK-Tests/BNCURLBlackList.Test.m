/**
 @file          BNCURLBlackList.Test.m
 @package       Branch-SDK-Tests
 @brief         BNCURLBlackList tests.

 @author        Edward Smith
 @date          February 14, 2018
 @copyright     Copyright © 2018 Branch. All rights reserved.
*/

#import "BNCTestCase.h"
#import "BNCURLBlackList.h"

@interface BNCURLBlackListTest : BNCTestCase
@end

@implementation BNCURLBlackListTest

- (void) setUp {
    [BNCPreferenceHelper preferenceHelper].URLBlackList = nil;
    [BNCPreferenceHelper preferenceHelper].URLBlackListVersion = 0;
}

- (void)testListDownLoad {
    XCTestExpectation *expectation = [self expectationWithDescription:@"BlackList Download"];
    BNCURLBlackList *blackList = [BNCURLBlackList new];
    [blackList refreshBlackListFromServerWithCompletion:^ (NSError*error, NSArray*list) {
        XCTAssertNil(error);
        XCTAssertTrue(list.count == 8);
        [expectation fulfill];
    }];
    [self awaitExpectations];
}

- (void)testBadURLs {
    BNCURLBlackList *blackList = [BNCURLBlackList new];
    NSArray *badURLs = @[
        @"fb123456:login/464646",
        @"twitterkit-.4545:",
        @"shsh:oauth/login",
        @"https://myapp.app.link/oauth_token=fred",
        @"fb1234:",
        @"fb1234:/",
        @"fb1234:/this-is-some-extra-info/?whatever",
        @"myscheme:path/to/resource?oauth=747474",
        @"fb1234:/this-is-some-extra-info/?whatever:andstuff",
    ];
    for (NSString *string in badURLs) {
        NSURL *URL = [NSURL URLWithString:string];
        XCTAssertTrue([blackList isBlackListedURL:URL]);
    }
}

- (void)testGoodURLs {
    BNCURLBlackList *blackList = [BNCURLBlackList new];
    NSArray *goodURLs = @[
        @"shshs:/content/path",
        @"shshs:content/path",
        @"https://myapp.app.link/12345/link",
        @"fb123x:/",
        @"https://myapp.app.link?authentic=true&tokemonsta=false",
    ];
    for (NSString *string in goodURLs) {
        NSURL *URL = [NSURL URLWithString:string];
        XCTAssertFalse([blackList isBlackListedURL:URL], @"Checking '%@'", URL);
    }
}

@end
