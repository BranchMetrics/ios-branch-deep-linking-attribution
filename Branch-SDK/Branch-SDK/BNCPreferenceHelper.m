//
//  BNCPreferenceHelper.m
//  Branch-SDK
//
//  Created by Alex Austin on 6/6/14.
//  Copyright (c) 2014 Branch Metrics. All rights reserved.
//

#import "BNCPreferenceHelper.h"
#import "BranchServerInterface.h"
#import "BNCConfig.h"

static const NSInteger DEFAULT_TIMEOUT = 3;
static const NSInteger RETRY_INTERVAL = 3;
static const NSInteger MAX_RETRIES = 5;
static const NSInteger APP_READ_INTERVAL = 520000;

static NSString *KEY_APP_KEY = @"bnc_app_key";

static NSString *KEY_DEVICE_FINGERPRINT_ID = @"bnc_device_fingerprint_id";
static NSString *KEY_SESSION_ID = @"bnc_session_id";
static NSString *KEY_IDENTITY_ID = @"bnc_identity_id";
static NSString *KEY_IDENTITY = @"bnc_identity";
static NSString *KEY_LINK_CLICK_IDENTIFIER = @"bnc_link_click_identifier";
static NSString *KEY_LINK_CLICK_ID = @"bnc_link_click_id";
static NSString *KEY_SESSION_PARAMS = @"bnc_session_params";
static NSString *KEY_INSTALL_PARAMS = @"bnc_install_params";
static NSString *KEY_USER_URL = @"bnc_user_url";
static NSString *KEY_IS_REFERRABLE = @"bnc_is_referrable";
static NSString *KEY_APP_LIST_CHECK = @"bnc_app_list_check";

static NSString *KEY_CREDITS = @"bnc_credits";
static NSString *KEY_CREDIT_BASE = @"bnc_credit_base_";

static NSString *KEY_COUNTS = @"bnc_counts";
static NSString *KEY_TOTAL_BASE = @"bnc_total_base_";
static NSString *KEY_UNIQUE_BASE = @"bnc_unique_base_";

static BNCPreferenceHelper *instance = nil;
static BOOL BNC_Debug = NO;
static BOOL BNC_Dev_Debug = NO;
static BOOL BNC_Remote_Debug = NO;

static dispatch_queue_t bnc_asyncLogQueue = nil;
static id<BNCDebugConnectionDelegate> bnc_asyncDebugConnectionDelegate = nil;
static BranchServerInterface *serverInterface = nil;

static NSString *KEY_TIMEOUT = @"bnc_timeout";
static NSString *KEY_RETRY_INTERVAL = @"bnc_retry_interval";
static NSString *KEY_RETRY_COUNT = @"bnc_retry_count";

static id<BNCTestDelegate> bnc_testDelegate = nil;

@interface BNCPreferenceHelper() <BNCServerInterfaceDelegate>

@end

@implementation BNCPreferenceHelper

+ (void)setDebug {
    BNC_Debug = YES;
    
    if (!instance) {
        instance = [[BNCPreferenceHelper alloc] init];
        serverInterface = [[BranchServerInterface alloc] init];
        serverInterface.delegate = instance;
        bnc_asyncLogQueue = dispatch_queue_create("bnc_log_queue", NULL);
    }
    
    dispatch_async(bnc_asyncLogQueue, ^{
        [serverInterface connectToDebug];
    });
}

+ (void)setDevDebug {
    BNC_Dev_Debug = YES;
}

+ (BOOL)getDevDebug {
    return BNC_Dev_Debug;
}

+ (void)clearDebug {
    BNC_Debug = NO;
    
    if (BNC_Remote_Debug) {
        BNC_Remote_Debug = NO;
        
        dispatch_async(bnc_asyncLogQueue, ^{
            [serverInterface disconnectFromDebug];
        });
    }
}

+ (BOOL)isDebug {
    return BNC_Debug;
}

+ (BOOL)isRemoteDebug {
    return BNC_Remote_Debug;
}

