//
//  BNCSwiftLog.h
//  WebViewExample
//
//  Created by Jimmy Dee on 4/7/17.
//  Copyright © 2017 Branch Metrics. All rights reserved.
//

@import Foundation;

/**
 * Swift-friendly Obj-C wrapper for BNCLogMessageInternal
 */
@interface BNCSwiftLog : NSObject

/**
 * Logs a message at BNCLogLevelDebug
 * @param message the message to log
 * @param file path to the source file from which this method was called in Swift
 * @param line line number from which this method was called in Swift
 */
+ (void)debug:(NSString * _Nonnull)message file:(NSString * _Nonnull)file line:(NSUInteger)line;

/**
 * Logs a message at BNCLogLevelError
 * @param message the message to log
 * @param file path to the source file from which this method was called in Swift
 * @param line line number from which this method was called in Swift
 */
+ (void)error:(NSString * _Nonnull)message file:(NSString * _Nonnull)file line:(NSUInteger)line;

/**
 * Logs a message at BNCLogLevelLog
 * @param message the message to log
 * @param file path to the source file from which this method was called in Swift
 * @param line line number from which this method was called in Swift
 */
+ (void)log:(NSString * _Nonnull)message file:(NSString * _Nonnull)file line:(NSUInteger)line;

/**
 * Logs a message at BNCLogLevelWarning
 * @param message the message to log
 * @param file path to the source file from which this method was called in Swift
 * @param line line number from which this method was called in Swift
 */
+ (void)warning:(NSString * _Nonnull)message file:(NSString * _Nonnull)file line:(NSUInteger)line;

@end
