//
//  BNCRequestFactory.m
//  Branch
//
//  Created by Ernest Cho on 8/16/23.
//  Copyright © 2023 Branch, Inc. All rights reserved.
//

#import "BNCRequestFactory.h"

// For privacy setting
#import "Branch.h"

// For SDK version number
#import "BNCConfig.h"

// For request JSON key names
#import "BranchConstants.h"

// Data format utility
#import "BNCEncodingUtils.h"

// nil checked set and copy methods
#import "NSMutableDictionary+Branch.h"

// Data sources
#import "BNCApplication.h"
#import "BNCSystemObserver.h"
#import "BNCPartnerParameters.h"
#import "BNCDeviceInfo.h"
#import "BNCPreferenceHelper.h"
#import "BNCAppleReceipt.h"
#import "BNCAppGroupsData.h"
#import "BNCSKAdNetwork.h"
#import "BNCReferringURLUtility.h"
#import "BNCPasteboard.h"
#import "BNCODMInfoCollector.h"

@interface BNCRequestFactory()

@property (nonatomic, strong, readwrite) NSString *branchKey;

@property (nonatomic, strong, readwrite) BNCDeviceInfo *deviceInfo;
@property (nonatomic, strong, readwrite) BNCPreferenceHelper *preferenceHelper;
@property (nonatomic, strong, readwrite) BNCPartnerParameters *partnerParameters;
@property (nonatomic, strong, readwrite) BNCApplication *application;
@property (nonatomic, strong, readwrite) BNCAppGroupsData *appGroupsData;
@property (nonatomic, strong, readwrite) BNCSKAdNetwork *skAdNetwork;
@property (nonatomic, strong, readwrite) BNCAppleReceipt *appleReceipt;
@property (nonatomic, strong, readwrite) BNCPasteboard *pasteboard;
@property (nonatomic, strong, readwrite) NSNumber *requestCreationTimeStamp;
@property (nonatomic, strong, readwrite) NSString *requestUUID;

@end

@implementation BNCRequestFactory

- (instancetype)initWithBranchKey:(NSString *)key UUID:(NSString *)requestUUID TimeStamp:(NSNumber *)requestTimeStamp {
    self = [super init];
    if (self) {
        self.branchKey = key;
        
        self.deviceInfo = [BNCDeviceInfo getInstance];
        self.preferenceHelper = [BNCPreferenceHelper sharedInstance];
        self.partnerParameters = [BNCPartnerParameters shared];
        self.application = [BNCApplication currentApplication];
        self.appGroupsData = [BNCAppGroupsData shared];
        self.skAdNetwork = [BNCSKAdNetwork sharedInstance];
        self.appleReceipt = [BNCAppleReceipt sharedInstance];
        self.pasteboard = [BNCPasteboard sharedInstance];
        self.requestUUID = requestUUID;
        self.requestCreationTimeStamp = requestTimeStamp;
    }
    return self;
}

// SDK level tracking control
// When set to YES, only link creation and resolution calls are allowed.
// NO by default.
- (BOOL)isTrackingDisabled {
    return Branch.trackingDisabled;
}

- (NSDictionary *)dataForInstallWithURLString:(NSString *)urlString {
    NSMutableDictionary *json = [NSMutableDictionary new];
    
    // All requests
    [self addDefaultRequestDataToJSON:json];
        
    // All POST requests
    [self addInstrumentationToJSON:json];
    
    // Install, Open and Event
    [self addMetadataWithSKANMaxTimeToJSON:json];
    
    // All POST requests other than Events
    [self addSDKVersionToJSON:json];
    [self addV1DictionaryToJSON:json];
    
    // Install and Open
    [self addDeveloperUserIDToJSON:json];
    [self addSystemObserverDataToJSON:json];
    [self addPreferenceHelperDataToJSON:json];
    [self addPartnerParametersToJSON:json];
    [self addAppleReceiptSourceToJSON:json];
    [self addTimestampsToJSON:json];
    
    // Check if the urlString is a valid URL to ensure it's a universal link, not the external intent uri
    if (urlString) {
        NSURL *url = [NSURL URLWithString:urlString];
        if (url && ([url.scheme isEqualToString:@"http"] || [url.scheme isEqualToString:@"https"])) {
            [self safeSetValue:urlString forKey:BRANCH_REQUEST_KEY_UNIVERSAL_LINK_URL onDict:json];
        } else {
            [self safeSetValue:urlString forKey:BRANCH_REQUEST_KEY_EXTERNAL_INTENT_URI onDict:json];
        }
    }
    
    [self addAppleAttributionTokenToJSON:json];

    // Install Only
    [self addAppleReceiptDataToJSON:json];
    [self addAppClipDataToJSON:json];
    [self addLocalURLToInstallJSON:json];
    
    // TODO: refactor to simply request values for install
    [self addReferringURLsToJSON:json forEndpoint:@"/v1/install"];
    
    // Add DMA Compliance Params for Google
    [self addDMAConsentParamsToJSON:json];
    
    [self addConsumerProtectionAttributionLevel:json];
    
    // Add ODM Data if available
    [self addODMInfoToJSON:json];
    
    // Add Enhanced Web UX params
    [self addWebUXParams:json];

    return json;
}

