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
#import "NSError+Branch.h"
#import "BranchConstants.h"
#import "NSMutableDictionary+Branch.h"
#import "BNCLog.h"
#import "Branch.h"
#import "BNCSKAdNetwork.h"
#import "BNCReferringURLUtility.h"

@interface BNCServerInterface ()
@property (copy, nonatomic) NSString *requestEndpoint;
@property (strong, nonatomic) id<BNCNetworkServiceProtocol> networkService;

@end

@implementation BNCServerInterface

- (instancetype) init {
    self = [super init];
    if (self) {
        self.networkService = [[Branch networkServiceClass] new];
    }
    return self;
}

- (void) dealloc {
    [self.networkService cancelAllOperations];
    self.networkService = nil;
}

#pragma mark - GET methods

- (void)getRequest:(NSDictionary *)params url:(NSString *)url key:(NSString *)key callback:(BNCServerCallback)callback {
    [self getRequest:params url:url key:key retryNumber:0 callback:callback];
}

- (void)getRequest:(NSDictionary *)params url:(NSString *)url key:(NSString *)key retryNumber:(NSInteger)retryNumber callback:(BNCServerCallback)callback {
    NSURLRequest *request = [self prepareGetRequest:params url:url key:key retryNumber:retryNumber];

    [self genericHTTPRequest:request retryNumber:retryNumber callback:callback
        retryHandler:^NSURLRequest *(NSInteger lastRetryNumber) {
            return [self prepareGetRequest:params url:url key:key retryNumber:lastRetryNumber+1];
    }];
}

#pragma mark - POST methods

- (void)postRequest:(NSDictionary *)post url:(NSString *)url key:(NSString *)key callback:(BNCServerCallback)callback {
    [self postRequest:post url:url retryNumber:0 key:key callback:callback];
}

- (void)postRequest:(NSDictionary *)post url:(NSString *)url retryNumber:(NSInteger)retryNumber key:(NSString *)key callback:(BNCServerCallback)callback {
    
    // TODO: confirm it's ok to send full URL instead of with the domain trimmed off
    self.requestEndpoint = url;
    NSURLRequest *request = [self preparePostRequest:post url:url key:key retryNumber:retryNumber];
    
    [self genericHTTPRequest:request
                 retryNumber:retryNumber
                    callback:callback
                retryHandler:^ NSURLRequest *(NSInteger lastRetryNumber) {
        return [self preparePostRequest:post url:url key:key retryNumber:lastRetryNumber+1];
    }];
}

// Only used by BranchShortUrlSyncRequest
- (BNCServerResponse *)postRequestSynchronous:(NSDictionary *)post url:(NSString *)url key:(NSString *)key {
    NSURLRequest *request = [self preparePostRequest:post url:url key:key retryNumber:0];
    return [self genericHTTPRequestSynchronous:request];
}

#pragma mark - Generic requests

- (void)genericHTTPRequest:(NSURLRequest *)request callback:(BNCServerCallback)callback {
    [self genericHTTPRequest:request retryNumber:0 callback:callback
        retryHandler:^NSURLRequest *(NSInteger lastRetryNumber) {
            return request;
    }];
}

