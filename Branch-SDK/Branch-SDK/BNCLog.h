

//--------------------------------------------------------------------------------------------------
//
//                                                                                          BNCLog.h
//                                                                                  Branch.framework
//
//                                                                          Simple logging functions
//                                                                        Edward Smith, October 2016
//
//                                             -©- Copyright © 2016 Branch, all rights reserved. -©-
//
//--------------------------------------------------------------------------------------------------


#import <Foundation/Foundation.h>
#import "BNCDebug.h"


#ifdef __cplusplus
extern "C" {
#endif


///@functiongroup Branch Logging Functions


#pragma mark Log Message Severity

/// Log message severity
typedef NS_ENUM(NSInteger, BNCLogLevel) {
    BNCLogLevelAll = 0,
    BNCLogLevelDebug = BNCLogLevelAll,
    BNCLogLevelBreakPoint,
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
extern BNCLogLevel BNCLogDisplayLevel();

/*!
* @param level Sets the current display level for log messages.
*/
extern void BNCLogSetDisplayLevel(BNCLogLevel level);


#pragma mark - Log Message Synchronization


/*!
* @discussion   When log messages are synchronized they are written to the log in order, including
*   across separate threads. Synchronizing log messages usually improves performance since it
*   reduces global resource lock contention. Note that synchronization has the side effect of some
*   messages not being available immediately since they are written on a separate thread.
*
* @param enable Enable log message synchronization.
*/
extern void BNCLogSetSynchronizeMessages(BOOL enable);

/*!@return Returns YES if log messages are synchronized between threads.
*/
extern BOOL BNCLogSynchronizeMessages();


#pragma mark - Programmatic Breakpoints


///@return Returns 'YES' if programmatic breakpoints are enabled.
extern BOOL BNCLogBreakPointsAreEnabled();

///@param enabled Sets programmatic breakpoints enabled or disabled.
extern void BNCLogSetBreakPointsEnabled(BOOL enabled);


#pragma mark - Optional Log Output Handlers


///@info Pre-defined log message handlers --

typedef void (*BNCLogOutputFunctionPtr)(NSDate*_Nonnull timestamp, BNCLogLevel level, NSString*_Nullable message);

extern void BNCLogFunctionOutputToStdOut(NSDate*_Nonnull timestamp, BNCLogLevel level, NSString *_Nullable message);
extern void BNCLogFunctionOutputToStdErr(NSDate*_Nonnull timestamp, BNCLogLevel level, NSString *_Nullable message);

///@param functionPtr   A pointer to the logging function.  Setting the parameter to NULL will flush
///                     and close the currently set log function and future log messages will be
///                     ignored until a non-NULL logging function is set.
extern void BNCLogSetOutputFunction(BNCLogOutputFunctionPtr _Nullable functionPtr);

///@return Returns the current logging function.
extern BNCLogOutputFunctionPtr _Nullable BNCLogOutputFunction();

///@param URL Sets the log output function to a function that writes messages to the file at URL.
extern void BNCLogSetOutputToURL(NSURL *_Nullable URL);

///@param URL Sets the log output function to a function that writes messages to the file at URL.
///@param maxRecords Wraps the file at `maxRecords` records.
extern void BNCLogSetOutputToURLRecordWrap(NSURL *_Nullable URL, long maxRecords);

///@param URL Sets the log output function to a function that writes messages to the file at URL.
///@param maxBytes Wraps the file at `maxBytes` bytes.  Must be an even number of bytes.
extern void BNCLogSetOutputToURLByteWrap(NSURL *_Nullable URL, long maxBytes);

typedef void (*BNCLogFlushFunctionPtr)();

///@param flushFunction The logging functions use `flushFunction` to flush the outstanding log
///                     messages to the output function.  For instance, this function may call
///                     `fsync` to assure that the log messages are written to disk.
extern void BNCLogSetFlushFunction(BNCLogFlushFunctionPtr _Nullable flushFunction);

///@return Returns the current flush function.
extern BNCLogFlushFunctionPtr _Nullable BNCLogFlushFunction();


#pragma mark - BNCLogMessageInternal


/// The main logging function used in the logging defines.
extern void BNCLogMessageInternal(
    BNCLogLevel logLevel,
    const char *_Nullable sourceFileName,
    int sourceLineNumber,
    id _Nullable messageFormat,
    ...
);

/// This function synchronizes all outstanding log messages and writes them to the logging function
/// set by BNCLogSetOutputFunction.
extern void BNCLogFlushMessages();


#pragma mark - Logging
///@info Logging

///@param format Log a debug message with the specified formatting.
#define BNCLogDebug(...) \
    do  { BNCLogMessageInternal(BNCLogLevelDebug, __FILE__, __LINE__, __VA_ARGS__); } while (0)

///@param format Log a warning message with the specified formatting.
#define BNCLogWarning(...) \
    do  { BNCLogMessageInternal(BNCLogLevelWarning, __FILE__, __LINE__, __VA_ARGS__); } while (0)

///@param format Log an error message with the specified formatting.
#define BNCLogError(...) \
    do  { BNCLogMessageInternal(BNCLogLevelError, __FILE__, __LINE__, __VA_ARGS__); } while (0)

///@param format Log a message with the specified formatting.
#define BNCLog(...) \
    do  { BNCLogMessageInternal(BNCLogLevelLog, __FILE__, __LINE__, __VA_ARGS__); } while (0)

///Cause a programmatic breakpoint if breakpoints are enabled.
#define BNCLogBreakPoint() \
    do  { \
        if (BNCLogBreakPointsAreEnabled()) { \
            BNCLogMessageInternal(BNCLogLevelBreakPoint, __FILE__, __LINE__, @"Programmatic breakpoint."); \
            if (BNCDebuggerIsAttached()) { \
                BNCLogFlushMessages(); \
                BNCDebugBreakpoint(); \
            } \
        } \
    } while (0)

///Log a message and cause a programmatic breakpoint if breakpoints are enabled.
#define BNCBreakPointWithMessage(...) \
    do  { \
        if (BNCLogBreakPointsAreEnabled() { \
            BNCLogMessageInternal(BNCLogLevelBreakPoint, __FILE__, __LINE__, __VA_ARGS__); \
            if (BNCDebuggerIsAttached()) { \
                BNCLogFlushMessages(); \
                BNCDebugBreakpoint(); \
            } \
        } \
    } while (0)

///Check if an asserting is true.  If programmatic breakpoints are enabled then break.
#define BNCLogAssert(condition) \
    do  { \
        if (!(condition)) { \
            BNCLogMessageInternal(BNCLogLevelAssert, __FILE__, __LINE__, @"(%s) !!!", #condition); \
            if (BNCLogBreakPointsAreEnabled() && BNCDebuggerIsAttached()) { \
                BNCLogFlushMessages(); \
                BNCDebugBreakpoint(); \
            } \
        } \
    } while (0)

///Check if an asserting is true logging a message if the assertion fails.
///If programmatic breakpoints are enabled then break.
#define BNCLogAssertWithMessage(condition, message, ...) \
    do  { \
        if (!(condition)) { \
            NSString *m = [NSString stringWithFormat:message, __VA_ARGS__]; \
            BNCLogMessageInternal(BNCLogLevelAssert, __FILE__, __LINE__, @"(%s) !!! %@", #condition, m); \
            if (BNCLogBreakPointsAreEnabled() && BNCDebuggerIsAttached()) { \
                BNCLogFlushMessages(); \
                BNCDebugBreakpoint(); \
            } \
        } \
    } while (0)

///Assert that the current thread is the main thread.
#define BNCLogAssertIsMainThread() \
    BNCLogAssert([NSThread isMainThread])

///Write the name of the current method to the log.
#define BNCLogMethodName() \
    BNCLogDebug(@"Method '%@'.",  NSStringFromSelector(_cmd))

///Write the name of the current function to the log.
#define BNCLogFunctionName() \
    BNCLogDebug(@"Function '%s'.", __FUNCTION__)


#ifdef __cplusplus
}
#endif