- (NSDictionary *)dataForOpenWithURLString:(NSString *)urlString {
    NSMutableDictionary *json = [NSMutableDictionary new];
    
    // All requests
    [self addDefaultRequestDataToJSON:json];
        
    // All POST requests
    [self addInstrumentationToJSON:json];
    
    // Install, Open and Event
    [self addMetadataWithSKANMaxTimeToJSON:json];
    
    // Open and Event
    [self addSKANWindowToJSON:json];
    
    // All POST requests other than Events
    [self addSDKVersionToJSON:json];
    [self addV1DictionaryToJSON:json];
    
    // Install and Open
    [self addDeveloperUserIDToJSON:json];
    [self addSystemObserverDataToJSON:json];
    [self addPreferenceHelperDataToJSON:json];
    [self addPartnerParametersToJSON:json];
    [self addAppleReceiptSourceToJSON:json];
    [self addTimestampsToJSON:json];
    
    
    // Check if the urlString is a valid URL to ensure it's a universal link, not the external intent uri
    if (urlString) {
        NSURL *url = [NSURL URLWithString:urlString];
        if (url && ([url.scheme isEqualToString:@"http"] || [url.scheme isEqualToString:@"https"])) {
            [self safeSetValue:urlString forKey:BRANCH_REQUEST_KEY_UNIVERSAL_LINK_URL onDict:json];
        } else {
            [self safeSetValue:urlString forKey:BRANCH_REQUEST_KEY_EXTERNAL_INTENT_URI onDict:json];
        }
    }
    
    // Usually sent with install, but retry on open if it didn't get sent
    [self addAppleAttributionTokenToJSON:json];
    
    // Only for opens
    [self addOpenTokensToJSON:json];
    [self addLocalURLToOpenJSON:json];
    
    // TODO: refactor to simply request values for open
    [self addReferringURLsToJSON:json forEndpoint:@"/v1/open"];
    
    // Add DMA Compliance Params for Google
    [self addDMAConsentParamsToJSON:json];
    
    [self addConsumerProtectionAttributionLevel:json];
    
    // Add ODM Data if available
    [self addODMInfoToJSON:json];

    // Add Enhanced Web UX params
    [self addWebUXParams:json];
    
    return json;
}

// The event data dictionary is NOT checked or changed
- (NSDictionary *)dataForEventWithEventDictionary:(NSMutableDictionary *)dictionary {
    
    // Event requests are not valid when tracking is disabled
    if ([self isTrackingDisabled]) {
        return [NSMutableDictionary new];
    }
    
    NSMutableDictionary *json = dictionary ? dictionary : [NSMutableDictionary new];

    // All requests
    [self addDefaultRequestDataToJSON:json];
        
    // All POST requests
    [self addInstrumentationToJSON:json];
    
    // Install, Open and Event
    [self addMetadataWithSKANMaxTimeToJSON:json];

    // Open and Event
    [self addSKANWindowToJSON:json];
    
    // Event and LATD
    [self addV2DictionaryToJSON:json];
    
    // TODO: refactor to simply request values for event
    [self addReferringURLsToJSON:json forEndpoint:@"/v2/event"];
    
    
    return json;
}

// The short URL link data dictionary is NOT checked or changed
- (NSDictionary *)dataForShortURLWithLinkDataDictionary:(NSMutableDictionary *)dictionary isSpotlightRequest:(BOOL)isSpotlightRequest {
    NSMutableDictionary *json = dictionary ? dictionary : [NSMutableDictionary new];
    
    // All requests
    [self addDefaultRequestDataToJSON:json];
        
    // All POST requests
    [self addInstrumentationToJSON:json];
    
    // All POST requests other than Events
    [self addSDKVersionToJSON:json];
    
    // TODO: is this required? Confirm with server team that we can remove this.
    [self addV1DictionaryToJSON:json];
    
    // TODO: metadata is very likely dropped at server. Confirm with server team.
    [self addMetadataToJSON:json];
    
    // TODO: These are optional fields in the server code. Can we drop these as well?
    [self addShortURLTokensToJSON:json isSpotlightRequest:isSpotlightRequest];
    
    return json;
}

