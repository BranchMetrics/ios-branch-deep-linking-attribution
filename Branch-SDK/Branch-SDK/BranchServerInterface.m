//
//  BranchServerInterface.m
//  Branch-SDK
//
//  Created by Alex Austin on 6/6/14.
//  Copyright (c) 2014 Branch Metrics. All rights reserved.
//

#import "BranchServerInterface.h"
#import "BNCSystemObserver.h"
#import "BNCPreferenceHelper.h"

@implementation BranchServerInterface

- (void)registerInstall:(BOOL)debug {
    NSMutableDictionary *post = [[NSMutableDictionary alloc] init];
    
    [post setObject:[BNCPreferenceHelper getAppKey] forKey:@"app_id"];
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
    NSString *uriScheme = [BNCSystemObserver getURIScheme];
    if (uriScheme) [post setObject:uriScheme forKey:@"uri_scheme"];
    NSNumber *updateState = [BNCSystemObserver getUpdateState];
    if (updateState) [post setObject:updateState forKeyedSubscript:@"update"];
    if (![[BNCPreferenceHelper getLinkClickIdentifier] isEqualToString:NO_STRING_VALUE]) [post setObject:[BNCPreferenceHelper getLinkClickIdentifier] forKey:@"link_identifier"];
    [post setObject:[NSNumber numberWithBool:[BNCSystemObserver adTrackingSafe]] forKey:@"ad_tracking_enabled"];
    [post setObject:[NSNumber numberWithInteger:[BNCPreferenceHelper getIsReferrable]] forKey:@"is_referrable"];
    [post setObject:[NSNumber numberWithBool:debug] forKey:@"debug"];
    
    [self postRequestAsync:post url:[BNCPreferenceHelper getAPIURL:@"install"] andTag:REQ_TAG_REGISTER_INSTALL];
}

- (void)registerOpen:(BOOL)debug {
    NSMutableDictionary *post = [[NSMutableDictionary alloc] init];
    
    [post setObject:[BNCPreferenceHelper getAppKey] forKey:@"app_id"];
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
    NSString *uriScheme = [BNCSystemObserver getURIScheme];
    if (uriScheme) [post setObject:uriScheme forKey:@"uri_scheme"];
    [post setObject:[NSNumber numberWithBool:[BNCSystemObserver adTrackingSafe]] forKey:@"ad_tracking_enabled"];
    [post setObject:[NSNumber numberWithInteger:[BNCPreferenceHelper getIsReferrable]] forKey:@"is_referrable"];
    [post setObject:[NSNumber numberWithBool:debug] forKey:@"debug"];
    if (![[BNCPreferenceHelper getLinkClickIdentifier] isEqualToString:NO_STRING_VALUE]) [post setObject:[BNCPreferenceHelper getLinkClickIdentifier] forKey:@"link_identifier"];
    
    [self postRequestAsync:post url:[BNCPreferenceHelper getAPIURL:@"open"] andTag:REQ_TAG_REGISTER_OPEN];
}

- (void)registerClose {
    NSMutableDictionary *post = [[NSMutableDictionary alloc] init];
    
    [post setObject:[BNCPreferenceHelper getAppKey] forKey:@"app_id"];
    [post setObject:[BNCPreferenceHelper getIdentityID] forKey:@"identity_id"];
    [post setObject:[BNCPreferenceHelper getSessionID] forKey:@"session_id"];
    [post setObject:[BNCPreferenceHelper getDeviceFingerprintID] forKey:@"device_fingerprint_id"];
    
    [self postRequestAsync:post url:[BNCPreferenceHelper getAPIURL:@"close"] andTag:REQ_TAG_REGISTER_CLOSE];
}

- (void)uploadListOfApps:(NSDictionary *)post {
    [self postRequestAsync:post url:[BNCPreferenceHelper getAPIURL:@"applist"] andTag:REQ_TAG_UPLOAD_LIST_OF_APPS];
}

- (BNCServerResponse *)retrieveAppsToCheck {
    return [self getRequestSync:nil url:[BNCPreferenceHelper getAPIURL:@"applist"] andTag:REQ_TAG_GET_LIST_OF_APPS];
}

- (void)userCompletedAction:(NSDictionary *)post {
    [self postRequestAsync:post url:[BNCPreferenceHelper getAPIURL:@"event"] andTag:REQ_TAG_COMPLETE_ACTION];
}

- (void)getReferralCounts {
    [self getRequestAsync:@{@"app_id": [BNCPreferenceHelper getAppKey]} url:[BNCPreferenceHelper getAPIURL:[NSString stringWithFormat:@"%@/%@", @"referrals", [BNCPreferenceHelper getIdentityID]]] andTag:REQ_TAG_GET_REFERRAL_COUNTS];
}

- (void)getRewards {
    [self getRequestAsync:@{@"app_id": [BNCPreferenceHelper getAppKey]} url:[BNCPreferenceHelper getAPIURL:[NSString stringWithFormat:@"%@/%@", @"credits", [BNCPreferenceHelper getIdentityID]]] andTag:REQ_TAG_GET_REWARDS];
}

- (void)redeemRewards:(NSDictionary *)post {
    [self postRequestAsync:post url:[BNCPreferenceHelper getAPIURL:@"redeem"] andTag:REQ_TAG_REDEEM_REWARDS];
}

- (void)getCreditHistory:(NSDictionary *)post {
    [self postRequestAsync:post url:[BNCPreferenceHelper getAPIURL:@"credithistory"] andTag:REQ_TAG_GET_REWARD_HISTORY];
}

- (void)createCustomUrl:(BNCServerRequest *)req {
    [self postRequestAsync:req.postData url:[BNCPreferenceHelper getAPIURL:@"url"] andTag:REQ_TAG_GET_CUSTOM_URL andLinkData:req.linkData];
}

