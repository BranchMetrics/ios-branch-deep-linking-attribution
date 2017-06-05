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
#import "BNCLog.h"
#import "Branch.h"

@interface BNCServerInterface ()
@property (strong) NSString *requestEndpoint;
@property (strong) id<BNCNetworkServiceProtocol> networkService;
@end

@implementation BNCServerInterface

- (instancetype) init {
    self = [super init];
    if (!self) return self;

    NSArray *publicKeys = @[];
    id networkClass = [Branch networkServiceClass];
    if ([networkClass respondsToSelector:@selector(networkServiceWithPinnedPublicKeys:)]) {
        self.networkService = [[Branch networkServiceClass] networkServiceWithPinnedPublicKeys:publicKeys];
    } else
    if ([networkClass respondsToSelector:@selector(new)]) {
        self.networkService = [[Branch networkServiceClass] new];
    }

    return self;
}

#pragma mark - GET methods

- (void)getRequest:(NSDictionary *)params url:(NSString *)url key:(NSString *)key callback:(BNCServerCallback)callback {
    [self getRequest:params url:url key:key retryNumber:0 callback:callback];
}

- (void)getRequest:(NSDictionary *)params
               url:(NSString *)url
               key:(NSString *)key
       retryNumber:(NSInteger)retryNumber
          callback:(BNCServerCallback)callback {
    NSURLRequest *request = [self prepareGetRequest:params url:url key:key retryNumber:retryNumber];

    [self genericHTTPRequest:request retryNumber:retryNumber callback:callback retryHandler:^NSURLRequest *(NSInteger lastRetryNumber) {
        return [self prepareGetRequest:params url:url key:key retryNumber:++lastRetryNumber];
    }];
}

#pragma mark - POST methods

- (void)postRequest:(NSDictionary *)post
                url:(NSString *)url
                key:(NSString *)key
           callback:(BNCServerCallback)callback {
    [self postRequest:post url:url retryNumber:0 key:key callback:callback];
}

- (void)postRequest:(NSDictionary *)post url:(NSString *)url retryNumber:(NSInteger)retryNumber key:(NSString *)key callback:(BNCServerCallback)callback {
    NSDictionary *extendedParams = [self updateDeviceInfoToParams:post];
    NSURLRequest *request = [self preparePostRequest:extendedParams url:url key:key retryNumber:retryNumber];
    
    // Instrumentation metrics
    self.requestEndpoint = [self.preferenceHelper getEndpointFromURL:url];

    [self genericHTTPRequest:request retryNumber:retryNumber callback:callback retryHandler:^NSURLRequest *(NSInteger lastRetryNumber) {
        return [self preparePostRequest:extendedParams url:url key:key retryNumber:++lastRetryNumber];
    }];
}

- (BNCServerResponse *)postRequestSynchronous:(NSDictionary *)post url:(NSString *)url key:(NSString *)key {
    NSDictionary *extendedParams = [self updateDeviceInfoToParams:post];
    NSURLRequest *request = [self preparePostRequest:extendedParams url:url key:key retryNumber:0];
    return [self genericHTTPRequestSynchronous:request];
}

#pragma mark - Generic requests

- (void)genericHTTPRequest:(NSURLRequest *)request callback:(BNCServerCallback)callback {
    [self genericHTTPRequest:request retryNumber:0 callback:callback retryHandler:^NSURLRequest *(NSInteger lastRetryNumber) {
        return request;
    }];
}

- (void)genericHTTPRequest:(NSURLRequest *)request
               retryNumber:(NSInteger)retryNumber
                  callback:(BNCServerCallback)callback
              retryHandler:(NSURLRequest *(^)(NSInteger))retryHandler {

    void (^completionHandler)(id<BNCNetworkOperationProtocol>operation) =
        ^void (id<BNCNetworkOperationProtocol>operation) {

            BNCServerResponse *serverResponse =
                [self processServerResponse:operation.response data:operation.responseData error:operation.error log:YES];
            [self collectInstrumentationMetricsWithOperation:operation];

            NSError *error = operation.error;
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
                    BNCLogDebug(@"Retrying request with url %@", request.URL.relativePath);
                    // Create the next request
                    NSURLRequest *retryRequest = retryHandler(retryNumber);
                    [self genericHTTPRequest:retryRequest retryNumber:(retryNumber + 1) callback:callback retryHandler:retryHandler];
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
                
                if (error) {
                    BNCLogError(@"An error prevented request to %@ from completing: %@", request.URL.absoluteString, error.localizedDescription);
                }
                
            }
            //	Don't call on the main queue since it might be blocked.
            if (callback)
                callback(serverResponse, error);
        };

    id<BNCNetworkOperationProtocol> operation =
        [self.networkService networkOperationWithURLRequest:request.copy completion:completionHandler];
    if (![operation conformsToProtocol:@protocol(BNCNetworkOperationProtocol)]) {
        NSError *error =
            [NSError errorWithDomain:BNCErrorDomain code:BNCNetworkProtocolError userInfo:
                @{NSLocalizedDescriptionKey:
                    @"Network object of class '%@' does not conform to the BNCNetworkOperationProtocol."}];
        BNCLogError(@"Protocol error: %@.", error);
        if (callback) {
            callback(nil, error);
        }
        return;
    }

    // Check for required fields
    if (operation.startDate) {
        BNCLogError(
            @"The network operation start date is not set. The Branch SDK expects the network operation"
             " start date to be set by the network provider."
        );
    }
    if (!operation.timeoutDate) {
        BNCLogError(
            @"The network operation timeout date is not set. The Branch SDK expects the network operation"
             " timeout date to be set by the network provider."
        );
    }
    if (!operation.request) {
        BNCLogError(
            @"The network operation request is not set. The Branch SDK expects the network operation"
             " request to be set by the network provider."
        );
    }
    [operation start];
}

