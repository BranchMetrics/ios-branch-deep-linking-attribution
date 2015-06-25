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
    
    NSString *fingerprintId = [BNCPreferenceHelper getDeviceFingerprintID];
    if (!fingerprintId) {
        BOOL isRealHardwareId;
        NSString *hardwareId = [BNCSystemObserver getUniqueHardwareId:&isRealHardwareId andIsDebug:[BNCPreferenceHelper isDebug]];
        if (hardwareId) {
            params[BRANCH_REQUEST_KEY_HARDWARE_ID] = hardwareId;
            params[BRANCH_REQUEST_KEY_IS_HARDWARE_ID_REAL] = @(isRealHardwareId);
        }
    }
    else {
        params[BRANCH_REQUEST_KEY_DEVICE_FINGERPRINT_ID] = fingerprintId;
    }

    params[BRANCH_REQUEST_KEY_BRANCH_IDENTITY] = [BNCPreferenceHelper getIdentityID];
    params[BRANCH_REQUEST_KEY_AD_TRACKING_ENABLED] = @([BNCSystemObserver adTrackingSafe]);
    params[BRANCH_REQUEST_KEY_IS_REFERRABLE] = @([BNCPreferenceHelper getIsReferrable]);
    params[BRANCH_REQUEST_KEY_DEBUG] = @([BNCPreferenceHelper isDebug]);

    [self safeSetValue:[BNCSystemObserver getBundleID] forKey:BRANCH_REQUEST_KEY_BUNDLE_ID onDict:params];
    [self safeSetValue:[BNCSystemObserver getAppVersion] forKey:BRANCH_REQUEST_KEY_APP_VERSION onDict:params];
    [self safeSetValue:[BNCSystemObserver getOS] forKey:BRANCH_REQUEST_KEY_OS onDict:params];
    [self safeSetValue:[BNCSystemObserver getOSVersion] forKey:BRANCH_REQUEST_KEY_OS_VERSION onDict:params];
    [self safeSetValue:[BNCSystemObserver getDefaultUriScheme] forKey:BRANCH_REQUEST_KEY_URI_SCHEME onDict:params];
    [self safeSetValue:[BNCSystemObserver getUpdateState] forKey:BRANCH_REQUEST_KEY_UPDATE onDict:params];
    [self safeSetValue:[BNCPreferenceHelper getLinkClickIdentifier] forKey:BRANCH_REQUEST_KEY_LINK_IDENTIFIER onDict:params];
    
    [serverInterface postRequest:params url:[BNCPreferenceHelper getAPIURL:BRANCH_REQUEST_ENDPOINT_OPEN] key:key callback:callback];
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

    NSDictionary *data = response.data;
    [BNCPreferenceHelper setDeviceFingerprintID:data[BRANCH_RESPONSE_KEY_DEVICE_FINGERPRINT_ID]];
    [BNCPreferenceHelper setUserURL:data[BRANCH_RESPONSE_KEY_USER_URL]];
    [BNCPreferenceHelper setUserIdentity:data[BRANCH_RESPONSE_KEY_DEVELOPER_IDENTITY]];
    [BNCPreferenceHelper setSessionID:data[BRANCH_RESPONSE_KEY_SESSION_ID]];
    [BNCSystemObserver setUpdateState];
    
    NSString *sessionData = data[BRANCH_RESPONSE_KEY_SESSION_DATA];
    
    // Update session params
    [BNCPreferenceHelper setSessionParams:sessionData];
    
    // If referable, also se tup install params
    if ([BNCPreferenceHelper getIsReferrable]) {
        // If present, set it.
        if (sessionData) {
            [BNCPreferenceHelper setInstallParams:sessionData];
        }
        // If not present, only allow nil to be set if desired (don't clear otherwise)
        else if (self.allowInstallParamsToBeCleared) {
            [BNCPreferenceHelper setInstallParams:nil];
        }
    }
    
    // Clear link click so it doesn't get reused on the next open
    [BNCPreferenceHelper setLinkClickIdentifier:nil];
    
    if (data[BRANCH_RESPONSE_KEY_BRANCH_IDENTITY]) {
        [BNCPreferenceHelper setIdentityID:data[BRANCH_RESPONSE_KEY_BRANCH_IDENTITY]];
    }
    
    if (self.callback) {
        self.callback(YES, nil);
    }
}

@end
