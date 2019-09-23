//
//  BranchCrossPlatformIDTests.m
//  Branch-SDK-Tests
//
//  Created by Ernest Cho on 9/16/19.
//  Copyright © 2019 Branch, Inc. All rights reserved.
//

#import <XCTest/XCTest.h>
#import "BranchCrossPlatformID.h"
#import "BNCJsonLoader.h"

@interface BranchCrossPlatformIDTests : XCTestCase

@end

@implementation BranchCrossPlatformIDTests

- (void)setUp {
    // Put setup code here. This method is called before the invocation of each test method in the class.
}

- (void)tearDown {
    // Put teardown code here. This method is called after the invocation of each test method in the class.
}

- (void)testBuildFromJSON {
    NSDictionary *json = [BNCJsonLoader dictionaryFromJSONFileNamed:@"cpid"];
    XCTAssertNotNil(json);
    
    BranchCrossPlatformID *cpid = [BranchCrossPlatformID buildFromJSON:json];
    XCTAssertNotNil(cpid);
    XCTAssertNotNil(cpid.developerID);
    XCTAssertNotNil(cpid.crossPlatformID);
    XCTAssertNotNil(cpid.pastCrossPlatformIDs);
    XCTAssertNotNil(cpid.probabiliticCrossPlatformIDs);
}

- (void)testBuildFromJSON_EmptyId {
    NSDictionary *json = [BNCJsonLoader dictionaryFromJSONFileNamed:@"cpid_empty_id"];
    XCTAssertNotNil(json);
    
    BranchCrossPlatformID *cpid = [BranchCrossPlatformID buildFromJSON:json];
    XCTAssertNotNil(cpid);
    XCTAssertTrue([@"" isEqualToString:cpid.crossPlatformID]);
}

- (void)testBuildFromJSON_EmptyPast {
    NSDictionary *json = [BNCJsonLoader dictionaryFromJSONFileNamed:@"cpid_empty_past"];
    XCTAssertNotNil(json);
    
    BranchCrossPlatformID *cpid = [BranchCrossPlatformID buildFromJSON:json];
    XCTAssertNotNil(cpid);
    XCTAssertTrue(cpid.pastCrossPlatformIDs.count == 0);
}

- (void)testBuildFromJSON_EmptyProb {
    NSDictionary *json = [BNCJsonLoader dictionaryFromJSONFileNamed:@"cpid_empty_prob"];
    XCTAssertNotNil(json);
    
    BranchCrossPlatformID *cpid = [BranchCrossPlatformID buildFromJSON:json];
    XCTAssertNotNil(cpid);
    XCTAssertTrue(cpid.probabiliticCrossPlatformIDs.count == 0);
}

- (void)testBuildFromJSON_EmptyDevId {
    NSDictionary *json = [BNCJsonLoader dictionaryFromJSONFileNamed:@"cpid_empty_dev_id"];
    XCTAssertNotNil(json);
    
    BranchCrossPlatformID *cpid = [BranchCrossPlatformID buildFromJSON:json];
    XCTAssertNotNil(cpid);
    XCTAssertTrue([@"" isEqualToString:cpid.developerID]);
}

- (void)testBuildFromJSON_MissingId {
    NSDictionary *json = [BNCJsonLoader dictionaryFromJSONFileNamed:@"cpid_missing_id"];
    XCTAssertNotNil(json);
    
    BranchCrossPlatformID *cpid = [BranchCrossPlatformID buildFromJSON:json];
    XCTAssertNil(cpid);
}

- (void)testBuildFromJSON_MissingPast {
    NSDictionary *json = [BNCJsonLoader dictionaryFromJSONFileNamed:@"cpid_missing_past"];
    XCTAssertNotNil(json);
    
    BranchCrossPlatformID *cpid = [BranchCrossPlatformID buildFromJSON:json];
    XCTAssertNil(cpid);
}

- (void)testBuildFromJSON_MissingProb {
    NSDictionary *json = [BNCJsonLoader dictionaryFromJSONFileNamed:@"cpid_missing_prob"];
    XCTAssertNotNil(json);
    
    BranchCrossPlatformID *cpid = [BranchCrossPlatformID buildFromJSON:json];
    XCTAssertNil(cpid);
}

- (void)testBuildFromJSON_MissingDevId {
    NSDictionary *json = [BNCJsonLoader dictionaryFromJSONFileNamed:@"cpid_missing_dev_id"];
    XCTAssertNotNil(json);
    
    BranchCrossPlatformID *cpid = [BranchCrossPlatformID buildFromJSON:json];
    XCTAssertNotNil(cpid);
    XCTAssertNil(cpid.developerID);
}

@end
