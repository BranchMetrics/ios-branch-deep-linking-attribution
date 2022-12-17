//
//  BranchOpenRequest.m
//  Branch-TestBed
//
//  Created by Graham Mueller on 5/26/15.
//  Copyright (c) 2015 Branch Metrics. All rights reserved.
//

#import "BranchOpenRequest.h"
#import "BNCSystemObserver.h"
#import "BranchConstants.h"
#import "BranchContentDiscoveryManifest.h"
#import "BranchContentDiscoverer.h"
#import "NSMutableDictionary+Branch.h"
#import "BNCEncodingUtils.h"
#import "BNCCrashlyticsWrapper.h"
#import "Branch.h"
#import "BNCApplication.h"
#import "BNCAppleReceipt.h"
#import "BNCTuneUtility.h"
#import "BNCSKAdNetwork.h"
#import "BNCAppGroupsData.h"
#import "BNCPartnerParameters.h"

@interface BranchOpenRequest ()
@property (assign, nonatomic) BOOL isInstall;
@end


@implementation BranchOpenRequest

- (id)initWithCallback:(callbackWithStatus)callback {
    return [self initWithCallback:callback isInstall:NO];
}

- (id)initWithCallback:(callbackWithStatus)callback isInstall:(BOOL)isInstall {
    if ((self = [super init])) {
        _callback = callback;
        _isInstall = isInstall;
    }

    return self;
}

