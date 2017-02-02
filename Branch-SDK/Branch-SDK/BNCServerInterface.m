//
//  BNCServerInterface.m
//  Branch-SDK
//
//  Created by Alex Austin on 6/6/14.
//  Copyright (c) 2014 Branch Metrics. All rights reserved.
//

#import "BNCServerInterface.h"
#import "BNCConfig.h"
#import "BNCEncodingUtils.h"
#import "BNCError.h"
#import "BranchConstants.h"
#import "BNCDeviceInfo.h"
#import "NSMutableDictionary+Branch.h"

typedef void (^NSURLSessionCompletionHandler) (NSData *data, NSURLResponse *response, NSError *error);
typedef void (^NSURLConnectionCompletionHandler) (NSURLResponse *response, NSData *responseData, NSError *error);

@implementation BNCServerInterface

NSDate *startTime;
NSString *requestEndpoint;

#pragma mark - GET methods

- (void)getRequest:(NSDictionary *)params url:(NSString *)url key:(NSString *)key callback:(BNCServerCallback)callback {
    [self getRequest:params url:url key:key retryNumber:0 log:YES callback:callback];
}

- (void)getRequest:(NSDictionary *)params url:(NSString *)url key:(NSString *)key log:(BOOL)log callback:(BNCServerCallback)callback {
    [self getRequest:params url:url key:key retryNumber:0 log:log callback:callback];
}

- (void)getRequest:(NSDictionary *)params url:(NSString *)url key:(NSString *)key retryNumber:(NSInteger)retryNumber log:(BOOL)log callback:(BNCServerCallback)callback {
    NSURLRequest *request = [self prepareGetRequest:params url:url key:key retryNumber:retryNumber log:log];

    [self genericHTTPRequest:request retryNumber:retryNumber log:log callback:callback retryHandler:^NSURLRequest *(NSInteger lastRetryNumber) {
        return [self prepareGetRequest:params url:url key:key retryNumber:++lastRetryNumber log:log];
    }];
}

- (BNCServerResponse *)getRequest:(NSDictionary *)params url:(NSString *)url key:(NSString *)key {
    return [self getRequest:params url:url key:key log:YES];
}

- (BNCServerResponse *)getRequest:(NSDictionary *)params url:(NSString *)url key:(NSString *)key log:(BOOL)log {
    NSURLRequest *request = [self prepareGetRequest:params url:url key:key retryNumber:0 log:log];
    return [self genericHTTPRequest:request log:log];
}


#pragma mark - POST methods

- (void)postRequest:(NSDictionary *)post url:(NSString *)url key:(NSString *)key callback:(BNCServerCallback)callback {
    [self postRequest:post url:url retryNumber:0 key:key log:YES callback:callback];
}

- (void)postRequest:(NSDictionary *)post url:(NSString *)url key:(NSString *)key log:(BOOL)log callback:(BNCServerCallback)callback {
    [self postRequest:post url:url retryNumber:0 key: key log:log callback:callback];
}

- (void)postRequest:(NSDictionary *)post url:(NSString *)url retryNumber:(NSInteger)retryNumber key:(NSString *)key log:(BOOL)log callback:(BNCServerCallback)callback {
    NSDictionary *extendedParams = [self updateDeviceInfoToParams:post];
    NSURLRequest *request = [self preparePostRequest:extendedParams url:url key:key retryNumber:retryNumber log:log];
    
    // Instrumentation metrics
    requestEndpoint = [self.preferenceHelper getEndpointFromURL:url];

    [self genericHTTPRequest:request retryNumber:retryNumber log:log callback:callback retryHandler:^NSURLRequest *(NSInteger lastRetryNumber) {
        return [self preparePostRequest:extendedParams url:url key:key retryNumber:++lastRetryNumber log:log];
    }];
}

- (BNCServerResponse *)postRequest:(NSDictionary *)post url:(NSString *)url key:(NSString *)key log:(BOOL)log {
    NSDictionary *extendedParams = [self updateDeviceInfoToParams:post];
    NSURLRequest *request = [self preparePostRequest:extendedParams url:url key:key retryNumber:0 log:log];
    return [self genericHTTPRequest:request log:log];
}


#pragma mark - Generic requests

- (void)genericHTTPRequest:(NSURLRequest *)request log:(BOOL)log callback:(BNCServerCallback)callback {
    [self genericHTTPRequest:request retryNumber:0 log:log callback:callback retryHandler:^NSURLRequest *(NSInteger lastRetryNumber) {
        return request;
    }];
}