+ (void)log:(NSString *)filename line:(int)line message:(NSString *)format, ... {
    if (BNC_Debug || BNC_Dev_Debug) {
        va_list args;
        va_start(args, format);
        NSString *log = [NSString stringWithFormat:@"[%@:%d] %@", filename, line, [[NSString alloc] initWithFormat:format arguments:args]];
        va_end(args);
        NSLog(@"%@", log);
        
        if (BNC_Remote_Debug) {
            dispatch_async(bnc_asyncLogQueue, ^{
                [serverInterface sendLog:log];
            });
        }
    }
}

+ (void)keepDebugAlive {
    if (BNC_Remote_Debug) {
        dispatch_async(bnc_asyncLogQueue, ^{
            [serverInterface sendLog:@""];
        });
    }
}

+ (void)sendScreenshot:(NSData *)data {
    if (BNC_Remote_Debug) {
        dispatch_async(bnc_asyncLogQueue, ^{
            [serverInterface sendScreenshot:data];
        });
    }
}

+ (void)setDebugConnectionDelegate:(id<BNCDebugConnectionDelegate>) debugConnectionDelegate {
    bnc_asyncDebugConnectionDelegate = debugConnectionDelegate;
}

+ (NSString *)getAPIBaseURL {
    return [NSString stringWithFormat:@"%@/%@/", BNC_API_BASE_URL, BNC_API_VERSION];
}

+ (NSString *)getAPIURL:(NSString *) endpoint {
    return [[BNCPreferenceHelper getAPIBaseURL] stringByAppendingString:endpoint];
}

// PREFERENCE STORAGE

+ (void)setTimeout:(NSInteger)timeout {
    [BNCPreferenceHelper writeIntegerToDefaults:KEY_TIMEOUT value:timeout];
}

+ (NSInteger)getTimeout {
    NSInteger timeout = [BNCPreferenceHelper readIntegerFromDefaults:KEY_TIMEOUT];
    if (timeout <= 0) {
        timeout = DEFAULT_TIMEOUT;
    }
    return timeout;
}

+ (void)setRetryInterval:(NSInteger)retryInterval {
    [BNCPreferenceHelper writeIntegerToDefaults:KEY_RETRY_INTERVAL value:retryInterval];
}

+ (NSInteger)getRetryInterval {
    NSInteger retryInt = [BNCPreferenceHelper readIntegerFromDefaults:KEY_RETRY_INTERVAL];
    if (retryInt <= 0) {
        retryInt = RETRY_INTERVAL;
    }
    return retryInt;
}

+ (void)setRetryCount:(NSInteger)retryCount {
    [BNCPreferenceHelper writeIntegerToDefaults:KEY_RETRY_COUNT value:retryCount];
}

+ (NSInteger)getRetryCount {
    NSInteger retryCount = [BNCPreferenceHelper readIntegerFromDefaults:KEY_RETRY_COUNT];
    if (retryCount <= 0) {
        retryCount = MAX_RETRIES;
    }
    return retryCount;
}

+ (NSString *)getAppKey {
    NSString *ret = [[[NSBundle mainBundle] infoDictionary] objectForKey:KEY_APP_KEY];
    if (!ret || ret.length == 0) {
        // for backward compatibility
        ret = [BNCPreferenceHelper readStringFromDefaults:KEY_APP_KEY];
        if (!ret) {
            ret = NO_STRING_VALUE;
        }
    }
    
    return ret;
}

+ (void)setAppKey:(NSString *)appKey {
    [BNCPreferenceHelper writeObjectToDefaults:KEY_APP_KEY value:appKey];
}

+ (void)setDeviceFingerprintID:(NSString *)deviceID {
    [BNCPreferenceHelper writeObjectToDefaults:KEY_DEVICE_FINGERPRINT_ID value:deviceID];
}

+ (NSString *)getDeviceFingerprintID {
    NSString *ret = [BNCPreferenceHelper readStringFromDefaults:KEY_DEVICE_FINGERPRINT_ID];
    if (!ret)
        ret = NO_STRING_VALUE;
    return ret;
}

+ (void)setSessionID:(NSString *)sessionID {
    [BNCPreferenceHelper writeObjectToDefaults:KEY_SESSION_ID value:sessionID];
}

+ (NSString *)getSessionID {
    NSString *ret = [BNCPreferenceHelper readStringFromDefaults:KEY_SESSION_ID];
    if (!ret)
        ret = NO_STRING_VALUE;
    return ret;
}

