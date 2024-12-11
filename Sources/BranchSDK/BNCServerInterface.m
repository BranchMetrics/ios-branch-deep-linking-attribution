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
#import "BranchConstants.h"
#import "NSMutableDictionary+Branch.h"
#import "BranchLogger.h"
#import "Branch.h"
#import "BNCSKAdNetwork.h"
#import "BNCReferringURLUtility.h"
#import "NSError+Branch.h"

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
    
    [[BranchLogger shared] logVerbose:[NSString stringWithFormat:@"retryNumber %ld", retryNumber] error:nil];
    
    // TODO: confirm it's ok to send full URL instead of with the domain trimmed off
    self.requestEndpoint = url;
    
    // Drops non-linking requests when tracking is disabled
    if (Branch.trackingDisabled) {
    
        [[BranchLogger shared] logVerbose:[NSString stringWithFormat:@"Tracking is disabled, checking if %@ is linking request.", url] error:nil];

        if (![self isLinkingRelatedRequest:url postParams:post]) {
            [[BNCPreferenceHelper sharedInstance] clearTrackingInformation];
            NSError *error = [NSError branchErrorWithCode:BNCTrackingDisabledError];
            [[BranchLogger shared] logWarning:[NSString stringWithFormat:@"Dropping non-linking request"] error:error];
            if (callback) {
                callback(nil, error);
            }
            return;
        }
    }
    
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

            BNCServerResponse *serverResponse = [self processServerResponse:operation.response data:operation.responseData error:operation.error];
            [self collectInstrumentationMetricsWithOperation:operation];

            // If the phone is in a poor network condition,
            // iOS will return statuses such as -1001, -1003, -1200, -9806
            // indicating various parts of the HTTP post failed.
            // We should retry in those conditions in addition to the case where the server returns a 500

            // Status 53 means the request was killed by the OS because we're still in the background.
            // This started happening in iOS 12 / Xcode 10 production when we're called from continueUserActivity:
            // but we're not fully out of the background yet.
            
            NSInteger status = [serverResponse.statusCode integerValue];
            NSError *underlyingError = operation.error;

            // Retry request if appropriate
            BOOL isRetryableStatusCode = status >= 500 || status < 0 || status == 53;
            if (retryNumber < self.preferenceHelper.retryCount && isRetryableStatusCode) {
                dispatch_time_t dispatchTime = dispatch_time(DISPATCH_TIME_NOW, self.preferenceHelper.retryInterval * NSEC_PER_SEC);
                dispatch_after(dispatchTime, dispatch_get_main_queue(), ^{
                    if (retryHandler) {
                        [[BranchLogger shared] logDebug: [NSString stringWithFormat:@"Retrying request with HTTP status code %ld", (long)status] error:underlyingError];
                        NSURLRequest *retryRequest = retryHandler(retryNumber);
                        [self genericHTTPRequest:retryRequest retryNumber:(retryNumber + 1) callback:callback retryHandler:retryHandler];
                    }
                });
                
            } else {
                if (status != 200) {
                    if ([NSError branchDNSBlockingError:underlyingError]) {
                        NSError *error = [NSError branchErrorWithCode:BNCDNSAdBlockerError];
                        [[BranchLogger shared] logError:[NSString stringWithFormat:@"Possible DNS Ad Blocker. Giving up on request with HTTP status code %ld. Underlying error: %@", (long)status, underlyingError] error:error];
                    } else if ([NSError branchVPNBlockingError:underlyingError]) {
                        NSError *error = [NSError branchErrorWithCode:BNCVPNAdBlockerError];
                        [[BranchLogger shared] logError:[NSString stringWithFormat:@"Possible VPN Ad Blocker. Giving up on request with HTTP status code %ld. Underlying error: %@", (long)status, underlyingError] error:error];
                    } else {
                        [[BranchLogger shared] logWarning: [NSString stringWithFormat:@"Giving up on request with HTTP status code %ld", (long)status] error:underlyingError];
                    }
                }

                // Don't call on the main queue since it might be blocked.
                if (callback) {
                    callback(serverResponse, underlyingError);
                }
            }
        };


    
    id<BNCNetworkOperationProtocol> operation = [self.networkService networkOperationWithURLRequest:request.copy completion:completionHandler];
    [operation start];
    
    // In the past we allowed clients to provide their own networking classes.
    NSError *error = [self verifyNetworkOperation:operation];
    if (error) {
        [[BranchLogger shared] logError:@"NetworkService returned an operation that failed validation" error:error];
        if (callback) {
            callback(nil, error);
        }
        return;
    }
}