- (void)genericHTTPRequest:(NSURLRequest *)request retryNumber:(NSInteger)retryNumber log:(BOOL)log callback:(BNCServerCallback)callback retryHandler:(NSURLRequest *(^)(NSInteger))retryHandler {
    // This method uses NSURLConnection for iOS 6 and NSURLSession for iOS 7 and above
    // Assigning completion handlers blocks to variables eliminates redundancy 
    // Defining both completion handlers before the request methods otherwise they won't be called
    NSURLSessionCompletionHandler sessionHandler = ^void(NSData *data, NSURLResponse *response, NSError *error) {
        BNCServerResponse *serverResponse = [self processServerResponse:response data:data error:error log:log];
        NSInteger status = [serverResponse.statusCode integerValue];
        // If the phone is in a poor network condition,
        // iOS will return statuses such as -1001, -1003, -1200, -9806
        // indicating various parts of the HTTP post failed.
        // We should retry in those conditions in addition to the case where the server returns a 500
        BOOL isRetryableStatusCode = status >= 500 || status < 0;
        
        // Retry the request if appropriate
        if (retryNumber < self.preferenceHelper.retryCount && isRetryableStatusCode) {
            dispatch_time_t dispatchTime = dispatch_time(DISPATCH_TIME_NOW, self.preferenceHelper.retryInterval * NSEC_PER_SEC);
            dispatch_after(dispatchTime, dispatch_get_main_queue(), ^{
                if (log) {
                    [self.preferenceHelper log:FILE_NAME line:LINE_NUM message:@"Replaying request with url %@", request.URL.relativePath];
                }
                
                // Create the next request
                NSURLRequest *retryRequest = retryHandler(retryNumber);
                [self genericHTTPRequest:retryRequest retryNumber:(retryNumber + 1) log:log callback:callback retryHandler:retryHandler];
            });
            
            // Do not continue on if retrying, else the callback will be called incorrectly
            return;
        }
        else if (callback) {
            // Wrap up bad statuses w/ specific error messages
            if (status >= 500) {
                error = [NSError errorWithDomain:BNCErrorDomain code:BNCServerProblemError userInfo:@{ NSLocalizedDescriptionKey: @"Trouble reaching the Branch servers, please try again shortly" }];
            }
            else if (status == 409) {
                error = [NSError errorWithDomain:BNCErrorDomain code:BNCDuplicateResourceError userInfo:@{ NSLocalizedDescriptionKey: @"A resource with this identifier already exists" }];
            }
            else if (status >= 400) {
                NSString *errorString = @"The request was invalid.";
                
                if ([serverResponse.data objectForKey:@"error"] && [[serverResponse.data objectForKey:@"error"] isKindOfClass:[NSString class]]) {
                    errorString = [serverResponse.data objectForKey:@"error"];
                }
                
                error = [NSError errorWithDomain:BNCErrorDomain code:BNCBadRequestError userInfo:@{ NSLocalizedDescriptionKey: errorString }];
            }
            
            if (error && log) {
                [self.preferenceHelper log:FILE_NAME line:LINE_NUM message:@"An error prevented request to %@ from completing: %@", request.URL.absoluteString, error.localizedDescription];
            }
            
        }
        dispatch_async(dispatch_get_main_queue(), ^{
            if (callback)
                callback(serverResponse, error);
        });
    };
    
    NSURLConnectionCompletionHandler connectionHandler = ^void(NSURLResponse *response, NSData *responseData, NSError *error) {
        // NSURLConnection and NSURLSession expect the same arguments for completion handlers but in different order
        sessionHandler(responseData, response, error);
    };
    
    // start the reqeust timer here. This will account for retries.
    startTime = [NSDate date];

    // NSURLSession is available in iOS 7 and above
    if (NSFoundationVersionNumber >= NSFoundationVersionNumber_iOS_7_0) {
        NSURLSession *session = [NSURLSession sessionWithConfiguration:[NSURLSessionConfiguration defaultSessionConfiguration]];
        NSURLSessionDataTask *task = [session dataTaskWithRequest:request.copy completionHandler:sessionHandler];
        [task resume];
        [session finishTasksAndInvalidate];
    } else {
        #pragma clang diagnostic push
        #pragma clang diagnostic ignored "-Wdeprecated-declarations"
        [NSURLConnection sendAsynchronousRequest:request queue:[NSOperationQueue mainQueue] completionHandler:connectionHandler];
        #pragma clang diagnostic pop
    }
}