- (void)makeRequest:(BNCServerInterface *)serverInterface key:(NSString *)key callback:(BNCServerCallback)callback {
    self.clearLocalURL = FALSE;
    NSMutableDictionary *params = [[NSMutableDictionary alloc] init];

    BNCPreferenceHelper *preferenceHelper = [BNCPreferenceHelper sharedInstance];
    if (preferenceHelper.randomizedDeviceToken) {
        params[BRANCH_REQUEST_KEY_RANDOMIZED_DEVICE_TOKEN] = preferenceHelper.randomizedDeviceToken;
    }

    params[BRANCH_REQUEST_KEY_RANDOMIZED_BUNDLE_TOKEN] = preferenceHelper.randomizedBundleToken;
    params[BRANCH_REQUEST_KEY_DEBUG] = @(preferenceHelper.isDebug);

    [self safeSetValue:[BNCSystemObserver getBundleID] forKey:BRANCH_REQUEST_KEY_BUNDLE_ID onDict:params];
    [self safeSetValue:[BNCSystemObserver getTeamIdentifier] forKey:BRANCH_REQUEST_KEY_TEAM_ID onDict:params];
    [self safeSetValue:[BNCSystemObserver getAppVersion] forKey:BRANCH_REQUEST_KEY_APP_VERSION onDict:params];
    [self safeSetValue:[BNCSystemObserver getDefaultUriScheme] forKey:BRANCH_REQUEST_KEY_URI_SCHEME onDict:params];
    [self safeSetValue:[NSNumber numberWithBool:preferenceHelper.checkedFacebookAppLinks]
        forKey:BRANCH_REQUEST_KEY_CHECKED_FACEBOOK_APPLINKS onDict:params];
    [self safeSetValue:[NSNumber numberWithBool:preferenceHelper.checkedAppleSearchAdAttribution]
        forKey:BRANCH_REQUEST_KEY_CHECKED_APPLE_AD_ATTRIBUTION onDict:params];
    [self safeSetValue:preferenceHelper.linkClickIdentifier forKey:BRANCH_REQUEST_KEY_LINK_IDENTIFIER onDict:params];
    [self safeSetValue:preferenceHelper.spotlightIdentifier forKey:BRANCH_REQUEST_KEY_SPOTLIGHT_IDENTIFIER onDict:params];
    [self safeSetValue:preferenceHelper.universalLinkUrl forKey:BRANCH_REQUEST_KEY_UNIVERSAL_LINK_URL onDict:params];
    [self safeSetValue:preferenceHelper.initialReferrer forKey:BRANCH_REQUEST_KEY_INITIAL_REFERRER onDict:params];
    [self safeSetValue:preferenceHelper.externalIntentURI forKey:BRANCH_REQUEST_KEY_EXTERNAL_INTENT_URI onDict:params];
    if (preferenceHelper.limitFacebookTracking)
        params[@"limit_facebook_tracking"] = (__bridge NSNumber*) kCFBooleanTrue;

    [self safeSetValue:[NSNumber numberWithBool:[[BNCAppleReceipt sharedInstance] isTestFlight]] forKey:BRANCH_REQUEST_KEY_APPLE_TESTFLIGHT onDict:params];
    
    NSMutableDictionary *cdDict = [[NSMutableDictionary alloc] init];
    BranchContentDiscoveryManifest *contentDiscoveryManifest = [BranchContentDiscoveryManifest getInstance];
    [cdDict bnc_safeSetObject:[contentDiscoveryManifest getManifestVersion] forKey:BRANCH_MANIFEST_VERSION_KEY];
    [cdDict bnc_safeSetObject:[BNCSystemObserver getBundleID] forKey:BRANCH_BUNDLE_IDENTIFIER];
    [self safeSetValue:cdDict forKey:BRANCH_CONTENT_DISCOVER_KEY onDict:params];

    if (preferenceHelper.appleSearchAdNeedsSend) {
        NSString *encodedSearchData = nil;
        @try {
            NSData *jsonData = [BNCEncodingUtils encodeDictionaryToJsonData:preferenceHelper.appleSearchAdDetails];
            encodedSearchData = [BNCEncodingUtils base64EncodeData:jsonData];
        } @catch (id) { }
        [self safeSetValue:encodedSearchData
                    forKey:BRANCH_REQUEST_KEY_SEARCH_AD
                    onDict:params];
    }
    
    if (!preferenceHelper.appleAttributionTokenChecked) {
        NSString *appleAttributionToken = [BNCSystemObserver appleAttributionToken];
        if (appleAttributionToken) {
            preferenceHelper.appleAttributionTokenChecked = YES;
            [self safeSetValue:appleAttributionToken forKey:BRANCH_REQUEST_KEY_APPLE_ATTRIBUTION_TOKEN onDict:params];
        }
    }
    
    NSDictionary *partnerParameters = [[BNCPartnerParameters shared] parameterJson];
    if (partnerParameters.count > 0) {
        [self safeSetValue:partnerParameters forKey:BRANCH_REQUEST_KEY_PARTNER_PARAMETERS onDict:params];
    }
        
    if (@available(iOS 16.0, *)) {
        NSString *localURLString = [[BNCPreferenceHelper sharedInstance] localUrl];
        if(localURLString){
            NSURL *localURL = [[NSURL alloc] initWithString:localURLString];
            if (localURL) {
                [self safeSetValue:localURL.absoluteString forKey:BRANCH_REQUEST_KEY_LOCAL_URL onDict:params];
                self.clearLocalURL = TRUE;
            }
        }
    }

    BNCApplication *application = [BNCApplication currentApplication];
    params[@"lastest_update_time"] = BNCWireFormatFromDate(application.currentBuildDate);
    params[@"previous_update_time"] = BNCWireFormatFromDate(preferenceHelper.previousAppBuildDate);
    params[@"latest_install_time"] = BNCWireFormatFromDate(application.currentInstallDate);
    params[@"first_install_time"] = BNCWireFormatFromDate(application.firstInstallDate);
    params[@"update"] = [self.class appUpdateState];

    [serverInterface postRequest:params
        url:[preferenceHelper
        getAPIURL:BRANCH_REQUEST_ENDPOINT_OPEN]
        key:key
        callback:callback];
}

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

+ (NSNumber *)appUpdateState {
    BNCUpdateState update_state = BNCUpdateStateIgnored0;
    if ([BNCTuneUtility isTuneDataPresent]) {
        update_state = BNCUpdateStateTuneMigration;
    }
    return @(update_state);
}

