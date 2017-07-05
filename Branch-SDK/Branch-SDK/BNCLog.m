

//--------------------------------------------------------------------------------------------------
//
//                                                                                          BNCLog.m
//                                                                                  Branch.framework
//
//                                                                          Simple logging functions
//                                                                        Edward Smith, October 2016
//
//                                             -©- Copyright © 2016 Branch, all rights reserved. -©-
//
//--------------------------------------------------------------------------------------------------


#import  "BNCLog.h"


#define _countof(array)  (sizeof(array)/sizeof(array[0]))
static NSNumber *bnc_LogIsInitialized = nil;

// An 'inner', last attempt at logging if an error occurs in BNCLog.
// BNCLog can't log itself, but if an error occurs it uses this simple define:

extern void BNCLogInternalErrorFunction(int linenumber, NSString*format, ...);
void BNCLogInternalErrorFunction(int linenumber, NSString*format, ...) {

    va_list args;
    va_start(args, format);
    NSString* message = [[NSString alloc] initWithFormat:format arguments:args];
    va_end(args);

    NSLog(@"[branch.io] BNCLog.m (%d) Log error: %@", linenumber, message);
}

#define BNCLogInternalError(...) \
    BNCLogInternalErrorFunction(__LINE__, __VA_ARGS__)


#pragma mark - Default Output Functions

static int bnc_LogDescriptor = -1;

void BNCLogFunctionOutputToStdOut(
        NSDate*_Nonnull timestamp,
        BNCLogLevel level,
        NSString *_Nullable message
    ) {
    NSData *data = [message dataUsingEncoding:NSNEXTSTEPStringEncoding];
    if (!data) data = [@"<nil>" dataUsingEncoding:NSNEXTSTEPStringEncoding];
    long n = write(STDOUT_FILENO, data.bytes, data.length);
    if (n < 0) {
        int e = errno;
        BNCLogInternalError(@"Can't write log message (%d): %s.", e, strerror(e));
    }
    write(STDOUT_FILENO, "\n", sizeof('\n'));
}

void BNCLogFunctionOutputToStdErr(
        NSDate*_Nonnull timestamp,
        BNCLogLevel level,
        NSString *_Nullable message
    ) {
    NSData *data = [message dataUsingEncoding:NSNEXTSTEPStringEncoding];
    if (!data) data = [@"<nil>" dataUsingEncoding:NSNEXTSTEPStringEncoding];
    long n = write(STDERR_FILENO, data.bytes, data.length);
    if (n < 0) {
        int e = errno;
        BNCLogInternalError(@"Can't write log message (%d): %s.", e, strerror(e));
    }
    write(STDERR_FILENO, "\n", sizeof('\n'));
}

void BNCLogFunctionOutputToFileDescriptor(
        NSDate*_Nonnull timestamp,
        BNCLogLevel level,
        NSString *_Nullable message
    ) {
    // Pad length to even characters
    if (!message) message = @"";
    NSString *string = [NSString stringWithFormat:@"%@\n", message];
    NSData *data = [string dataUsingEncoding:NSUTF8StringEncoding];
    if ((data.length & 1) == 1) {
        string = [NSString stringWithFormat:@"%@ \n", message];
        data = [string dataUsingEncoding:NSUTF8StringEncoding];
    }
    if ((data.length & 1) != 0) {
        BNCLogInternalError(@"Writing un-even bytes!");
    }
    long n = write(bnc_LogDescriptor, data.bytes, data.length);
    if (n < 0) {
        int e = errno;
        BNCLogInternalError(@"Can't write log message (%d): %s.", e, strerror(e));
    }
}

void BNCLogFlushFileDescriptor() {
    if (bnc_LogDescriptor >= 0) {
        fsync(bnc_LogDescriptor);
    }
}

void BNCLogSetOutputToURL(NSURL *_Nullable url) {
    if (url == nil) return;
    BNCLogSetOutputFunction(BNCLogFunctionOutputToFileDescriptor);
    BNCLogSetFlushFunction(BNCLogFlushFileDescriptor);
    bnc_LogDescriptor = open(
        url.path.UTF8String,
        O_RDWR|O_CREAT|O_APPEND,
        S_IRUSR|S_IWUSR|S_IRGRP|S_IWGRP
    );
    if (bnc_LogDescriptor < 0) {
        int e = errno;
        BNCLogInternalError(@"Can't open log file '%@'.", url);
        BNCLogInternalError(@"Can't open log file (%d): %s.", e, strerror(e));
    }
}

