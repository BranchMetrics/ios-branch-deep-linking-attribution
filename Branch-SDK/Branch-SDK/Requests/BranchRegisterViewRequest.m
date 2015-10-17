//
//  BranchRegisterViewRequest.m
//  Branch-TestBed
//
//  Created by Derrick Staten on 10/16/15.
//  Copyright © 2015 Branch Metrics. All rights reserved.
//

#import "BranchRegisterViewRequest.h"
#import "BNCPreferenceHelper.h"
#import "BranchConstants.h"
#import "BNCSystemObserver.h"

@interface BranchRegisterViewRequest ()

@property (strong, nonatomic) NSDictionary *params;
@property (strong, nonatomic) callbackWithParams callback;

@end

@implementation BranchRegisterViewRequest

- (id)initWithParams:(NSDictionary *)params andCallback:(callbackWithParams)callback {
    if (self = [super init]) {
        _params = params;
        if (!_params) {
            _params = [[NSDictionary alloc] init];
        }
        _callback = callback;
    }
    
    return self;
}

- (void)makeRequest:(BNCServerInterface *)serverInterface key:(NSString *)key callback:(BNCServerCallback)callback {
    NSMutableDictionary *params = [self.params mutableCopy];
    
    BNCPreferenceHelper *preferenceHelper = [BNCPreferenceHelper preferenceHelper];
    [self safeSetValue:preferenceHelper.deviceFingerprintID forKey:BRANCH_REQUEST_KEY_DEVICE_FINGERPRINT_ID onDict:params];
    [self safeSetValue:preferenceHelper.identityID forKey:BRANCH_REQUEST_KEY_BRANCH_IDENTITY onDict:params];
    [self safeSetValue:preferenceHelper.sessionID forKey:BRANCH_REQUEST_KEY_SESSION_ID onDict:params];
    [self safeSetValue:@([BNCSystemObserver adTrackingSafe]) forKey:BRANCH_REQUEST_KEY_AD_TRACKING_ENABLED onDict:params];
    [self safeSetValue:@(preferenceHelper.isDebug) forKey:BRANCH_REQUEST_KEY_DEBUG onDict:params];
    [self safeSetValue:[BNCSystemObserver getOS] forKey:BRANCH_REQUEST_KEY_OS onDict:params];
    [self safeSetValue:[BNCSystemObserver getOSVersion] forKey:BRANCH_REQUEST_KEY_OS_VERSION onDict:params];
    [self safeSetValue:[BNCSystemObserver getModel] forKey:BRANCH_REQUEST_KEY_MODEL onDict:params];
    [self safeSetValue:@([BNCSystemObserver isSimulator]) forKey:BRANCH_REQUEST_KEY_IS_SIMULATOR onDict:params];

    [self safeSetValue:[BNCSystemObserver getAppVersion] forKey:BRANCH_REQUEST_KEY_APP_VERSION onDict:params];
    [self safeSetValue:[BNCSystemObserver getDeviceName] forKey:BRANCH_REQUEST_KEY_DEVICE_NAME onDict:params];

    BOOL isRealHardwareId;
    NSString *hardwareId = [BNCSystemObserver getUniqueHardwareId:&isRealHardwareId andIsDebug:preferenceHelper.isDebug];
    if (hardwareId && isRealHardwareId) {
        params[BRANCH_REQUEST_KEY_HARDWARE_ID] = hardwareId;
    }
    
    [serverInterface postRequest:params url:[preferenceHelper getAPIURL:BRANCH_REQUEST_ENDPOINT_REGISTER_VIEW] key:key callback:callback];
}

- (void)processResponse:(BNCServerResponse *)response error:(NSError *)error {
    if (error) {
        if (self.callback) {
            self.callback(nil, error);
        }
        return;
    }
    
    if (self.callback) {
        self.callback(response.data, error);
    }
}

- (void)safeSetValue:(NSObject *)value forKey:(NSString *)key onDict:(NSMutableDictionary *)dict {
    if (value) {
        dict[key] = value;
    }
}

#pragma mark - NSCoding methods

- (id)initWithCoder:(NSCoder *)decoder {
    if (self = [super initWithCoder:decoder]) {
        _params = [decoder decodeObjectForKey:@"params"];
    }
    
    return self;
}

- (void)encodeWithCoder:(NSCoder *)coder {
    [super encodeWithCoder:coder];
    
    [coder encodeObject:self.params forKey:@"params"];
}

@end