- (BNCServerResponse *)genericHTTPRequest:(NSURLRequest *)request log:(BOOL)log {
    __block NSURLResponse *_response = nil;
    __block NSError *_error = nil;
    __block NSData *_respData = nil;
    
    //NSURLSession is available in iOS 7 and above
    if (NSFoundationVersionNumber >= NSFoundationVersionNumber_iOS_7_0) {
        dispatch_semaphore_t semaphore = dispatch_semaphore_create(0);
        NSURLSession *session = [NSURLSession sessionWithConfiguration:[NSURLSessionConfiguration defaultSessionConfiguration]];
        NSURLSessionDataTask *task = [session dataTaskWithRequest:request completionHandler:^(NSData * _Nullable data, NSURLResponse * _Nullable urlResp, NSError * _Nullable error) {
            _response = urlResp;
            _error = error;
            _respData = data;
            dispatch_semaphore_signal(semaphore);
        }];
        [task resume];
        [session finishTasksAndInvalidate];
        dispatch_semaphore_wait(semaphore, DISPATCH_TIME_FOREVER);
    } else {
        #pragma clang diagnostic push
        #pragma clang diagnostic ignored "-Wdeprecated-declarations"
        _respData = [NSURLConnection sendSynchronousRequest:request returningResponse:&_response error:&_error];
        #pragma clang diagnostic pop
    }
    return [self processServerResponse:_response data:_respData error:_error log:log];
}


#pragma mark - Internals

- (NSURLRequest *)prepareGetRequest:(NSDictionary *)params url:(NSString *)url key:(NSString *)key retryNumber:(NSInteger)retryNumber log:(BOOL)log {
    NSDictionary *preparedParams = [self prepareParamDict:params key:key retryNumber:retryNumber requestType:@"GET"];
    
    NSString *requestUrlString = [NSString stringWithFormat:@"%@%@", url, [BNCEncodingUtils encodeDictionaryToQueryString:preparedParams]];
    
    if (log) {
        [self.preferenceHelper log:FILE_NAME line:LINE_NUM message:@"using url = %@", url];
    }
    
    NSMutableURLRequest *request = [[NSMutableURLRequest alloc] init];
    [request setURL:[NSURL URLWithString:requestUrlString]];
    [request setHTTPMethod:@"GET"];
    [request setValue:@"application/json" forHTTPHeaderField:@"Content-Type"];
    
    return request;
}

- (NSURLRequest *)preparePostRequest:(NSDictionary *)params url:(NSString *)url key:(NSString *)key retryNumber:(NSInteger)retryNumber log:(BOOL)log {
    NSDictionary *preparedParams = [self prepareParamDict:params key:key retryNumber:retryNumber requestType:@"POST"];

    NSData *postData = [BNCEncodingUtils encodeDictionaryToJsonData:preparedParams];
    NSString *postLength = [NSString stringWithFormat:@"%lu", (unsigned long)[postData length]];
    
    if (log) {
        [self.preferenceHelper log:FILE_NAME line:LINE_NUM message:@"using url = %@", url];
        [self.preferenceHelper log:FILE_NAME line:LINE_NUM message:@"body = %@", preparedParams];
    }
    
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:url]];
    [request setTimeoutInterval:self.preferenceHelper.timeout];
    [request setHTTPMethod:@"POST"];
    [request setValue:postLength forHTTPHeaderField:@"Content-Length"];
    [request setValue:@"application/json" forHTTPHeaderField:@"Content-Type"];
    [request setHTTPBody:postData];
    
    return request;
}

- (NSDictionary *)prepareParamDict:(NSDictionary *)params
							   key:(NSString *)key
					   retryNumber:(NSInteger)retryNumber requestType:(NSString *)reqType {

    NSMutableDictionary *fullParamDict = [[NSMutableDictionary alloc] init];
    [fullParamDict bnc_safeAddEntriesFromDictionary:params];
    fullParamDict[@"sdk"] = [NSString stringWithFormat:@"ios%@", BNC_SDK_VERSION];
    
    // using rangeOfString instead of containsString to support devices running pre iOS 8
    if ([[[NSBundle mainBundle] executablePath] rangeOfString:@".appex/"].location != NSNotFound) {
        fullParamDict[@"ios_extension"] = @(1);
    }
    fullParamDict[@"retryNumber"] = @(retryNumber);
    fullParamDict[@"branch_key"] = key;

    NSMutableDictionary *metadata = [[NSMutableDictionary alloc] init];
    [metadata bnc_safeAddEntriesFromDictionary:self.preferenceHelper.requestMetadataDictionary];
    [metadata bnc_safeAddEntriesFromDictionary:fullParamDict[BRANCH_REQUEST_KEY_STATE]];
    if (metadata.count) {
        fullParamDict[BRANCH_REQUEST_KEY_STATE] = metadata;
    }
    // we only send instrumentation info in the POST body request
    if (self.preferenceHelper.instrumentationDictionary.count && [reqType isEqualToString:@"POST"]) {
        fullParamDict[BRANCH_REQUEST_KEY_INSTRUMENTATION] = self.preferenceHelper.instrumentationDictionary;
    }
   
    return fullParamDict;
}

