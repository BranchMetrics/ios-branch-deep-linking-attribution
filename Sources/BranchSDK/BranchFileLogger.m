//
//  BranchFileLogger.m
//
//
//  Created by Sharath Sriram on 15/10/24.
//
#if !TARGET_OS_TV

#import "BranchFileLogger.h"

@interface BranchFileLogger ()

@property (nonatomic, strong) NSString *logFilePath;

@end

@implementation BranchFileLogger

+ (instancetype)sharedInstance {
    static BranchFileLogger *sharedInstance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedInstance = [[self alloc] init];
    });
    return sharedInstance;
}

- (instancetype)init {
    if (self = [super init]) {
        _logFilePath = [self getLogFilePath];
        [self clearLogs];  // Clear logs at the start of each app session
    }
    return self;
}

// Get the log file path in the app’s documents directory
- (NSString *)getLogFilePath {
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *documentsDirectory = [paths firstObject];
    return [documentsDirectory stringByAppendingPathComponent:@"app_log.txt"];
}

// Append a message to the log file
- (void)logMessage:(NSString *)message {
    NSString *timestampedMessage = [NSString stringWithFormat:@"%@: %@\n", [self currentTimestamp], message];
    
    NSFileHandle *fileHandle = [NSFileHandle fileHandleForWritingAtPath:self.logFilePath];
    if (!fileHandle) {
        [[NSFileManager defaultManager] createFileAtPath:self.logFilePath contents:nil attributes:nil];
        fileHandle = [NSFileHandle fileHandleForWritingAtPath:self.logFilePath];
    }
    
    [fileHandle seekToEndOfFile];
    NSData *data = [timestampedMessage dataUsingEncoding:NSUTF8StringEncoding];
    [fileHandle writeData:data];
    [fileHandle closeFile];
}

// Helper: Get the current timestamp
- (NSString *)currentTimestamp {
    NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
    [formatter setDateFormat:@"yyyy-MM-dd HH:mm:ss"];
    return [formatter stringFromDate:[NSDate date]];
}

// Clear the log file (called at app start)
- (void)clearLogs {
    [[NSFileManager defaultManager] removeItemAtPath:self.logFilePath error:nil];
    [[NSFileManager defaultManager] createFileAtPath:self.logFilePath contents:nil attributes:nil];
}

- (BOOL)isLogFilePopulated {
    // Check if the file exists
    if (![[NSFileManager defaultManager] fileExistsAtPath:self.logFilePath]) {
        return NO;
    }
    
    // Check if the file is non-empty
    NSDictionary *attributes = [[NSFileManager defaultManager] attributesOfItemAtPath:self.logFilePath error:nil];
    unsigned long long fileSize = [attributes fileSize];
    
    return fileSize > 0;  // Return YES if file is populated, NO otherwise
}

- (void)shareLogFileFromViewController:(UIViewController *)viewController {
    // Check if the log file exists
    if (![[NSFileManager defaultManager] fileExistsAtPath:self.logFilePath]) {
        NSLog(@"No log file found to share.");
        return;
    }
    
    // Create a URL from the log file path
    NSURL *logFileURL = [NSURL fileURLWithPath:self.logFilePath];
    
    // Create an activity view controller with the log file
    UIActivityViewController *activityVC =
        [[UIActivityViewController alloc] initWithActivityItems:@[logFileURL]
                                          applicationActivities:nil];

    // Exclude certain activities if necessary (optional)
    activityVC.excludedActivityTypes = @[UIActivityTypePostToFacebook,
                                         UIActivityTypePostToTwitter];
    
    // Present the share sheet
    [viewController presentViewController:activityVC animated:YES completion:nil];
}

@end

#endif