#pragma mark - Record Wrap Output File Functions

static off_t bnc_LogOffset           = 0;
static off_t bnc_LogOffsetMax        = 100;
static off_t bnc_LogRecordSize       = 1024;
static NSDateFormatter *bnc_LogDateFormatter = nil;

void BNCLogRecordWrapWrite(NSDate*_Nonnull timestamp, BNCLogLevel level, NSString *_Nullable message) {

    NSString * string = [NSString stringWithFormat:@"%@ %ld %@",
        [bnc_LogDateFormatter stringFromDate:timestamp], (long) level, message];
    NSData *stringData = [string dataUsingEncoding:NSUTF8StringEncoding];

    char buffer[bnc_LogRecordSize];
    memset(buffer, ' ', sizeof(buffer));
    buffer[sizeof(buffer)-1] = '\n';
    long len = MIN(stringData.length, sizeof(buffer)-1);
    memcpy(buffer, stringData.bytes, len);

    off_t n = write(bnc_LogDescriptor, buffer, sizeof(buffer));
    if (n < 0) {
        int e = errno;
        BNCLogInternalError(@"Can't write log message (%d): %s.", e, strerror(e));
    }
    bnc_LogOffset++;
    if (bnc_LogOffset >= bnc_LogOffsetMax) {
        bnc_LogOffset = 0;
        n = lseek(bnc_LogDescriptor, 0, SEEK_SET);
        if (n < 0) {
            int e = errno;
            BNCLogInternalError(@"Can't seek in log (%d): %s.", e, strerror(e));
        }
    }
}

void BNCLogRecordWrapFlush() {
    if (bnc_LogDescriptor >= 0) {
        fsync(bnc_LogDescriptor);
    }
}

BOOL BNCLogRecordWrapOpenURL(NSURL *url, long maxRecords, long recordSize) {
    if (url == nil) return NO;
    bnc_LogOffsetMax = MAX(1, maxRecords);
    bnc_LogRecordSize = MAX(64, recordSize);
    if ((bnc_LogRecordSize & 1) != 0) {
        // Can't have odd-length records.
        bnc_LogRecordSize++;
    }
    BNCLogSetOutputFunction(BNCLogRecordWrapWrite);
    BNCLogSetFlushFunction(BNCLogRecordWrapFlush);
    bnc_LogDescriptor = open(
        url.path.UTF8String,
        O_RDWR|O_CREAT,
        S_IRUSR|S_IWUSR|S_IRGRP|S_IWGRP
    );
    if (bnc_LogDescriptor < 0) {
        int e = errno;
        BNCLogInternalError(@"Can't open log file '%@'.", url);
        BNCLogInternalError(@"Can't open log file (%d): %s.", e, strerror(e));
        return NO;
    }

    // Truncate the file if the file size > max file size.

    off_t n = 0;
    off_t maxSz = bnc_LogOffsetMax * bnc_LogRecordSize;
    off_t sz = lseek(bnc_LogDescriptor, 0, SEEK_END);
    if (sz < 0) {
        int e = errno;
        BNCLogInternalError(@"Can't seek in log (%d): %s.", e, strerror(e));
    } else if (sz > maxSz) {
        n = ftruncate(bnc_LogDescriptor, maxSz);
        if (n < 0) {
            int e = errno;
            BNCLogInternalError(@"Can't truncate log (%d): %s.", e, strerror(e));
        }
    }
    lseek(bnc_LogDescriptor, 0, SEEK_SET);

    // Read the records until the oldest record is found --

    off_t oldestOffset = 0;
    NSDate * oldestDate = [NSDate distantFuture];

    off_t offset = 0;
    char buffer[bnc_LogRecordSize];
    n = read(bnc_LogDescriptor, &buffer, sizeof(buffer));
    while (n == sizeof(buffer)) {
        NSString *dateString =
            [[NSString alloc] initWithBytes:buffer length:27 encoding:NSUTF8StringEncoding];
        NSDate *date = [bnc_LogDateFormatter dateFromString:dateString];
        if (date && [date compare:oldestDate] < 0) {
            oldestOffset = offset;
            oldestDate = date;
        }
        offset++;
        n = read(bnc_LogDescriptor, &buffer, sizeof(buffer));
    }
    if (offset < bnc_LogOffsetMax)
        bnc_LogOffset = offset;
    else
    if (oldestOffset >= bnc_LogOffsetMax)
        bnc_LogOffset = 0;
    else
        bnc_LogOffset = oldestOffset;
    n = lseek(bnc_LogDescriptor, bnc_LogOffset*bnc_LogRecordSize, SEEK_SET);
    if (n < 0) {
        int e = errno;
        BNCLogInternalError(@"Can't seek in log (%d): %s.", e, strerror(e));
    }
    return YES;
}