- (BNCServerResponse *)processServerResponse:(NSURLResponse *)response data:(NSData *)data error:(NSError *)error log:(BOOL)log {
    BNCServerResponse *serverResponse = [[BNCServerResponse alloc] init];

    if (!error) {
        serverResponse.statusCode = @([(NSHTTPURLResponse *)response statusCode]);
        serverResponse.data = [BNCEncodingUtils decodeJsonDataToDictionary:data];
    }
    else {
        serverResponse.statusCode = @(error.code);
        serverResponse.data = error.userInfo;
    }

    if (log) {
        [self.preferenceHelper log:FILE_NAME line:LINE_NUM message:@"returned = %@", serverResponse];
    }
    
    [self collectInstrumentationMetrics];
    return serverResponse;
}

- (void) collectInstrumentationMetrics {
    // multiplying by negative because startTime happened in the past
    NSTimeInterval elapsedTime = [startTime timeIntervalSinceNow] * -1000.0;
    NSString *lastRoundTripTime = [[NSNumber numberWithDouble:floor(elapsedTime)] stringValue];
    NSString * brttKey = [NSString stringWithFormat:@"%@-brtt", requestEndpoint];
    [self.preferenceHelper clearInstrumentationDictionary];
    [self.preferenceHelper addInstrumentationDictionaryKey:brttKey value:lastRoundTripTime];
}
- (void)updateDeviceInfoToMutableDictionary:(NSMutableDictionary *)dict {
    BNCDeviceInfo *deviceInfo  = [BNCDeviceInfo getInstance];
   
    if (deviceInfo.hardwareId && deviceInfo.hardwareIdType) {
        dict[BRANCH_REQUEST_KEY_HARDWARE_ID] = deviceInfo.hardwareId;
        dict[BRANCH_REQUEST_KEY_HARDWARE_ID_TYPE] = deviceInfo.hardwareIdType;
        dict[BRANCH_REQUEST_KEY_IS_HARDWARE_ID_REAL] = @(deviceInfo.isRealHardwareId);
    }
    
    [self safeSetValue:deviceInfo.vendorId forKey:BRANCH_REQUEST_KEY_IOS_VENDOR_ID onDict:dict];
    [self safeSetValue:deviceInfo.brandName forKey:BRANCH_REQUEST_KEY_BRAND onDict:dict];
    [self safeSetValue:deviceInfo.modelName forKey:BRANCH_REQUEST_KEY_MODEL onDict:dict];
    [self safeSetValue:deviceInfo.osName forKey:BRANCH_REQUEST_KEY_OS onDict:dict];
    [self safeSetValue:deviceInfo.osVersion forKey:BRANCH_REQUEST_KEY_OS_VERSION onDict:dict];
    [self safeSetValue:deviceInfo.screenWidth forKey:BRANCH_REQUEST_KEY_SCREEN_WIDTH onDict:dict];
    [self safeSetValue:deviceInfo.screenHeight forKey:BRANCH_REQUEST_KEY_SCREEN_HEIGHT onDict:dict];

    [self safeSetValue:deviceInfo.browserUserAgent forKey:@"user_agent" onDict:dict];
    [self safeSetValue:deviceInfo.country forKey:@"country" onDict:dict];
    [self safeSetValue:deviceInfo.language forKey:@"language" onDict:dict];

    dict[BRANCH_REQUEST_KEY_AD_TRACKING_ENABLED] = @(deviceInfo.isAdTrackingEnabled);
    
}

- (NSDictionary*)updateDeviceInfoToParams:(NSDictionary *)params {
    NSMutableDictionary *extendedParams=[[NSMutableDictionary alloc] init];
    [extendedParams addEntriesFromDictionary:params];
    [self updateDeviceInfoToMutableDictionary:extendedParams];
    return extendedParams;
}

- (void)safeSetValue:(NSObject *)value forKey:(NSString *)key onDict:(NSMutableDictionary *)dict {
    if (value) {
        dict[key] = value;
    }
}



@end
