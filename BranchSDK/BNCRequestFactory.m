//
//  BNCRequestFactory.m
//  Branch
//
//  Created by Ernest Cho on 8/16/23.
//  Copyright © 2023 Branch, Inc. All rights reserved.
//

#import "BNCRequestFactory.h"

// consistent date formatting
#import "BNCEncodingUtils.h"

// this should be the only location for shared request building
#import "BranchConstants.h"

// Data sources
#import "BNCApplication.h"
#import "BNCSystemObserver.h"
#import "BNCPartnerParameters.h"
#import "BNCDeviceInfo.h"
#import "BNCPreferenceHelper.h"
#import "BNCTuneUtility.h"
#import "BNCAppleReceipt.h"
#import "BNCAppGroupsData.h"

@interface BNCRequestFactory()
@property (nonatomic, strong, readwrite) BNCPartnerParameters *partnerParameters;

@property (nonatomic, strong, readwrite) BNCDeviceInfo *deviceInfo;
@property (nonatomic, strong, readwrite) BNCPreferenceHelper *preferenceHelper;
@end

@implementation BNCRequestFactory

- (instancetype)init {
    self = [super init];
    if (self) {
        // data sources pulled via singletons
        self.deviceInfo = [BNCDeviceInfo getInstance];
        self.preferenceHelper = [BNCPreferenceHelper sharedInstance];
        self.partnerParameters = [BNCPartnerParameters shared];
    }
    return self;
}

- (NSDictionary *)dataForInstall {
    NSMutableDictionary *json = [NSMutableDictionary new];
    [self addSystemObserverData:json];
    [self addPreferenceHelperData:json];
    [self addPartnerParameters:json];
    [self addAppleReceiptSource:json];
    [self addPartnerParameters:json];
    [self addLocalURL:json];
    [self addTimestamps:json];
    
    // Only for installs
    [self addAppleReceiptData:json];
    [self addAppClipData:json];
    
    return json;
}

- (NSDictionary *)dataForOpen {
    NSMutableDictionary *json = [NSMutableDictionary new];
    [self addSystemObserverData:json];
    [self addPreferenceHelperData:json];
    [self addAppleReceiptSource:json];
    [self addAppleAttributionToken:json];
    [self addPartnerParameters:json];
    [self addLocalURL:json];
    [self addTimestamps:json];
    
    // Only for opens
    [self addOpenTokens:json];
    
    return json;
}