void BNCLogSetOutputToURLRecordWrapSize(NSURL *_Nullable url, long maxRecords, long recordSize) {
    BNCLogRecordWrapOpenURL(url, maxRecords, recordSize);
}

void BNCLogSetOutputToURLRecordWrap(NSURL *_Nullable url, long maxRecords) {
    BNCLogSetOutputToURLRecordWrapSize(url, maxRecords, 1024);
}

#pragma mark - Byte Wrap Output File Functions

void BNCLogByteWrapWrite(NSDate*_Nonnull timestamp, BNCLogLevel level, NSString *_Nullable message) {

    NSString * string = [NSString stringWithFormat:@"%@ %ld %@\n",
        [bnc_LogDateFormatter stringFromDate:timestamp], (long) level, message];
    NSData *stringData = [string dataUsingEncoding:NSUTF8StringEncoding];

    if ((stringData.length & 1) != 0) {
        string = [NSString stringWithFormat:@"%@ %ld %@ \n",
            [bnc_LogDateFormatter stringFromDate:timestamp], (long) level, message];
        stringData = [string dataUsingEncoding:NSUTF8StringEncoding];
    }

    // Truncate the file if the file size > max file size.

    if ((bnc_LogOffset + stringData.length) > bnc_LogOffsetMax) {
        long n = ftruncate(bnc_LogDescriptor, bnc_LogOffset);
        if (n < 0) {
            int e = errno;
            BNCLogInternalError(@"Can't truncate log (%d): %s.", e, strerror(e));
        }
        lseek(bnc_LogDescriptor, 0, SEEK_SET);
        bnc_LogOffset = 0;
    }

    long n = write(bnc_LogDescriptor, stringData.bytes, stringData.length);
    if (n < 0) {
        int e = errno;
        BNCLogInternalError(@"Can't write log message (%d): %s.", e, strerror(e));
    } else {
        bnc_LogOffset += n;
    }
}

void BNCLogByteWrapFlush() {
    if (bnc_LogDescriptor >= 0) {
        fsync(bnc_LogDescriptor);
    }
}

NSString *BNCLogByteWrapReadNextRecord() {

    char *buffer = NULL;
    long bufferSize = 0;
    off_t originalOffset = lseek(bnc_LogDescriptor, 0, SEEK_CUR);
    if (originalOffset < 0) {
        int e = errno;
        BNCLogInternalError(@"Can't find offset in log file (%d): %s.", e, strerror(e));
        goto error_exit;
    }

    do {

        bufferSize += 1024;
        if (buffer) free(buffer);
        buffer = malloc(bufferSize);
        if (!buffer) {
            BNCLogInternalError(@"Can't allocate a buffer of %ld bytes.", bufferSize);
            goto error_exit;
        }

        off_t n = lseek(bnc_LogDescriptor, originalOffset, SEEK_SET);
        if (n < 0) {
            int e = errno;
            BNCLogInternalError(@"Can't seek in log file (%d): %s.", e, strerror(e));
            goto error_exit;
        }
        n = read(bnc_LogDescriptor, buffer, bufferSize);
        if (n == 0) {
            goto error_exit;
        } else if (n < 0) {
            int e = errno;
            if (e != EOF) {
                BNCLogInternalError(@"Can't read log message (%d): %s.", e, strerror(e));
            }
            goto error_exit;
        }

        char* p = buffer;
        while ( (p-buffer) < n && *p != '\n') {
            p++;
        }
        if (*p == '\n') {
            long offset = (p-buffer)+1;
            NSString *result = [[NSString alloc]
                initWithBytes:buffer length:offset encoding:NSUTF8StringEncoding];
            bnc_LogOffset = originalOffset + offset;
            n = lseek(bnc_LogDescriptor, bnc_LogOffset, SEEK_SET);
            if (n < 0) {
                int e = errno;
                BNCLogInternalError(@"Can't seek in log file (%d): %s.", e, strerror(e));
            }
            free(buffer);
            return result;
        }

    } while (bufferSize < 1024*20);

error_exit:
    if (buffer) free(buffer);
    return nil;
}

