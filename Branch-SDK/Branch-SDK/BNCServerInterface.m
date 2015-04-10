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
#import "BNCLinkData.h"
#import "BNCEncodingUtils.h"

@implementation BNCServerInterface

// make a generalized get request
- (void)getRequestAsync:(NSDictionary *)params url:(NSString *)url andTag:(NSString *)requestTag {
    [self getRequestAsync:params url:url andTag:requestTag retryNumber:0 log:YES];
}

// this is actually a synchronous call; it should NOT be called from the main queue
- (void)getRequestAsync:(NSDictionary *)params url:(NSString *)url andTag:(NSString *)requestTag log:(BOOL)log {
    [self getRequestAsync:params url:url andTag:requestTag retryNumber:0 log:log];
}

- (void)getRequestAsync:(NSDictionary *)params url:(NSString *)url andTag:(NSString *)requestTag retryNumber:(NSInteger)retryNumber log:(BOOL)log {
    BNCServerResponse *serverResponse = [self genericSyncHTTPRequest:[self prepareGetRequest:params url:url retryNumber:retryNumber log:log] withTag:requestTag andLinkData:nil];

    NSInteger status = [serverResponse.statusCode integerValue];
    BOOL isRetryableStatusCode = status >= 500;
    
    // Retry the request if appropriate
    if (retryNumber < [BNCPreferenceHelper getRetryCount] && isRetryableStatusCode) {
        [NSThread sleepForTimeInterval:[BNCPreferenceHelper getRetryInterval]];

        if (log) {
            [BNCPreferenceHelper log:FILE_NAME line:LINE_NUM message:@"Replaying request with tag %@", requestTag];
        }

        [self getRequestAsync:params url:url andTag:requestTag retryNumber:++retryNumber log:log];
    }
    // Otherwise, let the delegate handle it
    else if (self.delegate) {
        [self.delegate serverCallback:serverResponse];
    }
}

- (BNCServerResponse *)getRequestSync:(NSDictionary *)params url:(NSString *)url andTag:(NSString *)requestTag {
    return [self getRequestSync:params url:url andTag:requestTag log:YES];
}

- (BNCServerResponse *)getRequestSync:(NSDictionary *)params url:(NSString *)url andTag:(NSString *)requestTag log:(BOOL)log {
    return [self genericSyncHTTPRequest:[self prepareGetRequest:params url:url retryNumber:0 log:log] withTag:requestTag andLinkData:nil];
}

// make a generalized post request
- (void)postRequestAsync:(NSDictionary *)post url:(NSString *)url andTag:(NSString *)requestTag {
    [self postRequestAsync:post url:url andTag:requestTag andLinkData:nil retryNumber:0 log:YES];
}

- (void)postRequestAsync:(NSDictionary *)post url:(NSString *)url andTag:(NSString *)requestTag log:(BOOL)log {
    [self postRequestAsync:post url:url andTag:requestTag andLinkData:nil retryNumber:0 log:log];
}

- (void)postRequestAsync:(NSDictionary *)post url:(NSString *)url andTag:(NSString *)requestTag andLinkData:(BNCLinkData *)linkData {
    [self postRequestAsync:post url:url andTag:requestTag andLinkData:linkData retryNumber:0 log:YES];
}

// this is actually a synchronous call; it should NOT be called from the main queue
- (void)postRequestAsync:(NSDictionary *)post url:(NSString *)url andTag:(NSString *)requestTag andLinkData:(BNCLinkData *)linkData log:(BOOL)log {
    [self postRequestAsync:post url:url andTag:requestTag andLinkData:linkData retryNumber:0 log:log];
}

- (void)postRequestAsync:(NSDictionary *)post url:(NSString *)url andTag:(NSString *)requestTag andLinkData:(BNCLinkData *)linkData retryNumber:(NSInteger)retryNumber log:(BOOL)log {
    BNCServerResponse *serverResponse = [self genericSyncHTTPRequest:[self preparePostRequest:post url:url retryNumber:retryNumber log:log] withTag:requestTag andLinkData:linkData];
    
    NSInteger status = [serverResponse.statusCode integerValue];
    BOOL isRetryableStatusCode = status >= 500;

    // Retry the request if appropriate
    if (retryNumber < [BNCPreferenceHelper getRetryCount] && isRetryableStatusCode) {
        [NSThread sleepForTimeInterval:[BNCPreferenceHelper getRetryInterval]];

        if (log) {
            [BNCPreferenceHelper log:FILE_NAME line:LINE_NUM message:@"Replaying request with tag %@", requestTag];
        }

        [self postRequestAsync:post url:url andTag:requestTag andLinkData:linkData retryNumber:++retryNumber log:log];
    }
    // Otherwise, let the delegate handle it
    else if (self.delegate) {
        [self.delegate serverCallback:serverResponse];
    }
}

- (BNCServerResponse *)postRequestSync:(NSDictionary *)post url:(NSString *)url andTag:(NSString *)requestTag andLinkData:(BNCLinkData *)linkData log:(BOOL)log {
    NSURLRequest *request = [self preparePostRequest:post url:url retryNumber:0 log:log];
    return [self genericSyncHTTPRequest:request withTag:requestTag andLinkData:linkData];
}

- (void)genericAsyncHTTPRequest:(NSMutableURLRequest *)request withTag:(NSString *)requestTag andLinkData:(BNCLinkData *)linkData {
    [NSURLConnection sendAsynchronousRequest:request queue:[NSOperationQueue mainQueue] completionHandler: ^(NSURLResponse *response, NSData *POSTReply, NSError *error) {
        BNCServerResponse *serverResponse = [self processServerResponse:response data:POSTReply error:error tag:requestTag andLinkData:linkData];
        if (self.delegate) [self.delegate serverCallback:serverResponse];
    }];
}

- (BNCServerResponse *)genericSyncHTTPRequest:(NSURLRequest *)request withTag:(NSString *)requestTag andLinkData:(BNCLinkData *)linkData {
    NSURLResponse * response = nil;
    NSError * error = nil;
    NSData * POSTReply = [NSURLConnection sendSynchronousRequest:request returningResponse:&response error:&error];
    
    return [self processServerResponse:response data:POSTReply error:error tag:requestTag andLinkData:linkData];
}

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

- (BNCServerResponse *)processServerResponse:(NSURLResponse *)response data:(NSData *)data error:(NSError *)error tag:(NSString *)requestTag andLinkData:(BNCLinkData *)linkData {
    BNCServerResponse *serverResponse = [[BNCServerResponse alloc] initWithTag:requestTag];
    serverResponse.linkData = linkData;

    if (!error) {
        serverResponse.statusCode = @([(NSHTTPURLResponse *)response statusCode]);
        serverResponse.data = [BNCEncodingUtils decodeJsonDataToDictionary:data];
    }
    else {
        serverResponse.statusCode = @(error.code);
        serverResponse.data = error.userInfo;
    }

    if ([BNCPreferenceHelper isDebug]  // for efficiency short-circuit purpose
        && ![requestTag isEqualToString:REQ_TAG_DEBUG_LOG]
        && ![requestTag isEqualToString:REQ_TAG_DEBUG_CONNECT]
        && [requestTag isEqualToString:REQ_TAG_DEBUG_DISCONNECT]
        && [requestTag isEqualToString:REQ_TAG_DEBUG_SCREEN])
    {
        [BNCPreferenceHelper log:FILE_NAME line:LINE_NUM message:@"returned = %@", [serverResponse description]];
    }
    
    return serverResponse;
}

@end
