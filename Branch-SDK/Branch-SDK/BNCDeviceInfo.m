//
//  BNCDeviceInfo.m
//  Branch-TestBed
//
//  Created by Sojan P.R. on 3/22/16.
//  Copyright © 2016 Branch Metrics. All rights reserved.
//


#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import <sys/sysctl.h>
#import "BNCDeviceInfo.h"
#import "BNCPreferenceHelper.h"
#import "BNCSystemObserver.h"
#import "BNCXcode7Support.h"
#import "BNCLog.h"


@interface BNCDeviceInfo()
@end


@implementation BNCDeviceInfo {
    NSString * volatile _vendorId;
}

+ (BNCDeviceInfo *)getInstance {
    static BNCDeviceInfo *bnc_deviceInfo = 0;
    static dispatch_once_t onceToken = 0;
    dispatch_once(&onceToken, ^{
        bnc_deviceInfo = [[BNCDeviceInfo alloc] init];
    });
    return bnc_deviceInfo;
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
        _hardwareId = hardwareId.copy;
        _isRealHardwareId = isRealHardwareId;
        _hardwareIdType = hardwareIdType.copy;
    }

    _brandName = [BNCSystemObserver getBrand].copy;
    _modelName = [BNCSystemObserver getModel].copy;
    _osName = [BNCSystemObserver getOS].copy;
    _osVersion = [BNCSystemObserver getOSVersion].copy;
    _screenWidth = [BNCSystemObserver getScreenWidth].copy;
    _screenHeight = [BNCSystemObserver getScreenHeight].copy;
    _isAdTrackingEnabled = [BNCSystemObserver adTrackingSafe];

    _country = [BNCDeviceInfo bnc_country].copy;
    _language = [BNCDeviceInfo bnc_language].copy;
    _browserUserAgent = [BNCDeviceInfo userAgentString].copy;
    return self;
}

- (NSString *)vendorId {
    @synchronized (self) {
        if (_vendorId) return _vendorId;
        /*
         * https://developer.apple.com/documentation/uikit/uidevice/1620059-identifierforvendor
         * BNCSystemObserver.getVendorId is based on UIDevice.identifierForVendor. Note from the
         * docs above:
         *
         * If the value is nil, wait and get the value again later. This happens, for example,
         * after the device has been restarted but before the user has unlocked the device.
         *
         * It's not clear if that specific example scenario would apply to opening Branch links,
         * but this lazy initialization is probably safer.
         */
        _vendorId = [BNCSystemObserver getVendorId].copy;
        return _vendorId;
    }
}

+ (NSString*) bnc_country {

    NSString *country = nil;
    #define returnIfValidCountry() \
        if ([country isKindOfClass:[NSString class]] && country.length) { \
            return country; \
        } else { \
            country = nil; \
        }

    // Should work on iOS 10
    NSLocale *currentLocale = [NSLocale currentLocale];
    if ([currentLocale respondsToSelector:@selector(countryCode)]) {
        country = [currentLocale countryCode];
    }
    returnIfValidCountry();

    // Should work on iOS 9
    NSString *rawLanguage = [[NSLocale preferredLanguages] firstObject];
    NSDictionary *languageDictionary = [NSLocale componentsFromLocaleIdentifier:rawLanguage];
    country = [languageDictionary objectForKey:@"kCFLocaleCountryCodeKey"];
    returnIfValidCountry();

    // Should work on iOS 8 and below.
    //NSString* language = [[NSLocale preferredLanguages] firstObject];
    NSString *rawLocale = currentLocale.localeIdentifier;
    NSRange range = [rawLocale rangeOfString:@"_"];
    if (range.location != NSNotFound) {
        range = NSMakeRange(range.location+1, rawLocale.length-range.location-1);
        country = [rawLocale substringWithRange:range];
    }
    returnIfValidCountry();

    #undef returnIfValidCountry

    return nil;
}

+ (NSString*) bnc_language {

    NSString *language = nil;
    #define returnIfValidLanguage() \
        if ([language isKindOfClass:[NSString class]] && language.length) { \
            return language; \
        } else { \
            language = nil; \
        } \

    // Should work on iOS 10
    NSLocale *currentLocale = [NSLocale currentLocale];
    if ([currentLocale respondsToSelector:@selector(languageCode)]) {
        language = [currentLocale languageCode];
    }
    returnIfValidLanguage();

    // Should work on iOS 9
    NSString *rawLanguage = [[NSLocale preferredLanguages] firstObject];
    NSDictionary *languageDictionary = [NSLocale componentsFromLocaleIdentifier:rawLanguage];
    language = [languageDictionary  objectForKey:@"kCFLocaleLanguageCodeKey"];
    returnIfValidLanguage();

    // Should work on iOS 8 and below.
    language = [[NSLocale preferredLanguages] firstObject];
    returnIfValidLanguage();

    #undef returnIfValidLanguage

    return nil;
}

