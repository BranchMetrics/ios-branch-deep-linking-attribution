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

@implementation BNCServerInterface

// make a generalized get request
- (void)getRequestAsync:(NSDictionary *)params url:(NSString *)url andTag:(NSString *)requestTag {
    [self getRequestAsync:params url:url andTag:requestTag log:YES];
}

// this is actually a synchronous call; it should NOT be called from the main queue
- (void)getRequestAsync:(NSDictionary *)params url:(NSString *)url andTag:(NSString *)requestTag log:(BOOL)log {
    BNCServerResponse *serverResponse = [self genericSyncHTTPRequest:[self prepareGetRequest:params url:url log:log] withTag:requestTag andLinkData:nil];
    if (self.delegate) [self.delegate serverCallback:serverResponse];
}

- (BNCServerResponse *)getRequestSync:(NSDictionary *)params url:(NSString *)url andTag:(NSString *)requestTag {
    return [self getRequestSync:params url:url andTag:requestTag log:YES];
}

- (BNCServerResponse *)getRequestSync:(NSDictionary *)params url:(NSString *)url andTag:(NSString *)requestTag log:(BOOL)log {
    return [self genericSyncHTTPRequest:[self prepareGetRequest:params url:url log:log] withTag:requestTag andLinkData:nil];
}

// make a generalized post request
- (void)postRequestAsync:(NSDictionary *)post url:(NSString *)url andTag:(NSString *)requestTag {
    [self postRequestAsync:post url:url andTag:requestTag andLinkData:nil log:YES];
}

- (void)postRequestAsync:(NSDictionary *)post url:(NSString *)url andTag:(NSString *)requestTag log:(BOOL)log {
    [self postRequestAsync:post url:url andTag:requestTag andLinkData:nil log:log];
}

- (void)postRequestAsync:(NSDictionary *)post url:(NSString *)url andTag:(NSString *)requestTag andLinkData:(BNCLinkData *)linkData {
    [self postRequestAsync:post url:url andTag:requestTag andLinkData:linkData log:YES];
}

// this is actually a synchronous call; it should NOT be called from the main queue
- (void)postRequestAsync:(NSDictionary *)post url:(NSString *)url andTag:(NSString *)requestTag andLinkData:(BNCLinkData *)linkData log:(BOOL)log {
    BNCServerResponse *serverResponse = [self genericSyncHTTPRequest:[self preparePostRequest:post url:url log:log] withTag:requestTag andLinkData:linkData];
    if (self.delegate) [self.delegate serverCallback:serverResponse];
}

- (BNCServerResponse *)postRequestSync:(NSDictionary *)post url:(NSString *)url andTag:(NSString *)requestTag andLinkData:(BNCLinkData *)linkData log:(BOOL)log {
    NSMutableURLRequest *request = [self preparePostRequest:post url:url log:log];
    return [self genericSyncHTTPRequest:request withTag:requestTag andLinkData:linkData];
}

+ (NSData *)encodePostParams:(NSDictionary *)params {
    NSError *writeError = nil;
    NSData *postData = [NSJSONSerialization dataWithJSONObject:params options:NSJSONWritingPrettyPrinted error:&writeError];
    return postData;
}

+ (NSString *)encodePostToUniversalString:(NSDictionary *)params {
    return [BNCServerInterface encodePostToUniversalString:params needSource:YES];
}

+ (NSString *)encodePostToUniversalString:(NSDictionary *)params needSource:(BOOL)source {
    NSMutableString *encodedParams = [[NSMutableString alloc] initWithString:@"{ "];
    for (NSString *key in params) {
        NSString *value = nil;
        BOOL string = YES;
        if ([[params objectForKey:key] isKindOfClass:[NSString class]]) {
            value = [params objectForKey:key];
        } else if ([[params objectForKey:key] isKindOfClass:[NSDictionary class]]) {
            value = [BNCServerInterface encodePostToUniversalString:[params objectForKey:key]];
        } else if ([[params objectForKey:key] isKindOfClass:[NSNumber class]]) {
            value = [[params objectForKey:key] stringValue];
            string = NO;
        }
        [encodedParams appendString:@"\""];
        [encodedParams appendString:key];
        if (string) [encodedParams appendString:@"\":\""];
        else [encodedParams appendString:@"\":"];
        [encodedParams appendString:value];
        if (string) [encodedParams appendString:@"\","];
        else [encodedParams appendString:@","];
    }

    if (source) {
        [encodedParams appendString:@"\"source\":\"ios\" }"];
    } else {
        [encodedParams deleteCharactersInRange:NSMakeRange([encodedParams length]-1, 1)];
        [encodedParams appendString:@" }"];
    }
    
    [BNCPreferenceHelper log:FILE_NAME line:LINE_NUM message:@"encoded params : %@", encodedParams];

    return encodedParams;
}

