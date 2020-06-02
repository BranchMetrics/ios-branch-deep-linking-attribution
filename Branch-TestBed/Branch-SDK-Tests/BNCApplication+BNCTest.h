/**
 @file          BNCApplication+BNCTest.h
 @package       Branch-SDK-Tests
 @brief         Expose BNCApplication interfaces for testing.

 @author        Edward Smith
 @date          May 4, 2018
 @copyright     Copyright © 2018 Branch. All rights reserved.
*/

#import <Foundation/Foundation.h>
#import "BNCApplication.h"

@interface BNCApplication (BNCTest)

- (void) setAppOriginalInstallDate:(NSDate*)originalInstallDate
        firstInstallDate:(NSDate*)firstInstallDate
        lastUpdateDate:(NSDate*)lastUpdateDate;

@end