- (void)processResponse:(BNCServerResponse *)response error:(NSError *)error {
    BNCPreferenceHelper *preferenceHelper = [BNCPreferenceHelper sharedInstance];
    if (error && preferenceHelper.dropURLOpen) {
        // Ignore this response from the server. Dummy up a response:
        error = nil;
        response.data = @{
            BRANCH_RESPONSE_KEY_SESSION_DATA: @{
                BRANCH_RESPONSE_KEY_CLICKED_BRANCH_LINK: @0
            }
        };
    } else
    if (error) {
        [BranchOpenRequest releaseOpenResponseLock];
        if (self.callback) {
            self.callback(NO, error);
        }
        return;
    }

    NSDictionary *data = response.data;
    
    // Handle possibly mis-parsed identity.
    id userIdentity = data[BRANCH_RESPONSE_KEY_DEVELOPER_IDENTITY];
    if ([userIdentity isKindOfClass:[NSNumber class]]) {
        userIdentity = [userIdentity stringValue];
    }
    
    if ([data objectForKey:BRANCH_RESPONSE_KEY_RANDOMIZED_DEVICE_TOKEN]) {
        preferenceHelper.randomizedDeviceToken = data[BRANCH_RESPONSE_KEY_RANDOMIZED_DEVICE_TOKEN];
        if (!preferenceHelper.randomizedDeviceToken) {
            // fallback to deprecated name. Fingerprinting was removed long ago, hence the name change.
            preferenceHelper.randomizedDeviceToken = data[@"device_fingerprint_id"];
        }
    }
   
    if (data[BRANCH_RESPONSE_KEY_USER_URL]) {
        preferenceHelper.userUrl = data[BRANCH_RESPONSE_KEY_USER_URL];
    }
    preferenceHelper.userIdentity = userIdentity;
    if ([data objectForKey:BRANCH_RESPONSE_KEY_SESSION_ID])
        preferenceHelper.sessionID = data[BRANCH_RESPONSE_KEY_SESSION_ID];
    preferenceHelper.previousAppBuildDate = [BNCApplication currentApplication].currentBuildDate;

    NSString *sessionData = data[BRANCH_RESPONSE_KEY_SESSION_DATA];
    if (sessionData == nil || [sessionData isKindOfClass:[NSString class]]) {
    } else
    if ([sessionData isKindOfClass:[NSDictionary class]]) {
        BNCLogWarning([NSString stringWithFormat:@"Received session data of type '%@' data is '%@'.",
            NSStringFromClass(sessionData.class), sessionData]);
        sessionData = [BNCEncodingUtils encodeDictionaryToJsonString:(NSDictionary*)sessionData];
    } else
    if ([sessionData isKindOfClass:[NSArray class]]) {
        BNCLogWarning([NSString stringWithFormat:@"Received session data of type '%@' data is '%@'.",
            NSStringFromClass(sessionData.class), sessionData]);
        sessionData = [BNCEncodingUtils encodeArrayToJsonString:(NSArray*)sessionData];
    } else {
        BNCLogError([NSString stringWithFormat:@"Received session data of type '%@' data is '%@'.",
            NSStringFromClass(sessionData.class), sessionData]);
        sessionData = nil;
    }

    // Update session params

    if (preferenceHelper.spotlightIdentifier) {
        NSMutableDictionary *sessionDataDict =
        [NSMutableDictionary dictionaryWithDictionary: [BNCEncodingUtils decodeJsonStringToDictionary:sessionData]];
        NSDictionary *spotlightDic = @{BRANCH_RESPONSE_KEY_SPOTLIGHT_IDENTIFIER:preferenceHelper.spotlightIdentifier};
        [sessionDataDict addEntriesFromDictionary:spotlightDic];
        sessionData = [BNCEncodingUtils encodeDictionaryToJsonString:sessionDataDict];
    }
    
    preferenceHelper.sessionParams = sessionData;

    // Scenarios:
    // If no data, data isn't from a link click, or isReferrable is false, don't set, period.
    // Otherwise,
    // * On Install: set.
    // * On Open and installParams set: don't set.
    if (sessionData.length) {
        NSDictionary *sessionDataDict = [BNCEncodingUtils decodeJsonStringToDictionary:sessionData];
        BOOL dataIsFromALinkClick = [sessionDataDict[BRANCH_RESPONSE_KEY_CLICKED_BRANCH_LINK] isEqual:@1];

        if (dataIsFromALinkClick && self.isInstall) {
            preferenceHelper.installParams = sessionData;
        }
    }

    NSString *referringURL = nil;
    if (preferenceHelper.universalLinkUrl.length) {
        referringURL = preferenceHelper.universalLinkUrl;
    }
    else if (preferenceHelper.externalIntentURI.length) {
        referringURL = preferenceHelper.externalIntentURI;
    }
    else {
        NSDictionary *sessionDataDict = [BNCEncodingUtils decodeJsonStringToDictionary:sessionData];
        NSString *link = sessionDataDict[BRANCH_RESPONSE_KEY_BRANCH_REFERRING_LINK];
        if ([link isKindOfClass:[NSString class]]) {
            if (link.length) {
                referringURL = link;
            }
        }
    }

    // Clear link identifiers so they don't get reused on the next open
    preferenceHelper.checkedFacebookAppLinks = NO;
    preferenceHelper.linkClickIdentifier = nil;
    preferenceHelper.spotlightIdentifier = nil;
    preferenceHelper.universalLinkUrl = nil;
    preferenceHelper.externalIntentURI = nil;
    preferenceHelper.appleSearchAdNeedsSend = NO;
    preferenceHelper.referringURL = referringURL;
    preferenceHelper.dropURLOpen = NO;

    
    NSString *string = BNCStringFromWireFormat(data[BRANCH_RESPONSE_KEY_RANDOMIZED_BUNDLE_TOKEN]);
    if (!string) {
        // fallback to deprecated name. The old name was easily confused with the setIdentity, hence the name change.
        string = BNCStringFromWireFormat(data[@"identity_id"]);
    }
    
    if (string) {
        preferenceHelper.randomizedBundleToken = string;
    }
    
    if (self.clearLocalURL) {
        preferenceHelper.localUrl = nil;
#if !TARGET_OS_TV
        UIPasteboard.generalPasteboard.URL = nil;
#endif
    }
    
    [BranchOpenRequest releaseOpenResponseLock];

    BranchContentDiscoveryManifest *cdManifest = [BranchContentDiscoveryManifest getInstance];
    [cdManifest onBranchInitialised:data withUrl:referringURL];
    if ([cdManifest isCDEnabled]) {
        [[BranchContentDiscoverer getInstance] startDiscoveryTaskWithManifest:cdManifest];
    }
    
    if (self.isInstall) {
        [[BNCAppGroupsData shared] saveAppClipData];
    }
    
    if ([data[BRANCH_RESPONSE_KEY_INVOKE_REGISTER_APP] isKindOfClass:NSNumber.class]) {
        NSNumber *invokeRegister = (NSNumber *)data[BRANCH_RESPONSE_KEY_INVOKE_REGISTER_APP];
        preferenceHelper.invokeRegisterApp = invokeRegister.boolValue;
        if (invokeRegister.boolValue && self.isInstall) {
            if (@available(iOS 16.1, *)){
                NSString *defaultCoarseConValue = [[BNCSKAdNetwork sharedInstance] getCoarseConversionValueFromDataResponse:@{}];
                [[BNCSKAdNetwork sharedInstance] updatePostbackConversionValue:0 coarseValue:defaultCoarseConValue
                    lockWindow:NO completionHandler:^(NSError * _Nullable error) {
                    if (error) {
                        BNCLogError([NSString stringWithFormat:@"Update conversion value failed with error - %@", [error description]]);
                    } else {
                        BNCLogDebug([NSString stringWithFormat:@"Update conversion value was successful for INSTALL Event"]);
                    }
                }];
            } else if (@available(iOS 15.4, *)){
                [[BNCSKAdNetwork sharedInstance] updatePostbackConversionValue:0 completionHandler:^(NSError * _Nullable error) {
                    if (error) {
                        BNCLogError([NSString stringWithFormat:@"Update conversion value failed with error - %@", [error description]]);
                    } else {
                        BNCLogDebug([NSString stringWithFormat:@"Update conversion value was successful for INSTALL Event"]);
                    }
                }];
            }
            else {
                [[BNCSKAdNetwork sharedInstance] registerAppForAdNetworkAttribution];
            }
        }
    } else {
        preferenceHelper.invokeRegisterApp = NO;
    }
    
 
    if (data && [data[BRANCH_RESPONSE_KEY_UPDATE_CONVERSION_VALUE] isKindOfClass:NSNumber.class] && !self.isInstall) {
        NSNumber *conversionValue = (NSNumber *)data[BRANCH_RESPONSE_KEY_UPDATE_CONVERSION_VALUE];
        // Regardless of SKAN opted-in in dashboard, we always get conversionValue, so adding check to find out if install/open response had "invoke_register_app" true
        if (conversionValue && preferenceHelper.invokeRegisterApp ) {
            if (@available(iOS 16.1, *)){
                NSString* coarseConversionValue = [[BNCSKAdNetwork sharedInstance] getCoarseConversionValueFromDataResponse:data] ;
                BOOL lockWin = [[BNCSKAdNetwork sharedInstance] getLockedStatusFromDataResponse:data];
                BOOL shouldCallUpdatePostback = [[BNCSKAdNetwork sharedInstance] shouldCallPostbackForDataResponse:data];
                
                BNCLogDebug([NSString stringWithFormat:@"SKAN 4.0 params - conversionValue:%@ coarseValue:%@, locked:%d, shouldCallPostback:%d, currentWindow:%d, firstAppLaunchTime: %@", conversionValue, coarseConversionValue, lockWin, shouldCallUpdatePostback, (int)preferenceHelper.skanCurrentWindow, preferenceHelper.firstAppLaunchTime]);
                
                if(shouldCallUpdatePostback){
                    [[BNCSKAdNetwork sharedInstance] updatePostbackConversionValue: conversionValue.longValue coarseValue:coarseConversionValue lockWindow:lockWin completionHandler:^(NSError * _Nullable error) {
                        if (error) {
                            BNCLogError([NSString stringWithFormat:@"Update conversion value failed with error - %@", [error description]]);
                        } else {
                            BNCLogDebug([NSString stringWithFormat:@"Update conversion value was successful. Conversion Value - %@", conversionValue]);
                        }
                    }];
                }
            } else if (@available(iOS 15.4, *)) {
                [[BNCSKAdNetwork sharedInstance] updatePostbackConversionValue:conversionValue.intValue completionHandler: ^(NSError *error){
                    if (error) {
                        BNCLogError([NSString stringWithFormat:@"Update conversion value failed with error - %@", [error description]]);
                    } else {
                        BNCLogDebug([NSString stringWithFormat:@"Update conversion value was successful. Conversion Value - %@", conversionValue]);
                    }
                }];
            } else {
                [[BNCSKAdNetwork sharedInstance] updateConversionValue:conversionValue.integerValue];
            }
        }
    }

    
    if (self.callback) {
        self.callback(YES, nil);
    }
}