- (NSDictionary *)dataForLATDWithDataDictionary:(NSMutableDictionary *)dictionary {
    
    // LATD requests are not valid when tracking is disabled
    if ([self isTrackingDisabled]) {
        return [NSMutableDictionary new];
    }
    
    NSMutableDictionary *json = dictionary ? dictionary : [NSMutableDictionary new];
    
    // All requests
    [self addDefaultRequestDataToJSON:json];
        
    // All POST requests
    [self addInstrumentationToJSON:json];
    
    // All POST requests other than Events
    [self addSDKVersionToJSON:json];
    
    // TODO: likely a subset of the V2 dictionary is sufficient, should we minimize it.
    [self addV2DictionaryToJSON:json];

    // TODO: probably remove this, this is a data pull request and likely does nothing.
    [self addMetadataToJSON:json];
    
    return json;
}

- (void)addOpenTokensToJSON:(NSMutableDictionary *)json {
    // Tokens are not valid when tracking is disabled
    if ([self isTrackingDisabled]) {
        return;
    }
    
    if (self.preferenceHelper.randomizedDeviceToken) {
        json[BRANCH_REQUEST_KEY_RANDOMIZED_DEVICE_TOKEN] = self.preferenceHelper.randomizedDeviceToken;
    }
    json[BRANCH_REQUEST_KEY_RANDOMIZED_BUNDLE_TOKEN] = self.preferenceHelper.randomizedBundleToken;
    
    // TODO: remove if deprecated
    // tmp location, it's only on opens like the tokens but it will probably be deleted
    if (self.preferenceHelper.limitFacebookTracking) {
        json[@"limit_facebook_tracking"] = (__bridge NSNumber*) kCFBooleanTrue;
    }
}

- (void)addShortURLTokensToJSON:(NSMutableDictionary *)json isSpotlightRequest:(BOOL)isSpotlightRequest {
    // Tokens are not valid when tracking is disabled
    if ([self isTrackingDisabled]) {
        return;
    }
    
    json[BRANCH_REQUEST_KEY_RANDOMIZED_DEVICE_TOKEN] = self.preferenceHelper.randomizedDeviceToken;
    if (!isSpotlightRequest) {
        json[BRANCH_REQUEST_KEY_RANDOMIZED_BUNDLE_TOKEN] = self.preferenceHelper.randomizedBundleToken;
    }
    json[BRANCH_REQUEST_KEY_SESSION_ID] = self.preferenceHelper.sessionID;
}

- (void)addPreferenceHelperDataToJSON:(NSMutableDictionary *)json {
    json[BRANCH_REQUEST_KEY_DEBUG] = @(self.preferenceHelper.isDebug);

    [self safeSetValue:self.preferenceHelper.linkClickIdentifier forKey:BRANCH_REQUEST_KEY_LINK_IDENTIFIER onDict:json];
    [self safeSetValue:self.preferenceHelper.spotlightIdentifier forKey:BRANCH_REQUEST_KEY_SPOTLIGHT_IDENTIFIER onDict:json];
    [self safeSetValue:self.preferenceHelper.initialReferrer forKey:BRANCH_REQUEST_KEY_INITIAL_REFERRER onDict:json];
    
    // This was only on opens before, cause it can't exist on install.
    [self safeSetValue:self.preferenceHelper.externalIntentURI forKey:BRANCH_REQUEST_KEY_EXTERNAL_INTENT_URI onDict:json];
}

- (void)addSystemObserverDataToJSON:(NSMutableDictionary *)json {
    [self safeSetValue:[BNCSystemObserver bundleIdentifier] forKey:BRANCH_REQUEST_KEY_BUNDLE_ID onDict:json];
    [self safeSetValue:[BNCSystemObserver teamIdentifier] forKey:BRANCH_REQUEST_KEY_TEAM_ID onDict:json];
    [self safeSetValue:[BNCSystemObserver applicationVersion] forKey:BRANCH_REQUEST_KEY_APP_VERSION onDict:json];
    [self safeSetValue:[BNCSystemObserver defaultURIScheme] forKey:BRANCH_REQUEST_KEY_URI_SCHEME onDict:json];
}

- (void)addAppleReceiptDataToJSON:(NSMutableDictionary *)json {
    [self safeSetValue:[self.appleReceipt installReceipt] forKey:BRANCH_REQUEST_KEY_APPLE_RECEIPT onDict:json];
}