+ (void)setIdentityID:(NSString *)identityID {
    [BNCPreferenceHelper writeObjectToDefaults:KEY_IDENTITY_ID value:identityID];
}

+ (NSString *)getIdentityID {
    NSString *ret = [BNCPreferenceHelper readStringFromDefaults:KEY_IDENTITY_ID];
    if (!ret)
        ret = NO_STRING_VALUE;
    return ret;
}

+ (void)setUserIdentity:(NSString *)userIdentity {
    [BNCPreferenceHelper writeObjectToDefaults:KEY_IDENTITY value:userIdentity];
}
+ (NSString *)getUserIdentity {
    NSString *ret = [BNCPreferenceHelper readStringFromDefaults:KEY_IDENTITY];
    if (!ret)
        ret = NO_STRING_VALUE;
    return ret;

}

+ (void)setLinkClickIdentifier:(NSString *)linkClickIdentifier {
    [BNCPreferenceHelper writeObjectToDefaults:KEY_LINK_CLICK_IDENTIFIER value:linkClickIdentifier];

}
+ (NSString *)getLinkClickIdentifier {
    NSString *ret = [BNCPreferenceHelper readStringFromDefaults:KEY_LINK_CLICK_IDENTIFIER];
    if (!ret)
        ret = NO_STRING_VALUE;
    return ret;
}

+ (void)setLinkClickID:(NSString *)linkClickId {
    [BNCPreferenceHelper writeObjectToDefaults:KEY_LINK_CLICK_ID value:linkClickId];
}

+ (NSString *)getLinkClickID {
    NSString *ret = [BNCPreferenceHelper readStringFromDefaults:KEY_LINK_CLICK_ID];
    if (!ret)
        ret = NO_STRING_VALUE;
    return ret;
}

+ (void)setSessionParams:(NSString *)sessionParams {
    [BNCPreferenceHelper writeObjectToDefaults:KEY_SESSION_PARAMS value:sessionParams];
}

+ (NSString *)getSessionParams {
    NSString *ret = [BNCPreferenceHelper readStringFromDefaults:KEY_SESSION_PARAMS];
    if (!ret)
        ret = NO_STRING_VALUE;
    return ret;
}

+ (void)setInstallParams:(NSString *)installParams {
    [BNCPreferenceHelper writeObjectToDefaults:KEY_INSTALL_PARAMS value:installParams];
}

+ (NSString *)getInstallParams {
    NSString *ret = [BNCPreferenceHelper readStringFromDefaults:KEY_INSTALL_PARAMS];
    if (!ret)
        ret = NO_STRING_VALUE;
    return ret;
}

+ (void)setUserURL:(NSString *)userUrl {
    [BNCPreferenceHelper writeObjectToDefaults:KEY_USER_URL value:userUrl];
}

+ (NSString *)getUserURL {
    NSString *ret = [BNCPreferenceHelper readStringFromDefaults:KEY_USER_URL];
    if (!ret)
        ret = NO_STRING_VALUE;
    return ret;
}

+ (NSInteger)getIsReferrable {
    return [BNCPreferenceHelper readIntegerFromDefaults:KEY_IS_REFERRABLE];
}

+ (void)setIsReferrable {
    [BNCPreferenceHelper writeIntegerToDefaults:KEY_IS_REFERRABLE value:1];
}

+ (void)clearIsReferrable {
    [BNCPreferenceHelper writeIntegerToDefaults:KEY_IS_REFERRABLE value:0];
}

+ (void)setAppListCheckDone {
    [BNCPreferenceHelper writeObjectToDefaults:KEY_APP_LIST_CHECK value:[NSDate date]];
}

+ (BOOL)getNeedAppListCheck {
    NSDate *lastDate = (NSDate *)[self readObjectFromDefaults:KEY_APP_LIST_CHECK];
    if (lastDate) {
        NSDate *currDate = [NSDate date];
        NSTimeInterval diff = [currDate timeIntervalSinceDate:lastDate];
        if (diff < APP_READ_INTERVAL) {
            return NO;
        }
    }
    return YES;
}

