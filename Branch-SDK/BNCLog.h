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

#pragma mark Log Initialization

/// Log facility initialization. Usually there is no need to call this directly.
extern void BNCLogInitialize(void) __attribute__((constructor));

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


#pragma mark - Programmatic Breakpoints


///@return Returns 'YES' if programmatic breakpoints are enabled.
extern BOOL BNCLogBreakPointsAreEnabled(void);

///@param enabled Sets programmatic breakpoints enabled or disabled.
extern void BNCLogSetBreakPointsEnabled(BOOL enabled);


#pragma mark - Client Initialization Function


typedef void (*BNCLogClientInitializeFunctionPtr)(void);

///@param clientInitializationFunction The client function that should be called before logging starts.
extern BNCLogClientInitializeFunctionPtr _Null_unspecified
    BNCLogSetClientInitializeFunction(BNCLogClientInitializeFunctionPtr _Nullable clientInitializationFunction);


#pragma mark - Optional Log Output Handlers


///@brief Pre-defined log message handlers --

typedef void (*BNCLogOutputFunctionPtr)(NSDate*_Nonnull timestamp, BNCLogLevel level, NSString*_Nullable message);

extern void BNCLogFunctionOutputToStdOut(NSDate*_Nonnull timestamp, BNCLogLevel level, NSString *_Nullable message);
extern void BNCLogFunctionOutputToStdErr(NSDate*_Nonnull timestamp, BNCLogLevel level, NSString *_Nullable message);

///@param functionPtr   A pointer to the logging function.  Setting the parameter to NULL will flush
///                     and close the currently set log function and future log messages will be
///                     ignored until a non-NULL logging function is set.
extern void BNCLogSetOutputFunction(BNCLogOutputFunctionPtr _Nullable functionPtr);

///@return Returns the current logging function.
extern BNCLogOutputFunctionPtr _Nullable BNCLogOutputFunction(void);

/// If a predefined log handler is being used, the function closes the output file.
extern void BNCLogCloseLogFile(void);

///@param URL Sets the log output function to a function that writes messages to the file at URL.
extern void BNCLogSetOutputToURL(NSURL *_Nullable URL);

///@param URL Sets the log output function to a function that writes messages to the file at URL.
///@param maxRecords Wraps the file at `maxRecords` records.
extern void BNCLogSetOutputToURLRecordWrap(NSURL *_Nullable URL, long maxRecords);

///@param URL Sets the log output function to a function that writes messages to the file at URL.
///@param maxBytes Wraps the file at `maxBytes` bytes.  Must be an even number of bytes.
extern void BNCLogSetOutputToURLByteWrap(NSURL *_Nullable URL, long maxBytes);

typedef void (*BNCLogFlushFunctionPtr)(void);

///@param flushFunction The logging functions use `flushFunction` to flush the outstanding log
///                     messages to the output function.  For instance, this function may call
///                     `fsync` to assure that the log messages are written to disk.
extern void BNCLogSetFlushFunction(BNCLogFlushFunctionPtr _Nullable flushFunction);

///@return Returns the current flush function.
extern BNCLogFlushFunctionPtr _Nullable BNCLogFlushFunction(void);


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

/// This function synchronizes all outstanding log messages and writes them to the logging function
/// set by BNCLogSetOutputFunction.
extern void BNCLogFlushMessages(void);
