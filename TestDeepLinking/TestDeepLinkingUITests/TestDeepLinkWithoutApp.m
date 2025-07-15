//
//  TestDeepLinkWithoutApp.m
//  TestDeepLinking
//
//  Created by Nidhi on 3/21/21.
//

#import <XCTest/XCTest.h>

@interface TestDeepLinkWithoutApp : XCTestCase

@end

@implementation TestDeepLinkWithoutApp

- (void)setUp {
    self.continueAfterFailure = YES;
    [self addUIInterruptionMonitorWithDescription:@"Open App" handler:^BOOL(XCUIElement * _Nonnull interruptingElement) {
        [interruptingElement description];
        XCUIElement *button = interruptingElement.buttons[@"Open"];
        if ([button exists]) {
            [button tap];
            return YES;
        }
        return NO;
    }];

}

- (void)tearDown {
    // Put teardown code here. This method is called after the invocation of each test method in the class.
}

- (void)test0OpenLinkWithoutApp {
    
    XCUIApplication *safariApp = [[XCUIApplication alloc] initWithBundleIdentifier:@"com.apple.mobilesafari"];
    //[safariApp setLaunchArguments: @[@"-u",@"https://ndixit-branch.github.io/TestWebPage.html"]];
    [safariApp launch];

    sleep(1.0);
    [safariApp.buttons[@"URL"] tap];
    //[safariApp.otherElements[@"URL"] tap];
    [safariApp.textFields[@"Search or enter website name"] tap];
    [safariApp typeText:@"https://mnl7s.app.link/CwOJ5aTaNeb"];
    [safariApp.buttons[@"Go"] tap];
    XCUIElement *testBedLink = [[safariApp.webViews descendantsMatchingType:XCUIElementTypeLink] elementBoundByIndex:0];
    
    [testBedLink tap];
    
    sleep(10);
    [safariApp terminate];
    
//    XCUIApplication *app = [[XCUIApplication alloc] initWithBundleIdentifier:@"io.branch.TestiOSDeepLink"];
//    
//    if ([ app waitForExistenceWithTimeout:5] != NO) {
//        NSString *deepLinkData = app.textViews[@"DeepLinkData"].value;
//        XCTAssertTrue([deepLinkData containsString:self.deeplinkDataToCheck]);
//   } else {
//       XCTFail("Application not launched");
//   }
//    
}

@end
