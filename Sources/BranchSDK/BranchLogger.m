//
//  BranchLogger.m
//  Branch
//
//  Created by Nipun Singh on 2/1/24.
//  Copyright © 2024 Branch, Inc. All rights reserved.
//

#import "BranchLogger.h"
#if !TARGET_OS_TV
#import "BranchFileLogger.h"
#endif
#import <os/log.h>

@implementation BranchLogger

- (instancetype)init {
    if ((self = [super init])) {
        _loggingEnabled = NO;
        _logLevelThreshold = BranchLogLevelDebug;
        _includeCallerDetails = YES;
        
        // default callback sends logs to os_log
        _logCallback = ^(NSString * _Nonnull message, BranchLogLevel logLevel, NSError * _Nullable error) {
            NSString *formattedMessage = [BranchLogger formatMessage:message logLevel:logLevel error:error];
            
            os_log_t log = os_log_create("io.branch.sdk", "BranchSDK");
            os_log_type_t osLogType = [BranchLogger osLogTypeForBranchLogLevel:logLevel];
            os_log_with_type(log, osLogType, "%{private}@", formattedMessage);
        };
    }
    return self;
}

+ (instancetype)shared {
    static BranchLogger *sharedInstance = nil;
    static dispatch_once_t onceToken = 0;
    dispatch_once(&onceToken, ^{
        sharedInstance = [[BranchLogger alloc] init];
        sharedInstance.loggingEnabled = NO;
        sharedInstance.logLevelThreshold = BranchLogLevelDebug;
        sharedInstance.includeCallerDetails = YES;
    });
    return sharedInstance;
}

- (BOOL)shouldLog:(BranchLogLevel)level {
    if (!self.loggingEnabled || level < self.logLevelThreshold) {
        return NO;
    }
    return YES;
}

- (void)disableCallerDetails {
    self.includeCallerDetails = NO;
}

- (void)logError:(NSString *)message error:(NSError *_Nullable)error {
    [self logMessage:message withLevel:BranchLogLevelError error:error request:nil response:nil];
}

- (void)logWarning:(NSString *)message error:(NSError *_Nullable)error {
    [self logMessage:message withLevel:BranchLogLevelWarning error:error request:nil response:nil];
}

- (void)logDebug:(NSString * _Nonnull)message error:(NSError * _Nullable)error {
    [self logDebug:message error:error request:nil response:nil];
}

- (void)logDebug:(NSString * _Nonnull)message
           error:(NSError * _Nullable)error
         request:(NSMutableURLRequest * _Nullable)request
        response:(BNCServerResponse * _Nullable)response {
    [self logMessage:message withLevel:BranchLogLevelDebug error:error request:request response:response];
}

- (void)logVerbose:(NSString *)message error:(NSError *_Nullable)error {
    [self logMessage:message withLevel:BranchLogLevelVerbose error:error request:nil response:nil];
}

- (void)logMessage:(NSString *)message withLevel:(BranchLogLevel)level error:(NSError *_Nullable)error request:(NSMutableURLRequest * _Nullable)request response:(BNCServerResponse * _Nullable)response {
    if (!self.loggingEnabled || level < self.logLevelThreshold || message.length == 0) {
        return;
    }
    
    NSString *formattedMessage = message;
    if (self.includeCallerDetails) {
        formattedMessage = [NSString stringWithFormat:@"%@ %@", [self callingClass], message];
    }
    
    if  (self.advancedLogCallback) {
        self.advancedLogCallback(formattedMessage, level, error, request, response);
    } else if (self.logCallback) {
        self.logCallback(formattedMessage, level, error);
    }
    #if !TARGET_OS_TV
    #ifdef DEBUG
    [[BranchFileLogger sharedInstance] logMessage:formattedMessage];
    #endif
    #endif
}

- (NSString *)callingClass {
    NSArray<NSString *> *stackSymbols = [NSThread callStackSymbols];
    NSRegularExpression *regex = [NSRegularExpression regularExpressionWithPattern:@"\\[([^\\]]+)\\]" options:0 error:nil];
    if (stackSymbols.count > 3 && regex) {
        NSString *callSite = stackSymbols[3];
        NSTextCheckingResult *match = [regex firstMatchInString:callSite options:0 range:NSMakeRange(0, [callSite length])];
        if (match && match.range.location != NSNotFound) {
            NSString *callerDetails = [callSite substringWithRange:[match rangeAtIndex:0]];
            return callerDetails;
        }
    }
    return @"";
}

+ (NSString *)formatMessage:(NSString *)message logLevel:(BranchLogLevel)logLevel error:(NSError *)error {
    NSString *logLevelString = [BranchLogger stringForLogLevel:logLevel];
    NSString *logTag = [NSString stringWithFormat:@"[BranchSDK][%@]", logLevelString];
    NSMutableString *fullMessage = [NSMutableString stringWithFormat:@"%@%@", logTag, message];
    if (error) {
        [fullMessage appendFormat:@" NSError: %@", error];
    }
    return fullMessage;
}

+ (NSString *)stringForLogLevel:(BranchLogLevel)level {
    switch (level) {
        case BranchLogLevelVerbose: return @"Verbose";
        case BranchLogLevelDebug: return @"Debug";
        case BranchLogLevelWarning: return @"Warning";
        case BranchLogLevelError: return @"Error";
        default: return @"Unknown";
    }
}

// Map the Branch log level to a similar Apple log level
+ (os_log_type_t)osLogTypeForBranchLogLevel:(BranchLogLevel)level {
    switch (level) {
        case BranchLogLevelError: return OS_LOG_TYPE_ERROR; // "report process-level errors"
        case BranchLogLevelWarning: return OS_LOG_TYPE_DEFAULT; // "things that might result in a failure"
        case BranchLogLevelDebug: return OS_LOG_TYPE_INFO; // "helpful, but not essential, for troubleshooting errors"
        case BranchLogLevelVerbose: return OS_LOG_TYPE_DEBUG; // "useful during development or while troubleshooting a specific problem"
        default: return OS_LOG_TYPE_DEFAULT;
    }
}

@end
