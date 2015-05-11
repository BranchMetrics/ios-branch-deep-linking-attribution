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

- (void)registerInstall:(BOOL)debug callback:(BNCServerCallback)callback {
    NSMutableDictionary *post = [[NSMutableDictionary alloc] init];
    
    BOOL isRealHardwareId;
    NSString *hardwareId = [BNCSystemObserver getUniqueHardwareId:&isRealHardwareId andIsDebug:[BNCPreferenceHelper getDevDebug]];
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
    if (![[BNCPreferenceHelper getLinkClickIdentifier] isEqualToString:NO_STRING_VALUE]) [post setObject:[BNCPreferenceHelper getLinkClickIdentifier] forKey:@"link_identifier"];
    [post setObject:[NSNumber numberWithBool:[BNCSystemObserver adTrackingSafe]] forKey:@"ad_tracking_enabled"];
    [post setObject:[NSNumber numberWithInteger:[BNCPreferenceHelper getIsReferrable]] forKey:@"is_referrable"];
    [post setObject:[NSNumber numberWithBool:debug] forKey:@"debug"];
    
    [self postRequest:post url:[BNCPreferenceHelper getAPIURL:@"install"] andTag:REQ_TAG_REGISTER_INSTALL callback:callback];
}

- (void)registerOpen:(BOOL)debug callback:(BNCServerCallback)callback {
    NSMutableDictionary *post = [[NSMutableDictionary alloc] init];
    
    if ([[BNCPreferenceHelper getDeviceFingerprintID] isEqualToString:NO_STRING_VALUE]) {
        BOOL isRealHardwareId;
        NSString *hardwareId = [BNCSystemObserver getUniqueHardwareId:&isRealHardwareId andIsDebug:[BNCPreferenceHelper getDevDebug]];
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
    if (![[BNCPreferenceHelper getLinkClickIdentifier] isEqualToString:NO_STRING_VALUE]) [post setObject:[BNCPreferenceHelper getLinkClickIdentifier] forKey:@"link_identifier"];
    
    [self postRequest:post url:[BNCPreferenceHelper getAPIURL:@"open"] andTag:REQ_TAG_REGISTER_OPEN callback:callback];
}

- (void)registerCloseWithCallback:(BNCServerCallback)callback{
    NSMutableDictionary *post = [[NSMutableDictionary alloc] init];
    
    [post setObject:[BNCPreferenceHelper getIdentityID] forKey:@"identity_id"];
    [post setObject:[BNCPreferenceHelper getSessionID] forKey:@"session_id"];
    [post setObject:[BNCPreferenceHelper getDeviceFingerprintID] forKey:@"device_fingerprint_id"];
    
    [self postRequest:post url:[BNCPreferenceHelper getAPIURL:@"close"] andTag:REQ_TAG_REGISTER_CLOSE callback:callback];
}

- (void)uploadListOfApps:(NSDictionary *)post callback:(BNCServerCallback)callback {
    [self postRequest:post url:[BNCPreferenceHelper getAPIURL:@"applist"] andTag:REQ_TAG_UPLOAD_LIST_OF_APPS callback:callback];
}

- (void)retrieveAppsToCheckWithCallback:(BNCServerCallback)callback {
    return [self getRequest:nil url:[BNCPreferenceHelper getAPIURL:@"applist"] andTag:REQ_TAG_GET_LIST_OF_APPS callback:callback];
}

- (void)userCompletedAction:(NSDictionary *)post callback:(BNCServerCallback)callback {
    [self postRequest:post url:[BNCPreferenceHelper getAPIURL:@"event"] andTag:REQ_TAG_COMPLETE_ACTION callback:callback];
}

- (void)getReferralCountsWithCallback:(BNCServerCallback)callback {
    [self getRequest:nil url:[BNCPreferenceHelper getAPIURL:[NSString stringWithFormat:@"%@/%@", @"referrals", [BNCPreferenceHelper getIdentityID]]] andTag:REQ_TAG_GET_REFERRAL_COUNTS callback:callback];
}

- (void)getRewardsWithCallback:(BNCServerCallback)callback {
    [self getRequest:nil url:[BNCPreferenceHelper getAPIURL:[NSString stringWithFormat:@"%@/%@", @"credits", [BNCPreferenceHelper getIdentityID]]] andTag:REQ_TAG_GET_REWARDS callback:callback];
}

- (void)redeemRewards:(NSDictionary *)post callback:(BNCServerCallback)callback {
    [self postRequest:post url:[BNCPreferenceHelper getAPIURL:@"redeem"] andTag:REQ_TAG_REDEEM_REWARDS callback:callback];
}

- (void)getCreditHistory:(NSDictionary *)post callback:(BNCServerCallback)callback {
    [self postRequest:post url:[BNCPreferenceHelper getAPIURL:@"credithistory"] andTag:REQ_TAG_GET_REWARD_HISTORY callback:callback];
}

- (void)createCustomUrl:(BNCServerRequest *)req callback:(BNCServerCallback)callback {
    [self postRequest:req.postData url:[BNCPreferenceHelper getAPIURL:@"url"] andTag:REQ_TAG_GET_CUSTOM_URL callback:callback];
}

- (BNCServerResponse *)createCustomUrl:(BNCServerRequest *)req {
    return [self postRequest:req.postData url:[BNCPreferenceHelper getAPIURL:@"url"] andTag:REQ_TAG_GET_CUSTOM_URL log:YES];
}

- (void)identifyUser:(NSDictionary *)post callback:(BNCServerCallback)callback {
    [self postRequest:post url:[BNCPreferenceHelper getAPIURL:@"profile"] andTag:REQ_TAG_IDENTIFY callback:callback];
}

- (void)logoutUser:(NSDictionary *)post callback:(BNCServerCallback)callback {
    [self postRequest:post url:[BNCPreferenceHelper getAPIURL:@"logout"] andTag:REQ_TAG_LOGOUT callback:callback];
}

- (void)addProfileParams:(NSDictionary *)post withParams:(NSDictionary *)params callback:(BNCServerCallback)callback {
    NSMutableDictionary *newPost = [post mutableCopy];
    [newPost setObject:params forKey:@"add"];
    [self updateProfileParams:newPost callback:callback];
}

- (void)setProfileParams:(NSDictionary *)post withParams:(NSDictionary *)params callback:(BNCServerCallback)callback {
    NSMutableDictionary *newPost = [post mutableCopy];
    [newPost setObject:params forKey:@"set"];
    [self updateProfileParams:newPost callback:callback];
}

- (void)appendProfileParams:(NSDictionary *)post withParams:(NSDictionary *)params callback:(BNCServerCallback)callback {
    NSMutableDictionary *newPost = [post mutableCopy];
    [newPost setObject:params forKey:@"append"];
    [self updateProfileParams:newPost callback:callback];
}

- (void)unionProfileParams:(NSDictionary *)post withParams:(NSDictionary *)params callback:(BNCServerCallback)callback {
    NSMutableDictionary *newPost = [post mutableCopy];
    [newPost setObject:params forKey:@"union"];
    [self updateProfileParams:newPost callback:callback];
}

- (void)updateProfileParams:(NSDictionary *)post callback:(BNCServerCallback)callback {
    [self postRequest:post url:[BNCPreferenceHelper getAPIURL:@"profile"] andTag:REQ_TAG_PROFILE_DATA callback:callback];
}

- (void)connectToDebugWithCallback:(BNCServerCallback)callback {
    NSMutableDictionary *post = [[NSMutableDictionary alloc] init];
    [post setObject:[BNCPreferenceHelper getDeviceFingerprintID] forKey:@"device_fingerprint_id"];
    [post setObject:[BNCSystemObserver getDeviceName] forKey:@"device_name"];
    [post setObject:[BNCSystemObserver getOS] forKey:@"os"];
    [post setObject:[BNCSystemObserver getOSVersion] forKey:@"os_version"];
    [post setObject:[BNCSystemObserver getModel] forKey:@"model"];
    [post setObject:[NSNumber numberWithBool:[BNCSystemObserver isSimulator]] forKey:@"is_simulator"];
    
    [self postRequest:post url:[BNCPreferenceHelper getAPIURL:@"debug/connect"] andTag:REQ_TAG_DEBUG_CONNECT log:NO callback:callback];
}

- (void)disconnectFromDebugWithCallback:(BNCServerCallback)callback {
    NSMutableDictionary *post = [[NSMutableDictionary alloc] init];
    [post setObject:[BNCPreferenceHelper getDeviceFingerprintID] forKey:@"device_fingerprint_id"];
    
    [self postRequest:post url:[BNCPreferenceHelper getAPIURL:@"debug/disconnect"] andTag:REQ_TAG_DEBUG_DISCONNECT log:NO callback:callback];
}

- (void)sendLog:(NSString *)log callback:(BNCServerCallback)callback {
    NSMutableDictionary *post = [NSMutableDictionary dictionaryWithObject:log forKey:@"log"];
    [post setObject:[BNCPreferenceHelper getDeviceFingerprintID] forKey:@"device_fingerprint_id"];
    
    [self postRequest:post url:[BNCPreferenceHelper getAPIURL:@"debug/log"] andTag:REQ_TAG_DEBUG_LOG log:NO callback:callback];
}

- (void)sendScreenshot:(NSData *)data callback:(BNCServerCallback)callback {
    NSMutableURLRequest *request = [[NSMutableURLRequest alloc] init];
    NSString *file = @"BNC_Debug_Screen.png";
    
    [request setURL:[NSURL URLWithString:[NSString stringWithFormat:@"%@?%@=%@&app_id=%@&sdk=ios%@&device_fingerprint_id=%@", [BNCPreferenceHelper getAPIURL:@"debug/screenshot"], KEY_BRANCH_KEY, [BNCPreferenceHelper getBranchKey], [BNCPreferenceHelper getAppKey], SDK_VERSION, [BNCPreferenceHelper getDeviceFingerprintID]]]];
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

    [self genericHTTPRequest:request withTag:REQ_TAG_DEBUG_SCREEN callback:callback];
}

- (void)getReferralCode:(NSDictionary *)post callback:(BNCServerCallback)callback {
    [self postRequest:post url:[BNCPreferenceHelper getAPIURL:@"referralcode"] andTag:REQ_TAG_GET_REFERRAL_CODE callback:callback];
}

- (void)validateReferralCode:(NSDictionary *)post callback:(BNCServerCallback)callback {
    [self postRequest:post url:[[BNCPreferenceHelper getAPIURL:@"referralcode/"] stringByAppendingString:[post objectForKey:@"referral_code"]] andTag:REQ_TAG_VALIDATE_REFERRAL_CODE callback:callback];
}

- (void)applyReferralCode:(NSDictionary *)post callback:(BNCServerCallback)callback {
    [self postRequest:post url:[[BNCPreferenceHelper getAPIURL:@"applycode/"] stringByAppendingString:[post objectForKey:@"referral_code"]] andTag:REQ_TAG_APPLY_REFERRAL_CODE callback:callback];
}


@end