- (BNCServerResponse *)createCustomUrlSynchronous:(BNCServerRequest *)req {
    return [self postRequestSync:req.postData url:[BNCPreferenceHelper getAPIURL:@"url"] andTag:REQ_TAG_GET_CUSTOM_URL andLinkData:req.linkData log:YES];
}

- (void)identifyUser:(NSDictionary *)post {
    [self postRequestAsync:post url:[BNCPreferenceHelper getAPIURL:@"profile"] andTag:REQ_TAG_IDENTIFY];
}

- (void)logoutUser:(NSDictionary *)post {
    [self postRequestAsync:post url:[BNCPreferenceHelper getAPIURL:@"logout"] andTag:REQ_TAG_LOGOUT];
}

- (void)addProfileParams:(NSDictionary *)post withParams:(NSDictionary *)params {
    NSMutableDictionary *newPost = [post mutableCopy];
    [newPost setObject:params forKey:@"add"];
    [self updateProfileParams:newPost];
}

- (void)setProfileParams:(NSDictionary *)post withParams:(NSDictionary *)params {
    NSMutableDictionary *newPost = [post mutableCopy];
    [newPost setObject:params forKey:@"set"];
    [self updateProfileParams:newPost];
}

- (void)appendProfileParams:(NSDictionary *)post withParams:(NSDictionary *)params {
    NSMutableDictionary *newPost = [post mutableCopy];
    [newPost setObject:params forKey:@"append"];
    [self updateProfileParams:newPost];
}

- (void)unionProfileParams:(NSDictionary *)post withParams:(NSDictionary *)params {
    NSMutableDictionary *newPost = [post mutableCopy];
    [newPost setObject:params forKey:@"union"];
    [self updateProfileParams:newPost];
}

- (void)updateProfileParams:(NSDictionary *)post {
    [self postRequestAsync:post url:[BNCPreferenceHelper getAPIURL:@"profile"] andTag:REQ_TAG_PROFILE_DATA];
}

- (void)connectToDebug {
    NSMutableDictionary *post = [[NSMutableDictionary alloc] init];
    [post setObject:[BNCPreferenceHelper getAppKey] forKey:@"app_id"];
    [post setObject:[BNCPreferenceHelper getDeviceFingerprintID] forKey:@"device_fingerprint_id"];
    [post setObject:[BNCSystemObserver getDeviceName] forKey:@"device_name"];
    [post setObject:[BNCSystemObserver getOS] forKey:@"os"];
    [post setObject:[BNCSystemObserver getOSVersion] forKey:@"os_version"];
    [post setObject:[BNCSystemObserver getModel] forKey:@"model"];
    [post setObject:[NSNumber numberWithBool:[BNCSystemObserver isSimulator]] forKey:@"is_simulator"];
    
    [self postRequestAsync:post url:[BNCPreferenceHelper getAPIURL:@"debug/connect"] andTag:REQ_TAG_DEBUG_CONNECT log:NO];
}

- (void)disconnectFromDebug {
    NSMutableDictionary *post = [[NSMutableDictionary alloc] init];
    [post setObject:[BNCPreferenceHelper getAppKey] forKey:@"app_id"];
    [post setObject:[BNCPreferenceHelper getDeviceFingerprintID] forKey:@"device_fingerprint_id"];
    
    [self postRequestAsync:post url:[BNCPreferenceHelper getAPIURL:@"debug/disconnect"] andTag:REQ_TAG_DEBUG_DISCONNECT log:NO];
}

- (void)sendLog:(NSString *)log {
    NSMutableDictionary *post = [NSMutableDictionary dictionaryWithObject:log forKey:@"log"];
    [post setObject:[BNCPreferenceHelper getAppKey] forKey:@"app_id"];
    [post setObject:[BNCPreferenceHelper getDeviceFingerprintID] forKey:@"device_fingerprint_id"];
    
    [self postRequestAsync:post url:[BNCPreferenceHelper getAPIURL:@"debug/log"] andTag:REQ_TAG_DEBUG_LOG log:NO];
}

- (void)sendScreenshot:(NSData *)data {
    NSMutableURLRequest *request = [[NSMutableURLRequest alloc] init];
    NSString *file = @"BNC_Debug_Screen.png";
    
    [request setURL:[NSURL URLWithString:[NSString stringWithFormat:@"%@?app_id=%@&device_fingerprint_id=%@", [BNCPreferenceHelper getAPIURL:@"debug/screenshot"], [BNCPreferenceHelper getAppKey], [BNCPreferenceHelper getDeviceFingerprintID]]]];
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
    NSLog(@"================== Data size: %lu", (unsigned long)[body length]);  //temp

    [self genericAsyncHTTPRequest:request withTag:REQ_TAG_DEBUG_SCREEN andLinkData:nil];
}

- (void)getReferralCode:(NSDictionary *)post {
    [self postRequestAsync:post url:[BNCPreferenceHelper getAPIURL:@"referralcode"] andTag:REQ_TAG_GET_REFERRAL_CODE];
}

- (void)validateReferralCode:(NSDictionary *)post {
    [self postRequestAsync:post url:[[BNCPreferenceHelper getAPIURL:@"referralcode/"] stringByAppendingString:[post objectForKey:@"referral_code"]] andTag:REQ_TAG_VALIDATE_REFERRAL_CODE];
}

- (void)applyReferralCode:(NSDictionary *)post {
    [self postRequestAsync:post url:[[BNCPreferenceHelper getAPIURL:@"applycode/"] stringByAppendingString:[post objectForKey:@"referral_code"]] andTag:REQ_TAG_APPLY_REFERRAL_CODE];
}


@end
