//
//  BranchFileLogger.h
//
//
//  Created by Sharath Sriram on 15/10/24.
//

#if !TARGET_OS_TV

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

@interface BranchFileLogger : NSObject

+ (instancetype)sharedInstance;
- (void)logMessage:(NSString *)message;
- (NSString *)getLogFilePath;
- (void)clearLogs;
- (BOOL)isLogFilePopulated;
- (void)shareLogFileFromViewController:(UIViewController *)viewController;

@end

#endif
