//
//  TestDeepLinkingUITestsWithHostApp.m
//  TestDeepLinkingUITestsWithHostApp
//
//  Created by Nidhi on 3/21/21.
//

#import <XCTest/XCTest.h>

@interface TestDeepLinkingUITestsWithHostApp : XCTestCase

@end

@implementation TestDeepLinkingUITestsWithHostApp

- (void)setUp {
      self.continueAfterFailure = YES;
}

- (void)tearDown {
}

- (void)test1OpenApp {
    XCUIApplication *app = [[XCUIApplication alloc] init];
    [app launch];

    sleep(3);
    if ([ app waitForExistenceWithTimeout:15] != NO) {
        NSString *deepLinkData = app.textViews[@"tvID"].value;
        NSLog(@"==== %@" , deepLinkData);
        XCTAssertTrue([deepLinkData containsString:@"https:\\/\\/mnl7s.app.link\\/CwOJ5aTaNeb"]);
   } else {
       XCTFail("Application not launched");
   }
}


@end
