//
//  BranchLastAttributedTouchDataTests.m
//  Branch-SDK-Tests
//
//  Created by Ernest Cho on 9/18/19.
//  Copyright © 2019 Branch, Inc. All rights reserved.
//

#import <XCTest/XCTest.h>
#import "BNCJsonLoader.h"
#import "BranchLastAttributedTouchData.h"

@interface BranchLastAttributedTouchDataTests : XCTestCase

@end

@implementation BranchLastAttributedTouchDataTests

- (void)setUp {
    // Put setup code here. This method is called before the invocation of each test method in the class.
}

- (void)tearDown {
    // Put teardown code here. This method is called after the invocation of each test method in the class.
}

- (void)testBuildFromJSON {
    NSDictionary *json = [BNCJsonLoader dictionaryFromJSONFileNamed:@"latd"];
    XCTAssertNotNil(json);
    
    BranchLastAttributedTouchData *latd = [BranchLastAttributedTouchData buildFromJSON:json];
    XCTAssertNotNil(latd);
    XCTAssertNotNil(latd.lastAttributedTouchJSON);
    XCTAssertNotNil(latd.attributionWindow);
}

- (void)testBuildFromJSON_EmptyData {
    NSDictionary *json = [BNCJsonLoader dictionaryFromJSONFileNamed:@"latd_empty_data"];
    XCTAssertNotNil(json);
    
    BranchLastAttributedTouchData *latd = [BranchLastAttributedTouchData buildFromJSON:json];
    XCTAssertNotNil(latd);
    XCTAssertTrue(latd.lastAttributedTouchJSON.count == 0);
}

- (void)testBuildFromJSON_MissingData {
    NSDictionary *json = [BNCJsonLoader dictionaryFromJSONFileNamed:@"latd_missing_data"];
    XCTAssertNotNil(json);
    
    BranchLastAttributedTouchData *latd = [BranchLastAttributedTouchData buildFromJSON:json];
    XCTAssertNil(latd);
}

- (void)testBuildFromJSON_MissingWindow {
    NSDictionary *json = [BNCJsonLoader dictionaryFromJSONFileNamed:@"latd_missing_window"];
    XCTAssertNotNil(json);
    
    BranchLastAttributedTouchData *latd = [BranchLastAttributedTouchData buildFromJSON:json];
    XCTAssertNotNil(latd);
    XCTAssertNil(latd.attributionWindow);
}

@end
