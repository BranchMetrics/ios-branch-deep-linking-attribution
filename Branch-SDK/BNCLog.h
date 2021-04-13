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

///@name Pre-defined log message handlers --
typedef void (*BNCLogOutputFunctionPtr)(NSDate*_Nonnull timestamp, BNCLogLevel level, NSString*_Nullable message);

///@param functionPtr   A pointer to the logging function.  Setting the parameter to NULL will flush
///                     and close the currently set log function and future log messages will be
///                     ignored until a non-NULL logging function is set.
extern void BNCLogSetOutputFunction(BNCLogOutputFunctionPtr _Nullable functionPtr);

#pragma mark - BNCLogWriteMessage

/// The main logging function used in the variadic logging defines.
extern void BNCLogWriteMessage(
    BNCLogLevel logLevel,
    const char *_Nullable sourceFileName,
    int32_t sourceLineNumber,
    NSString *_Nullable message
);

///@param format Log an info message
#define BNCLogDebugSDK(...) \
    do  { BNCLogWriteMessage(BNCLogLevelDebugSDK, __FILE__, __LINE__, __VA_ARGS__); } while (0)

///@param format Log a debug message
#define BNCLogDebug(...) \
    do  { BNCLogWriteMessage(BNCLogLevelDebug, __FILE__, __LINE__, __VA_ARGS__); } while (0)

///@param format Log a warning message
#define BNCLogWarning(...) \
    do  { BNCLogWriteMessage(BNCLogLevelWarning, __FILE__, __LINE__, __VA_ARGS__); } while (0)

///@param format Log an error message
#define BNCLogError(...) \
    do  { BNCLogWriteMessage(BNCLogLevelError, __FILE__, __LINE__, __VA_ARGS__); } while (0)

///@param format Log a message
#define BNCLog(...) \
    do  { BNCLogWriteMessage(BNCLogLevelLog, __FILE__, __LINE__, __VA_ARGS__); } while (0)