- (void)genericHTTPRequest:(NSURLRequest *)request retryNumber:(NSInteger)retryNumber callback:(BNCServerCallback)callback retryHandler:(NSURLRequest *(^)(NSInteger))retryHandler {

    void (^completionHandler)(id<BNCNetworkOperationProtocol>operation) =
        ^void (id<BNCNetworkOperationProtocol>operation) {

            BNCServerResponse *serverResponse =
                [self processServerResponse:operation.response data:operation.responseData error:operation.error];
            [self collectInstrumentationMetricsWithOperation:operation];

            NSError *underlyingError = operation.error;
            NSInteger status = [serverResponse.statusCode integerValue];

            // If the phone is in a poor network condition,
            // iOS will return statuses such as -1001, -1003, -1200, -9806
            // indicating various parts of the HTTP post failed.
            // We should retry in those conditions in addition to the case where the server returns a 500

            // Status 53 means the request was killed by the OS because we're still in the background.
            // This started happening in iOS 12 / Xcode 10 production when we're called from continueUserActivity:
            // but we're not fully out of the background yet.

            BOOL isRetryableStatusCode = status >= 500 || status < 0 || status == 53;
            
            // Retry the request if appropriate
            if (retryNumber < self.preferenceHelper.retryCount && isRetryableStatusCode) {
                dispatch_time_t dispatchTime =
                    dispatch_time(DISPATCH_TIME_NOW, self.preferenceHelper.retryInterval * NSEC_PER_SEC);
                dispatch_after(dispatchTime, dispatch_get_main_queue(), ^{
                    if (retryHandler) {
                        BNCLogDebug([NSString stringWithFormat:@"Retrying request with url %@", request.URL.relativePath]);
                        // Create the next request
                        NSURLRequest *retryRequest = retryHandler(retryNumber);
                        [self genericHTTPRequest:retryRequest
                                     retryNumber:(retryNumber + 1)
                                        callback:callback retryHandler:retryHandler];
                    }
                });
                
                // Do not continue on if retrying, else the callback will be called incorrectly
                return;
            }

            NSError *branchError = nil;

            // Wrap up bad statuses w/ specific error messages
            if (status >= 500) {
                branchError = [NSError branchErrorWithCode:BNCServerProblemError error:underlyingError];
            }
            else if (status == 409) {
                branchError = [NSError branchErrorWithCode:BNCDuplicateResourceError error:underlyingError];
            }
            else if (status >= 400) {
                NSString *errorString = [serverResponse.data objectForKey:@"error"];
                if (![errorString isKindOfClass:[NSString class]])
                    errorString = nil;
                if (!errorString)
                    errorString = underlyingError.localizedDescription;
                if (!errorString)
                    errorString = @"The request was invalid.";
                branchError = [NSError branchErrorWithCode:BNCBadRequestError localizedMessage:errorString];
            }
            else if (underlyingError) {
                branchError = [NSError branchErrorWithCode:BNCServerProblemError error:underlyingError];
            }

            if (branchError) {
                BNCLogError([NSString stringWithFormat:@"An error prevented request to %@ from completing: %@",
                    request.URL.absoluteString, branchError]);
            }
            
            //	Don't call on the main queue since it might be blocked.
            if (callback)
                callback(serverResponse, branchError);
        };

    if (Branch.trackingDisabled) {
        NSString *endpoint = request.URL.absoluteString;
        
        // if endpoint is not linking related, fail it.
        if (![self isLinkingRelatedRequest:endpoint]) {
            [[BNCPreferenceHelper sharedInstance] clearTrackingInformation];
            NSError *error = [NSError branchErrorWithCode:BNCTrackingDisabledError];
            BNCLogWarning([NSString stringWithFormat:@"Dropping Request %@: - %@", endpoint, error]);
            if (callback) {
                callback(nil, error);
            }
            return;
        }
    }
    
    id<BNCNetworkOperationProtocol> operation =
        [self.networkService networkOperationWithURLRequest:request.copy completion:completionHandler];
    [operation start];
    NSError *error = [self verifyNetworkOperation:operation];
    if (error) {
        BNCLogError([NSString stringWithFormat:@"Network service error: %@.", error]);
        if (callback) {
            callback(nil, error);
        }
        return;
    }
}

- (BOOL)isLinkingRelatedRequest:(NSString *)endpoint {
    BNCPreferenceHelper *prefs = [BNCPreferenceHelper sharedInstance];
    BOOL hasIdentifier = (prefs.linkClickIdentifier.length > 0 ) || (prefs.spotlightIdentifier.length > 0 ) || (prefs.universalLinkUrl.length > 0);
    
    // Allow install to resolve a link.
    if ([endpoint containsString:@"/v1/install"]) {
        return YES;
    }
    
    // Allow open to resolve a link.
    if ([endpoint containsString:@"/v1/open"] && hasIdentifier) {
        return YES;
    }
    
    // Allow short url creation requests
    if ([endpoint containsString:@"/v1/url"]) {
        return YES;
    }
    
    return NO;
}

- (NSError *)verifyNetworkOperation:(id<BNCNetworkOperationProtocol>)operation {

    if (!operation) {
        NSString *message = @"A network operation instance is expected to be returned by the"
             " networkOperationWithURLRequest:completion: method.";
        NSError *error = [NSError branchErrorWithCode:BNCNetworkServiceInterfaceError localizedMessage:message];
        return error;
    }
    if (![operation conformsToProtocol:@protocol(BNCNetworkOperationProtocol)]) {
        NSString *message = [NSString stringWithFormat:
                @"Network operation of class '%@' does not conform to the BNCNetworkOperationProtocol.",
                NSStringFromClass([operation class])];
        NSError *error = [NSError branchErrorWithCode:BNCNetworkServiceInterfaceError localizedMessage:message];
        return error;
    }
    if (!operation.startDate) {
        NSString *message = @"The network operation start date is not set. The Branch SDK expects the network operation"
             " start date to be set by the network provider.";
        NSError *error = [NSError branchErrorWithCode:BNCNetworkServiceInterfaceError localizedMessage:message];
        return error;
    }
    if (!operation.timeoutDate) {
        NSString*message = @"The network operation timeout date is not set. The Branch SDK expects the network operation"
             " timeout date to be set by the network provider.";
        NSError *error = [NSError branchErrorWithCode:BNCNetworkServiceInterfaceError localizedMessage:message];
        return error;
    }
    if (!operation.request) {
        NSString *message = @"The network operation request is not set. The Branch SDK expects the network operation"
             " request to be set by the network provider.";
        NSError *error = [NSError branchErrorWithCode:BNCNetworkServiceInterfaceError localizedMessage:message];
        return error;
    }
    return nil;
}

