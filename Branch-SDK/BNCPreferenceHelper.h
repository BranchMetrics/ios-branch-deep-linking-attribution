//
//  BNCPreferenceHelper.h
//  Branch-SDK
//
//  Created by Alex Austin on 6/6/14.
//  Copyright (c) 2014 Branch Metrics. All rights reserved.
//

#if __has_feature(modules)
@import Foundation;
#else
#import <Foundation/Foundation.h>
#endif

#define FILE_NAME   [[NSString stringWithUTF8String:__FILE__] lastPathComponent]
#define LINE_NUM    __LINE__

NSURL* /* _Nonnull */ BNCURLForBranchDirectory(void);

@interface BNCPreferenceHelper : NSObject

@property (copy, nonatomic) NSString *lastRunBranchKey;
@property (strong, nonatomic) NSDate   *lastStrongMatchDate;
@property (copy, nonatomic) NSString *appVersion;

@property (copy, nonatomic) NSString *randomizedDeviceToken;
@property (copy, nonatomic) NSString *randomizedBundleToken;

@property (copy, nonatomic) NSString *sessionID;
@property (copy, nonatomic) NSString *linkClickIdentifier;
@property (copy, nonatomic) NSString *spotlightIdentifier;
@property (copy, nonatomic)    NSString *universalLinkUrl;
@property (copy, nonatomic)    NSString *initialReferrer;
@property (copy, nonatomic) NSString *userUrl;
@property (copy, nonatomic) NSString *userIdentity;
@property (copy, nonatomic) NSString *sessionParams;
@property (copy, nonatomic) NSString *installParams;
@property (assign, nonatomic) BOOL isDebug;
@property (assign, nonatomic) BOOL checkedFacebookAppLinks;
@property (assign, nonatomic) BOOL checkedAppleSearchAdAttribution;
@property (nonatomic, assign, readwrite) BOOL appleAttributionTokenChecked;
@property (nonatomic, assign, readwrite) BOOL hasOptedInBefore;
@property (nonatomic, assign, readwrite) BOOL hasCalledHandleATTAuthorizationStatus;
@property (assign, nonatomic) NSInteger retryCount;
@property (assign, nonatomic) NSTimeInterval retryInterval;
@property (assign, nonatomic) NSTimeInterval timeout;
@property (copy, nonatomic)    NSString *externalIntentURI;
@property (strong, nonatomic) NSMutableDictionary *savedAnalyticsData;
@property (strong, nonatomic) NSDictionary *appleSearchAdDetails;
@property (assign, nonatomic) BOOL          appleSearchAdNeedsSend;
@property (copy, nonatomic) NSString *lastSystemBuildVersion;
@property (copy, nonatomic) NSString *browserUserAgentString;
@property (copy, nonatomic) NSString *referringURL;
@property (copy, nonatomic) NSString *branchAPIURL;
@property (assign, nonatomic) BOOL      limitFacebookTracking;
@property (strong, nonatomic) NSDate   *previousAppBuildDate;
@property (assign, nonatomic, readwrite) BOOL disableAdNetworkCallouts;

@property (strong, nonatomic, readwrite) NSURL *faceBookAppLink;

@property (nonatomic, copy, readwrite) NSString *patternListURL;
@property (strong, nonatomic) NSArray<NSString*> *savedURLPatternList;
@property (assign, nonatomic) NSInteger savedURLPatternListVersion;
@property (assign, nonatomic) BOOL dropURLOpen;

@property (assign, nonatomic) BOOL sendCloseRequests;

@property (assign, nonatomic) BOOL trackingDisabled;
- (void) clearTrackingInformation;

+ (BNCPreferenceHelper *)sharedInstance;

- (NSString *)getAPIBaseURL;
- (NSString *)getAPIURL:(NSString *)endpoint;
- (NSString *)getEndpointFromURL:(NSString *)url;

- (void)setRequestMetadataKey:(NSString *)key value:(NSObject *)value;
- (NSMutableDictionary *)requestMetadataDictionary;

- (void)addInstrumentationDictionaryKey:(NSString *)key value:(NSString *)value;
- (NSMutableDictionary *)instrumentationDictionary;
- (NSDictionary *)instrumentationParameters; // a safe copy to use in a POST body
- (void)clearInstrumentationDictionary;

- (void)saveBranchAnalyticsData:(NSDictionary *)analyticsData;
- (void)clearBranchAnalyticsData;
- (NSMutableDictionary *)getBranchAnalyticsData;
- (NSDictionary *)getContentAnalyticsManifest;
- (void)saveContentAnalyticsManifest:(NSDictionary *)cdManifest;

- (NSMutableString*) sanitizedMutableBaseURL:(NSString*)baseUrl;
- (void) synchronize;  //  Flushes preference queue to persistence.
+ (void) clearAll;

@end
