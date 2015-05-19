//
//  BNCServerInterface.m
//  Branch-SDK
//
//  Created by Alex Austin on 6/6/14.
//  Copyright (c) 2014 Branch Metrics. All rights reserved.
//

#import "BNCServerInterface.h"
#import "BNCPreferenceHelper.h"
#import "BNCConfig.h"
#import "BNCEncodingUtils.h"
#import "BNCError.h"

@implementation BNCServerInterface

#pragma mark - GET methods

- (void)getRequest:(NSDictionary *)params url:(NSString *)url callback:(BNCServerCallback)callback {
    [self getRequest:params url:url retryNumber:0 log:YES callback:callback];
}

- (void)getRequest:(NSDictionary *)params url:(NSString *)url log:(BOOL)log callback:(BNCServerCallback)callback {
    [self getRequest:params url:url retryNumber:0 log:log callback:callback];
}

- (void)getRequest:(NSDictionary *)params url:(NSString *)url retryNumber:(NSInteger)retryNumber log:(BOOL)log callback:(BNCServerCallback)callback {
    NSURLRequest *request = [self prepareGetRequest:params url:url retryNumber:retryNumber log:log];

    [self genericHTTPRequest:request retryNumber:retryNumber log:log callback:callback retryHandler:^NSURLRequest *(NSInteger lastRetryNumber) {
        return [self prepareGetRequest:params url:url retryNumber:++lastRetryNumber log:log];
    }];
}

- (BNCServerResponse *)getRequest:(NSDictionary *)params url:(NSString *)url {
    return [self getRequest:params url:url log:YES];
}

- (BNCServerResponse *)getRequest:(NSDictionary *)params url:(NSString *)url log:(BOOL)log {
    NSURLRequest *request = [self prepareGetRequest:params url:url retryNumber:0 log:log];
    return [self genericHTTPRequest:request log:log];
}


#pragma mark - POST methods

- (void)postRequest:(NSDictionary *)post url:(NSString *)url callback:(BNCServerCallback)callback {
    [self postRequest:post url:url retryNumber:0 log:YES callback:callback];
}

- (void)postRequest:(NSDictionary *)post url:(NSString *)url log:(BOOL)log callback:(BNCServerCallback)callback {
    [self postRequest:post url:url retryNumber:0 log:log callback:callback];
}

- (void)postRequest:(NSDictionary *)post url:(NSString *)url retryNumber:(NSInteger)retryNumber log:(BOOL)log callback:(BNCServerCallback)callback {
    NSURLRequest *request = [self preparePostRequest:post url:url retryNumber:retryNumber log:log];

    [self genericHTTPRequest:request retryNumber:retryNumber log:log callback:callback retryHandler:^NSURLRequest *(NSInteger lastRetryNumber) {
        return [self preparePostRequest:post url:url retryNumber:++lastRetryNumber log:log];
    }];
}

- (BNCServerResponse *)postRequest:(NSDictionary *)post url:(NSString *)url log:(BOOL)log {
    NSURLRequest *request = [self preparePostRequest:post url:url retryNumber:0 log:log];
    return [self genericHTTPRequest:request log:log];
}


#pragma mark - Generic requests

- (void)genericHTTPRequest:(NSURLRequest *)request log:(BOOL)log callback:(BNCServerCallback)callback {
    [self genericHTTPRequest:request retryNumber:0 log:log callback:callback retryHandler:^NSURLRequest *(NSInteger lastRetryNumber) {
        return request;
    }];
}

- (void)genericHTTPRequest:(NSURLRequest *)request retryNumber:(NSInteger)retryNumber log:(BOOL)log callback:(BNCServerCallback)callback retryHandler:(NSURLRequest *(^)(NSInteger))retryHandler {
    [NSURLConnection sendAsynchronousRequest:request queue:[NSOperationQueue mainQueue] completionHandler:^(NSURLResponse *response, NSData *responseData, NSError *error) {
        BNCServerResponse *serverResponse = [self processServerResponse:response data:responseData error:error log:log];
        NSInteger status = [serverResponse.statusCode integerValue];
        BOOL isRetryableStatusCode = status >= 500;
        
        // Retry the request if appropriate
        if (retryNumber < [BNCPreferenceHelper getRetryCount] && isRetryableStatusCode) {
            [NSThread sleepForTimeInterval:[BNCPreferenceHelper getRetryInterval]];
            
            if (log) {
                [BNCPreferenceHelper log:FILE_NAME line:LINE_NUM message:@"Replaying request with url %@", request.URL.relativePath];
            }
            
            // Create the next request
            NSURLRequest *retryRequest = retryHandler(retryNumber);
            [self genericHTTPRequest:retryRequest retryNumber:(retryNumber + 1) log:log callback:callback retryHandler:retryHandler];
        }
        else if (callback) {
            // Wrap up bad statuses w/ specific error messages
            if (status > 500) {
                error = [NSError errorWithDomain:BNCErrorDomain code:BNCRequestError userInfo:@{ NSLocalizedDescriptionKey: @"Trouble reaching the Branch servers, please try again shortly" }];
            }
            else if (status == 409) {
                error = [NSError errorWithDomain:BNCErrorDomain code:BNCDuplicateResourceError userInfo:@{ NSLocalizedDescriptionKey: @"A resource with this identifier already exists" }];
            }
            else if (status > 400) {
                NSString *errorString = [serverResponse.data objectForKey:@"error"] ?: @"The request was invalid.";

                error = [NSError errorWithDomain:BNCErrorDomain code:BNCRequestError userInfo:@{ NSLocalizedDescriptionKey: errorString }];
            }
            
            if (error && log) {
                [BNCPreferenceHelper log:FILE_NAME line:LINE_NUM message:@"An error prevented request to %@ from completing: %@", request.URL.absoluteString, error.localizedDescription];
            }

            callback(serverResponse, error);
        }
    }];
}

