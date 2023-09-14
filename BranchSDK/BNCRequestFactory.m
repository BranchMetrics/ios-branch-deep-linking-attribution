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

@interface BNCRequestFactory()

@property (nonatomic, strong, readwrite) NSString *branchKey;

// Data sources singletons, makes it easier to mock them out for testing
@property (nonatomic, strong, readwrite) BNCDeviceInfo *deviceInfo;
@property (nonatomic, strong, readwrite) BNCPreferenceHelper *preferenceHelper;
@property (nonatomic, strong, readwrite) BNCPartnerParameters *partnerParameters;
@property (nonatomic, strong, readwrite) BNCApplication *application;
@property (nonatomic, strong, readwrite) BNCAppGroupsData *appGroupsData;
@property (nonatomic, strong, readwrite) BNCSKAdNetwork *skAdNetwork;
@property (nonatomic, strong, readwrite) BNCAppleReceipt *appleReceipt;

@end

/**
 BNCRequestFactory
 
 Collates general device and app data for request JSONs.
 Enforces privacy controls on data within request JSONs.
 */
@implementation BNCRequestFactory

- (instancetype)initWithBranchKey:(NSString *)key {
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
    }
    return self;
}

// SDK level tracking control
// When set to YES, only link creation and resolution calls are allowed.
// NO by default.
- (BOOL)isTrackingDisabled {
    return Branch.trackingDisabled;
}

- (NSDictionary *)dataForInstall {
    NSMutableDictionary *json = [NSMutableDictionary new];
    
    // All requests
    [self addDefaultRequestDataToJSON:json];
        
    // All POST requests
    [self addInstrumentationToJSON:json];
    
    // Install, Open and Event
    [self addMetadataWithSKANWindowToJSON:json];
    
    // All POST requests other than Events
    [self addSDKVersionToJSON:json];
    [self addV1DictionaryToJSON:json];
    
    // Install and Open
    [self addDeveloperUserIDToJSON:json];
    [self addSystemObserverDataToJSON:json];
    [self addPreferenceHelperDataToJSON:json];
    [self addPartnerParametersToJSON:json];
    [self addAppleReceiptSourceToJSON:json];
    [self addLocalURLToJSON:json];
    [self addTimestampsToJSON:json];
    
    [self addAppleAttributionTokenToJSON:json];

    // Install Only
    [self addAppleReceiptDataToJSON:json];
    [self addAppClipDataToJSON:json];
    
    // TODO: refactor to simply request values for install
    [self addReferringURLsToJSON:json forEndpoint:@"/v1/install"];
    
    return json;
}

- (NSDictionary *)dataForOpen {
    NSMutableDictionary *json = [NSMutableDictionary new];
    
    // All requests
    [self addDefaultRequestDataToJSON:json];
        
    // All POST requests
    [self addInstrumentationToJSON:json];
    
    // Install, Open and Event
    [self addMetadataWithSKANWindowToJSON:json];
    
    // All POST requests other than Events
    [self addSDKVersionToJSON:json];
    [self addV1DictionaryToJSON:json];
    
    // Install and Open
    [self addDeveloperUserIDToJSON:json];
    [self addSystemObserverDataToJSON:json];
    [self addPreferenceHelperDataToJSON:json];
    [self addPartnerParametersToJSON:json];
    [self addAppleReceiptSourceToJSON:json];
    [self addLocalURLToJSON:json];
    [self addTimestampsToJSON:json];
    
    // Usually sent with install, but retry on open if it didn't get sent
    [self addAppleAttributionTokenToJSON:json];
    
    // Only for opens
    [self addOpenTokensToJSON:json];
    
    // TODO: refactor to simply request values for open
    [self addReferringURLsToJSON:json forEndpoint:@"/v1/open"];
    
    return json;
}

// The event data dictionary is NOT checked
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
    [self addMetadataWithSKANWindowToJSON:json];
    
    // Event and LATD
    [self addV2DictionaryToJSON:json];
    
    // TODO: refactor to simply request values for event
    [self addReferringURLsToJSON:json forEndpoint:@"/v2/event"];
    
    return json;
}

