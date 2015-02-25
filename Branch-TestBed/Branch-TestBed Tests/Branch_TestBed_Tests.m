//
//  Branch_TestBed_Tests.m
//  Branch-TestBed Tests
//
//  Created by Qinwei Gong on 2/24/15.
//  Copyright (c) 2015 Branch Metrics. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <XCTest/XCTest.h>
#import "Branch.h"
#import "BNCSystemObserver.h"
#import "BNCPreferenceHelper.h"
#import "ViewController.h"

@interface Branch_TestBed_Tests : XCTestCase {
    ViewController *mainVC;
    Branch *branch;
}

@end

@implementation Branch_TestBed_Tests

- (void)setUp {
    [super setUp];
    
    UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"Main" bundle:nil];
    mainVC = [storyboard instantiateViewControllerWithIdentifier:@"MainVC"];
    [UIApplication sharedApplication].keyWindow.rootViewController = mainVC;

    branch = [Branch getInstance];
}

- (void)tearDown {
    [super tearDown];
}

- (void)testDebuggerGestureRecognizer {
    int hasLongPress = NO;
    for (UIGestureRecognizer *gestureRecognizer in [UIApplication sharedApplication].keyWindow.gestureRecognizers) {
        if ([gestureRecognizer isMemberOfClass:[UILongPressGestureRecognizer class]]) {
            UILongPressGestureRecognizer *longPress = (UILongPressGestureRecognizer *)gestureRecognizer;
            if (longPress.minimumPressDuration == 3) {
                if ([BNCSystemObserver isSimulator]) {
                    hasLongPress = YES;
                } else {
                    hasLongPress = YES;
                }
            }
        }
    }
    
    XCTAssertTrue(hasLongPress);
}

- (void)testButton {
    XCTAssertNotNil(mainVC.refreshUrlButton);

    [mainVC.refreshUrlButton sendActionsForControlEvents:UIControlEventTouchUpInside];

    XCTestExpectation *getShortURLExpectation = [self expectationWithDescription:@"Test getShortURL"];
    
    NSDictionary*params = [[NSDictionary alloc] initWithObjects:@[@"test_object", @"here is another object!!", @"Kindred", @"https://s3-us-west-1.amazonaws.com/branchhost/mosaic_og.png"] forKeys:@[@"key1", @"key2", @"$og_title", @"$og_image_url"]];
    
    [branch initSession];
    
    [branch getShortURLWithParams:params andTags:@[@"tag1", @"tag2"] andChannel:@"facebook" andFeature:@"invite" andStage:@"2" andCallback:^(NSString *url, NSError *err) {
        XCTAssertNil(err);
        XCTAssertNotNil(url);

        mainVC.editRefShortUrl.text = url;  // how to do it with this line commented?
        XCTAssertTrue([mainVC.editRefShortUrl.text hasPrefix:@"https://bnc.lt/l/"]);
        
        [getShortURLExpectation fulfill];
    }];
    
    [self waitForExpectationsWithTimeout:1 handler:^(NSError *error) {
    }];
}

@end