- (BOOL)isLinkingRelatedRequest:(NSString *)endpoint postParams:(NSDictionary *)post {
   
    BOOL hasIdentifier = (post[BRANCH_REQUEST_KEY_LINK_IDENTIFIER] != nil ) || (post[BRANCH_REQUEST_KEY_LINK_IDENTIFIER] != nil) || (post[BRANCH_REQUEST_KEY_UNIVERSAL_LINK_URL] != nil);
    
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
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:requestUrlString]
                                                           cachePolicy:NSURLRequestReloadIgnoringLocalCacheData
                                                       timeoutInterval:self.preferenceHelper.timeout];
    [request setHTTPMethod:@"GET"];
    [request setValue:@"application/json" forHTTPHeaderField:@"Content-Type"];
    
    [[BranchLogger shared] logDebug:[NSString stringWithFormat:@"%@\nHeaders %@", request, [request allHTTPHeaderFields]] error:nil];

    return request;
}

- (NSURLRequest *)preparePostRequest:(NSDictionary *)params url:(NSString *)url key:(NSString *)key retryNumber:(NSInteger)retryNumber {
    
    NSDictionary *updatedParams = [self addRetryCount:retryNumber toJSON:params];

    NSData *postData = [BNCEncodingUtils encodeDictionaryToJsonData:updatedParams];
    NSString *postLength = [NSString stringWithFormat:@"%lu", (unsigned long)[postData length]];
    
    NSMutableURLRequest *request =
        [NSMutableURLRequest requestWithURL:[NSURL URLWithString:url]
            cachePolicy:NSURLRequestReloadIgnoringLocalCacheData
            timeoutInterval:self.preferenceHelper.timeout];
    [request setHTTPMethod:@"POST"];
    [request setValue:postLength forHTTPHeaderField:@"Content-Length"];
    [request setValue:@"application/json" forHTTPHeaderField:@"Content-Type"];
    [request setHTTPBody:postData];
    
    if ([[BranchLogger shared] shouldLog:BranchLogLevelDebug]) {
        [[BranchLogger shared] logDebug:[NSString stringWithFormat:@"%@\nHeaders %@\nBody %@", request, [request allHTTPHeaderFields], [BNCEncodingUtils prettyPrintJSON:updatedParams]] error:nil request:request response:nil];
    }
    
    return request;
}

- (BNCServerResponse *)processServerResponse:(NSURLResponse *)response data:(NSData *)data error:(NSError *)error {
    BNCServerResponse *serverResponse = [[BNCServerResponse alloc] init];
    NSHTTPURLResponse *httpResponse = (NSHTTPURLResponse *)response;
    NSString *requestId = httpResponse.allHeaderFields[@"X-Branch-Request-Id"];
    
    if ([[BranchLogger shared] shouldLog:BranchLogLevelVerbose]) {
        [[BranchLogger shared] logVerbose:[NSString stringWithFormat:@"Processing response %@", requestId] error:nil];
    }

    if (!error) {
        serverResponse.statusCode = @([httpResponse statusCode]);
        serverResponse.data = [BNCEncodingUtils decodeJsonDataToDictionary:data];
        serverResponse.requestId = requestId;
     
        if ([[BranchLogger shared] shouldLog:BranchLogLevelDebug]) {
            [[BranchLogger shared] logDebug:[NSString stringWithFormat:@"%@\nBody %@", response, [BNCEncodingUtils prettyPrintJSON:serverResponse.data]] error:nil request:nil response:serverResponse];
        }
        
    } else {
        serverResponse.statusCode = @(error.code);
        serverResponse.data = error.userInfo;
        serverResponse.requestId = requestId;
        
        if ([[BranchLogger shared] shouldLog:BranchLogLevelDebug]) {
            [[BranchLogger shared] logDebug:@"Request failed with NSError" error:error];
        }
    }
    
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
