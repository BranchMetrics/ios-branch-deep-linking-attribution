//
//  BNCDeviceInfo.m
//  Branch-TestBed
//
//  Created by Sojan P.R. on 3/22/16.
//  Copyright © 2016 Branch Metrics. All rights reserved.
//


#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import "BNCDeviceInfo.h"
#import "BNCPreferenceHelper.h"
#import "BNCSystemObserver.h"
#import "BNCXcode7Support.h"


@interface BNCDeviceInfo()
@end


@implementation BNCDeviceInfo

static BNCDeviceInfo *bncDeviceInfo;

+ (BNCDeviceInfo *)getInstance {
    if (!bncDeviceInfo) {
        bncDeviceInfo = [[BNCDeviceInfo alloc] init];
    }
    return bncDeviceInfo;
}

- (id)init {
    self = [super init];
    if (!self) return self;

    BNCPreferenceHelper *preferenceHelper = [BNCPreferenceHelper preferenceHelper];
    BOOL isRealHardwareId;
    NSString *hardwareIdType;
    NSString *hardwareId =
        [BNCSystemObserver getUniqueHardwareId:&isRealHardwareId
            isDebug:preferenceHelper.isDebug
            andType:&hardwareIdType];
    if (hardwareId) {
        self.hardwareId = hardwareId;
        self.isRealHardwareId = isRealHardwareId;
        self.hardwareIdType = hardwareIdType;
    }

    self.vendorId = [BNCSystemObserver getVendorId];
    self.brandName = [BNCSystemObserver getBrand];
    self.modelName = [BNCSystemObserver getModel];
    self.osName = [BNCSystemObserver getOS];
    self.osVersion = [BNCSystemObserver getOSVersion];
    self.screenWidth = [BNCSystemObserver getScreenWidth];
    self.screenHeight = [BNCSystemObserver getScreenHeight];
    self.isAdTrackingEnabled = [BNCSystemObserver adTrackingSafe];

    //  Get the locale info --
    CGFloat systemVersion = [UIDevice currentDevice].systemVersion.floatValue;
    if (systemVersion < 9.0) {

        self.language = [[NSLocale preferredLanguages] firstObject];
        NSString *rawLocale = [NSLocale currentLocale].localeIdentifier;
        NSRange range = [rawLocale rangeOfString:@"_"];
        if (range.location != NSNotFound) {
            range = NSMakeRange(range.location+1, rawLocale.length-range.location-1);
            self.country = [rawLocale substringWithRange:range];
        }

    } else if (systemVersion < 10.0) {

        NSString *rawLanguage = [[NSLocale preferredLanguages] firstObject];
        NSDictionary *languageDictionary = [NSLocale componentsFromLocaleIdentifier:rawLanguage];
        self.country = [languageDictionary objectForKey:@"kCFLocaleCountryCodeKey"];
        self.language = [languageDictionary  objectForKey:@"kCFLocaleLanguageCodeKey"];

    } else {

        NSLocale *locale = [NSLocale currentLocale];
        self.country = [locale countryCode];
        self.language = [locale languageCode ];

    }

    static NSString* browserUserAgentString = nil;

    void (^setUpBrowserUserAgent)() = ^() {
        browserUserAgentString =
            [[[UIWebView alloc]
              initWithFrame:CGRectZero]
                stringByEvaluatingJavaScriptFromString:@"navigator.userAgent"];
        self.browserUserAgent = browserUserAgentString;
    };

    @synchronized (self.class) {
        if (browserUserAgentString) {
            self.browserUserAgent = browserUserAgentString;
        } else if (NSThread.isMainThread) {
            setUpBrowserUserAgent();
        } else {
            dispatch_sync(dispatch_get_main_queue(), setUpBrowserUserAgent);
        }
    }

    return self;
}

@end
