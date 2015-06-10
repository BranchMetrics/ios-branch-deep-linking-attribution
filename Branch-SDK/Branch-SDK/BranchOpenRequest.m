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

@interface BranchOpenRequest ()

@property (strong, nonatomic) callbackWithStatus callback;
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
    
    if (![BNCPreferenceHelper getDeviceFingerprintID]) {
        BOOL isRealHardwareId;
        NSString *hardwareId = [BNCSystemObserver getUniqueHardwareId:&isRealHardwareId andIsDebug:[BNCPreferenceHelper isDebug]];
        if (hardwareId) {
            params[@"hardware_id"] = hardwareId;
            params[@"is_hardware_id_real"] = @(isRealHardwareId);
        }
    }
    else {
        params[@"device_fingerprint_id"] = [BNCPreferenceHelper getDeviceFingerprintID];
    }

    params[@"identity_id"] = [BNCPreferenceHelper getIdentityID];
    params[@"ad_tracking_enabled"] = @([BNCSystemObserver adTrackingSafe]);
    params[@"is_referrable"] = @([BNCPreferenceHelper getIsReferrable]);
    params[@"debug"] = @([BNCPreferenceHelper isDebug]);

    [self safeSetValue:[BNCSystemObserver getAppVersion] forKey:@"app_version" onDict:params];
    [self safeSetValue:[BNCSystemObserver getOS] forKey:@"os" onDict:params];
    [self safeSetValue:[BNCSystemObserver getOSVersion] forKey:@"os_version" onDict:params];
    [self safeSetValue:[BNCSystemObserver getDefaultUriScheme] forKey:@"uri_scheme" onDict:params];
    [self safeSetValue:[BNCSystemObserver getUpdateState] forKey:@"update" onDict:params];
    [self safeSetValue:[BNCPreferenceHelper getLinkClickIdentifier] forKey:@"link_identifier" onDict:params];
    
    [serverInterface postRequest:params url:[BNCPreferenceHelper getAPIURL:@"open"] key:key callback:callback];
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
    [BNCPreferenceHelper setDeviceFingerprintID:data[@"device_fingerprint_id"]];
    [BNCPreferenceHelper setUserURL:data[@"link"]];
    [BNCPreferenceHelper setUserIdentity:data[@"identity"]];
    [BNCPreferenceHelper setSessionID:data[@"session_id"]];
    [BNCSystemObserver setUpdateState];
    
    NSString *sessionData = data[@"data"];
    
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
    
    if (data[@"link_click_id"]) {
        [BNCPreferenceHelper setLinkClickID:data[@"link_click_id"]];
    }
    else {
        [BNCPreferenceHelper setLinkClickID:nil];
    }
    
    if (data[@"identity_id"]) {
        [BNCPreferenceHelper setIdentityID:data[@"identity_id"]];
    }
    
    if (self.callback) {
        self.callback(YES, nil);
    }
}

@end
