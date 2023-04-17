//
//  BNCURLFilterSkiplistUpgradeTests.m
//  Branch-SDK-Tests
//
//  Created by Ernest Cho on 4/4/23.
//  Copyright © 2023 Branch, Inc. All rights reserved.
//

#import <XCTest/XCTest.h>
#import "BNCURLFilter.h"

@interface BNCURLFilter(Test)

// BNCURLFilter defines this as an ivar with a setter & getter, redefine it as a property
@property (nonatomic, strong, readwrite) NSArray<NSString *> *patternList;
@property (assign, nonatomic) NSInteger listVersion;
@end

@interface BNCURLFilterSkiplistUpgradeTests : XCTestCase

@end

@implementation BNCURLFilterSkiplistUpgradeTests

- (void)setUp {
    
}

- (void)tearDown {
    
}

 // v0 list
 // https://cdn.branch.io/sdk/uriskiplist_v0.json
- (NSArray <NSString *> *)v0PatternList {
    NSArray<NSString *> *patternList = @[
        @"^fb\\d+:",
        @"^li\\d+:",
        @"^pdk\\d+:",
        @"^twitterkit-.*:",
        @"^com\\.googleusercontent\\.apps\\.\\d+-.*:\\/oauth",
        @"^(?i)(?!(http|https):).*(:|:.*\\b)(password|o?auth|o?auth.?token|access|access.?token)\\b",
        @"^(?i)((http|https):\\/\\/).*[\\/|?|#].*\\b(password|o?auth|o?auth.?token|access|access.?token)\\b"
    ];
    return patternList;
}

// v1 list
// https://cdn.branch.io/sdk/uriskiplist_v1.json
- (NSArray <NSString *> *)v1PatternList {
   NSArray<NSString *> *patternList = @[
       @"^fb\\d+:",
       @"^li\\d+:",
       @"^pdk\\d+:",
       @"^twitterkit-.*:",
       @"^com\\.googleusercontent\\.apps\\.\\d+-.*:\\/oauth",
       @"^(?i)(?!(http|https):).*(:|:.*\\b)(password|o?auth|o?auth.?token|access|access.?token)\\b",
       @"^(?i)((http|https):\\/\\/).*[\\/|?|#].*\\b(password|o?auth|o?auth.?token|access|access.?token)\\b"
   ];
   return patternList;
}

// v2 list
// https://cdn.branch.io/sdk/uriskiplist_v2.json
- (NSArray <NSString *> *)v2PatternList {
    NSArray<NSString *> *patternList = @[
        @"^fb\\d+:((?!campaign_ids).)*$",
        @"^li\\d+:",
        @"^pdk\\d+:",
        @"^twitterkit-.*:",
        @"^com\\.googleusercontent\\.apps\\.\\d+-.*:\\/oauth",
        @"^(?i)(?!(http|https):).*(:|:.*\\b)(password|o?auth|o?auth.?token|access|access.?token)\\b",
        @"^(?i)((http|https):\\/\\/).*[\\/|?|#].*\\b(password|o?auth|o?auth.?token|access|access.?token)\\b"
    ];
    return patternList;
}

- (BNCURLFilter *)filterWithV0List {
    BNCURLFilter *filter = [BNCURLFilter new];
    [self migrateFilter:filter patternList:[self v1PatternList] version:1];
    return filter;
}

- (BNCURLFilter *)filterWithV1List {
    BNCURLFilter *filter = [BNCURLFilter new];
    [self migrateFilter:filter patternList:[self v1PatternList] version:1];
    return filter;
}

- (BNCURLFilter *)filterWithV2List {
    BNCURLFilter *filter = [BNCURLFilter new];
    [self migrateFilter:filter patternList:[self v2PatternList] version:2];
    return filter;
}

- (void)migrateFilter:(BNCURLFilter *)filter patternList:(NSArray<NSString *> *)patternList version:(NSInteger)version {
    // BNCURLFilter updates the global storage when these are set
    filter.patternList = patternList;
    filter.listVersion = version;
}