+ (NSString *)urlEncode:(NSString *)string {
    return (NSString *)CFBridgingRelease(CFURLCreateStringByAddingPercentEscapes(NULL,
                                                                                 (CFStringRef)string,
                                                                                 NULL,
                                                                                 (CFStringRef)@"!*'\"();:@&=+$,/?%#[]% ",
                                                                                 CFStringConvertNSStringEncodingToEncoding(NSUTF8StringEncoding)));
}

- (void)genericAsyncHTTPRequest:(NSMutableURLRequest *)request withTag:(NSString *)requestTag andLinkData:(BNCLinkData *)linkData {
    [NSURLConnection sendAsynchronousRequest:request queue:[NSOperationQueue mainQueue] completionHandler: ^(NSURLResponse *response, NSData *POSTReply, NSError *error) {
        BNCServerResponse *serverResponse = [self processServerResponse:response data:POSTReply error:error tag:requestTag andLinkData:linkData];
        if (self.delegate) [self.delegate serverCallback:serverResponse];
    }];
}

- (BNCServerResponse *)genericSyncHTTPRequest:(NSMutableURLRequest *)request withTag:(NSString *)requestTag andLinkData:(BNCLinkData *)linkData {
    NSURLResponse * response = nil;
    NSError * error = nil;
    NSData * POSTReply = [NSURLConnection sendSynchronousRequest:request returningResponse:&response error:&error];
    
    return [self processServerResponse:response data:POSTReply error:error tag:requestTag andLinkData:linkData];
}

- (NSMutableURLRequest *)prepareGetRequest:(NSDictionary *)params url:(NSString *)url log:(BOOL)log {
    url = [url stringByAppendingString:@"?"];
    
    if (params) {
        NSArray *allKeys = [params allKeys];
        
        for (NSString *key in allKeys) {
            if ([key length] > 0) {
                if ([params objectForKey:key]) {
                    url = [url stringByAppendingString:[BNCServerInterface urlEncode:key]];
                    url = [url stringByAppendingString:@"="];
                    url = [url stringByAppendingString:[[BNCServerInterface urlEncode:[params objectForKey:key]] description]];
                    url = [url stringByAppendingString:@"&"];
                }
            }
        }
    }
    
    url = [url stringByAppendingFormat:@"sdk=ios%@", SDK_VERSION];
    if (log) {
        [BNCPreferenceHelper log:FILE_NAME line:LINE_NUM message:@"using url = %@", url];
    }
    
    NSMutableURLRequest *request = [[NSMutableURLRequest alloc] init];
    [request setURL:[NSURL URLWithString:url]];
    
    [request setHTTPMethod:@"GET"];
    [request setValue:@"applications/json" forHTTPHeaderField:@"Content-Type"];
    
    return request;
}

- (NSMutableURLRequest *)preparePostRequest:(NSDictionary *)post url:(NSString *)url log:(BOOL)log {
    NSData *postData = [BNCServerInterface encodePostParams:post];
    NSString *postLength = [NSString stringWithFormat:@"%lu", (unsigned long)[postData length]];
    
    if (log) {
        [BNCPreferenceHelper log:FILE_NAME line:LINE_NUM message:@"using url = %@", url];
        [BNCPreferenceHelper log:FILE_NAME line:LINE_NUM message:@"body = %@", [post description]];
    }
    
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:url]];
    [request setTimeoutInterval:[BNCPreferenceHelper getTimeout]];
    [request setHTTPMethod:@"POST"];
    [request setValue:postLength forHTTPHeaderField:@"Content-Length"];
    [request setValue:@"application/json" forHTTPHeaderField:@"Content-Type"];
    [request setHTTPBody:postData];
    
    return request;
}

- (BNCServerResponse *)processServerResponse:(NSURLResponse *)response data:(NSData *)POSTReply error:(NSError *)error tag:(NSString *)requestTag andLinkData:(BNCLinkData *)linkData {
    BNCServerResponse *serverResponse = nil;
    if (!error) {
        NSHTTPURLResponse *httpResponse = (NSHTTPURLResponse *)response;
        NSNumber *statusCode = [NSNumber numberWithLong:[httpResponse statusCode]];
        
        serverResponse = [[BNCServerResponse alloc] initWithTag:requestTag andStatusCode:statusCode];
        serverResponse.linkData = linkData;
        
        if (POSTReply != nil) {
            NSError *convError;
            id jsonData = [NSJSONSerialization JSONObjectWithData:POSTReply options:NSJSONReadingMutableContainers error:&convError];
            if (!convError) {
                serverResponse.data = jsonData;
            }
        }
    } else {
        serverResponse = [[BNCServerResponse alloc] initWithTag:requestTag andStatusCode:[NSNumber numberWithInteger:error.code]];
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