+ (void)clearUserCreditsAndCounts {
    [BNCPreferenceHelper setCreditsDictionary:[[NSDictionary alloc] init]];
    [BNCPreferenceHelper setCountsDictionary:[[NSDictionary alloc] init]];
}

// CREDIT STORAGE

+ (NSDictionary *)getCreditsDictionary {
    NSDictionary *dict = (NSDictionary *)[BNCPreferenceHelper readObjectFromDefaults:KEY_CREDITS];
    if (!dict)
        dict = [[NSDictionary alloc] init];
    return dict;
}

+ (void)setCreditsDictionary:(NSDictionary *)credits {
    [BNCPreferenceHelper writeObjectToDefaults:KEY_CREDITS value:credits];
}

+ (void)setCreditCount:(NSInteger)count {
    [self setCreditCount:count forBucket:@"default"];
}
+ (void)setCreditCount:(NSInteger)count forBucket:(NSString *)bucket {
    NSMutableDictionary *creditDict = [[BNCPreferenceHelper getCreditsDictionary] mutableCopy];
    [creditDict setObject:[NSNumber numberWithInteger:count] forKey:[KEY_CREDIT_BASE stringByAppendingString:bucket]];
    [BNCPreferenceHelper setCreditsDictionary:creditDict];
}
+ (NSInteger)getCreditCount {
    return [self getCreditCountForBucket:@"default"];
}
+ (NSInteger)getCreditCountForBucket:(NSString *)bucket {
    NSDictionary *creditDict = [BNCPreferenceHelper getCreditsDictionary];
    return [[creditDict objectForKey:[KEY_CREDIT_BASE stringByAppendingString:bucket]] integerValue];
}

// COUNT STORAGE

+ (NSDictionary *)getCountsDictionary {
    NSDictionary *dict = (NSDictionary *)[BNCPreferenceHelper readObjectFromDefaults:KEY_COUNTS];
    if (!dict)
        dict = [[NSDictionary alloc] init];
    return dict;
}

+ (void)setCountsDictionary:(NSDictionary *)counts {
    [BNCPreferenceHelper writeObjectToDefaults:KEY_COUNTS value:counts];
}

+ (void)setActionTotalCount:(NSString *)action withCount:(NSInteger)count {
    NSMutableDictionary *counts = [[BNCPreferenceHelper getCountsDictionary] mutableCopy];
    [counts setObject:[NSNumber numberWithInteger:count] forKey:[KEY_TOTAL_BASE stringByAppendingString:action]];
    [BNCPreferenceHelper setCountsDictionary:counts];
}
+ (void)setActionUniqueCount:(NSString *)action withCount:(NSInteger)count {
    NSMutableDictionary *counts = [[BNCPreferenceHelper getCountsDictionary] mutableCopy];
    [counts setObject:[NSNumber numberWithInteger:count] forKey:[KEY_UNIQUE_BASE stringByAppendingString:action]];
    [BNCPreferenceHelper setCountsDictionary:counts];
}
+ (NSInteger)getActionTotalCount:(NSString *)action {
    NSDictionary *counts = [BNCPreferenceHelper getCountsDictionary];
    return [[counts objectForKey:[KEY_TOTAL_BASE stringByAppendingString:action]] integerValue];
}
+ (NSInteger)getActionUniqueCount:(NSString *)action {
    NSDictionary *counts = [BNCPreferenceHelper getCountsDictionary];
    return [[counts objectForKey:[KEY_UNIQUE_BASE stringByAppendingString:action]] integerValue];
}

// GENERIC FUNCS

+ (void)writeIntegerToDefaults:(NSString *)key value:(NSInteger)value
{
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [defaults setInteger:value forKey:key];
    [defaults synchronize];
}

+ (void)writeBoolToDefaults:(NSString *)key value:(BOOL)value
{
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [defaults setBool:value forKey:key];
    [defaults synchronize];
}

+ (void)writeObjectToDefaults:(NSString *)key value:(NSObject *)value
{
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [defaults setObject:value forKey:key];
    [defaults synchronize];
}

+ (NSObject *)readObjectFromDefaults:(NSString *)key
{
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    NSObject *obj = [defaults objectForKey:key];
    return obj;
}

+ (NSString *)readStringFromDefaults:(NSString *)key
{
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    NSString *str = [defaults stringForKey:key];
    return str;
}