BOOL BNCLogByteWrapOpenURL(NSURL *url, long maxBytes) {
    if (url == nil) return NO;
    bnc_LogOffsetMax = MAX(256, maxBytes);
    BNCLogSetOutputFunction(BNCLogByteWrapWrite);
    BNCLogSetFlushFunction(BNCLogByteWrapFlush);
    bnc_LogDescriptor = open(
        url.path.UTF8String,
        O_RDWR|O_CREAT,
        S_IRUSR|S_IWUSR|S_IRGRP|S_IWGRP
    );
    if (bnc_LogDescriptor < 0) {
        int e = errno;
        BNCLogInternalError(@"Can't open log file '%@'.", url);
        BNCLogInternalError(@"Can't open log file (%d): %s.", e, strerror(e));
        return NO;
    }

    // Truncate the file if the file size > max file size.

    off_t n = 0;
    off_t maxSz = bnc_LogOffsetMax;
    off_t sz = lseek(bnc_LogDescriptor, 0, SEEK_END);
    if (sz < 0) {
        int e = errno;
        BNCLogInternalError(@"Can't seek in log (%d): %s.", e, strerror(e));
    } else if (sz > maxSz) {
        n = ftruncate(bnc_LogDescriptor, maxSz);
        if (n < 0) {
            int e = errno;
            BNCLogInternalError(@"Can't truncate log (%d): %s.", e, strerror(e));
        }
    }
    bnc_LogOffset = 0;
    lseek(bnc_LogDescriptor, bnc_LogOffset, SEEK_SET);

    // Read the records until the oldest record is found --

    BOOL logDidWrap = NO;
    off_t wrapOffset = 0;

    off_t lastOffset = 0;
    NSDate *lastDate = [NSDate distantPast];

    NSString *record = BNCLogByteWrapReadNextRecord();
    while (record) {
        NSString *dateString = @"";
        if (record.length >= 27) dateString = [record substringWithRange:NSMakeRange(0, 27)];
        NSDate *date = [bnc_LogDateFormatter dateFromString:dateString];
        if (!date || [date compare:lastDate] < 0) {
            wrapOffset = lastOffset;
            logDidWrap = YES;
        }
        lastDate = date ?: [NSDate distantPast];
        lastOffset = bnc_LogOffset;
        record = BNCLogByteWrapReadNextRecord();
    }
    if (logDidWrap) {
        bnc_LogOffset = wrapOffset;
    } else if (bnc_LogOffset >= bnc_LogOffsetMax)
        bnc_LogOffset = 0;
    n = lseek(bnc_LogDescriptor, bnc_LogOffset, SEEK_SET);
    if (n < 0) {
        int e = errno;
        BNCLogInternalError(@"Can't seek in log (%d): %s.", e, strerror(e));
    }
    return YES;
}

void BNCLogSetOutputToURLByteWrap(NSURL *_Nullable URL, long maxBytes) {
    BNCLogByteWrapOpenURL(URL, maxBytes);
}

#pragma mark - Log Message Severity

static BNCLogLevel bnc_LogDisplayLevel = BNCLogLevelWarning;

BNCLogLevel BNCLogDisplayLevel() {
    @synchronized (bnc_LogIsInitialized) {
        return bnc_LogDisplayLevel;
    }
}

void BNCLogSetDisplayLevel(BNCLogLevel level) {
    @synchronized (bnc_LogIsInitialized) {
        bnc_LogDisplayLevel = level;
    }
}

#pragma mark - Log Synchronization

static BOOL bnc_SynchronizeMessages = YES;

void BNCLogSetSynchronizeMessages(BOOL enable) {
    @synchronized (bnc_LogIsInitialized) {
        bnc_SynchronizeMessages = enable;
    }
}

BOOL BNCLogSynchronizeMessages() {
    @synchronized (bnc_LogIsInitialized) {
        return bnc_SynchronizeMessages;
    }
}

#pragma mark - Break Points

static BOOL bnc_LogBreakPointsAreEnabled = NO;