// The short URL link data dictionary is NOT checked
- (NSDictionary *)dataForShortURLWithLinkDataDictionary:(NSMutableDictionary *)dictionary isSpotlightRequest:(BOOL)isSpotlightRequest {
    NSMutableDictionary *json = dictionary ? dictionary : [NSMutableDictionary new];
    
    // All requests
    [self addDefaultRequestDataToJSON:json];
        
    // All POST requests
    [self addInstrumentationToJSON:json];
    
    // All POST requests other than Events
    [self addSDKVersionToJSON:json];
    
    // TODO: is this required? Confirm with server team that we can remove this?
    [self addV1DictionaryToJSON:json];
    
    // TODO: metadata is very likely dropped at server
    [self addMetadataToJSON:json];
    
    // TODO: These are optional fields in the server code. Is there value in sending it?
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
    
    // TODO: likely a subset of the V2 dictionary is sufficient, should we minimize it
    [self addV2DictionaryToJSON:json];

    // TODO: probably remove this, this is a pull request
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

    [self safeSetValue:[NSNumber numberWithBool:self.preferenceHelper.checkedFacebookAppLinks] forKey:BRANCH_REQUEST_KEY_CHECKED_FACEBOOK_APPLINKS onDict:json];
    [self safeSetValue:self.preferenceHelper.linkClickIdentifier forKey:BRANCH_REQUEST_KEY_LINK_IDENTIFIER onDict:json];
    [self safeSetValue:self.preferenceHelper.spotlightIdentifier forKey:BRANCH_REQUEST_KEY_SPOTLIGHT_IDENTIFIER onDict:json];
    [self safeSetValue:self.preferenceHelper.universalLinkUrl forKey:BRANCH_REQUEST_KEY_UNIVERSAL_LINK_URL onDict:json];
    [self safeSetValue:self.preferenceHelper.initialReferrer forKey:BRANCH_REQUEST_KEY_INITIAL_REFERRER onDict:json];
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

- (void)addPartnerParametersToJSON:(NSMutableDictionary *)json {
    NSDictionary *partnerParameters = [[BNCPartnerParameters shared] parameterJson];
    if (partnerParameters.count > 0) {
        [self safeSetValue:partnerParameters forKey:BRANCH_REQUEST_KEY_PARTNER_PARAMETERS onDict:json];
    }
}

// NativeLink URL
// TODO: isn't this install only? Why was this code in the open request code? Bad inheritance design?
- (BOOL)addLocalURLToJSON:(NSMutableDictionary *)json {
    if (@available(iOS 16.0, macCatalyst 16.0, *)) {
        NSString *localURLString = [[BNCPreferenceHelper sharedInstance] localUrl];
        if(localURLString){
            NSURL *localURL = [[NSURL alloc] initWithString:localURLString];
            if (localURL) {
                [self safeSetValue:localURL.absoluteString forKey:BRANCH_REQUEST_KEY_LOCAL_URL onDict:json];
                // TODO: add logic status logic. Maybe a callback block indicating status?
                //self.clearLocalURL = TRUE;
                return YES;
            }
        }
    }
    return NO;
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
    
    // TODO: can we remove this deprecated update flag?
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
    
    // omit field if value is NO
    if ([self isTrackingDisabled]) {
        json[@"tracking_disabled"] = @(1);
    }
    
    // TODO: does anyone actually use this, it's set for every request
    // omit field if value is NO
//    if ([self isAppExtension]) {
//        json[@"ios_extension"] = @(1);
//    }
}

// event omits this from the top level
- (void)addSDKVersionToJSON:(NSMutableDictionary *)json {
    json[@"sdk"] = [NSString stringWithFormat:@"ios%@", BNC_SDK_VERSION];
}

- (void)addMetadataToJSON:(NSMutableDictionary *)json {
    NSMutableDictionary *metadata = [[NSMutableDictionary alloc] init];
    [metadata bnc_safeAddEntriesFromDictionary:self.preferenceHelper.requestMetadataDictionary];
    
    // TODO: confirm this call does nothing with the new design. copies existing metadata keys
    [metadata bnc_safeAddEntriesFromDictionary:json[BRANCH_REQUEST_KEY_STATE]];
    
    if (metadata.count) {
        json[BRANCH_REQUEST_KEY_STATE] = metadata;
    }
}

// install, open and event requests  include SKAN window within the metadata block
- (void)addMetadataWithSKANWindowToJSON:(NSMutableDictionary *)json {
    NSMutableDictionary *metadata = [[NSMutableDictionary alloc] init];
    [metadata bnc_safeAddEntriesFromDictionary:self.preferenceHelper.requestMetadataDictionary];
    [metadata bnc_safeAddEntriesFromDictionary:json[BRANCH_REQUEST_KEY_STATE]];
    
    [metadata bnc_safeSetObject:[NSString stringWithFormat:@"%f", self.skAdNetwork.maxTimeSinceInstall] forKey:BRANCH_REQUEST_METADATA_KEY_SCANTIME_WINDOW];
    
    if (metadata.count) {
        json[BRANCH_REQUEST_KEY_STATE] = metadata;
    }
}

// TODO: android is looking to remove this, confirm with server team
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
    BNCReferringURLUtility *utility = [BNCReferringURLUtility new];
    NSDictionary *urlQueryParams = [utility referringURLQueryParamsForEndpoint:endpoint];
    [json bnc_safeAddEntriesFromDictionary:urlQueryParams];
}

