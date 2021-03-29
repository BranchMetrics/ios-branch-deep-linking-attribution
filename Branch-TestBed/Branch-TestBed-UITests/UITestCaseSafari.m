//
//  UITestCaseSafari.m
//  Branch-TestBed-UITests
//
//  Created by Nidhi on 3/25/21.
//  Copyright © 2021 Branch, Inc. All rights reserved.
//

#import "UITestCaseTestBed.h"

@interface UITestCaseSafari : UITestCaseTestBed

@end

@implementation UITestCaseSafari

- (void)setUp {
    self.continueAfterFailure = NO;
    [super setUp];
    //[[[XCUIApplication alloc] init] launch];
}

- (void)tearDown {
}

- (void)testOpenURL {
    //[self OpenLinkInWebPage:@"TestWebPage.html"];
}

- (void)testOpenURLInNewWindow {
    
}

- (void)testClickURL {
    
}


@end
