//
//  Branch_TestBed_Tests.m
//  Branch-TestBed Tests
//
//  Created by Qinwei Gong on 2/24/15.
//  Copyright (c) 2015 Branch Metrics. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <XCTest/XCTest.h>
#import "BNCSystemObserver.h"

@interface Branch_TestBed_Tests : XCTestCase

@end

@implementation Branch_TestBed_Tests

- (void)setUp {
    [super setUp];
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

@end
