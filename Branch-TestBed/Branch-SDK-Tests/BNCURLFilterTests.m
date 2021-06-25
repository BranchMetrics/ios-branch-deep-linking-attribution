/**
 @file          BNCURLFilterTests.m
 @package       Branch-SDK-Tests
 @brief         BNCURLFilter  tests.

 @author        Edward Smith
 @date          February 14, 2018
 @copyright     Copyright © 2018 Branch. All rights reserved.
*/

#import "BNCTestCase.h"
#import "BNCURLFilter.h"
#import "Branch.h"

@interface BNCURLFilter ()
@property (readwrite) NSURL *jsonURL;
@end

@interface BNCURLFilterTests : BNCTestCase
@end

@implementation BNCURLFilterTests

- (void) setUp {
    [BNCPreferenceHelper sharedInstance].savedURLPatternList = nil;
    [BNCPreferenceHelper sharedInstance].savedURLPatternListVersion = 0;
    [BNCPreferenceHelper sharedInstance].dropURLOpen = NO;
}

- (void) tearDown {
    [BNCPreferenceHelper sharedInstance].dropURLOpen = NO;
}

- (void)testListDownLoad {
    XCTestExpectation *expectation = [self expectationWithDescription:@"List Download"];
    BNCURLFilter *filter = [BNCURLFilter new];
    [filter updatePatternListWithCompletion:^ (NSError*error, NSArray*list) {
        XCTAssertNil(error);
        XCTAssertTrue(list.count == 6);
        [expectation fulfill];
    }];
    [self awaitExpectations];
}

- (NSArray*) badURLs {
    NSArray *kBadURLs = @[
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
    return kBadURLs;
}

- (NSArray*) goodURLs {
    NSArray *kGoodURLs = @[
        @"shshs:/content/path",
        @"shshs:content/path",
        @"https://myapp.app.link/12345/link",
        @"fb123x:/",
        @"https://myapp.app.link?authentic=true&tokemonsta=false",
        @"myscheme://path/brauth=747474",
    ];
    return kGoodURLs;
}

- (void)testBadURLs {
    // Test default list.
    BNCURLFilter *filter = [BNCURLFilter new];
    for (NSString *string in self.badURLs) {
        NSURL *URL = [NSURL URLWithString:string];
        XCTAssertTrue([filter shouldIgnoreURL:URL], @"Checking '%@'.", URL);
    }
}

- (void) testDownloadBadURLs {
    // Test download list.
    XCTestExpectation *expectation = [self expectationWithDescription:@"List Download"];
    BNCURLFilter *filter = [BNCURLFilter new];
    filter.jsonURL = [NSURL URLWithString:@"https://cdn.branch.io/sdk/uriskiplist_tv1.json"];
    [filter updatePatternListWithCompletion:^ (NSError*error, NSArray*list) {
        XCTAssertNil(error);
        XCTAssertTrue(list.count == 7);
        [expectation fulfill];
    }];
    [self awaitExpectations];
    for (NSString *string in self.badURLs) {
        NSURL *URL = [NSURL URLWithString:string];
        XCTAssertTrue([filter shouldIgnoreURL:URL], @"Checking '%@'.", URL);
    }
}

- (void)testGoodURLs {
    // Test default list.
    BNCURLFilter *filter = [BNCURLFilter new];
    for (NSString *string in self.goodURLs) {
        NSURL *URL = [NSURL URLWithString:string];
        XCTAssertFalse([filter shouldIgnoreURL:URL], @"Checking '%@'", URL);
    }
}

- (void) testDownloadGoodURLs {
    // Test download list.
    XCTestExpectation *expectation = [self expectationWithDescription:@"List Download"];
    BNCURLFilter *filter = [BNCURLFilter new];
    filter.jsonURL = [NSURL URLWithString:@"https://cdn.branch.io/sdk/uriskiplist_tv1.json"];
    [filter updatePatternListWithCompletion:^ (NSError*error, NSArray*list) {
        XCTAssertNil(error);
        XCTAssertTrue(list.count == 7);
        [expectation fulfill];
    }];
    [self awaitExpectations];
    for (NSString *string in self.goodURLs) {
        NSURL *URL = [NSURL URLWithString:string];
        XCTAssertFalse([filter shouldIgnoreURL:URL], @"Checking '%@'.", URL);
    }
}

- (void) testStandardList {
    BNCLogSetDisplayLevel(BNCLogLevelAll);
    Branch *branch = (Branch.branchKey.length) ? Branch.getInstance : [Branch getInstance:@"key_live_foo"];
    id serverInterfaceMock = OCMPartialMock(branch.serverInterface);
    XCTestExpectation *expectation = [self expectationWithDescription:@"OpenRequest Expectation"];

    OCMStub(
        [serverInterfaceMock postRequest:[OCMArg any]
            url:[OCMArg any]
            key:[OCMArg any]
            callback:[OCMArg any]]
    ).andDo(^(NSInvocation *invocation) {
        __unsafe_unretained NSDictionary *dictionary = nil;
        __unsafe_unretained NSString *url = nil;
        [invocation getArgument:&dictionary atIndex:2];
        [invocation getArgument:&url atIndex:3];

        NSLog(@"d: %@", dictionary);
        NSString* link = dictionary[@"external_intent_uri"];
        NSString *pattern1 = @"^(?i)((http|https):\\/\\/).*[\\/|?|#].*\\b(password|o?auth|o?auth.?token|access|access.?token)\\b";
        NSString *pattern2 = @"^(?i).+:.*[?].*\\b(password|o?auth|o?auth.?token|access|access.?token)\\b";
        NSLog(@"\n   Link: '%@'\nPattern1: '%@'\nPattern2: '%@'.", link, pattern1, pattern2);
        if ([link isEqualToString:pattern1] || [link isEqualToString:pattern2]) {
            [expectation fulfill];
        }
        else
        if ([url containsString:@"install"]) {
            [expectation fulfill];
        }
    });
    [branch clearNetworkQueue];
    [branch handleDeepLink:[NSURL URLWithString:@"https://myapp.app.link/bob/link?oauth=true"]];
    [self waitForExpectationsWithTimeout:5.0 handler:nil];
    [serverInterfaceMock stopMocking];
    [BNCPreferenceHelper sharedInstance].referringURL = nil;
    [[BNCPreferenceHelper sharedInstance] synchronize];
}

- (void) testUserList {
    BNCLogSetDisplayLevel(BNCLogLevelAll);
    Branch *branch = (Branch.branchKey.length) ? Branch.getInstance : [Branch getInstance:@"key_live_foo"];
    [branch clearNetworkQueue];
    branch.urlPatternsToIgnore = @[
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
        __unsafe_unretained NSString *URL = nil;
        [invocation getArgument:&dictionary atIndex:2];
        [invocation getArgument:&URL atIndex:3];

        NSString* link = dictionary[@"external_intent_uri"];
        NSString *pattern = @"\\/bob\\/";
        NSLog(@"\n    URL: '%@'\n   Link: '%@'\nPattern: '%@'\n.", URL, link, pattern);
        if ([link isEqualToString:pattern]) {
            [expectation fulfill];
        }
        else
        if ([URL containsString:@"install"]) {
            [expectation fulfill];
        }
    });
    [branch handleDeepLink:[NSURL URLWithString:@"https://myapp.app.link/bob/link"]];
    [self waitForExpectationsWithTimeout:5.0 handler:nil];
    [serverInterfaceMock stopMocking];
    [BNCPreferenceHelper sharedInstance].referringURL = nil;
    [[BNCPreferenceHelper sharedInstance] synchronize];
}

@end
