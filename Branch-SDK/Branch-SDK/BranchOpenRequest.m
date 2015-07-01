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

@interface BranchOpenRequest ()

@property (assign, nonatomic) BOOL allowInstallParamsToBeCleared;

@end

@implementation BranchOpenRequest

- (id)initWithCallback:(callbackWithStatus)callback {
    return [self initWithCallback:callback allowInstallParamsToBeCleared:NO];
}

- (id)initWithCallback:(callbackWithStatus)callback allowInstallParamsToBeCleared:(BOOL)allowInstallParamsToBeCleared {
    if (self = [super init]) {
        _callback = callback;
        _allowInstallParamsToBeCleared = allowInstallParamsToBeCleared;
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
    [self safeSetValue:[BNCSystemObserver getAppVersion] forKey:BRANCH_REQUEST_KEY_APP_VERSION onDict:params];
    [self safeSetValue:[BNCSystemObserver getOS] forKey:BRANCH_REQUEST_KEY_OS onDict:params];
    [self safeSetValue:[BNCSystemObserver getOSVersion] forKey:BRANCH_REQUEST_KEY_OS_VERSION onDict:params];
    [self safeSetValue:[BNCSystemObserver getDefaultUriScheme] forKey:BRANCH_REQUEST_KEY_URI_SCHEME onDict:params];
    [self safeSetValue:[BNCSystemObserver getUpdateState] forKey:BRANCH_REQUEST_KEY_UPDATE onDict:params];
    [self safeSetValue:preferenceHelper.linkClickIdentifier forKey:BRANCH_REQUEST_KEY_LINK_IDENTIFIER onDict:params];
    
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
    preferenceHelper.deviceFingerprintID = data[BRANCH_RESPONSE_KEY_DEVICE_FINGERPRINT_ID];
    preferenceHelper.userUrl = data[BRANCH_RESPONSE_KEY_USER_URL];
    preferenceHelper.userIdentity = data[BRANCH_RESPONSE_KEY_DEVELOPER_IDENTITY];
    preferenceHelper.sessionID = data[BRANCH_RESPONSE_KEY_SESSION_ID];
    [BNCSystemObserver setUpdateState];
    
    NSString *sessionData = data[BRANCH_RESPONSE_KEY_SESSION_DATA];
    
    // Update session params
    preferenceHelper.sessionParams = sessionData;
    
    // If referable, also se tup install params
    if (preferenceHelper.isReferrable) {
        // If present, set it.
        if (sessionData) {
            preferenceHelper.installParams = sessionData;
        }
        // If not present, only allow nil to be set if desired (don't clear otherwise)
        else if (self.allowInstallParamsToBeCleared) {
            preferenceHelper.installParams = nil;
        }
    }
    
    // Clear link click so it doesn't get reused on the next open
    preferenceHelper.linkClickIdentifier = nil;
    
    if (data[BRANCH_RESPONSE_KEY_BRANCH_IDENTITY]) {
        preferenceHelper.identityID = data[BRANCH_RESPONSE_KEY_BRANCH_IDENTITY];
    }
    
    if (self.callback) {
        self.callback(YES, nil);
    }
}

@end