- (void)addAppleReceiptSourceToJSON:(NSMutableDictionary *)json {
    NSNumber *isSandboxReceipt = [NSNumber numberWithBool:[self.appleReceipt isTestFlight]];
    
    // The JSON key name is misleading, really indicates if the receipt is real or a sandbox receipt
    [self safeSetValue:isSandboxReceipt forKey:BRANCH_REQUEST_KEY_APPLE_TESTFLIGHT onDict:json];
}
 
- (void)addAppleAttributionTokenToJSON:(NSMutableDictionary *)json {
    // This value is only sent once usually on install
    if (!self.preferenceHelper.appleAttributionTokenChecked) {
        NSString *appleAttributionToken = [BNCSystemObserver appleAttributionToken];
        if (appleAttributionToken) {
            self.preferenceHelper.appleAttributionTokenChecked = YES;
            [self safeSetValue:appleAttributionToken forKey:BRANCH_REQUEST_KEY_APPLE_ATTRIBUTION_TOKEN onDict:json];
        }
    }
}


- (void)addODMInfoToJSON:(NSMutableDictionary *)json {
#if !TARGET_OS_TV
    if ([[self.preferenceHelper attributionLevel] isEqualToString:BranchAttributionLevelFull]) {
        NSString *odmInfo = [BNCODMInfoCollector instance].odmInfo ;
        if (odmInfo) {
            [self safeSetValue:odmInfo forKey:BRANCH_REQUEST_KEY_ODM_INFO onDict:json];
            NSNumber* odmInitDateInNumberFormat = BNCWireFormatFromDate(self.preferenceHelper.odmInfoInitDate);
            [self safeSetValue:odmInitDateInNumberFormat forKey:BRANCH_REQUEST_KEY_ODM_FIRST_OPEN_TIMESTAMP onDict:json];
        }
    }
#endif
}

- (void)addPartnerParametersToJSON:(NSMutableDictionary *)json {
    // Partner parameters are not valid when tracking is disabled
    if ([self isTrackingDisabled]) {
        return;
    }
    NSDictionary *partnerParameters = [[BNCPartnerParameters shared] parameterJson];
    if (partnerParameters.count > 0) {
        [self safeSetValue:partnerParameters forKey:BRANCH_REQUEST_KEY_PARTNER_PARAMETERS onDict:json];
    }
}

- (void)addDMAConsentParamsToJSON:(NSMutableDictionary *)json {
   
    if([self.preferenceHelper eeaRegionInitialized]){
        [self safeSetValue:@([self.preferenceHelper eeaRegion]) forKey:BRANCH_REQUEST_KEY_DMA_EEA onDict:json];
        [self safeSetValue:@([self.preferenceHelper adPersonalizationConsent]) forKey:BRANCH_REQUEST_KEY_DMA_AD_PEROSALIZATION onDict:json];
        [self safeSetValue:@([self.preferenceHelper adUserDataUsageConsent]) forKey:BRANCH_REQUEST_KEY_DMA_AD_USER_DATA onDict:json];        
    }
}

- (void)addLocalURLToInstallJSON:(NSMutableDictionary *)json {
    if ([BNCPasteboard sharedInstance].checkOnInstall) {
        NSURL *pasteboardURL = nil;
        if (@available(iOS 16.0, macCatalyst 16.0, *)) {
            NSString *localURLString = [self.preferenceHelper localUrl];
            if (localURLString){
                pasteboardURL = [[NSURL alloc] initWithString:localURLString];
            } else {
                pasteboardURL = [[BNCPasteboard sharedInstance] checkForBranchLink];
            }
        } else {
            pasteboardURL = [[BNCPasteboard sharedInstance] checkForBranchLink];
        }

        if (pasteboardURL) {
            [self safeSetValue:pasteboardURL.absoluteString forKey:BRANCH_REQUEST_KEY_LOCAL_URL onDict:json];
            [self clearLocalURLFromStorage];
        }
    }
}

// If the client uses a UIPasteControl, force a new open to fetch the payload
- (void)addLocalURLToOpenJSON:(NSMutableDictionary *)json {
    if (@available(iOS 16.0, macCatalyst 16.0, *)) {
        NSString *localURLString = [[BNCPreferenceHelper sharedInstance] localUrl];
        if (localURLString){
            NSURL *pasteboardURL = [[NSURL alloc] initWithString:localURLString];
            if (pasteboardURL) {
                [self safeSetValue:pasteboardURL.absoluteString forKey:BRANCH_REQUEST_KEY_LOCAL_URL onDict:json];
                [self clearLocalURLFromStorage];
            }
        }
    }
}