- (BNCServerResponse *)genericHTTPRequestSynchronous:(NSURLRequest *)request {

    __block BNCServerResponse *serverResponse = nil;
    dispatch_semaphore_t semaphore = dispatch_semaphore_create(0);

    id<BNCNetworkOperationProtocol> operation =
        [self.networkService
            networkOperationWithURLRequest:request.copy
            completion:^void (id<BNCNetworkOperationProtocol>operation) {
                serverResponse =
                    [self processServerResponse:operation.response
                        data:operation.responseData error:operation.error];
                [self collectInstrumentationMetricsWithOperation:operation];                    
                dispatch_semaphore_signal(semaphore);
            }];
    [operation start];
    NSError *error = [self verifyNetworkOperation:operation];
    if (!error) {
        dispatch_semaphore_wait(semaphore, DISPATCH_TIME_FOREVER);
    }
    return serverResponse;
}

#pragma mark - Internals

- (NSURLRequest *)prepareGetRequest:(NSDictionary *)params url:(NSString *)url key:(NSString *)key retryNumber:(NSInteger)retryNumber {

    NSDictionary *tmp = [self addRetryCount:retryNumber toJSON:params];
    NSString *requestUrlString = [NSString stringWithFormat:@"%@%@", url, [BNCEncodingUtils encodeDictionaryToQueryString:tmp]];
    BNCLogDebug([NSString stringWithFormat:@"URL: %@", requestUrlString]);

    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:requestUrlString]
                                                           cachePolicy:NSURLRequestReloadIgnoringLocalCacheData
                                                       timeoutInterval:self.preferenceHelper.timeout];
    [request setHTTPMethod:@"GET"];
    [request setValue:@"application/json" forHTTPHeaderField:@"Content-Type"];
    
    return request;
}

- (NSURLRequest *)preparePostRequest:(NSDictionary *)params url:(NSString *)url key:(NSString *)key retryNumber:(NSInteger)retryNumber {
    
    NSDictionary *tmp = [self addRetryCount:retryNumber toJSON:params];

    NSData *postData = [BNCEncodingUtils encodeDictionaryToJsonData:tmp];
    NSString *postLength = [NSString stringWithFormat:@"%lu", (unsigned long)[postData length]];

    BNCLogDebug([NSString stringWithFormat:@"URL: %@.\n", url]);
    BNCLogDebug([NSString stringWithFormat:@"Body: %@\nJSON: %@.",
        params,
        [[NSString alloc] initWithData:postData encoding:NSUTF8StringEncoding]]
    );
    
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

- (BNCServerResponse *)processServerResponse:(NSURLResponse *)response data:(NSData *)data error:(NSError *)error {
    BNCServerResponse *serverResponse = [[BNCServerResponse alloc] init];
    NSHTTPURLResponse *httpResponse = (NSHTTPURLResponse *)response;
    NSString *requestId = httpResponse.allHeaderFields[@"X-Branch-Request-Id"];
    
    if (!error) {
        serverResponse.statusCode = @([httpResponse statusCode]);
        serverResponse.data = [BNCEncodingUtils decodeJsonDataToDictionary:data];
        serverResponse.requestId = requestId;
    }
    else {
        serverResponse.statusCode = @(error.code);
        serverResponse.data = error.userInfo;
        serverResponse.requestId = requestId;
    }

    BNCLogDebug([NSString stringWithFormat:@"Server returned: %@.", serverResponse]);
    return serverResponse;
}

- (void)collectInstrumentationMetricsWithOperation:(id<BNCNetworkOperationProtocol>)operation {
    // multiplying by negative because startTime happened in the past
    NSTimeInterval elapsedTime = [operation.startDate timeIntervalSinceNow] * -1000.0;
    NSString *lastRoundTripTime = [[NSNumber numberWithDouble:floor(elapsedTime)] stringValue];
    NSString * brttKey = [NSString stringWithFormat:@"%@-brtt", self.requestEndpoint];
    [self.preferenceHelper clearInstrumentationDictionary];
    [self.preferenceHelper addInstrumentationDictionaryKey:brttKey value:lastRoundTripTime];
}

- (NSDictionary *)addRetryCount:(NSInteger)count toJSON:(NSDictionary *)json {
    // json should be a NSMutableDictionary, so this should be like a cast
    NSMutableDictionary *tmp = [json mutableCopy];
    
    if (count > 0) {
        tmp[@"retryNumber"] = @(count);
    } else {
        tmp[@"retryNumber"] = @(0);
    }
    return tmp;
}

@end
