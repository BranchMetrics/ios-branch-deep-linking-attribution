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
   
        NSString *logFileName = @"branch_sdk_test_logs.log";
        
        // Create a predictable path for the log file relative to the project root.
        NSString *projectDir = [NSProcessInfo processInfo].environment[@"SRCROOT"];
        if (!projectDir) {
            // Fallback for when SRCROOT is not set (e.g., direct xcodebuild)
            // This assumes the working directory is the project root.
            projectDir = [NSFileManager defaultManager].currentDirectoryPath;
        }
        
        NSString *buildDir = [projectDir stringByAppendingPathComponent:@"build"];
        [[NSFileManager defaultManager] createDirectoryAtPath:buildDir withIntermediateDirectories:YES attributes:nil error:nil];
        
        NSString *logFilePath = [buildDir stringByAppendingPathComponent:logFileName];
        
        // Clear any old log file before starting.
        [[NSFileManager defaultManager] removeItemAtPath:logFilePath error:nil];
        
        NSLog(@"BranchSDK test logs will be written to: %@", logFilePath);
        
        // Create a file handle that can be written to from multiple threads.
        NSFileHandle *fileHandle = [NSFileHandle fileHandleForWritingAtPath:logFilePath];
        if (!fileHandle) {
            [[NSData data] writeToFile:logFilePath atomically:YES];
            fileHandle = [NSFileHandle fileHandleForWritingAtPath:logFilePath];
        }

        // Enable logging and set our custom callback.
        [Branch enableLoggingAtLevel:BranchLogLevelVerbose withCallback:^(NSString * _Nonnull message, BranchLogLevel logLevel, NSError * _Nullable error) {
            // The callback can be called from any thread, so synchronize access to the file handle.
            @synchronized (fileHandle) {
                NSString *logLine = [NSString stringWithFormat:@"%@: %@\n", [NSDate date], message];
                [fileHandle seekToEndOfFile];
                [fileHandle writeData:[logLine dataUsingEncoding:NSUTF8StringEncoding]];
            }
        }];
    
}
- (void) testODMAPIsLoaded {
    
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
