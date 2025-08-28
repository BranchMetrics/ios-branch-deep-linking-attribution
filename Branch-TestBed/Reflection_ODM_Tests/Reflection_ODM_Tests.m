//
//  Reflection_ODM_Tests.m
//  Reflection_ODM_Tests
//
//  Created by Nidhi Dixit on 4/16/25.
//  Copyright © 2025 Branch, Inc. All rights reserved.
//

#import <XCTest/XCTest.h>
#import "BNCODMInfoCollector.h"
#import "NSError+Branch.h"
#import "BNCPreferenceHelper.h"
#import "BranchSDK.h"

@interface Reflection_ODM_Tests : XCTestCase

@end

@implementation Reflection_ODM_Tests


+ (void)load {
   
   
            // Find the Caches directory, a reliable place to write temporary files.
            NSArray *cachePaths = NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES);
            NSString *cacheDir = [cachePaths firstObject];
            NSString *logFilePath = [cacheDir stringByAppendingPathComponent:@"branch_sdk_test_logs.log"];

            // Clear any old log file before starting.
            [[NSFileManager defaultManager] removeItemAtPath:logFilePath error:nil];

            // This log will now appear in your main xcodebuild output.
            // It helps confirm that this code is running and shows the exact path.
            NSLog(@"[BRANCH SDK TEST LOGGING] Writing logs to: %@", logFilePath);

            NSFileHandle *fileHandle = [NSFileHandle fileHandleForWritingAtPath:logFilePath];
            if (!fileHandle) {
                [[NSData data] writeToFile:logFilePath atomically:YES];
                fileHandle = [NSFileHandle fileHandleForWritingAtPath:logFilePath];
            }

            [Branch enableLoggingAtLevel:BranchLogLevelVerbose withCallback:^(NSString * _Nonnull message, BranchLogLevel logLevel, NSError * _Nullable error) {
                @synchronized (fileHandle) {
                    NSString *logLine = [NSString stringWithFormat:@"%@: %@\n", [NSDate date], message];
                    [fileHandle seekToEndOfFile];
                    [fileHandle writeData:[logLine dataUsingEncoding:NSUTF8StringEncoding]];
                }
            }];
    
}
- (void) testODMAPIsLoaded {
    
   // [Reflection_ODM_Tests load];
    
    XCTestExpectation *expectation = [self expectationWithDescription:@"Network call"];
    
    [[BNCODMInfoCollector instance] fetchODMInfoFromDeviceWithInitDate:[NSDate date] andCompletion:^(NSString * _Nullable odmInfo, NSError * _Nullable error) {
        if ( !error) {
            [expectation fulfill];
        } else {
            if ((error.code != BNCClassNotFoundError) && (error.code != BNCMethodNotFoundError)) {
                [expectation fulfill];
            } else {
                XCTFail(@"Unexpected ODM error: %@", error.localizedDescription);
                [expectation fulfill];
            }
        }
    }];
    
    [self waitForExpectationsWithTimeout:15 handler:nil];
    
}


- (void) testODMAPICall {

    [Reflection_ODM_Tests load];
    
    XCTestExpectation *expectation = [self expectationWithDescription:@"Network call"];
    [BNCPreferenceHelper sharedInstance].odmInfo = nil;
    [[BNCODMInfoCollector instance ] loadODMInfoWithCompletionHandler:^(NSString * _Nullable odmInfo, NSError * _Nullable error) {
            if (!error){
                if (odmInfo) {
                    XCTAssertTrue([odmInfo isEqualToString:[BNCPreferenceHelper sharedInstance].odmInfo]);
                    XCTAssertTrue([BNCPreferenceHelper sharedInstance].odmInfoInitDate != nil);
                }
                XCTAssertTrue((error == nil), "%s", [[error description] UTF8String]);
                [expectation fulfill];
            } else {
                XCTFail(@"Unexpected ODM error: %@", error.localizedDescription);
                [expectation fulfill];
            }
    }];
    [self waitForExpectationsWithTimeout:15 handler:nil];
}

@end