+ (BOOL)readBoolFromDefaults:(NSString *)key {
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    BOOL boo = [defaults boolForKey:key];
    return boo;
}

+ (NSInteger)readIntegerFromDefaults:(NSString *)key
{
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    NSInteger integ = [defaults integerForKey:key];
    return integ;
}


// BASE 64 CRAP found on http://ios-dev-blog.com/base64-encodingdecoding/

static const char _base64EncodingTable[64] = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/";
static const short _base64DecodingTable[256] = {
	-2, -2, -2, -2, -2, -2, -2, -2, -2, -1, -1, -2, -1, -1, -2, -2,
	-2, -2, -2, -2, -2, -2, -2, -2, -2, -2, -2, -2, -2, -2, -2, -2,
	-1, -2, -2, -2, -2, -2, -2, -2, -2, -2, -2, 62, -2, -2, -2, 63,
	52, 53, 54, 55, 56, 57, 58, 59, 60, 61, -2, -2, -2, -2, -2, -2,
	-2,  0,  1,  2,  3,  4,  5,  6,  7,  8,  9, 10, 11, 12, 13, 14,
	15, 16, 17, 18, 19, 20, 21, 22, 23, 24, 25, -2, -2, -2, -2, -2,
	-2, 26, 27, 28, 29, 30, 31, 32, 33, 34, 35, 36, 37, 38, 39, 40,
	41, 42, 43, 44, 45, 46, 47, 48, 49, 50, 51, -2, -2, -2, -2, -2,
	-2, -2, -2, -2, -2, -2, -2, -2, -2, -2, -2, -2, -2, -2, -2, -2,
	-2, -2, -2, -2, -2, -2, -2, -2, -2, -2, -2, -2, -2, -2, -2, -2,
	-2, -2, -2, -2, -2, -2, -2, -2, -2, -2, -2, -2, -2, -2, -2, -2,
	-2, -2, -2, -2, -2, -2, -2, -2, -2, -2, -2, -2, -2, -2, -2, -2,
	-2, -2, -2, -2, -2, -2, -2, -2, -2, -2, -2, -2, -2, -2, -2, -2,
	-2, -2, -2, -2, -2, -2, -2, -2, -2, -2, -2, -2, -2, -2, -2, -2,
	-2, -2, -2, -2, -2, -2, -2, -2, -2, -2, -2, -2, -2, -2, -2, -2,
	-2, -2, -2, -2, -2, -2, -2, -2, -2, -2, -2, -2, -2, -2, -2, -2
};

+ (NSString *)base64EncodeStringToString:(NSString *)strData {
	return [self base64EncodeData:[strData dataUsingEncoding:NSUTF8StringEncoding]];
}

+ (NSString *)base64DecodeStringToString:(NSString *)strData {
    return [[NSString alloc] initWithData:[BNCPreferenceHelper base64DecodeString:strData] encoding:NSUTF8StringEncoding];
}

+ (NSString *)base64EncodeData:(NSData *)objData {
	const unsigned char * objRawData = [objData bytes];
	char * objPointer;
	char * strResult;
    
	// Get the Raw Data length and ensure we actually have data
	long intLength = [objData length];
	if (intLength == 0) return nil;
    
	// Setup the String-based Result placeholder and pointer within that placeholder
	strResult = (char *)calloc(((intLength + 2) / 3) * 4, sizeof(char));
	objPointer = strResult;
    
	// Iterate through everything
	while (intLength > 2) { // keep going until we have less than 24 bits
		*objPointer++ = _base64EncodingTable[objRawData[0] >> 2];
		*objPointer++ = _base64EncodingTable[((objRawData[0] & 0x03) << 4) + (objRawData[1] >> 4)];
		*objPointer++ = _base64EncodingTable[((objRawData[1] & 0x0f) << 2) + (objRawData[2] >> 6)];
		*objPointer++ = _base64EncodingTable[objRawData[2] & 0x3f];
        
		// we just handled 3 octets (24 bits) of data
		objRawData += 3;
		intLength -= 3;
	}
    
	// now deal with the tail end of things
	if (intLength != 0) {
		*objPointer++ = _base64EncodingTable[objRawData[0] >> 2];
		if (intLength > 1) {
			*objPointer++ = _base64EncodingTable[((objRawData[0] & 0x03) << 4) + (objRawData[1] >> 4)];
			*objPointer++ = _base64EncodingTable[(objRawData[1] & 0x0f) << 2];
			*objPointer++ = '=';
		} else {
			*objPointer++ = _base64EncodingTable[(objRawData[0] & 0x03) << 4];
			*objPointer++ = '=';
			*objPointer++ = '=';
		}
	}
    
	// Terminate the string-based result
	*objPointer = '\0';
    
    NSString *retString = [NSString stringWithCString:strResult encoding:NSASCIIStringEncoding];
    free(strResult);
    
	// Return the results as an NSString object
	return retString;
}