- (void)clearLocalURLFromStorage {
    self.preferenceHelper.localUrl = nil;
#if !TARGET_OS_TV
    UIPasteboard.generalPasteboard.URL = nil;
#endif
}

- (void)addTimestampsToJSON:(NSMutableDictionary *)json {
    // timestamps are not valid when tracking is disabled
    if ([self isTrackingDisabled]) {
        return;
    }
    
    json[@"lastest_update_time"] = BNCWireFormatFromDate(self.application.currentBuildDate);
    json[@"previous_update_time"] = BNCWireFormatFromDate(self.preferenceHelper.previousAppBuildDate);
    json[@"latest_install_time"] = BNCWireFormatFromDate(self.application.currentInstallDate);
    json[@"first_install_time"] = BNCWireFormatFromDate(self.application.firstInstallDate);
    
    // TODO: can we omit this deprecated update flag?
    json[@"update"] = @(0);
}

// App Clips upgrade data
- (void)addAppClipDataToJSON:(NSMutableDictionary *)json {
    if ([self.appGroupsData loadAppClipData]) {
        [self safeSetValue:self.appGroupsData.bundleID forKey:BRANCH_REQUEST_KEY_APP_CLIP_BUNDLE_ID onDict:json];
        [self safeSetValue:BNCWireFormatFromDate(self.appGroupsData.installDate) forKey:BRANCH_REQUEST_KEY_LATEST_APP_CLIP_INSTALL_TIME onDict:json];
        [self safeSetValue:self.appGroupsData.url forKey:BRANCH_REQUEST_KEY_UNIVERSAL_LINK_URL onDict:json];
        [self safeSetValue:self.appGroupsData.branchToken forKey:BRANCH_REQUEST_KEY_APP_CLIP_RANDOMIZED_DEVICE_TOKEN onDict:json];
        [self safeSetValue:self.appGroupsData.bundleToken forKey:BRANCH_REQUEST_KEY_APP_CLIP_RANDOMIZED_BUNDLE_TOKEN onDict:json];
    }
}

- (void)addDefaultRequestDataToJSON:(NSMutableDictionary *)json {
    json[@"branch_key"] = self.branchKey;
    json[BRANCH_REQUEST_KEY_REQUEST_UUID] = self.requestUUID;
    json[BRANCH_REQUEST_KEY_REQUEST_CREATION_TIME_STAMP] = self.requestCreationTimeStamp;
    
    // omit field if value is NO
    if ([self isTrackingDisabled]) {
        json[@"tracking_disabled"] = @(1);
    }
}

// event omits this from the top level
- (void)addSDKVersionToJSON:(NSMutableDictionary *)json {
    json[@"sdk"] = [NSString stringWithFormat:@"ios%@", BNC_SDK_VERSION];
}

- (void)addMetadataToJSON:(NSMutableDictionary *)json {
    NSMutableDictionary *metadata = [[NSMutableDictionary alloc] init];
    [metadata bnc_safeAddEntriesFromDictionary:self.preferenceHelper.requestMetadataDictionary];
    
    // copies existing metadata keys, believe there's only one pass now so this may be unnecessary
    [metadata bnc_safeAddEntriesFromDictionary:json[BRANCH_REQUEST_KEY_STATE]];
    
    if (metadata.count) {
        json[BRANCH_REQUEST_KEY_STATE] = metadata;
    }
}

// install, open and event requests  include SKAN max time within the metadata block
- (void)addMetadataWithSKANMaxTimeToJSON:(NSMutableDictionary *)json {
    NSMutableDictionary *metadata = [[NSMutableDictionary alloc] init];
    [metadata bnc_safeAddEntriesFromDictionary:self.preferenceHelper.requestMetadataDictionary];
    [metadata bnc_safeAddEntriesFromDictionary:json[BRANCH_REQUEST_KEY_STATE]];
    
    [metadata bnc_safeSetObject:[NSString stringWithFormat:@"%f", self.skAdNetwork.maxTimeSinceInstall] forKey:BRANCH_REQUEST_METADATA_KEY_SCANTIME_WINDOW];
    
    if (metadata.count) {
        json[BRANCH_REQUEST_KEY_STATE] = metadata;
    }
}

