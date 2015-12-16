//
//  BranchOpenRequest.m
//  Branch-TestBed
//
//  Created by Graham Mueller on 5/26/15.
//  Copyright (c) 2015 Branch Metrics. All rights reserved.
//

#import "BranchOpenRequest.h"
#import "BNCPreferenceHelper.h"
#import "BNCSystemObserver.h"
#import "BranchConstants.h"
#import "BNCEncodingUtils.h"

@interface BranchOpenRequest ()

@property (assign, nonatomic) BOOL isInstall;

@end

@implementation BranchOpenRequest

- (id)initWithCallback:(callbackWithStatus)callback {
    return [self initWithCallback:callback isInstall:NO];
}

- (id)initWithCallback:(callbackWithStatus)callback isInstall:(BOOL)isInstall {
    if (self = [super init]) {
        _callback = callback;
        _isInstall = isInstall;
    }
    
    return self;
}

- (void)makeRequest:(BNCServerInterface *)serverInterface key:(NSString *)key callback:(BNCServerCallback)callback {
    NSMutableDictionary *params = [[NSMutableDictionary alloc] init];
    
    BNCPreferenceHelper *preferenceHelper = [BNCPreferenceHelper preferenceHelper];
    if (!preferenceHelper.deviceFingerprintID) {
        BOOL isRealHardwareId;
        NSString *hardwareId = [BNCSystemObserver getUniqueHardwareId:&isRealHardwareId andIsDebug:preferenceHelper.isDebug];
        if (hardwareId) {
            params[BRANCH_REQUEST_KEY_HARDWARE_ID] = hardwareId;
            params[BRANCH_REQUEST_KEY_IS_HARDWARE_ID_REAL] = @(isRealHardwareId);
        }
    }
    else {
        params[BRANCH_REQUEST_KEY_DEVICE_FINGERPRINT_ID] = preferenceHelper.deviceFingerprintID;
    }

    params[BRANCH_REQUEST_KEY_BRANCH_IDENTITY] = preferenceHelper.identityID;
    params[BRANCH_REQUEST_KEY_AD_TRACKING_ENABLED] = @([BNCSystemObserver adTrackingSafe]);
    params[BRANCH_REQUEST_KEY_IS_REFERRABLE] = @(preferenceHelper.isReferrable);
    params[BRANCH_REQUEST_KEY_DEBUG] = @(preferenceHelper.isDebug);

    [self safeSetValue:[BNCSystemObserver getBundleID] forKey:BRANCH_REQUEST_KEY_BUNDLE_ID onDict:params];
    [self safeSetValue:[BNCSystemObserver getTeamIdentifier] forKey:BRANCH_REQUEST_KEY_TEAM_ID onDict:params];
    [self safeSetValue:[BNCSystemObserver getAppVersion] forKey:BRANCH_REQUEST_KEY_APP_VERSION onDict:params];
    [self safeSetValue:[BNCSystemObserver getOS] forKey:BRANCH_REQUEST_KEY_OS onDict:params];
    [self safeSetValue:[BNCSystemObserver getOSVersion] forKey:BRANCH_REQUEST_KEY_OS_VERSION onDict:params];
    [self safeSetValue:[BNCSystemObserver getDefaultUriScheme] forKey:BRANCH_REQUEST_KEY_URI_SCHEME onDict:params];
    [self safeSetValue:[BNCSystemObserver getUpdateState] forKey:BRANCH_REQUEST_KEY_UPDATE onDict:params];
    [self safeSetValue:preferenceHelper.linkClickIdentifier forKey:BRANCH_REQUEST_KEY_LINK_IDENTIFIER onDict:params];
    [self safeSetValue:preferenceHelper.spotlightIdentifier forKey:BRANCH_REQUEST_KEY_SPOTLIGHT_IDENTIFIER onDict:params];
    [self safeSetValue:preferenceHelper.universalLinkUrl forKey:BRANCH_REQUEST_KEY_UNIVERSAL_LINK_URL onDict:params];
    [self safeSetValue:preferenceHelper.externalIntentURI forKey:BRANCH_REQUEST_KEY_EXTERNAL_INTENT_URI onDict:params];
    [serverInterface postRequest:params url:[preferenceHelper getAPIURL:BRANCH_REQUEST_ENDPOINT_OPEN] key:key callback:callback];
}

- (void)safeSetValue:(NSObject *)value forKey:(NSString *)key onDict:(NSMutableDictionary *)dict {
    if (value) {
        dict[key] = value;
    }
}

- (void)processResponse:(BNCServerResponse *)response error:(NSError *)error {
    if (error) {
        if (self.callback) {
            self.callback(NO, error);
        }
        return;
    }
    
    BNCPreferenceHelper *preferenceHelper = [BNCPreferenceHelper preferenceHelper];

    NSDictionary *data = response.data;

    // Handle possibly mis-parsed identity.
    id userIdentity = data[BRANCH_RESPONSE_KEY_DEVELOPER_IDENTITY];
    if ([userIdentity isKindOfClass:[NSNumber class]]) {
        userIdentity = [userIdentity stringValue];
    }

    preferenceHelper.deviceFingerprintID = data[BRANCH_RESPONSE_KEY_DEVICE_FINGERPRINT_ID];
    preferenceHelper.userUrl = data[BRANCH_RESPONSE_KEY_USER_URL];
    preferenceHelper.userIdentity = userIdentity;
    preferenceHelper.sessionID = data[BRANCH_RESPONSE_KEY_SESSION_ID];

    [BNCSystemObserver setUpdateState];
    
    NSString *sessionData = data[BRANCH_RESPONSE_KEY_SESSION_DATA];
    
    // Update session params
    preferenceHelper.sessionParams = sessionData;
    
    // Scenarios:
    // If no data, data isn't from a link click, or isReferrable is false, don't set, period.
    // Otherwise,
    // * On Install: set.
    // * On Open and installParams set: don't set.
    // * On Open and stored installParams are empty: set.
    if (sessionData.length && preferenceHelper.isReferrable) {
        NSDictionary *sessionDataDict = [BNCEncodingUtils decodeJsonStringToDictionary:sessionData];
        BOOL dataIsFromALinkClick = [sessionDataDict[BRANCH_RESPONSE_KEY_CLICKED_BRANCH_LINK] isEqual:@1];
        BOOL storedParamsAreEmpty = !preferenceHelper.installParams.length;

        if (dataIsFromALinkClick && (self.isInstall || storedParamsAreEmpty)) {
            preferenceHelper.installParams = sessionData;
        }
    }
    
    // Clear link identifiers so they don't get reused on the next open
    preferenceHelper.linkClickIdentifier = nil;
    preferenceHelper.spotlightIdentifier = nil;
    preferenceHelper.universalLinkUrl = nil;
    preferenceHelper.externalIntentURI = nil;
    
    if (data[BRANCH_RESPONSE_KEY_BRANCH_IDENTITY]) {
        preferenceHelper.identityID = data[BRANCH_RESPONSE_KEY_BRANCH_IDENTITY];
    }
    
    if (self.callback) {
        self.callback(YES, nil);
    }
}

@end
