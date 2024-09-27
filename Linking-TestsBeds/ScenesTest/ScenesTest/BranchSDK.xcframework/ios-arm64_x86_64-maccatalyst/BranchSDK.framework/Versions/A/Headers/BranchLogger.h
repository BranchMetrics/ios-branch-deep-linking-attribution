//
//  BranchLogger.h
//  Branch
//
//  Created by Nipun Singh on 2/1/24.
//  Copyright © 2024 Branch, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef NS_ENUM(NSUInteger, BranchLogLevel) {
    BranchLogLevelVerbose, // development
    BranchLogLevelDebug,   // validation and troubleshooting
    BranchLogLevelWarning, // potential errors and attempts at recovery. SDK may be in a bad state.
    BranchLogLevelError,   // severe errors. SDK is probably in a bad state.
};

typedef void(^BranchLogCallback)(NSString * _Nonnull message, BranchLogLevel logLevel, NSError * _Nullable error);

NS_ASSUME_NONNULL_BEGIN

@interface BranchLogger : NSObject

@property (nonatomic, assign) BOOL loggingEnabled;
@property (nonatomic, assign) BOOL includeCallerDetails;
@property (nonatomic, copy, nullable) BranchLogCallback logCallback;
@property (nonatomic, assign) BranchLogLevel logLevelThreshold;

+ (instancetype _Nonnull)shared;

// For expensive Log messages, check if it's even worth building the log message
- (BOOL)shouldLog:(BranchLogLevel)level;

// Caller details are relatively expensive, option to disable if the cost is too high.
- (void)disableCallerDetails;

- (void)logError:(NSString * _Nonnull)message error:(NSError * _Nullable)error;
- (void)logWarning:(NSString * _Nonnull)message error:(NSError * _Nullable)error;
- (void)logDebug:(NSString * _Nonnull)message error:(NSError * _Nullable)error;
- (void)logVerbose:(NSString * _Nonnull)message error:(NSError * _Nullable)error;

// default Branch log format
+ (NSString *)formatMessage:(NSString *)message logLevel:(BranchLogLevel)logLevel error:(NSError *)error;

@end

NS_ASSUME_NONNULL_END