- (BNCServerResponse *)genericHTTPRequest:(NSURLRequest *)request log:(BOOL)log {
    NSURLResponse *response = nil;
    NSError *error = nil;
    NSData *respData = [NSURLConnection sendSynchronousRequest:request returningResponse:&response error:&error];
    
    return [self processServerResponse:response data:respData error:error log:log];
}


#pragma mark - Internals

- (NSURLRequest *)prepareGetRequest:(NSDictionary *)params url:(NSString *)url retryNumber:(NSInteger)retryNumber log:(BOOL)log {
    NSMutableDictionary *fullParamDict = [[NSMutableDictionary alloc] init];
    [fullParamDict addEntriesFromDictionary:params];
    fullParamDict[@"sdk"] = [NSString stringWithFormat:@"ios%@", SDK_VERSION];
    fullParamDict[@"retryNumber"] = @(retryNumber);
    
    NSString *appId = [BNCPreferenceHelper getAppKey];
    NSString *branchKey = [BNCPreferenceHelper getBranchKey];
    if (![branchKey isEqualToString:NO_STRING_VALUE]) {
        fullParamDict[KEY_BRANCH_KEY] = branchKey;
    } else if (![appId isEqualToString:NO_STRING_VALUE]) {
        fullParamDict[@"app_id"] = appId;
    }
    
    NSString *requestUrlString = [NSString stringWithFormat:@"%@%@", url, [BNCEncodingUtils encodeDictionaryToQueryString:fullParamDict]];
    
    if (log) {
        [BNCPreferenceHelper log:FILE_NAME line:LINE_NUM message:@"using url = %@", url];
    }
    
    NSMutableURLRequest *request = [[NSMutableURLRequest alloc] init];
    [request setURL:[NSURL URLWithString:requestUrlString]];
    [request setHTTPMethod:@"GET"];
    [request setValue:@"applications/json" forHTTPHeaderField:@"Content-Type"];
    
    return request;
}

- (NSURLRequest *)preparePostRequest:(NSDictionary *)params url:(NSString *)url retryNumber:(NSInteger)retryNumber log:(BOOL)log {
    NSMutableDictionary *fullParamDict = [[NSMutableDictionary alloc] init];
    [fullParamDict addEntriesFromDictionary:params];
    fullParamDict[@"sdk"] = [NSString stringWithFormat:@"ios%@", SDK_VERSION];
    fullParamDict[@"retryNumber"] = @(retryNumber);
    
    NSString *appId = [BNCPreferenceHelper getAppKey];
    NSString *branchKey = [BNCPreferenceHelper getBranchKey];
    if (![branchKey isEqualToString:NO_STRING_VALUE]) {
        fullParamDict[KEY_BRANCH_KEY] = branchKey;
    } else if (![appId isEqualToString:NO_STRING_VALUE]) {
        fullParamDict[@"app_id"] = appId;
    }

    NSData *postData = [BNCEncodingUtils encodeDictionaryToJsonData:fullParamDict];
    NSString *postLength = [NSString stringWithFormat:@"%lu", (unsigned long)[postData length]];
    
    if (log) {
        [BNCPreferenceHelper log:FILE_NAME line:LINE_NUM message:@"using url = %@", url];
        [BNCPreferenceHelper log:FILE_NAME line:LINE_NUM message:@"body = %@", [fullParamDict description]];
    }
    
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:url]];
    [request setTimeoutInterval:[BNCPreferenceHelper getTimeout]];
    [request setHTTPMethod:@"POST"];
    [request setValue:postLength forHTTPHeaderField:@"Content-Length"];
    [request setValue:@"application/json" forHTTPHeaderField:@"Content-Type"];
    [request setHTTPBody:postData];
    
    return request;
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
        [BNCPreferenceHelper log:FILE_NAME line:LINE_NUM message:@"returned = %@", serverResponse];
    }
    
    return serverResponse;
}

@end
