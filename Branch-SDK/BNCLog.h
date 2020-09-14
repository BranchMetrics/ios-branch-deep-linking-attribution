/**
 @file          BNCLog.h
 @package       Branch-SDK
 @brief         Simple logging functions.

 @author        Edward Smith
 @date          October 2016
 @copyright     Copyright © 2016 Branch. All rights reserved.
*/

///@functiongroup Branch Logging Functions
#import <Foundation/Foundation.h>

#pragma mark Log Message Severity

/// Log message severity
typedef NS_ENUM(NSInteger, BNCLogLevel) {
    BNCLogLevelAll = 0,
    BNCLogLevelDebugSDK = BNCLogLevelAll,
    BNCLogLevelBreakPoint,
    BNCLogLevelDebug,
    BNCLogLevelWarning,
    BNCLogLevelError,
    BNCLogLevelAssert,
    BNCLogLevelLog,
    BNCLogLevelNone,
    BNCLogLevelMax
};

/*!
* @return Returns the current log severity display level.
*/
extern BNCLogLevel BNCLogDisplayLevel(void);

/*!
* @param level Sets the current display level for log messages.
*/
extern void BNCLogSetDisplayLevel(BNCLogLevel level);

/*!
* @param level The log level to convert to a string.
* @return Returns the string indicating the log level.
*/
extern NSString *_Nonnull BNCLogStringFromLogLevel(BNCLogLevel level);

/*!
* @param string A string indicating the log level.
* @return Returns The log level corresponding to the string.
*/
extern BNCLogLevel BNCLogLevelFromString(NSString*_Null_unspecified string);

#pragma mark - BNCLogWriteMessage

/// The main logging function used in the variadic logging defines.
extern void BNCLogWriteMessage(
    BNCLogLevel logLevel,
    const char *_Nullable sourceFileName,
    int32_t sourceLineNumber,
    NSString *_Nullable message
);

extern void BNCLogDebugSDK(
    NSString *_Nonnull message
);

extern void BNCLogDebug(
    NSString *_Nonnull message
);

extern void BNCLogWarning(
    NSString *_Nonnull message
);

extern void BNCLogError(
    NSString *_Nonnull message
);

extern void BNCLog(
    NSString *_Nonnull message
);