- (BNCServerResponse *)genericHTTPRequestSynchronous:(NSURLRequest *)request {

    __block BNCServerResponse *serverResponse = nil;
    dispatch_semaphore_t semaphore = dispatch_semaphore_create(0);

    id<BNCNetworkOperationProtocol> operation =
        [self.networkService
            networkOperationWithURLRequest:request.copy
            completion:^void (id<BNCNetworkOperationProtocol>operation) {
                serverResponse =
                    [self processServerResponse:operation.response data:operation.responseData error:operation.error log:YES];
                [self collectInstrumentationMetricsWithOperation:operation];                    
                dispatch_semaphore_signal(semaphore);
            }];
    if (![operation conformsToProtocol:@protocol(BNCNetworkOperationProtocol)]) {
        NSError *error =
            [NSError errorWithDomain:BNCErrorDomain code:BNCNetworkProtocolError userInfo:@{NSLocalizedDescriptionKey:
                @"Network object of class '%@' does not conform to the BNCNetworkOperationProtocol."}];
        BNCLogError(@"Protocol error: %@.", error);
    } else {
        [operation start];
        dispatch_semaphore_wait(semaphore, DISPATCH_TIME_FOREVER);
    }
    return serverResponse;
}

#pragma mark - Internals

- (NSURLRequest *)prepareGetRequest:(NSDictionary *)params
                                url:(NSString *)url
                                key:(NSString *)key
                        retryNumber:(NSInteger)retryNumber {

    NSDictionary *preparedParams = [self prepareParamDict:params key:key retryNumber:retryNumber requestType:@"GET"];
    NSString *requestUrlString = [NSString stringWithFormat:@"%@%@", url, [BNCEncodingUtils encodeDictionaryToQueryString:preparedParams]];
    BNCLogDebug(@"URL: %@", requestUrlString);

    NSMutableURLRequest *request =
        [NSMutableURLRequest requestWithURL:[NSURL URLWithString:requestUrlString]
            cachePolicy:NSURLRequestReloadIgnoringLocalCacheData
            timeoutInterval:self.preferenceHelper.timeout];
    [request setHTTPMethod:@"GET"];
    [request setValue:@"application/json" forHTTPHeaderField:@"Content-Type"];
    
    return request;
}

- (NSURLRequest *)preparePostRequest:(NSDictionary *)params
                                 url:(NSString *)url
                                 key:(NSString *)key
                         retryNumber:(NSInteger)retryNumber {

    NSDictionary *preparedParams = [self prepareParamDict:params key:key retryNumber:retryNumber requestType:@"POST"];
    NSData *postData = [BNCEncodingUtils encodeDictionaryToJsonData:preparedParams];
    NSString *postLength = [NSString stringWithFormat:@"%lu", (unsigned long)[postData length]];

    BNCLogDebug(@"URL: %@.", url);
    BNCLogDebug(@"Body: %@.", preparedParams);
    
    NSMutableURLRequest *request =
        [NSMutableURLRequest requestWithURL:[NSURL URLWithString:url]
            cachePolicy:NSURLRequestReloadIgnoringLocalCacheData
            timeoutInterval:self.preferenceHelper.timeout];
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
    
    return serverResponse;
}

- (void) collectInstrumentationMetricsWithOperation:(id<BNCNetworkOperationProtocol>)operation {
    // multiplying by negative because startTime happened in the past
    NSTimeInterval elapsedTime = [operation.startDate timeIntervalSinceNow] * -1000.0;
    NSString *lastRoundTripTime = [[NSNumber numberWithDouble:floor(elapsedTime)] stringValue];
    NSString * brttKey = [NSString stringWithFormat:@"%@-brtt", self.requestEndpoint];
    [self.preferenceHelper clearInstrumentationDictionary];
    [self.preferenceHelper addInstrumentationDictionaryKey:brttKey value:lastRoundTripTime];
}

- (void)updateDeviceInfoToMutableDictionary:(NSMutableDictionary *)dict {
    BNCDeviceInfo *deviceInfo  = [BNCDeviceInfo getInstance];

    NSString *hardwareId = [deviceInfo.hardwareId copy];
    NSString *hardwareIdType = [deviceInfo.hardwareIdType copy];
    NSNumber *isRealHardwareId = @(deviceInfo.isRealHardwareId);

    if (hardwareId && hardwareIdType && isRealHardwareId) {
        dict[BRANCH_REQUEST_KEY_HARDWARE_ID] = hardwareId;
        dict[BRANCH_REQUEST_KEY_HARDWARE_ID_TYPE] = hardwareIdType;
        dict[BRANCH_REQUEST_KEY_IS_HARDWARE_ID_REAL] = isRealHardwareId;
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
