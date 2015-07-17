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
            params[@"hardware_id"] = hardwareId;
            params[@"is_hardware_id_real"] = @(isRealHardwareId);
        }
    }
    else {
        params[@"device_fingerprint_id"] = preferenceHelper.deviceFingerprintID;
    }

    params[@"identity_id"] = preferenceHelper.identityID;
    params[@"ad_tracking_enabled"] = @([BNCSystemObserver adTrackingSafe]);
    params[@"is_referrable"] = @(preferenceHelper.isReferrable);
    params[@"debug"] = @(preferenceHelper.isDebug);

    [self safeSetValue:[BNCSystemObserver getBundleID] forKey:@"ios_bundle_id" onDict:params];
    [self safeSetValue:[BNCSystemObserver getAppVersion] forKey:@"app_version" onDict:params];
    [self safeSetValue:[BNCSystemObserver getOS] forKey:@"os" onDict:params];
    [self safeSetValue:[BNCSystemObserver getOSVersion] forKey:@"os_version" onDict:params];
    [self safeSetValue:[BNCSystemObserver getDefaultUriScheme] forKey:@"uri_scheme" onDict:params];
    [self safeSetValue:[BNCSystemObserver getUpdateState] forKey:@"update" onDict:params];
    [self safeSetValue:preferenceHelper.linkClickIdentifier forKey:@"link_identifier" onDict:params];
    
    [serverInterface postRequest:params url:[preferenceHelper getAPIURL:@"open"] key:key callback:callback];
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
    id userIdentity = data[@"identity"];
    if ([userIdentity isKindOfClass:[NSNumber class]]) {
        userIdentity = [userIdentity stringValue];
    }
    
    preferenceHelper.deviceFingerprintID = data[@"device_fingerprint_id"];
    preferenceHelper.userUrl = data[@"link"];
    preferenceHelper.userIdentity = userIdentity;
    preferenceHelper.sessionID = data[@"session_id"];
    [BNCSystemObserver setUpdateState];
    
    NSString *sessionData = data[@"data"];
    
    // Update session params
    preferenceHelper.sessionParams = sessionData;
    
    // Scenarios:
    // If isReferrable is false, don't set, period.
    // Otherwise, if isReferrable and
    // * Install: set to whatever we get.
    // * Open and installParams set: don't set.
    // * Open and not installParams and isReferrable: set if not null.
    if (preferenceHelper.isReferrable) {
        BOOL storedParamsAreEmptyAndRequestValueIsNonNull = !preferenceHelper.installParams.length && sessionData.length;

        if (self.isInstall || storedParamsAreEmptyAndRequestValueIsNonNull) {
            preferenceHelper.installParams = sessionData;
        }
    }
    
    // Clear link click so it doesn't get reused on the next open
    preferenceHelper.linkClickIdentifier = nil;
    
    if (data[@"identity_id"]) {
        preferenceHelper.identityID = data[@"identity_id"];
    }
    
    if (self.callback) {
        self.callback(YES, nil);
    }
}

@end
