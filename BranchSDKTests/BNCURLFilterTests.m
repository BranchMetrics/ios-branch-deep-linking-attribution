/**
 @file          BNCURLFilterTests.m
 @package       Branch-SDK-Tests
 @brief         BNCURLFilter  tests.

 @author        Edward Smith
 @date          February 14, 2018
 @copyright     Copyright © 2018 Branch. All rights reserved.
*/

#import <XCTest/XCTest.h>
#import "BNCURLFilter.h"

@interface BNCURLFilterTests : XCTestCase
@end

@implementation BNCURLFilterTests

- (void)setUp {
    // Put setup code here. This method is called before the invocation of each test method in the class.
}

- (void)tearDown {
    // Put teardown code here. This method is called after the invocation of each test method in the class.
}

- (void)testPatternMatchingURL_nil {
    BNCURLFilter *filter = [BNCURLFilter new];
    NSURL *url = nil;
    NSString *matchingRegex = [filter patternMatchingURL:url];
    XCTAssertNil(matchingRegex);
}

- (void)testPatternMatchingURL_emptyString {
    BNCURLFilter *filter = [BNCURLFilter new];
    NSURL *url = [NSURL URLWithString:@""];
    NSString *matchingRegex = [filter patternMatchingURL:url];
    XCTAssertNil(matchingRegex);
}

- (void)testPatternMatchingURL_fbRegexMatches {
    NSString *pattern = @"^fb\\d+:((?!campaign_ids).)*$";
    NSString *sampleURL = @"fb12345://";
    
    BNCURLFilter *filter = [BNCURLFilter new];
    NSURL *url = [NSURL URLWithString:sampleURL];
    NSString *matchingRegex = [filter patternMatchingURL:url];
    XCTAssertTrue([pattern isEqualToString:matchingRegex]);
}

- (void)testPatternMatchingURL_fbRegexDoesNotMatch {
    NSString *pattern = @"^fb\\d+:((?!campaign_ids).)*$";
    NSString *sampleURL = @"fb12345://campaign_ids";
    
    BNCURLFilter *filter = [BNCURLFilter new];
    NSURL *url = [NSURL URLWithString:sampleURL];
    NSString *matchingRegex = [filter patternMatchingURL:url];
    XCTAssertFalse([pattern isEqualToString:matchingRegex]);
}


- (void)testIgnoredSuspectedAuthURLs {
    NSArray *urls = @[
        @"fb123456:login/464646",
        @"shsh:oauth/login",
        @"https://myapp.app.link/oauth_token=fred",
        @"https://myapp.app.link/auth_token=fred",
        @"https://myapp.app.link/authtoken=fred",
        @"https://myapp.app.link/auth=fred",
        @"myscheme:path/to/resource?oauth=747474",
        @"myscheme:oauth=747474",
        @"myscheme:/oauth=747474",
        @"myscheme://oauth=747474",
        @"myscheme://path/oauth=747474",
        @"myscheme://path/:oauth=747474",
        @"https://google.com/userprofile/devonbanks=oauth?"
    ];
    
    BNCURLFilter *filter = [BNCURLFilter new];
    for (NSString *string in urls) {
        NSURL *URL = [NSURL URLWithString:string];
        XCTAssertTrue([filter shouldIgnoreURL:URL], @"Checking '%@'.", URL);
    }
}

- (void)testAllowedURLsSimilarToAuthURLs {
    NSArray *urls = @[
        @"shshs:/content/path",
        @"shshs:content/path",
        @"https://myapp.app.link/12345/link",
        @"https://myapp.app.link?authentic=true&tokemonsta=false",
        @"myscheme://path/brauth=747474"
    ];
    
    BNCURLFilter *filter = [BNCURLFilter new];
    for (NSString *string in urls) {
        NSURL *URL = [NSURL URLWithString:string];
        XCTAssertFalse([filter shouldIgnoreURL:URL], @"Checking '%@'", URL);
    }
}