BOOL BNCLogBreakPointsAreEnabled() {
    @synchronized (bnc_LogIsInitialized) {
        return bnc_LogBreakPointsAreEnabled;
    }
}

void BNCLogSetBreakPointsEnabled(BOOL enabled) {
    @synchronized (bnc_LogIsInitialized) {
        bnc_LogBreakPointsAreEnabled = enabled;
    }
}

#pragma mark - Log Functions

static BNCLogOutputFunctionPtr bnc_LoggingFunction = nil; // Default to just NSLog output.
static BNCLogFlushFunctionPtr bnc_LogFlushFunction = BNCLogFlushFileDescriptor;

BNCLogOutputFunctionPtr _Nullable BNCLogOutputFunction() {
    @synchronized (bnc_LogIsInitialized) {
        return bnc_LoggingFunction;
    }
}

void BNCLogCloseLogFile() {
    @synchronized(bnc_LogIsInitialized) {
        if (bnc_LogDescriptor >= 0) {
            BNCLogFlushMessages();
            close(bnc_LogDescriptor);
            bnc_LogDescriptor = -1;
        }
    }
}

void BNCLogSetOutputFunction(BNCLogOutputFunctionPtr _Nullable logFunction) {
    @synchronized (bnc_LogIsInitialized) {
        BNCLogFlushMessages();
        bnc_LoggingFunction = logFunction;
    }
}

BNCLogFlushFunctionPtr BNCLogFlushFunction() {
    @synchronized (bnc_LogIsInitialized) {
        return bnc_LogFlushFunction;
    }
}

void BNCLogSetFlushFunction(BNCLogFlushFunctionPtr flushFunction) {
    @synchronized (bnc_LogIsInitialized) {
        bnc_LogFlushFunction = flushFunction;
    }
}

#pragma mark - BNCLogInternal

static dispatch_queue_t bnc_LogQueue = nil;

void BNCLogWriteMessageFormat(
        BNCLogLevel logLevel,
        const char *_Nullable file,
        int lineNumber,
        NSString *_Nullable message,
        ...
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

    NSString *logLevels[BNCLogLevelMax] = {
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

    va_list args;
    va_start(args, message);
    NSString* m = [[NSString alloc] initWithFormat:message arguments:args];
    NSString* s = [NSString stringWithFormat:
        @"[branch.io] %@(%d) %@: %@", filename, lineNumber, levelString, m];
    va_end(args);

    if (logLevel >= bnc_LogDisplayLevel) {
        NSLog(@"%@", s);
    }

    if (BNCLogSynchronizeMessages()) {
        dispatch_async(bnc_LogQueue, ^{
            if (bnc_LoggingFunction)
                bnc_LoggingFunction([NSDate date], logLevel, s);
        });
    } else {
        if (bnc_LoggingFunction)
            bnc_LoggingFunction([NSDate date], logLevel, s);
    }
}

void BNCLogWriteMessage(
                           BNCLogLevel logLevel,
                           NSString *_Nonnull file,
                           NSUInteger lineNumber,
                           NSString *_Nonnull message
                           ) {
    BNCLogWriteMessageFormat(logLevel, file.UTF8String, (int)lineNumber, @"%@", message);
}

void BNCLogFlushMessages() {
    if (BNCLogSynchronizeMessages()) {
        dispatch_sync(bnc_LogQueue, ^{
            if (bnc_LogFlushFunction)
                bnc_LogFlushFunction();
        });
    } else {
        if (bnc_LogFlushFunction)
            bnc_LogFlushFunction();
    }
}

#pragma mark - BNCLogInitialize

void BNCLogInitialize(void) __attribute__((constructor));
void BNCLogInitialize(void) {
    static dispatch_once_t onceToken = 0;
    dispatch_once(&onceToken, ^ {
        bnc_LogQueue = dispatch_queue_create("io.branch.log", DISPATCH_QUEUE_SERIAL);

        bnc_LogDateFormatter = [[NSDateFormatter alloc] init];
        bnc_LogDateFormatter.locale = [NSLocale localeWithLocaleIdentifier:@"en_US_POSIX"];
        bnc_LogDateFormatter.dateFormat = @"yyyy-MM-dd'T'HH:mm:ss.SSSSSSX";
        bnc_LogDateFormatter.timeZone = [NSTimeZone timeZoneForSecondsFromGMT:0];

        bnc_LogIsInitialized = @(YES);
    });
}