- (NSArray *)badURLs {
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

- (NSArray *)goodURLs {
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

- (void)testOldBadURLsWithV0 {
    BNCURLFilter *filter = [self filterWithV0List];
    NSArray *list = [self badURLs];
    for (NSString *string in list) {
        NSURL *url = [NSURL URLWithString:string];
        if (url) {
            XCTAssertTrue([filter shouldIgnoreURL:url], @"Checking '%@'.", url);
        }
    }
}

- (void)testOldGoodURLsWithV0 {
    BNCURLFilter *filter = [self filterWithV0List];
    NSArray *list = [self goodURLs];
    for (NSString *string in list) {
        NSURL *url = [NSURL URLWithString:string];
        if (url) {
            XCTAssertFalse([filter shouldIgnoreURL:url], @"Checking '%@'.", url);
        }
    }
}

- (void)testOldBadURLsWithV2 {
    BNCURLFilter *filter = [self filterWithV2List];
    NSArray *list = [self badURLs];
    for (NSString *string in list) {
        NSURL *url = [NSURL URLWithString:string];
        if (url) {
            XCTAssertTrue([filter shouldIgnoreURL:url], @"Checking '%@'.", url);
        }
    }
}

- (void)testOldGoodURLsWithV2 {
    BNCURLFilter *filter = [self filterWithV2List];
    NSArray *list = [self goodURLs];
    for (NSString *string in list) {
        NSURL *url = [NSURL URLWithString:string];
        if (url) {
            XCTAssertFalse([filter shouldIgnoreURL:url], @"Checking '%@'.", url);
        }
    }
}

- (void)testMetaAEMWithV0 {
    NSString *string = @"fb1://?campaign_ids=a";
    NSURL *url = [NSURL URLWithString:string];
    if (url) {
        BNCURLFilter *filter = [self filterWithV0List];
        XCTAssertTrue([filter shouldIgnoreURL:url]);
    }
}

- (void)testMetaAEMWithV2 {
    NSString *string = @"fb1://?campaign_ids=a";
    NSURL *url = [NSURL URLWithString:string];
    if (url) {
        BNCURLFilter *filter = [self filterWithV2List];
        XCTAssertFalse([filter shouldIgnoreURL:url]);
    }
}

- (void)testMetaAEMWithV2WithTrailingParameters {
    NSString *string = @"fb1://?campaign_ids=a&token=abcde";
    NSURL *url = [NSURL URLWithString:string];
    if (url) {
        BNCURLFilter *filter = [self filterWithV2List];
        XCTAssertFalse([filter shouldIgnoreURL:url]);
    }
}

- (void)testMetaAEMWithV2WithPrecedingParameters {
    NSString *string = @"fb1://?brand=abcde&campaign_ids=a";
    NSURL *url = [NSURL URLWithString:string];
    if (url) {
        BNCURLFilter *filter = [self filterWithV2List];
        XCTAssertFalse([filter shouldIgnoreURL:url]);
    }
}

- (void)testMetaAEMWithV2WithPrecedingAndTrailingParameters {
    NSString *string = @"fb1://?brand=abcde&campaign_ids=a&link=12345";
    NSURL *url = [NSURL URLWithString:string];
    if (url) {
        BNCURLFilter *filter = [self filterWithV2List];
        XCTAssertFalse([filter shouldIgnoreURL:url]);
    }
}

- (void)testSampleMetaAEMWithV0 {
    NSString *string = @"fb123456789://products/next?al_applink_data=%7B%22target_url%22%3A%22http%3A%5C%2F%5C%2Fitunes.apple.com%5C%2Fapp%5C%2Fid880047117%22%2C%22extras%22%3A%7B%22fb_app_id%22%3A2020399148181142%7D%2C%22referer_app_link%22%3A%7B%22url%22%3A%22fb%3A%5C%2F%5C%2F%5C%2F%3Fapp_id%3D2020399148181142%22%2C%22app_name%22%3A%22Facebook%22%7D%2C%22acs_token%22%3A%22debuggingtoken%22%2C%22campaign_ids%22%3A%22ARFUlbyOurYrHT2DsknR7VksCSgN4tiH8TzG8RIvVoUQoYog5bVCvADGJil5kFQC6tQm-fFJQH0w8wCi3NbOmEHHrtgCNglkXNY-bECEL0aUhj908hIxnBB0tchJCqwxHjorOUqyk2v4bTF75PyWvxOksZ6uTzBmr7wJq8XnOav0bA%22%2C%22test_deeplink%22%3A1%7D";
    NSURL *url = [NSURL URLWithString:string];
    if (url) {
        BNCURLFilter *filter = [self filterWithV0List];
        XCTAssertTrue([filter shouldIgnoreURL:url]);
    }
}

- (void)testSampleMetaAEMWithV1 {
    NSString *string = @"fb123456789://products/next?al_applink_data=%7B%22target_url%22%3A%22http%3A%5C%2F%5C%2Fitunes.apple.com%5C%2Fapp%5C%2Fid880047117%22%2C%22extras%22%3A%7B%22fb_app_id%22%3A2020399148181142%7D%2C%22referer_app_link%22%3A%7B%22url%22%3A%22fb%3A%5C%2F%5C%2F%5C%2F%3Fapp_id%3D2020399148181142%22%2C%22app_name%22%3A%22Facebook%22%7D%2C%22acs_token%22%3A%22debuggingtoken%22%2C%22campaign_ids%22%3A%22ARFUlbyOurYrHT2DsknR7VksCSgN4tiH8TzG8RIvVoUQoYog5bVCvADGJil5kFQC6tQm-fFJQH0w8wCi3NbOmEHHrtgCNglkXNY-bECEL0aUhj908hIxnBB0tchJCqwxHjorOUqyk2v4bTF75PyWvxOksZ6uTzBmr7wJq8XnOav0bA%22%2C%22test_deeplink%22%3A1%7D";
    NSURL *url = [NSURL URLWithString:string];
    if (url) {
        BNCURLFilter *filter = [self filterWithV1List];
        XCTAssertTrue([filter shouldIgnoreURL:url]);
    }
}

// This one is not filtered!
- (void)testSampleMetaAEMWithV2 {
    NSString *string = @"fb123456789://products/next?al_applink_data=%7B%22target_url%22%3A%22http%3A%5C%2F%5C%2Fitunes.apple.com%5C%2Fapp%5C%2Fid880047117%22%2C%22extras%22%3A%7B%22fb_app_id%22%3A2020399148181142%7D%2C%22referer_app_link%22%3A%7B%22url%22%3A%22fb%3A%5C%2F%5C%2F%5C%2F%3Fapp_id%3D2020399148181142%22%2C%22app_name%22%3A%22Facebook%22%7D%2C%22acs_token%22%3A%22debuggingtoken%22%2C%22campaign_ids%22%3A%22ARFUlbyOurYrHT2DsknR7VksCSgN4tiH8TzG8RIvVoUQoYog5bVCvADGJil5kFQC6tQm-fFJQH0w8wCi3NbOmEHHrtgCNglkXNY-bECEL0aUhj908hIxnBB0tchJCqwxHjorOUqyk2v4bTF75PyWvxOksZ6uTzBmr7wJq8XnOav0bA%22%2C%22test_deeplink%22%3A1%7D";
    NSURL *url = [NSURL URLWithString:string];
    if (url) {
        BNCURLFilter *filter = [self filterWithV2List];
        XCTAssertFalse([filter shouldIgnoreURL:url]);
    }
}

- (void)testSampleMetaAEMNoCampignIDsWithV0 {
    NSString *string = @"fb123456789://products/next?al_applink_data=%7B%22target_url%22%3A%22http%3A%5C%2F%5C%2Fitunes.apple.com%5C%2Fapp%5C%2Fid880047117%22%2C%22extras%22%3A%7B%22fb_app_id%22%3A2020399148181142%7D%2C%22referer_app_link%22%3A%7B%22url%22%3A%22fb%3A%5C%2F%5C%2F%5C%2F%3Fapp_id%3D2020399148181142%22%2C%22app_name%22%3A%22Facebook%22%7D%2C%22acs_token%22%3A%22debuggingtoken%22%2C%22test_deeplink%22%3A1%7D";
    NSURL *url = [NSURL URLWithString:string];
    if (url) {
        BNCURLFilter *filter = [self filterWithV0List];
        XCTAssertTrue([filter shouldIgnoreURL:url]);
    }
}

- (void)testSampleMetaAEMNoCampignIDsWithV1 {
    NSString *string = @"fb123456789://products/next?al_applink_data=%7B%22target_url%22%3A%22http%3A%5C%2F%5C%2Fitunes.apple.com%5C%2Fapp%5C%2Fid880047117%22%2C%22extras%22%3A%7B%22fb_app_id%22%3A2020399148181142%7D%2C%22referer_app_link%22%3A%7B%22url%22%3A%22fb%3A%5C%2F%5C%2F%5C%2F%3Fapp_id%3D2020399148181142%22%2C%22app_name%22%3A%22Facebook%22%7D%2C%22acs_token%22%3A%22debuggingtoken%22%2C%22test_deeplink%22%3A1%7D";
    NSURL *url = [NSURL URLWithString:string];
    if (url) {
        BNCURLFilter *filter = [self filterWithV1List];
        XCTAssertTrue([filter shouldIgnoreURL:url]);
    }
}

- (void)testSampleMetaAEMNoCampignIDsWithV2 {
    NSString *string = @"fb123456789://products/next?al_applink_data=%7B%22target_url%22%3A%22http%3A%5C%2F%5C%2Fitunes.apple.com%5C%2Fapp%5C%2Fid880047117%22%2C%22extras%22%3A%7B%22fb_app_id%22%3A2020399148181142%7D%2C%22referer_app_link%22%3A%7B%22url%22%3A%22fb%3A%5C%2F%5C%2F%5C%2F%3Fapp_id%3D2020399148181142%22%2C%22app_name%22%3A%22Facebook%22%7D%2C%22acs_token%22%3A%22debuggingtoken%22%2C%22test_deeplink%22%3A1%7D";
    NSURL *url = [NSURL URLWithString:string];
    if (url) {
        BNCURLFilter *filter = [self filterWithV2List];
        XCTAssertTrue([filter shouldIgnoreURL:url]);
    }
}

@end
