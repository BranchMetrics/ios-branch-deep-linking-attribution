//
//  BranchLogger.h
//  Branch
//
//  Created by Nipun Singh on 2/1/24.
//  Copyright © 2024 Branch, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef NS_ENUM(NSUInteger, BranchLogLevel) {
    BranchLogLevelVerbose,
    BranchLogLevelDebug,
    BranchLogLevelInfo,
    BranchLogLevelWarning,
    BranchLogLevelError,
};

typedef void(^BranchLogCallback)(NSString * _Nonnull message, BranchLogLevel logLevel, NSError * _Nullable error);

NS_ASSUME_NONNULL_BEGIN

@interface BranchLogger : NSObject

@property (nonatomic, assign) BOOL loggingEnabled;
@property (nonatomic, assign) BOOL includeCallerDetails;
@property (nonatomic, copy, nullable) BranchLogCallback logCallback;
@property (nonatomic, assign) BranchLogLevel logLevelThreshold;

+ (instancetype _Nonnull)shared;

- (void)disableCallerDetails;

- (void)logError:(NSString * _Nonnull)message error:(NSError * _Nullable)error;
- (void)logWarning:(NSString * _Nonnull)message;
- (void)logInfo:(NSString * _Nonnull)message;
- (void)logDebug:(NSString * _Nonnull)message;
- (void)logVerbose:(NSString * _Nonnull)message;

@end

NS_ASSUME_NONNULL_END
