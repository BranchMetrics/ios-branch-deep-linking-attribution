//
//  BranchServerInterface.m
//  Branch-SDK
//
//  Created by Alex Austin on 6/6/14.
//  Copyright (c) 2014 Branch Metrics. All rights reserved.
//

#import "BNCConfig.h"
#import "BranchServerInterface.h"
#import "BNCSystemObserver.h"
#import "BNCPreferenceHelper.h"

@implementation BranchServerInterface

- (void)registerInstall:(BOOL)debug key:(NSString *)key callback:(BNCServerCallback)callback{
    NSMutableDictionary *post = [[NSMutableDictionary alloc] init];
    
    BOOL isRealHardwareId;
    NSString *hardwareId = [BNCSystemObserver getUniqueHardwareId:&isRealHardwareId andIsDebug:[BNCPreferenceHelper isDebug]];
    if (hardwareId) {
        [post setObject:hardwareId forKey:@"hardware_id"];
        [post setObject:[NSNumber numberWithBool:isRealHardwareId] forKey:@"is_hardware_id_real"];
    }
    NSString *appVersion = [BNCSystemObserver getAppVersion];
    if (appVersion) [post setObject:appVersion forKey:@"app_version"];
    NSString *carrier = [BNCSystemObserver getCarrier];
    if (carrier) [post setObject:carrier forKey:@"carrier"];
    if ([BNCSystemObserver getBrand]) [post setObject:[BNCSystemObserver getBrand] forKey:@"brand"];
    NSString *model = [BNCSystemObserver getModel];
    if (model) [post setObject:model forKey:@"model"];
    if ([BNCSystemObserver getOS]) [post setObject:[BNCSystemObserver getOS] forKey:@"os"];
    NSString *osVersion = [BNCSystemObserver getOSVersion];
    if (osVersion) [post setObject:osVersion forKey:@"os_version"];
    NSNumber *screenWidth = [BNCSystemObserver getScreenWidth];
    if (screenWidth) [post setObject:screenWidth forKey:@"screen_width"];
    NSNumber *screenHeight = [BNCSystemObserver getScreenHeight];
    if (screenHeight) [post setObject:screenHeight forKey:@"screen_height"];
    NSString *uriScheme = [BNCSystemObserver getDefaultUriScheme];
    if (uriScheme) [post setObject:uriScheme forKey:@"uri_scheme"];
    NSNumber *updateState = [BNCSystemObserver getUpdateState];
    if (updateState) [post setObject:updateState forKey:@"update"];
    if ([BNCPreferenceHelper getLinkClickIdentifier]) [post setObject:[BNCPreferenceHelper getLinkClickIdentifier] forKey:@"link_identifier"];
    [post setObject:[NSNumber numberWithBool:[BNCSystemObserver adTrackingSafe]] forKey:@"ad_tracking_enabled"];
    [post setObject:[NSNumber numberWithInteger:[BNCPreferenceHelper getIsReferrable]] forKey:@"is_referrable"];
    [post setObject:[NSNumber numberWithBool:debug] forKey:@"debug"];
    
    [self postRequest:post url:[BNCPreferenceHelper getAPIURL:@"install"] key:key callback:callback];
}

- (void)registerOpen:(BOOL)debug key:(NSString *)key callback:(BNCServerCallback)callback {
    NSMutableDictionary *post = [[NSMutableDictionary alloc] init];
    
    if (![BNCPreferenceHelper getDeviceFingerprintID]) {
        BOOL isRealHardwareId;
        NSString *hardwareId = [BNCSystemObserver getUniqueHardwareId:&isRealHardwareId andIsDebug:[BNCPreferenceHelper isDebug]];
        if (hardwareId) {
            [post setObject:hardwareId forKey:@"hardware_id"];
            [post setObject:[NSNumber numberWithBool:isRealHardwareId] forKey:@"is_hardware_id_real"];
        }
    } else {
        [post setObject:[BNCPreferenceHelper getDeviceFingerprintID] forKey:@"device_fingerprint_id"];
    }
    [post setObject:[BNCPreferenceHelper getIdentityID] forKey:@"identity_id"];
    NSString *appVersion = [BNCSystemObserver getAppVersion];
    if (appVersion) [post setObject:appVersion forKey:@"app_version"];
    if ([BNCSystemObserver getOS]) [post setObject:[BNCSystemObserver getOS] forKey:@"os"];
    NSString *osVersion = [BNCSystemObserver getOSVersion];
    if (osVersion) [post setObject:osVersion forKey:@"os_version"];
    NSString *uriScheme = [BNCSystemObserver getDefaultUriScheme];
    if (uriScheme) [post setObject:uriScheme forKey:@"uri_scheme"];
    [post setObject:[NSNumber numberWithBool:[BNCSystemObserver adTrackingSafe]] forKey:@"ad_tracking_enabled"];
    [post setObject:[NSNumber numberWithInteger:[BNCPreferenceHelper getIsReferrable]] forKey:@"is_referrable"];
    NSNumber *updateState = [BNCSystemObserver getUpdateState];
    if (updateState) [post setObject:updateState forKey:@"update"];
    [post setObject:[NSNumber numberWithBool:debug] forKey:@"debug"];
    if ([BNCPreferenceHelper getLinkClickIdentifier]) [post setObject:[BNCPreferenceHelper getLinkClickIdentifier] forKey:@"link_identifier"];
    
    [self postRequest:post url:[BNCPreferenceHelper getAPIURL:@"open"] key:key callback:callback];
}