- (NSString *)getActionName {
    return @"open";
}


#pragma - Open Response Lock Handling


//	Instead of semaphores, the lock is handled by scheduled dispatch_queues.
//	This is the 'new' way to lock and is handled better optimized for iOS.
//	Also, since implied lock is handled by a scheduler and not a hard semaphore it's less error
//	prone.


static dispatch_queue_t openRequestWaitQueue = NULL;
static BOOL openRequestWaitQueueIsSuspended = NO;


+ (void) initialize {
    if (self != [BranchOpenRequest self])
        return;
    openRequestWaitQueue =
        dispatch_queue_create("io.branch.sdk.openqueue", DISPATCH_QUEUE_CONCURRENT);
}

+ (void) setWaitNeededForOpenResponseLock {
    @synchronized (self) {
        if (!openRequestWaitQueueIsSuspended) {
            BNCLogDebugSDK(@"Suspended for openRequestWaitQueue.");
            openRequestWaitQueueIsSuspended = YES;
            dispatch_suspend(openRequestWaitQueue);
        }
    }
}

+ (void) waitForOpenResponseLock {
    BNCLogDebugSDK(@"Waiting for openRequestWaitQueue.");
    dispatch_sync(openRequestWaitQueue, ^ {
        BNCLogDebugSDK(@"Finished waitForOpenResponseLock.");
    });
}

+ (void) releaseOpenResponseLock {
    @synchronized (self) {
        if (openRequestWaitQueueIsSuspended) {
            BNCLogDebugSDK(@"Resuming openRequestWaitQueue.");
            openRequestWaitQueueIsSuspended = NO;
            dispatch_resume(openRequestWaitQueue);
        }
    }
}

@end
