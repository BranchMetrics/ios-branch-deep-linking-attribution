//
//  BNCSwiftLog.m
//  WebViewExample
//
//  Created by Jimmy Dee on 4/7/17.
//  Copyright © 2017 Branch Metrics. All rights reserved.
//

@import Branch;

#import "BNCSwiftLog.h"

@implementation BNCSwiftLog

+ (void)debug:(NSString *)message file:(NSString *)file line:(NSUInteger)line
{
    BNCLogMessageInternal(BNCLogLevelDebug, file.UTF8String, (int)line, @"%@", message);
}

+ (void)error:(NSString *)message file:(NSString *)file line:(NSUInteger)line
{
    BNCLogMessageInternal(BNCLogLevelError, file.UTF8String, (int)line, @"%@", message);
}

+ (void)log:(NSString *)message file:(NSString *)file line:(NSUInteger)line
{
    BNCLogMessageInternal(BNCLogLevelLog, file.UTF8String, (int)line, @"%@", message);
}

+ (void)warning:(NSString *)message file:(NSString *)file line:(NSUInteger)line
{
    BNCLogMessageInternal(BNCLogLevelWarning, file.UTF8String, (int)line, @"%@", message);
}

@end
