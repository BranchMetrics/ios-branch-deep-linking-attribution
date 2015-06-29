//
//  BranchInstallRequest.m
//  Branch-TestBed
//
//  Created by Graham Mueller on 5/26/15.
//  Copyright (c) 2015 Branch Metrics. All rights reserved.
//

#import "BranchInstallRequest.h"
#import "BNCPreferenceHelper.h"
#import "BNCSystemObserver.h"

@implementation BranchInstallRequest

- (id)initWithCallback:(callbackWithStatus)callback {
    return [super initWithCallback:callback allowInstallParamsToBeCleared:YES];
}

- (void)makeRequest:(BNCServerInterface *)serverInterface key:(NSString *)key callback:(BNCServerCallback)callback {
    BNCPreferenceHelper *preferenceHelper = [BNCPreferenceHelper preferenceHelper];
    NSMutableDictionary *params = [[NSMutableDictionary alloc] init];
    
    BOOL isRealHardwareId;
    NSString *hardwareId = [BNCSystemObserver getUniqueHardwareId:&isRealHardwareId andIsDebug:preferenceHelper.isDebug];
    if (hardwareId) {
        params[@"hardware_id"] = hardwareId;
        params[@"is_hardware_id_real"] = @(isRealHardwareId);
    }
    
    [self safeSetValue:[BNCSystemObserver getBundleID] forKey:@"ios_bundle_id" onDict:params];
    [self safeSetValue:[BNCSystemObserver getAppVersion] forKey:@"app_version" onDict:params];
    [self safeSetValue:[BNCSystemObserver getCarrier] forKey:@"carrier" onDict:params];
    [self safeSetValue:[BNCSystemObserver getBrand] forKey:@"branch" onDict:params];
    [self safeSetValue:[BNCSystemObserver getModel] forKey:@"model" onDict:params];
    [self safeSetValue:[BNCSystemObserver getOS] forKey:@"os" onDict:params];
    [self safeSetValue:[BNCSystemObserver getOSVersion] forKey:@"os_version" onDict:params];
    [self safeSetValue:[BNCSystemObserver getScreenWidth] forKey:@"screen_width" onDict:params];
    [self safeSetValue:[BNCSystemObserver getScreenHeight] forKey:@"screen_height" onDict:params];
    [self safeSetValue:[BNCSystemObserver getDefaultUriScheme] forKey:@"uri_scheme" onDict:params];
    [self safeSetValue:[BNCSystemObserver getUpdateState] forKey:@"update" onDict:params];
    [self safeSetValue:preferenceHelper.linkClickIdentifier forKey:@"link_identifier" onDict:params];
    
    params[@"ad_tracking_enabled"] = @([BNCSystemObserver adTrackingSafe]);
    params[@"is_referrable"] = @(preferenceHelper.isReferrable);
    params[@"debug"] = @(preferenceHelper.isDebug);
    
    [serverInterface postRequest:params url:[preferenceHelper getAPIURL:@"install"] key:key callback:callback];
}

- (void)safeSetValue:(NSObject *)value forKey:(NSString *)key onDict:(NSMutableDictionary *)dict {
    if (value) {
        dict[key] = value;
    }
}

@end