// open and event requests include the postback window number
- (void)addSKANWindowToJSON:(NSMutableDictionary *)json {
    if (@available(iOS 16.1, macCatalyst 16.1, *)){
        if (self.preferenceHelper.invokeRegisterApp) {
            int currentWindow = [self.skAdNetwork calculateSKANWindowForTime:[NSDate date]];
            if (currentWindow == BranchSkanWindowFirst){
                json[BRANCH_REQUEST_KEY_SKAN_POSTBACK_INDEX] = BRANCH_REQUEST_KEY_VALUE_POSTBACK_SEQUENCE_INDEX_0;
            } else if (currentWindow == BranchSkanWindowSecond) {
                json[BRANCH_REQUEST_KEY_SKAN_POSTBACK_INDEX] = BRANCH_REQUEST_KEY_VALUE_POSTBACK_SEQUENCE_INDEX_1;
            } else if (currentWindow == BranchSkanWindowThird) {
                json[BRANCH_REQUEST_KEY_SKAN_POSTBACK_INDEX] = BRANCH_REQUEST_KEY_VALUE_POSTBACK_SEQUENCE_INDEX_2;
            }
        }
    }
}

// POST requests include instrumentation
- (void)addInstrumentationToJSON:(NSMutableDictionary *)json {
    NSDictionary *instrumentationDictionary = self.preferenceHelper.instrumentationParameters;
    if (instrumentationDictionary) {
        json[BRANCH_REQUEST_KEY_INSTRUMENTATION] = instrumentationDictionary;
    }
}

// BNCReferringURLUtility requires the endpoint string to determine which query params are applied
- (void)addReferringURLsToJSON:(NSMutableDictionary *)json forEndpoint:(NSString *)endpoint {
    // Not a singleton, but BNCReferringURLUtility does pull from storage
    if ([[self.preferenceHelper attributionLevel] isEqualToString:BranchAttributionLevelFull] ||
        ![self.preferenceHelper attributionLevelInitialized]) {
        BNCReferringURLUtility *utility = [BNCReferringURLUtility new];
        NSDictionary *urlQueryParams = [utility referringURLQueryParamsForEndpoint:endpoint];
        [json bnc_safeAddEntriesFromDictionary:urlQueryParams];
    }
}

// install and open
- (void)addDeveloperUserIDToJSON:(NSMutableDictionary *)json {
    [json bnc_safeSetObject:self.preferenceHelper.userIdentity forKey:@"identity"];
}

- (void)addConsumerProtectionAttributionLevel:(NSMutableDictionary *)json {
    if ([self.preferenceHelper attributionLevelInitialized]) {
        BranchAttributionLevel attributionLevel = [self.preferenceHelper attributionLevel];
        [self safeSetValue:attributionLevel forKey:BRANCH_REQUEST_KEY_CPP_LEVEL onDict:json];
    }
}

// install and open
- (void)addWebUXParams:(NSMutableDictionary *)json {
   if (self.preferenceHelper.uxType) {
       NSMutableDictionary *uxDictionary = [[NSMutableDictionary alloc] init];
       [self safeSetValue:self.preferenceHelper.uxType forKey:BRANCH_REQUEST_KEY_UX_TYPE onDict:uxDictionary];
       NSNumber* urlLoadMsInNumberFormat = BNCWireFormatFromDate(self.preferenceHelper.urlLoadMs);
       [self safeSetValue:urlLoadMsInNumberFormat forKey:BRANCH_REQUEST_KEY_URL_LOAD_MS onDict:uxDictionary];
       [self safeSetValue:uxDictionary forKey:BRANCH_REQUEST_KEY_WEB_LINK_CONTEXT onDict:json];
   }
}


// event
- (void)addV2DictionaryToJSON:(NSMutableDictionary *)json {
    NSDictionary *tmp = [self v2dictionary];
    if (tmp.count > 0) {
        json[@"user_data"] = tmp;
    }
}