+ (NSString*) systemBuildVersion {
    int mib[2] = { CTL_KERN, KERN_OSVERSION };
    u_int namelen = sizeof(mib) / sizeof(mib[0]);

    //	Get the size for the buffer --

    size_t bufferSize = 0;
    sysctl(mib, namelen, NULL, &bufferSize, NULL, 0);
	if (bufferSize <= 0) return nil;

    u_char buildBuffer[bufferSize];
    int result = sysctl(mib, namelen, buildBuffer, &bufferSize, NULL, 0);

	NSString *version = nil;
    if (result >= 0) {
        version = [[NSString alloc]
            initWithBytes:buildBuffer
            length:bufferSize-1
            encoding:NSUTF8StringEncoding];
    }
    return version;
}

+ (NSString*) userAgentString {
    
    static NSString* brn_browserUserAgentString = nil;

    void (^setBrowserUserAgent)(void) = ^() {
        @synchronized (self) {
            if (!brn_browserUserAgentString) {
                brn_browserUserAgentString =
                    [[[UIWebView alloc]
                      initWithFrame:CGRectZero]
                        stringByEvaluatingJavaScriptFromString:@"navigator.userAgent"];
                BNCPreferenceHelper *preferences = [BNCPreferenceHelper preferenceHelper];
                preferences.browserUserAgentString = brn_browserUserAgentString;
                preferences.lastSystemBuildVersion = self.systemBuildVersion;
                BNCLogDebugSDK(@"userAgentString: '%@'.", brn_browserUserAgentString);
            }
        }
	};

    NSString* (^browserUserAgent)(void) = ^ NSString* () {
        @synchronized (self) {
            return brn_browserUserAgentString;
        }
    };

    @synchronized (self) {
        //	We only get the string once per app run:

        if (brn_browserUserAgentString)
            return brn_browserUserAgentString;

        //  Did we cache it?

        BNCPreferenceHelper *preferences = [BNCPreferenceHelper preferenceHelper];
        if (preferences.browserUserAgentString &&
            preferences.lastSystemBuildVersion &&
            [preferences.lastSystemBuildVersion isEqualToString:self.systemBuildVersion]) {
            brn_browserUserAgentString = [preferences.browserUserAgentString copy];
            return brn_browserUserAgentString;
        }

        //	Make sure this executes on the main thread.
        //	Uses an implied lock through dispatch_queues:  This can deadlock if mis-used!

        if (NSThread.isMainThread) {
            setBrowserUserAgent();
            return brn_browserUserAgentString;
        }

        //  Different case for iOS 7.0:
        if ([UIDevice currentDevice].systemVersion.floatValue  < 8.0) {
            BNCLogDebugSDK(@"Getting iOS 7 UserAgent.");
            dispatch_sync(dispatch_get_main_queue(), ^ {
                setBrowserUserAgent();
            });
            BNCLogDebugSDK(@"Got iOS 7 UserAgent.");            
            return brn_browserUserAgentString;
        }
    }

    //	Wait and yield to prevent deadlock:

    int retries = 10;
    int64_t timeoutDelta = (dispatch_time_t)((long double)NSEC_PER_SEC * (long double)0.100);
    while (!browserUserAgent() && retries > 0) {

        dispatch_block_t agentBlock = dispatch_block_create_with_qos_class(
            DISPATCH_BLOCK_DETACHED | DISPATCH_BLOCK_ENFORCE_QOS_CLASS,
            QOS_CLASS_USER_INTERACTIVE,
            0,  ^ {
                BNCLogDebugSDK(@"Will set userAgent.");
                setBrowserUserAgent();
                BNCLogDebugSDK(@"Did set userAgent.");
            });
        dispatch_async(dispatch_get_main_queue(), agentBlock);

        dispatch_time_t timeoutTime = dispatch_time(DISPATCH_TIME_NOW, timeoutDelta);
        dispatch_block_wait(agentBlock, timeoutTime);
        retries--;
    }
    BNCLogDebugSDK(@"Retries: %d", 10-retries);

    return browserUserAgent();
}

@end
