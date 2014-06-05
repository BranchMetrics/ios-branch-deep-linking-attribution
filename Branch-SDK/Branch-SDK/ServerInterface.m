//
//  ServerInterface.m
//  KindredPrints-iOS-TestBed
//
//  Created by Alex Austin on 1/31/14.
//  Copyright (c) 2014 Kindred Prints. All rights reserved.
//

#import "ServerInterface.h"
#import "DevPreferenceHelper.h"

@implementation ServerInterface

#define BOUNDARY @"JFiID49gfTXOcugN3zxXEZICRLK6ffUQqi"


// make a generalized get request
- (void)getRequestAsync:(NSDictionary *)params url:(NSString *)url andTag:(NSString *)requestTag andIdentifier:(NSString *)ident {
    if (params) {
        
        NSArray *allKeys = [params allKeys];
        if ([allKeys count] > 0) {
            url = [url stringByAppendingString:@"?"];
        }
        int count = (int)[allKeys count];
        int i = 0;
        for (NSString *key in allKeys) {
            if ([key length] > 0) {
                if ([params objectForKey:key]) {
                    url = [url stringByAppendingString:key];
                    url = [url stringByAppendingString:@"="];
                    url = [url stringByAppendingString:[[params objectForKey:key] description]];
                    if(i < count-1)
                        url = [url stringByAppendingString:@"&"];
                }
            }
            i = i + 1;
        }
    }
    if(LOG) NSLog(@"using url = %@", url);
    NSMutableURLRequest *request = [[NSMutableURLRequest alloc] init];
    [request setURL:[NSURL URLWithString:url]];
    
    [request setHTTPMethod:@"GET"];
    [request setValue:@"0" forHTTPHeaderField:@"Content-Length"];
    [request setValue:@"applications/json" forHTTPHeaderField:@"Content-type"];
    [request setHTTPBody:nil];
    
    [self genericHTTPRequest:request withTag:requestTag andIdentifier:ident withAuth:YES];
}

// make a generalized post request
- (void)postRequestAsync:(NSDictionary *)post url:(NSString *)url andTag:(NSString *)requestTag andIdentifier:(NSString *)ident {
    NSData *postData = [ServerInterface encodePostParams:post];
    NSString *postLength = [NSString stringWithFormat:@"%lu", (unsigned long)[postData length]];
    
    if(LOG) NSLog(@"using url = %@", url);
    
    NSMutableURLRequest *request = [[NSMutableURLRequest alloc] init];
    [request setURL:[NSURL URLWithString:url]];
    
    [request setHTTPMethod:@"POST"];
    [request setValue:postLength forHTTPHeaderField:@"Content-Length"];
    [request setValue:@"application/json" forHTTPHeaderField:@"Content-type"];
    [request setHTTPBody:postData];
    
    [self genericHTTPRequest:request withTag:requestTag andIdentifier:ident withAuth:YES];
}

- (void)postToAWSRequestWithImageAsync:(NSDictionary *)post image:(NSData *)image url:(NSString *)url andTag:(NSString *)requestTag andIdentifier:(NSString *)ident {
    NSMutableURLRequest *request = [[NSMutableURLRequest alloc] init];
    
    if(LOG) NSLog(@"using url = %@", url);
    
    [request setURL:[NSURL URLWithString:url]];
    [request setCachePolicy:NSURLRequestReloadIgnoringLocalCacheData];
    [request setHTTPMethod:@"POST"];

    NSString *contentType = [NSString stringWithFormat:@"multipart/form-data, boundary=%@", BOUNDARY];
    [request setValue:contentType forHTTPHeaderField: @"Content-Type"];
    
    NSMutableData *body = [NSMutableData data];
    
    NSArray *keys = [post allKeys];
    for (NSString *key in keys) {
        [body appendData:[[NSString stringWithFormat:@"--%@\r\n", BOUNDARY] dataUsingEncoding:NSUTF8StringEncoding]];
        [body appendData:[[NSString stringWithFormat:@"Content-Disposition: form-data; name=\"%@\"\r\n\r\n", key] dataUsingEncoding:NSUTF8StringEncoding]];
        [body appendData:[[NSString stringWithFormat:@"%@", [post objectForKey:key]] dataUsingEncoding:NSUTF8StringEncoding]];
        [body appendData:[[NSString stringWithFormat:@"\r\n"] dataUsingEncoding:NSUTF8StringEncoding]];
    }
    
    [body appendData:[[NSString stringWithFormat:@"--%@\r\n", BOUNDARY] dataUsingEncoding:NSUTF8StringEncoding]];
    [body appendData:[@"Content-Disposition: form-data; name=\"file\"\r\n\r\n" dataUsingEncoding:NSUTF8StringEncoding]];
    [body appendData:image];
    [body appendData:[[NSString stringWithFormat:@"\r\n"] dataUsingEncoding:NSUTF8StringEncoding]];
    [body appendData:[[NSString stringWithFormat:@"--%@--", BOUNDARY] dataUsingEncoding:NSUTF8StringEncoding]];
    
    [request setHTTPBody:body];

    NSString *postLength = [NSString stringWithFormat:@"%lu", (unsigned long)[body length]];
    [request setValue:postLength forHTTPHeaderField:@"Content-Length"];
    
    [self genericHTTPRequest:request withTag:requestTag andIdentifier:ident withAuth:NO];
}

+ (NSData *) encodePostParams:(NSDictionary *)params {
    NSError *writeError = nil;
    NSData *postData = [NSJSONSerialization dataWithJSONObject:params options:NSJSONWritingPrettyPrinted error:&writeError];
    return postData;
}

- (void)genericHTTPRequest:(NSMutableURLRequest *)request withTag:(NSString *)requestTag andIdentifier:(NSString *)ident withAuth:(BOOL)auth {
    if (auth) {
        NSString *authValue = [NSString stringWithFormat:@"Basic %@", [DevPreferenceHelper getAppKey]];
        [request setValue:authValue forHTTPHeaderField:@"Authorization"];
    }

    [NSURLConnection sendAsynchronousRequest:request queue:[NSOperationQueue mainQueue] completionHandler: ^(NSURLResponse *response, NSData *POSTReply, NSError *error) {
        NSMutableDictionary *jsonObjects = [[NSMutableDictionary alloc] init];

        if ([error code] && ([error code] == NSURLErrorTimedOut || [error code] == NSURLErrorNotConnectedToInternet)) {
            UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"Internet Connection Error" message:@"Printing your images requires a stable internet connection. Please try again with better reception!" delegate:self cancelButtonTitle:@"OK" otherButtonTitles:nil, nil];
            [alertView show];
        }
        
        NSHTTPURLResponse *httpResponse = (NSHTTPURLResponse *)response;
        NSNumber *statusCode = [NSNumber numberWithLong:[httpResponse statusCode]];
        
        [jsonObjects setObject:statusCode forKey:kpServerStatusCode];
        [jsonObjects setObject:requestTag forKey:kpServerRequestTag];
        [jsonObjects setObject:ident forKey:kpServerIdentTag];
        
        if (POSTReply != nil) {
            NSError *convError;
            NSDictionary *returnedObjs = [NSJSONSerialization JSONObjectWithData:POSTReply options:NSJSONReadingMutableContainers error:&convError];
            
            for (NSString *key in returnedObjs) {
                [jsonObjects setObject:[returnedObjs objectForKey:key] forKey:key];
            }
        }
        
        if (self.delegate) [self.delegate serverCallback:jsonObjects];
    }];
}


@end
