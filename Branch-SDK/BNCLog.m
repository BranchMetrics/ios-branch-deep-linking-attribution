/**
 @file          BNCLog.m
 @package       Branch-SDK
 @brief         Simple logging functions.

 @author        Edward Smith
 @date          October 2016
 @copyright     Copyright © 2016 Branch. All rights reserved.
*/

#import "BNCLog.h"

#define _countof(array)  (sizeof(array)/sizeof(array[0]))

// A fallback attempt at logging if an error occurs in BNCLog.
// BNCLog can't log itself, but if an error occurs it uses this simple define:
extern void BNCLogInternalError(NSString *message);
void BNCLogInternalError(NSString *message) {
    NSLog(@"[branch.io] BNCLog.m (%d) Log error: %@", __LINE__, message);
}

#pragma mark - Log Message Severity

static BNCLogLevel bnc_LogDisplayLevel = BNCLogLevelWarning;

BNCLogLevel BNCLogDisplayLevel() {
    BNCLogLevel level = bnc_LogDisplayLevel;
    return level;
}

void BNCLogSetDisplayLevel(BNCLogLevel level) {
    bnc_LogDisplayLevel = level;
}

static NSString*const bnc_logLevelStrings[] = {
    @"BNCLogLevelAll",
    @"BNCLogLevelBreakPoint",
    @"BNCLogLevelDebug",
    @"BNCLogLevelWarning",
    @"BNCLogLevelError",
    @"BNCLogLevelAssert",
    @"BNCLogLevelLog",
    @"BNCLogLevelNone",
    @"BNCLogLevelMax"
};

NSString* BNCLogStringFromLogLevel(BNCLogLevel level) {
    level = MAX(MIN(level, BNCLogLevelMax), 0);
    return bnc_logLevelStrings[level];
}

BNCLogLevel BNCLogLevelFromString(NSString*string) {
    if (!string) return BNCLogLevelNone;
    for (NSUInteger i = 0; i < _countof(bnc_logLevelStrings); ++i) {
        if ([bnc_logLevelStrings[i] isEqualToString:string]) {
            return i;
        }
    }
    if ([string isEqualToString:@"BNCLogLevelDebugSDK"]) {
        return BNCLogLevelDebugSDK;
    }
    return BNCLogLevelNone;
}

#pragma mark - BNCLogInternal

void BNCLogWriteMessage(
        BNCLogLevel logLevel,
        const char *_Nullable file,
        int32_t lineNumber,
        NSString *_Nullable message
    ) {
    if (!file) file = "";
    if (!message) message = @"<nil>";
    if (![message isKindOfClass:[NSString class]]) {
        message = [NSString stringWithFormat:@"0x%016llx <%@> %@",
            (uint64_t) message, message.class, message.description];
    }

    NSString* filename =
        [[NSString stringWithCString:file encoding:NSMacOSRomanStringEncoding]
            lastPathComponent];

    NSString * const logLevels[BNCLogLevelMax] = {
        @"DebugSDK",
        @"Break",
        @"Debug",
        @"Warning",
        @"Error",
        @"Assert",
        @"Log",
        @"None",
    };

    logLevel = MAX(MIN(logLevel, BNCLogLevelMax-1), 0);
    NSString *levelString = logLevels[logLevel];
    NSString *s = [NSString stringWithFormat:@"[branch.io] %@(%d) %@: %@", filename, lineNumber, levelString, message];

    if (logLevel >= bnc_LogDisplayLevel) {
        NSLog(@"%@", s); // Upgrade this to unified logging when we can.
    }
}