// install and open
- (void)addDeveloperUserIDToJSON:(NSMutableDictionary *)json {
    [json bnc_safeSetObject:self.preferenceHelper.userIdentity forKey:@"identity"];
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
            [dictionary bnc_safeSetObject:self.deviceInfo.vendorId forKey:@"idfv"];
            [dictionary bnc_safeSetObject:self.deviceInfo.advertiserId forKey:@"idfa"];
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
            
            // hardware id information.  idfa, idfv or random
            NSString *hardwareId = [self.deviceInfo.hardwareId copy];
            NSString *hardwareIdType = [self.deviceInfo.hardwareIdType copy];
            NSNumber *isRealHardwareId = @(self.deviceInfo.isRealHardwareId);
            if (hardwareId != nil && hardwareIdType != nil && isRealHardwareId != nil) {
                dict[BRANCH_REQUEST_KEY_HARDWARE_ID] = hardwareId;
                dict[BRANCH_REQUEST_KEY_HARDWARE_ID_TYPE] = hardwareIdType;
                dict[BRANCH_REQUEST_KEY_IS_HARDWARE_ID_REAL] = isRealHardwareId;
            }

            // idfv is duplicated in the hardware id field when idfa is unavailable
            [self safeSetValue:self.deviceInfo.vendorId forKey:BRANCH_REQUEST_KEY_IOS_VENDOR_ID onDict:dict];
            // idfa is only in the hardware id field
            // [self safeSetValue:deviceInfo.advertiserId forKey:@"idfa" onDict:dict];
            [self safeSetValue:self.deviceInfo.anonId forKey:@"anon_id" onDict:dict];
            
            [self safeSetValue:[self.deviceInfo localIPAddress] forKey:@"local_ip" onDict:dict];
            
            [self safeSetValue:[self.deviceInfo optedInStatus] forKey:BRANCH_REQUEST_KEY_OPTED_IN_STATUS onDict:dict];
            if ([self installDateIsRecent] && [self.deviceInfo isFirstOptIn]) {
                [self safeSetValue:@(self.deviceInfo.isFirstOptIn) forKey:BRANCH_REQUEST_KEY_FIRST_OPT_IN onDict:dict];
                [BNCPreferenceHelper sharedInstance].hasOptedInBefore = YES;
            }
        }
        
        // TODO: if tracking is disabled can we drop most of these?
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

// TODO: consider moving to BNCSystemObserver where the other IDFA code lives
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

// TODO: consider moving to BNCSystemObserver where other NSBundle checks live
- (BOOL)isAppExtension {
    if ([[[NSBundle mainBundle] executablePath] containsString:@".appex/"]) {
        return YES;
    }
    return NO;
}

// Low value helper method, ignores nils. Also redundant with the category on NSMutableDictionary.
- (void)safeSetValue:(NSObject *)value forKey:(NSString *)key onDict:(NSMutableDictionary *)dict {
    if (value) {
        dict[key] = value;
    }
}

@end