- (void)testIgnoredFacebookURLs {
    // Most FB URIs are ignored
    NSArray *urls = @[
        @"fb123456://login/464646",
        @"fb1234:",
        @"fb1234:/",
        @"fb1234:/this-is-some-extra-info/?whatever",
        @"fb1234:/this-is-some-extra-info/?whatever:andstuff"
    ];
    
    BNCURLFilter *filter = [BNCURLFilter new];
    for (NSString *string in urls) {
        NSURL *URL = [NSURL URLWithString:string];
        XCTAssertTrue([filter shouldIgnoreURL:URL], @"Checking '%@'.", URL);
    }
}

- (void)testAllowedFacebookURLs {
    NSArray *urls = @[
        // Facebook URIs do not contain letters other than an fb prefix
        @"fb123x://",
        // FB URIs with campaign ids are allowed
        @"fb1234://helloworld?al_applink_data=%7B%22target_url%22%3A%22http%3A%5C%2F%5C%2Fitunes.apple.com%5C%2Fapp%5C%2Fid880047117%22%2C%22extras%22%3A%7B%22fb_app_id%22%3A2020399148181142%7D%2C%22referer_app_link%22%3A%7B%22url%22%3A%22fb%3A%5C%2F%5C%2F%5C%2F%3Fapp_id%3D2020399148181142%22%2C%22app_name%22%3A%22Facebook%22%7D%2C%22acs_token%22%3A%22debuggingtoken%22%2C%22campaign_ids%22%3A%22ARFUlbyOurYrHT2DsknR7VksCSgN4tiH8TzG8RIvVoUQoYog5bVCvADGJil5kFQC6tQm-fFJQH0w8wCi3NbOmEHHrtgCNglkXNY-bECEL0aUhj908hIxnBB0tchJCqwxHjorOUqyk2v4bTF75PyWvxOksZ6uTzBmr7wJq8XnOav0bA%22%2C%22test_deeplink%22%3A1%7D"
    ];
    
    BNCURLFilter *filter = [BNCURLFilter new];
    for (NSString *string in urls) {
        NSURL *URL = [NSURL URLWithString:string];
        XCTAssertFalse([filter shouldIgnoreURL:URL], @"Checking '%@'", URL);
    }
}

- (void)testCustomPatternList {
    BNCURLFilter *filter = [BNCURLFilter new];
    
    // sanity check default pattern list
    XCTAssertTrue([filter shouldIgnoreURL:[NSURL URLWithString:@"fb123://"]]);
    XCTAssertFalse([filter shouldIgnoreURL:[NSURL URLWithString:@"branch123://"]]);

    // confirm new pattern list is enforced
    [filter useCustomPatternList:@[@"^branch\\d+:"]];
    XCTAssertFalse([filter shouldIgnoreURL:[NSURL URLWithString:@"fb123://"]]);
    XCTAssertTrue([filter shouldIgnoreURL:[NSURL URLWithString:@"branch123://"]]);
}

// This is an end to end test and relies on a server call
- (void)testUpdatePatternListFromServer {
    BNCURLFilter *filter = [BNCURLFilter new];

    // confirm new pattern list is enforced
    [filter useCustomPatternList:@[@"^branch\\d+:"]];
    XCTAssertFalse([filter shouldIgnoreURL:[NSURL URLWithString:@"fb123://"]]);
    XCTAssertTrue([filter shouldIgnoreURL:[NSURL URLWithString:@"branch123://"]]);
    
    __block XCTestExpectation *expectation = [self expectationWithDescription:@"List updated"];
    [filter updatePatternListFromServerWithCompletion:^{
        [expectation fulfill];
    }];
    
    [self waitForExpectationsWithTimeout:5.0 handler:^(NSError * _Nullable error) { }];
    
    // the retrieved list should match default pattern list
    XCTAssertTrue([filter shouldIgnoreURL:[NSURL URLWithString:@"fb123://"]]);
    XCTAssertFalse([filter shouldIgnoreURL:[NSURL URLWithString:@"branch123://"]]);
}

@end