+ (NSData *)base64DecodeString:(NSString *)strBase64 {
	const char * objPointer = [strBase64 cStringUsingEncoding:NSASCIIStringEncoding];
	long intLength = strlen(objPointer);
	int intCurrent;
	int i = 0, j = 0, k;
    
    char * objResult;
	objResult = calloc(intLength, sizeof(char));
    
	// Run through the whole string, converting as we go
	while ( ((intCurrent = *objPointer++) != '\0') && (intLength-- > 0) ) {
		if (intCurrent == '=') {
			if (*objPointer != '=' && ((i % 4) == 1)) {// || (intLength > 0)) {
				// the padding character is invalid at this point -- so this entire string is invalid
				free(objResult);
				return nil;
			}
			continue;
		}
        
		intCurrent = _base64DecodingTable[intCurrent];
		if (intCurrent == -1) {
			// we're at a whitespace -- simply skip over
			continue;
		} else if (intCurrent == -2) {
			// we're at an invalid character
			free(objResult);
			return nil;
		}
        
		switch (i % 4) {
			case 0:
				objResult[j] = intCurrent << 2;
				break;
                
			case 1:
				objResult[j++] |= intCurrent >> 4;
				objResult[j] = (intCurrent & 0x0f) << 4;
				break;
                
			case 2:
				objResult[j++] |= intCurrent >>2;
				objResult[j] = (intCurrent & 0x03) << 6;
				break;
                
			case 3:
				objResult[j++] |= intCurrent;
				break;
		}
		i++;
	}
    
	// mop things up if we ended on a boundary
	k = j;
	if (intCurrent == '=') {
		switch (i % 4) {
			case 1:
				// Invalid state
				free(objResult);
				return nil;
                
			case 2:
				k++;
				// flow through
			case 3:
				objResult[k] = 0;
		}
	}
    
	// Cleanup and setup the return NSData
	NSData * objData = [[NSData alloc] initWithBytes:objResult length:j] ;
	free(objResult);
	return objData;
}

+ (void)setTestDelegate:(id<BNCTestDelegate>) testDelegate {
    bnc_testDelegate = testDelegate;
}

+ (void)simulateInitFinished {
    [bnc_testDelegate simulateInitFinished];
}

#pragma mark - ServerInterface delegate

- (void)serverCallback:(BNCServerResponse *)response {
    if (response) {
        NSInteger status = [response.statusCode integerValue];
        NSString *requestTag = response.tag;
        
        if (status == 465) {    // server not listening
            BNC_Remote_Debug = NO;
            NSLog(@"======= Server is not listening =======");
        } else if (status >= 400 && status < 500) {
            if (response.data && [response.data objectForKey:@"error"]) {
                NSLog(@"Branch API Error: %@", [[response.data objectForKey:@"error"] objectForKey:@"message"]);
            }
        } else if (status != 200) {
            if (status == NSURLErrorNotConnectedToInternet || status == NSURLErrorNetworkConnectionLost || status == NSURLErrorCannotFindHost) {
                NSLog(@"Branch API Error: Poor network connectivity. Please try again later.");
            } else {
                NSLog(@"Trouble reaching server. Please try again in a few minutes.");
            }
        } else if ([requestTag isEqualToString:REQ_TAG_DEBUG_CONNECT]) {
            BNC_Remote_Debug = YES;
            [bnc_asyncDebugConnectionDelegate bnc_debugConnectionEstablished];
        }
    }
}

@end