- (void)registerCloseWithKey:(NSString *)key callback:(BNCServerCallback)callback{
    NSMutableDictionary *post = [[NSMutableDictionary alloc] init];
    
    [post setObject:[BNCPreferenceHelper getIdentityID] forKey:@"identity_id"];
    [post setObject:[BNCPreferenceHelper getSessionID] forKey:@"session_id"];
    [post setObject:[BNCPreferenceHelper getDeviceFingerprintID] forKey:@"device_fingerprint_id"];
    
    [self postRequest:post url:[BNCPreferenceHelper getAPIURL:@"close"] key:key callback:callback];
}

- (void)uploadListOfApps:(NSDictionary *)post key:(NSString *)key callback:(BNCServerCallback)callback {
    [self postRequest:post url:[BNCPreferenceHelper getAPIURL:@"applist"] key:key callback:callback];
}

- (void)retrieveAppsToCheckWithKey:(NSString *)key callback:(BNCServerCallback)callback {
    return [self getRequest:nil url:[BNCPreferenceHelper getAPIURL:@"applist"] key:key callback:callback];
}

- (void)userCompletedAction:(NSDictionary *)post key:(NSString *)key callback:(BNCServerCallback)callback {
    [self postRequest:post url:[BNCPreferenceHelper getAPIURL:@"event"] key:key callback:callback];
}

- (void)getReferralCountsWithKey:(NSString *)key callback:(BNCServerCallback)callback {
    [self getRequest:nil url:[BNCPreferenceHelper getAPIURL:[NSString stringWithFormat:@"%@/%@", @"referrals", [BNCPreferenceHelper getIdentityID]]] key:key callback:callback];
}

- (void)getRewardsWithKey:(NSString *)key callback:(BNCServerCallback)callback {
    [self getRequest:nil url:[BNCPreferenceHelper getAPIURL:[NSString stringWithFormat:@"%@/%@", @"credits", [BNCPreferenceHelper getIdentityID]]] key:key callback:callback];
}

- (void)redeemRewards:(NSDictionary *)post key:(NSString *)key callback:(BNCServerCallback)callback {
    [self postRequest:post url:[BNCPreferenceHelper getAPIURL:@"redeem"] key:key callback:callback];
}

- (void)getCreditHistory:(NSDictionary *)post key:(NSString *)key callback:(BNCServerCallback)callback {
    [self postRequest:post url:[BNCPreferenceHelper getAPIURL:@"credithistory"] key:key callback:callback];
}

- (void)createCustomUrl:(BNCServerRequest *)req key:(NSString *)key callback:(BNCServerCallback)callback {
    [self postRequest:req.postData url:[BNCPreferenceHelper getAPIURL:@"url"] key:key callback:callback];
}

- (BNCServerResponse *)createCustomUrl:(BNCServerRequest *)req key:(NSString *)key {
    return [self postRequest:req.postData url:[BNCPreferenceHelper getAPIURL:@"url"] key:key log:YES];
}

- (void)identifyUser:(NSDictionary *)post key:(NSString *)key callback:(BNCServerCallback)callback {
    [self postRequest:post url:[BNCPreferenceHelper getAPIURL:@"profile"] key:key callback:callback];
}

- (void)logoutUser:(NSDictionary *)post key:(NSString *)key callback:(BNCServerCallback)callback {
    [self postRequest:post url:[BNCPreferenceHelper getAPIURL:@"logout"] key:key callback:callback];
}

- (void)connectToDebugWithKey:(NSString *)key callback:(BNCServerCallback)callback {
    NSMutableDictionary *post = [[NSMutableDictionary alloc] init];
    [post setObject:[BNCPreferenceHelper getDeviceFingerprintID] forKey:@"device_fingerprint_id"];
    [post setObject:[BNCSystemObserver getDeviceName] forKey:@"device_name"];
    [post setObject:[BNCSystemObserver getOS] forKey:@"os"];
    [post setObject:[BNCSystemObserver getOSVersion] forKey:@"os_version"];
    [post setObject:[BNCSystemObserver getModel] forKey:@"model"];
    [post setObject:[NSNumber numberWithBool:[BNCSystemObserver isSimulator]] forKey:@"is_simulator"];
    
    [self postRequest:post url:[BNCPreferenceHelper getAPIURL:@"debug/connect"] key:key log:NO callback:callback];
}

