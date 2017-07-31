//
//  Branch_TestBedUITests.m
//  Branch-TestBedUITests
//
//  Created by Parth Kalavadia on 7/28/17.
//  Copyright © 2017 Branch Metrics. All rights reserved.
//

#import <XCTest/XCTest.h>

@interface Branch_TestBedUITests : XCTestCase

@end

@interface XCUIApplication (Private)
- (id)initPrivateWithPath:(NSString *)path bundleID:(NSString *)bundleID;
- (void)resolve;
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

- (void)testExample {
    // Use recording to get started writing UI tests.
    // Use XCTAssert and related functions to verify your tests produce the correct results.
    
}

-(void)testDeepLinking {
    [XCUIDevice sharedDevice].orientation = UIDeviceOrientationFaceUp;
    
    XCUIApplication *currentApp = [[XCUIApplication alloc] init];
   
    //    XCUIApplication *safariApp = [self openSafariWithUrl:@"parthkalavadia.github.io/branch-web"];
//    [self deepLinkForSafari:safariApp];
    
    
}

-(XCUIApplication *) openSafariWithUrl: (NSString*) url {
    XCUIApplication *app = [[XCUIApplication alloc] initPrivateWithPath:nil bundleID:@"com.apple.mobilesafari"];
    [app launch];
        
    [app.otherElements[@"URL"] tap];
    [app.textFields[@"Search or enter website name"] tap];
    [app typeText:url];
    [app.buttons[@"Go"] tap];
    sleep(3);
    XCUIApplication *currentApp = [[XCUIApplication alloc] init];

    return app;

}

-(void) deepLinkForSafari:(XCUIApplication *) safariApp {
    NSLog(@"%@",safariApp.debugDescription);
    [safariApp.links[@"Universal Link TestBed Obj-c"] tap];
    
 //   NSLog(@"%@",);
}

@end
