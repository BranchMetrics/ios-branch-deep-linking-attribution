//
//  Branch_TestBedUITests.m
//  Branch-TestBedUITests
//
//  Created by Parth Kalavadia on 8/1/17.
//  Copyright © 2017 Branch Metrics. All rights reserved.
//

#import <XCTest/XCTest.h>
#define DEEPLINK_SLEEP 10
#define LOAD_WIKI_PAGE_SLEEP 3
#define LINK_TAG @"Universal Link TestBed Obj-c"
#define WIKI_PAGE_URL @"https://github.com/BranchMetrics/ios-branch-deep-linking/wiki/UITest-for-Testbed-App-for-Universal-links"

@interface XCUIApplication (Private)
- (id)initPrivateWithPath:(NSString *)path bundleID:(NSString *)bundleID;
- (void)resolve;
@end

@interface Branch_TestBedUITests : XCTestCase

@end

@implementation Branch_TestBedUITests

- (void)setUp {
    [super setUp];
    
    // Put setup code here. This method is called before the invocation of each test method in the class.
    
    // In UI tests it is usually best to stop immediately when a failure occurs.
    self.continueAfterFailure = NO;
    // UI tests must launch the application that they test. Doing this in setup will make sure it happens for each test method.
    [[[XCUIApplication alloc] init] launch];
    
    // In UI tests it’s important to set the initial state - such as interface orientation - required for your tests before they run. The setUp method is a good place to do this.
}

- (void)tearDown {
    // Put teardown code here. This method is called after the invocation of each test method in the class.
    [super tearDown];
}

//- (void)testExample {
//    // Use recording to get started writing UI tests.
//    // Use XCTAssert and related functions to verify your tests produce the correct results.
//}

-(void)testDeepLinking {
    [XCUIDevice sharedDevice].orientation = UIDeviceOrientationFaceUp;
    
    XCUIApplication *safariApp = [self openSafariWithUrl:WIKI_PAGE_URL];
    [self deepLinkForSafari:safariApp];
}

-(XCUIApplication *) openSafariWithUrl: (NSString*) url {
    XCUIApplication *app = [[XCUIApplication alloc] initPrivateWithPath:nil bundleID:@"com.apple.mobilesafari"];
    [app launch];
    
    [app.otherElements[@"URL"] tap];
    [app.textFields[@"Search or enter website name"] tap];
    [app typeText:url];
    [app.buttons[@"Go"] tap];
    sleep(LOAD_WIKI_PAGE_SLEEP);
    return app;
    
}

-(void) deepLinkForSafari:(XCUIApplication *) safariApp {
    NSLog(@"%@",safariApp.debugDescription);
    [safariApp.links[LINK_TAG] tap];
    
    sleep(DEEPLINK_SLEEP);
    
    XCUIApplication *currentApp = [[XCUIApplication alloc] init];
    XCUIElement* element = currentApp.textViews[@"DeepLinkData"];
    XCTAssertTrue([element.value containsString:@"Successfully Deeplinked"]);
}

@end