- (void)disconnectFromDebugWithKey:(NSString *)key callback:(BNCServerCallback)callback {
    NSMutableDictionary *post = [[NSMutableDictionary alloc] init];
    [post setObject:[BNCPreferenceHelper getDeviceFingerprintID] forKey:@"device_fingerprint_id"];
    
    [self postRequest:post url:[BNCPreferenceHelper getAPIURL:@"debug/disconnect"] key:key log:NO callback:callback];
}

- (void)sendLog:(NSString *)log key:(NSString *)key callback:(BNCServerCallback)callback {
    NSMutableDictionary *post = [NSMutableDictionary dictionaryWithObject:log forKey:@"log"];
    [post setObject:[BNCPreferenceHelper getDeviceFingerprintID] forKey:@"device_fingerprint_id"];
    
    [self postRequest:post url:[BNCPreferenceHelper getAPIURL:@"debug/log"] key:key log:NO callback:callback];
}

- (void)sendScreenshot:(NSData *)data key:(NSString *)key callback:(BNCServerCallback)callback {
    NSMutableURLRequest *request = [[NSMutableURLRequest alloc] init];
    NSString *file = @"BNC_Debug_Screen.png";
    
    NSString *keyString;
    if ([key hasPrefix:@"key_"]) {
        keyString = [NSString stringWithFormat:@"%@=%@", KEY_BRANCH_KEY, key];
    }
    else {
        keyString = [NSString stringWithFormat:@"app_id=%@", key];
    }

    [request setURL:[NSURL URLWithString:[NSString stringWithFormat:@"%@?%@&sdk=ios%@&device_fingerprint_id=%@", [BNCPreferenceHelper getAPIURL:@"debug/screenshot"], keyString, SDK_VERSION, [BNCPreferenceHelper getDeviceFingerprintID]]]];
    [request setHTTPMethod:@"POST"];
    
    NSString *boundary = @"---------------------------Boundary Line---------------------------";
    NSString *contentType = [NSString stringWithFormat:@"multipart/form-data; boundary=%@",boundary];
    [request addValue:contentType forHTTPHeaderField: @"Content-Type"];
    
    NSMutableData *body = [NSMutableData data];
    
    [body appendData:[[NSString stringWithFormat:@"\r\n--%@\r\n",boundary] dataUsingEncoding:NSUTF8StringEncoding]];
    [body appendData:[[NSString stringWithFormat:@"Content-Disposition: form-data; name=\"data\"\r\n\r\n"]  dataUsingEncoding:NSUTF8StringEncoding]];
    [body appendData:[[NSString stringWithFormat:@"{\"id\":\"%@\", \"fileName\":\"%@\"}\r\n", @"", file] dataUsingEncoding:NSUTF8StringEncoding]];
    
    [body appendData:[[NSString stringWithFormat:@"\r\n--%@\r\n",boundary] dataUsingEncoding:NSUTF8StringEncoding]];
    [body appendData:[[NSString stringWithFormat:@"Content-Disposition: form-data; name=\"Filedata\"; filename=\"%@\"\r\n", file] dataUsingEncoding:NSUTF8StringEncoding]];
    [body appendData:[@"Content-Type: application/octet-stream\r\n\r\n" dataUsingEncoding:NSUTF8StringEncoding]];
    [body appendData:[NSData dataWithData:data]];
    [body appendData:[[NSString stringWithFormat:@"\r\n--%@--\r\n",boundary] dataUsingEncoding:NSUTF8StringEncoding]];
    
    [request setHTTPBody:body];
    [request addValue:[NSString stringWithFormat:@"%lu", (unsigned long)[body length]] forHTTPHeaderField:@"Content-Length"];

    [self genericHTTPRequest:request log:YES callback:callback];
}

- (void)getReferralCode:(NSDictionary *)post key:(NSString *)key callback:(BNCServerCallback)callback {
    [self postRequest:post url:[BNCPreferenceHelper getAPIURL:@"referralcode"] key:key callback:callback];
}

- (void)validateReferralCode:(NSDictionary *)post key:(NSString *)key callback:(BNCServerCallback)callback {
    NSString *url = [[BNCPreferenceHelper getAPIURL:@"referralcode/"] stringByAppendingString:post[@"referral_code"]];
    [self postRequest:post url:url key:key callback:callback];
}

- (void)applyReferralCode:(NSDictionary *)post key:(NSString *)key callback:(BNCServerCallback)callback {
    NSString *url = [[BNCPreferenceHelper getAPIURL:@"applycode/"] stringByAppendingString:post[@"referral_code"]];
    [self postRequest:post url:url key:key callback:callback];
}

@end