- (NSDictionary *)v2dictionary {
    NSMutableDictionary *dictionary = [NSMutableDictionary new];
    @synchronized (self.deviceInfo) {
        [self.deviceInfo checkAdvertisingIdentifier];
        
        BOOL disableAdNetworkCallouts = self.preferenceHelper.disableAdNetworkCallouts;
        if (disableAdNetworkCallouts) {
            dictionary[@"disable_ad_network_callouts"] = [NSNumber numberWithBool:disableAdNetworkCallouts];
        }
        
        if (self.preferenceHelper.isDebug) {
            dictionary[@"unidentified_device"] = @(YES);
        } else {
            BranchAttributionLevel attributionLevel = [self.preferenceHelper attributionLevel];
            
            if ([attributionLevel isEqualToString:BranchAttributionLevelFull] ||
                ![self.preferenceHelper attributionLevelInitialized]) {
                [dictionary bnc_safeSetObject:self.deviceInfo.advertiserId forKey:@"idfa"];
            }

            if (![attributionLevel isEqualToString:BranchAttributionLevelNone] ||
                ![self.preferenceHelper attributionLevelInitialized]) {
                [dictionary bnc_safeSetObject:self.deviceInfo.vendorId forKey:@"idfv"];
            }
        }
        
        [dictionary bnc_safeSetObject:self.deviceInfo.anonId forKey:@"anon_id"];
        [dictionary bnc_safeSetObject:self.deviceInfo.localIPAddress forKey:@"local_ip"];

        [dictionary bnc_safeSetObject:self.deviceInfo.optedInStatus forKey:@"opted_in_status"];

        if (self.preferenceHelper.limitFacebookTracking) {
            dictionary[@"limit_facebook_tracking"] = @(YES);
        }
        [dictionary bnc_safeSetObject:self.deviceInfo.brandName forKey:@"brand"];
        [dictionary bnc_safeSetObject:self.deviceInfo.modelName forKey:@"model"];
        [dictionary bnc_safeSetObject:self.deviceInfo.osName forKey:@"os"];
        [dictionary bnc_safeSetObject:self.deviceInfo.osVersion forKey:@"os_version"];
        [dictionary bnc_safeSetObject:self.deviceInfo.osBuildVersion forKey:@"build"];
        [dictionary bnc_safeSetObject:self.deviceInfo.environment forKey:@"environment"];
        [dictionary bnc_safeSetObject:self.deviceInfo.cpuType forKey:@"cpu_type"];
        [dictionary bnc_safeSetObject:self.deviceInfo.screenScale forKey:@"screen_dpi"];
        [dictionary bnc_safeSetObject:self.deviceInfo.screenHeight forKey:@"screen_height"];
        [dictionary bnc_safeSetObject:self.deviceInfo.screenWidth forKey:@"screen_width"];
        [dictionary bnc_safeSetObject:self.deviceInfo.locale forKey:@"locale"];
        [dictionary bnc_safeSetObject:self.deviceInfo.country forKey:@"country"];
        [dictionary bnc_safeSetObject:self.deviceInfo.language forKey:@"language"];
        [dictionary bnc_safeSetObject:[self.deviceInfo connectionType] forKey:@"connection_type"];
        [dictionary bnc_safeSetObject:[self.deviceInfo userAgentString] forKey:@"user_agent"];

        [dictionary bnc_safeSetObject:[BNCPreferenceHelper sharedInstance].userIdentity forKey:@"developer_identity"];
        
        [dictionary bnc_safeSetObject:[BNCPreferenceHelper sharedInstance].randomizedDeviceToken forKey:@"randomized_device_token"];

        [dictionary bnc_safeSetObject:self.deviceInfo.applicationVersion forKey:@"app_version"];

        [dictionary bnc_safeSetObject:self.deviceInfo.pluginName forKey:@"plugin_name"];
        [dictionary bnc_safeSetObject:self.deviceInfo.pluginVersion forKey:@"plugin_version"];
        dictionary[@"sdk_version"] = BNC_SDK_VERSION;
        dictionary[@"sdk"] = @"ios";
    }

    // Add DMA Compliance Params for Google
    [self addDMAConsentParamsToJSON:dictionary];
    
    [self addConsumerProtectionAttributionLevel:dictionary];
    
    return dictionary;
}

// install, open and latd
- (void)addV1DictionaryToJSON:(NSMutableDictionary *)json {
    [self updateDeviceInfoToMutableDictionary:json];
}

