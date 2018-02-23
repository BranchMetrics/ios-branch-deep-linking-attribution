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
        @"https://myapp.app.link/auth_token=fred",
        @"https://myapp.app.link/authtoken=fred",
        @"https://myapp.app.link/auth=fred",
        @"fb1234:",
        @"fb1234:/",
        @"fb1234:/this-is-some-extra-info/?whatever",
        @"fb1234:/this-is-some-extra-info/?whatever:andstuff",
        @"myscheme:path/to/resource?oauth=747474",
        @"myscheme:oauth=747474",
        @"myscheme:/oauth=747474",
        @"myscheme://oauth=747474",
        @"myscheme://path/oauth=747474",
        @"myscheme://path/:oauth=747474",
        @"https://google.com/userprofile/devonbanks=oauth?",
    ];
    for (NSString *string in badURLs) {
        NSURL *URL = [NSURL URLWithString:string];
        XCTAssertTrue([blackList isBlackListedURL:URL], @"Checking '%@'.", URL);
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
        @"myscheme://path/brauth=747474",
    ];
    for (NSString *string in goodURLs) {
        NSURL *URL = [NSURL URLWithString:string];
        XCTAssertFalse([blackList isBlackListedURL:URL], @"Checking '%@'", URL);
    }
}

- (void) testStandardBlackList {
    Branch *branch = [Branch getInstance:@"key_live_foo"];
    id serverInterfaceMock = OCMPartialMock(branch.serverInterface);
    XCTestExpectation *expectation = [self expectationWithDescription:@"OpenRequest Expectation"];

    OCMStub(
        [serverInterfaceMock postRequest:[OCMArg any]
            url:[OCMArg any]
            key:[OCMArg any]
            callback:[OCMArg any]]
    ).andDo(^(NSInvocation *invocation) {
        __unsafe_unretained NSDictionary *dictionary = nil;
        [invocation getArgument:&dictionary atIndex:2];

        NSString* link = dictionary[@"universal_link_url"];
        NSString *pattern = @"^(?i)((http|https):\\/\\/).*[\\/|?|#].*\\b(password|o?auth|o?auth.?token|access|access.?token)\\b";
        NSLog(@"\n   Link: '%@'\nPattern: '%@'\n.", link, pattern);
        if ([link isEqualToString:pattern]) {
            [expectation fulfill];
        }
    });

    [branch clearNetworkQueue];
    [branch handleDeepLinkWithNewSession:[NSURL URLWithString:@"https://myapp.app.link/bob/link?oauth=true"]];
    [self waitForExpectationsWithTimeout:5.0 handler:nil];
    [serverInterfaceMock stopMocking];
    [BNCPreferenceHelper preferenceHelper].referringURL = nil;
    [[BNCPreferenceHelper preferenceHelper] synchronize];
}

- (void) testUserBlackList {
    Branch *branch = [Branch getInstance:@"key_live_foo"];
    branch.blackListURLRegex = @[
        @"\\/bob\\/"
    ];
    id serverInterfaceMock = OCMPartialMock(branch.serverInterface);
    XCTestExpectation *expectation = [self expectationWithDescription:@"OpenRequest Expectation"];

    OCMStub(
        [serverInterfaceMock postRequest:[OCMArg any]
            url:[OCMArg any]
            key:[OCMArg any]
            callback:[OCMArg any]]
    ).andDo(^(NSInvocation *invocation) {
        __unsafe_unretained NSDictionary *dictionary = nil;
        [invocation getArgument:&dictionary atIndex:2];

        NSString* link = dictionary[@"universal_link_url"];
        NSString *pattern = @"\\/bob\\/";
        NSLog(@"\n   Link: '%@'\nPattern: '%@'\n.", link, pattern);

        if ([link isEqualToString:pattern]) {
            [expectation fulfill];
        }
    });

    [branch clearNetworkQueue];
    [branch handleDeepLinkWithNewSession:[NSURL URLWithString:@"https://myapp.app.link/bob/link"]];
    [self waitForExpectationsWithTimeout:5.0 handler:nil];
    [serverInterfaceMock stopMocking];
    [BNCPreferenceHelper preferenceHelper].referringURL = nil;
    [[BNCPreferenceHelper preferenceHelper] synchronize];
}

@end