- (void)addOpenTokens:(NSMutableDictionary *)json {
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

- (void)addPreferenceHelperData:(NSMutableDictionary *)json {
    json[BRANCH_REQUEST_KEY_DEBUG] = @(self.preferenceHelper.isDebug);

    [self safeSetValue:[NSNumber numberWithBool:self.preferenceHelper.checkedFacebookAppLinks] forKey:BRANCH_REQUEST_KEY_CHECKED_FACEBOOK_APPLINKS onDict:json];
    [self safeSetValue:self.preferenceHelper.linkClickIdentifier forKey:BRANCH_REQUEST_KEY_LINK_IDENTIFIER onDict:json];
    [self safeSetValue:self.preferenceHelper.spotlightIdentifier forKey:BRANCH_REQUEST_KEY_SPOTLIGHT_IDENTIFIER onDict:json];
    [self safeSetValue:self.preferenceHelper.universalLinkUrl forKey:BRANCH_REQUEST_KEY_UNIVERSAL_LINK_URL onDict:json];
    [self safeSetValue:self.preferenceHelper.initialReferrer forKey:BRANCH_REQUEST_KEY_INITIAL_REFERRER onDict:json];
    [self safeSetValue:self.preferenceHelper.externalIntentURI forKey:BRANCH_REQUEST_KEY_EXTERNAL_INTENT_URI onDict:json];
}

- (void)addSystemObserverData:(NSMutableDictionary *)json {
    [self safeSetValue:[BNCSystemObserver bundleIdentifier] forKey:BRANCH_REQUEST_KEY_BUNDLE_ID onDict:json];
    [self safeSetValue:[BNCSystemObserver teamIdentifier] forKey:BRANCH_REQUEST_KEY_TEAM_ID onDict:json];
    [self safeSetValue:[BNCSystemObserver applicationVersion] forKey:BRANCH_REQUEST_KEY_APP_VERSION onDict:json];
    [self safeSetValue:[BNCSystemObserver defaultURIScheme] forKey:BRANCH_REQUEST_KEY_URI_SCHEME onDict:json];
}

- (void)addAppleReceiptData:(NSMutableDictionary *)json {
    [self safeSetValue:[[BNCAppleReceipt sharedInstance] installReceipt] forKey:BRANCH_REQUEST_KEY_APPLE_RECEIPT onDict:json];
}

- (void)addAppleReceiptSource:(NSMutableDictionary *)json {
    NSNumber *isSandboxReceipt = [NSNumber numberWithBool:[[BNCAppleReceipt sharedInstance] isTestFlight]];
    [self safeSetValue:isSandboxReceipt forKey:BRANCH_REQUEST_KEY_APPLE_TESTFLIGHT onDict:json];
}
 
- (void)addAppleAttributionToken:(NSMutableDictionary *)json {
    if (!self.preferenceHelper.appleAttributionTokenChecked) {
        NSString *appleAttributionToken = [BNCSystemObserver appleAttributionToken];
        if (appleAttributionToken) {
            self.preferenceHelper.appleAttributionTokenChecked = YES;
            [self safeSetValue:appleAttributionToken forKey:BRANCH_REQUEST_KEY_APPLE_ATTRIBUTION_TOKEN onDict:json];
        }
    }
}

- (void)addPartnerParameters:(NSMutableDictionary *)json {
    NSDictionary *partnerParameters = [[BNCPartnerParameters shared] parameterJson];
    if (partnerParameters.count > 0) {
        [self safeSetValue:partnerParameters forKey:BRANCH_REQUEST_KEY_PARTNER_PARAMETERS onDict:json];
    }
}

// NativeLink URL
// TODO: isn't this install only? Why was this code in the open request code? Bad inheritance design?
- (BOOL)addLocalURL:(NSMutableDictionary *)json {
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

- (void)addTimestamps:(NSMutableDictionary *)json {
    BNCApplication *application = [BNCApplication currentApplication];
    json[@"lastest_update_time"] = BNCWireFormatFromDate(application.currentBuildDate);
    json[@"previous_update_time"] = BNCWireFormatFromDate(self.preferenceHelper.previousAppBuildDate);
    json[@"latest_install_time"] = BNCWireFormatFromDate(application.currentInstallDate);
    json[@"first_install_time"] = BNCWireFormatFromDate(application.firstInstallDate);
    json[@"update"] = [self appUpdateState];
}

- (void)addAppClipData:(NSMutableDictionary *)json {
    if ([[BNCAppGroupsData shared] loadAppClipData]) {
        [self safeSetValue:[BNCAppGroupsData shared].bundleID forKey:BRANCH_REQUEST_KEY_APP_CLIP_BUNDLE_ID onDict:json];
        [self safeSetValue:BNCWireFormatFromDate([BNCAppGroupsData shared].installDate) forKey:BRANCH_REQUEST_KEY_LATEST_APP_CLIP_INSTALL_TIME onDict:json];
        [self safeSetValue:[BNCAppGroupsData shared].url forKey:BRANCH_REQUEST_KEY_UNIVERSAL_LINK_URL onDict:json];
        [self safeSetValue:[BNCAppGroupsData shared].branchToken forKey:BRANCH_REQUEST_KEY_APP_CLIP_RANDOMIZED_DEVICE_TOKEN onDict:json];
        [self safeSetValue:[BNCAppGroupsData shared].bundleToken forKey:BRANCH_REQUEST_KEY_APP_CLIP_RANDOMIZED_BUNDLE_TOKEN onDict:json];
    }
}

- (NSMutableDictionary *)v1dictionary:(NSMutableDictionary *)json {
    [self updateDeviceInfoToMutableDictionary:json];
    return json;
}

- (NSMutableDictionary *)v2dictionary:(NSMutableDictionary *)json {
    NSDictionary *tmp = [[BNCDeviceInfo getInstance] v2dictionary];
    [json addEntriesFromDictionary:tmp];
    return json;
}

// This one is pretty awkward, considering leaving this mostly as is
- (NSMutableDictionary *)performanceMetrics:(NSMutableDictionary *)json {
    return json;
}

- (void)updateDeviceInfoToMutableDictionary:(NSMutableDictionary *)dict {
    BNCDeviceInfo *deviceInfo  = [BNCDeviceInfo getInstance];
    @synchronized (deviceInfo) {
        [deviceInfo checkAdvertisingIdentifier];
        
        // hardware id information.  idfa, idfv or random
        NSString *hardwareId = [deviceInfo.hardwareId copy];
        NSString *hardwareIdType = [deviceInfo.hardwareIdType copy];
        NSNumber *isRealHardwareId = @(deviceInfo.isRealHardwareId);
        if (hardwareId != nil && hardwareIdType != nil && isRealHardwareId != nil) {
            dict[BRANCH_REQUEST_KEY_HARDWARE_ID] = hardwareId;
            dict[BRANCH_REQUEST_KEY_HARDWARE_ID_TYPE] = hardwareIdType;
            dict[BRANCH_REQUEST_KEY_IS_HARDWARE_ID_REAL] = isRealHardwareId;
        }

        // idfv is duplicated in the hardware id field when idfa is unavailable
        [self safeSetValue:deviceInfo.vendorId forKey:BRANCH_REQUEST_KEY_IOS_VENDOR_ID onDict:dict];
        // idfa is only in the hardware id field
        // [self safeSetValue:deviceInfo.advertiserId forKey:@"idfa" onDict:dict];
        [self safeSetValue:deviceInfo.anonId forKey:@"anon_id" onDict:dict];
        
        [self safeSetValue:deviceInfo.osName forKey:BRANCH_REQUEST_KEY_OS onDict:dict];
        [self safeSetValue:deviceInfo.osVersion forKey:BRANCH_REQUEST_KEY_OS_VERSION onDict:dict];
        [self safeSetValue:deviceInfo.osBuildVersion forKey:@"build" onDict:dict];
        [self safeSetValue:deviceInfo.environment forKey:@"environment" onDict:dict];
        [self safeSetValue:deviceInfo.locale forKey:@"locale" onDict:dict];
        [self safeSetValue:deviceInfo.country forKey:@"country" onDict:dict];
        [self safeSetValue:deviceInfo.language forKey:@"language" onDict:dict];
        [self safeSetValue:deviceInfo.brandName forKey:BRANCH_REQUEST_KEY_BRAND onDict:dict];
        [self safeSetValue:deviceInfo.modelName forKey:BRANCH_REQUEST_KEY_MODEL onDict:dict];
        [self safeSetValue:deviceInfo.cpuType forKey:@"cpu_type" onDict:dict];
        [self safeSetValue:deviceInfo.screenScale forKey:@"screen_dpi" onDict:dict];
        [self safeSetValue:deviceInfo.screenHeight forKey:BRANCH_REQUEST_KEY_SCREEN_HEIGHT onDict:dict];
        [self safeSetValue:deviceInfo.screenWidth forKey:BRANCH_REQUEST_KEY_SCREEN_WIDTH onDict:dict];
        
        [self safeSetValue:[deviceInfo localIPAddress] forKey:@"local_ip" onDict:dict];
        [self safeSetValue:[deviceInfo connectionType] forKey:@"connection_type" onDict:dict];
        [self safeSetValue:[deviceInfo userAgentString] forKey:@"user_agent" onDict:dict];
        
        [self safeSetValue:[deviceInfo optedInStatus] forKey:BRANCH_REQUEST_KEY_OPTED_IN_STATUS onDict:dict];
        
        if ([self installDateIsRecent] && [deviceInfo isFirstOptIn]) {
            [self safeSetValue:@(deviceInfo.isFirstOptIn) forKey:BRANCH_REQUEST_KEY_FIRST_OPT_IN onDict:dict];
            [BNCPreferenceHelper sharedInstance].hasOptedInBefore = YES;
        }
        
        [self safeSetValue:@(deviceInfo.isAdTrackingEnabled) forKey:BRANCH_REQUEST_KEY_AD_TRACKING_ENABLED onDict:dict];
        
        [self safeSetValue:deviceInfo.applicationVersion forKey:@"app_version" onDict:dict];
        [self safeSetValue:deviceInfo.pluginName forKey:@"plugin_name" onDict:dict];
        [self safeSetValue:deviceInfo.pluginVersion forKey:@"plugin_version" onDict:dict];
        
        BOOL disableAdNetworkCallouts = self.preferenceHelper.disableAdNetworkCallouts;
        if (disableAdNetworkCallouts) {
            [dict setObject:[NSNumber numberWithBool:disableAdNetworkCallouts] forKey:@"disable_ad_network_callouts"];
        }
    }
}

// TODO: consider moving business logic not related to privacy, this is only for installs
// we do not need to send first_opt_in, if the install is older than 30 days
- (BOOL)installDateIsRecent {
    //NSTimeInterval maxTimeSinceInstall = 60.0;
    NSTimeInterval maxTimeSinceInstall = 0;
    
    if (@available(iOS 16.1, macCatalyst 16.1, *)) {
        maxTimeSinceInstall = 3600.0 * 24.0 * 60; // For SKAN 4.0, The user has 60 days to launch the app.
    } else {
        maxTimeSinceInstall = 3600.0 * 24.0 * 30;
    }
        
    NSDate *now = [NSDate date];
    NSDate *maxDate = [[BNCApplication currentApplication].currentInstallDate dateByAddingTimeInterval:maxTimeSinceInstall];
    
    if ([now compare:maxDate] == NSOrderedDescending) {
        return NO;
    } else {
        return YES;
    }
}

// skips nils. Low value helper method
- (void)safeSetValue:(NSObject *)value forKey:(NSString *)key onDict:(NSMutableDictionary *)dict {
    if (value) {
        dict[key] = value;
    }
}

// TODO: consider moving business logic not related to privacy. This is only for installs
typedef NS_ENUM(NSInteger, BNCUpdateState) {
    // Values 0-4 are deprecated and ignored by the server
    BNCUpdateStateIgnored0 = 0,
    BNCUpdateStateIgnored1 = 1,
    BNCUpdateStateIgnored2 = 2,
    BNCUpdateStateIgnored3 = 3,
    BNCUpdateStateIgnored4 = 4,
    
    // App was migrated from Tune SDK to Branch SDK
    BNCUpdateStateTuneMigration = 5
};

- (NSNumber *)appUpdateState {
    BNCUpdateState update_state = BNCUpdateStateIgnored0;
    if ([BNCTuneUtility isTuneDataPresent]) {
        update_state = BNCUpdateStateTuneMigration;
    }
    return @(update_state);
}

@end