- (void)updateDeviceInfoToMutableDictionary:(NSMutableDictionary *)dict {
    @synchronized (self.deviceInfo) {
        
        // These fields are not necessary for link resolution calls
        if (![self isTrackingDisabled]) {
            [self.deviceInfo checkAdvertisingIdentifier];
            
            // Only include hardware ID fields for Full Attribution Level
            if (([[self.preferenceHelper attributionLevel] isEqualToString:BranchAttributionLevelFull])
                || [self.preferenceHelper attributionLevelInitialized] == false) {
                
                // hardware id information.  idfa, idfv or random
                NSString *hardwareId = [self.deviceInfo.hardwareId copy];
                NSString *hardwareIdType = [self.deviceInfo.hardwareIdType copy];
                NSNumber *isRealHardwareId = @(self.deviceInfo.isRealHardwareId);
       
                if (hardwareId != nil && hardwareIdType != nil && isRealHardwareId != nil) {
                    dict[BRANCH_REQUEST_KEY_HARDWARE_ID] = hardwareId;
                    dict[BRANCH_REQUEST_KEY_HARDWARE_ID_TYPE] = hardwareIdType;
                    dict[BRANCH_REQUEST_KEY_IS_HARDWARE_ID_REAL] = isRealHardwareId;
                }
            }
            
            // Only include hardware ID fields for attribution levels greater than None
            if ([self.preferenceHelper attributionLevel] != BranchAttributionLevelNone) {
                // idfv is duplicated in the hardware id field when idfa is unavailable
                [self safeSetValue:self.deviceInfo.vendorId forKey:BRANCH_REQUEST_KEY_IOS_VENDOR_ID onDict:dict];
            }
            
            [self safeSetValue:self.deviceInfo.anonId forKey:@"anon_id" onDict:dict];
            
            [self safeSetValue:[self.deviceInfo localIPAddress] forKey:@"local_ip" onDict:dict];
            
            [self safeSetValue:[self.deviceInfo optedInStatus] forKey:BRANCH_REQUEST_KEY_OPTED_IN_STATUS onDict:dict];
            if ([self installDateIsRecent] && [self.deviceInfo isFirstOptIn]) {
                [self safeSetValue:@(self.deviceInfo.isFirstOptIn) forKey:BRANCH_REQUEST_KEY_FIRST_OPT_IN onDict:dict];
                [BNCPreferenceHelper sharedInstance].hasOptedInBefore = YES;
            }
        }
        
        [self safeSetValue:self.deviceInfo.osName forKey:BRANCH_REQUEST_KEY_OS onDict:dict];
        [self safeSetValue:self.deviceInfo.osVersion forKey:BRANCH_REQUEST_KEY_OS_VERSION onDict:dict];
        [self safeSetValue:self.deviceInfo.osBuildVersion forKey:@"build" onDict:dict];
        [self safeSetValue:self.deviceInfo.environment forKey:@"environment" onDict:dict];
        [self safeSetValue:self.deviceInfo.locale forKey:@"locale" onDict:dict];
        [self safeSetValue:self.deviceInfo.country forKey:@"country" onDict:dict];
        [self safeSetValue:self.deviceInfo.language forKey:@"language" onDict:dict];
        [self safeSetValue:self.deviceInfo.brandName forKey:BRANCH_REQUEST_KEY_BRAND onDict:dict];
        [self safeSetValue:self.deviceInfo.modelName forKey:BRANCH_REQUEST_KEY_MODEL onDict:dict];
        [self safeSetValue:self.deviceInfo.cpuType forKey:@"cpu_type" onDict:dict];
        [self safeSetValue:self.deviceInfo.screenScale forKey:@"screen_dpi" onDict:dict];
        [self safeSetValue:self.deviceInfo.screenHeight forKey:BRANCH_REQUEST_KEY_SCREEN_HEIGHT onDict:dict];
        [self safeSetValue:self.deviceInfo.screenWidth forKey:BRANCH_REQUEST_KEY_SCREEN_WIDTH onDict:dict];
        
        [self safeSetValue:[self.deviceInfo connectionType] forKey:@"connection_type" onDict:dict];
        [self safeSetValue:[self.deviceInfo userAgentString] forKey:@"user_agent" onDict:dict];
        
        [self safeSetValue:self.deviceInfo.applicationVersion forKey:@"app_version" onDict:dict];
        [self safeSetValue:self.deviceInfo.pluginName forKey:@"plugin_name" onDict:dict];
        [self safeSetValue:self.deviceInfo.pluginVersion forKey:@"plugin_version" onDict:dict];
        
        BOOL disableAdNetworkCallouts = self.preferenceHelper.disableAdNetworkCallouts;
        if (disableAdNetworkCallouts) {
            [dict setObject:[NSNumber numberWithBool:disableAdNetworkCallouts] forKey:@"disable_ad_network_callouts"];
        }
    }
}

// Do not send first_opt_in, if the install is older than 30 days
- (BOOL)installDateIsRecent {
    //NSTimeInterval maxTimeSinceInstall = 60.0;
    NSTimeInterval maxTimeSinceInstall = 0;
    
    if (@available(iOS 16.1, macCatalyst 16.1, *)) {
        maxTimeSinceInstall = 3600.0 * 24.0 * 60; // For SKAN 4.0, The user has 60 days to launch the app.
    } else {
        maxTimeSinceInstall = 3600.0 * 24.0 * 30;
    }
        
    NSDate *now = [NSDate date];
    NSDate *maxDate = [self.application.currentInstallDate dateByAddingTimeInterval:maxTimeSinceInstall];
    
    if ([now compare:maxDate] == NSOrderedDescending) {
        return NO;
    } else {
        return YES;
    }
}

// Low value helper method, ignores nils. Also redundant with the category on NSMutableDictionary.
- (void)safeSetValue:(NSObject *)value forKey:(NSString *)key onDict:(NSMutableDictionary *)dict {
    if (value) {
        dict[key] = value;
    }
}

@end
