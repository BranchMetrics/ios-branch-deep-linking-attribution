//
//  BranchServerInterface.m
//  Branch-SDK
//
//  Created by Alex Austin on 6/6/14.
//  Copyright (c) 2014 Branch Metrics. All rights reserved.
//

#import "BNCConfig.h"
#import "BranchServerInterface.h"
#import "BNCSystemObserver.h"
#import "BNCPreferenceHelper.h"

@implementation BranchServerInterface

- (void)connectToDebugWithKey:(NSString *)key callback:(BNCServerCallback)callback {
    NSMutableDictionary *post = [[NSMutableDictionary alloc] init];
    [post setObject:[BNCPreferenceHelper getDeviceFingerprintID] forKey:@"device_fingerprint_id"];
    [post setObject:[BNCSystemObserver getDeviceName] forKey:@"device_name"];
    [post setObject:[BNCSystemObserver getOS] forKey:@"os"];
    [post setObject:[BNCSystemObserver getOSVersion] forKey:@"os_version"];
    [post setObject:[BNCSystemObserver getModel] forKey:@"model"];
    [post setObject:[NSNumber numberWithBool:[BNCSystemObserver isSimulator]] forKey:@"is_simulator"];
    
    [self postRequest:post url:[BNCPreferenceHelper getAPIURL:@"debug/connect"] key:key log:NO callback:callback];
}

- (void)disconnectFromDebugWithKey:(NSString *)key callback:(BNCServerCallback)callback {
    NSMutableDictionary *post = [[NSMutableDictionary alloc] init];
    [post setObject:[BNCPreferenceHelper getDeviceFingerprintID] forKey:@"device_fingerprint_id"];
    
    [self postRequest:post url:[BNCPreferenceHelper getAPIURL:@"debug/disconnect"] key:key log:NO callback:callback];
}

- (void)sendLog:(NSString *)log key:(NSString *)key callback:(BNCServerCallback)callback {
    NSMutableDictionary *post = [NSMutableDictionary dictionaryWithObject:log forKey:@"log"];
    [post setObject:[BNCPreferenceHelper getDeviceFingerprintID] forKey:@"device_fingerprint_id"];
    
    [self postRequest:post url:[BNCPreferenceHelper getAPIURL:@"debug/log"] key:key log:NO callback:callback];
}

- (void)sendScreenshot:(NSData *)data key:(NSString *)key callback:(BNCServerCallback)callback {
    NSMutableURLRequest *request = [[NSMutableURLRequest alloc] init];
    NSString *file = @"BNC_Debug_Screen.png";
    
    NSString *keyString;
    if ([key hasPrefix:@"key_"]) {
        keyString = [NSString stringWithFormat:@"%@=%@", KEY_BRANCH_KEY, key];
    }
    else {
        keyString = [NSString stringWithFormat:@"app_id=%@", key];
    }

    [request setURL:[NSURL URLWithString:[NSString stringWithFormat:@"%@?%@&sdk=ios%@&device_fingerprint_id=%@", [BNCPreferenceHelper getAPIURL:@"debug/screenshot"], keyString, SDK_VERSION, [BNCPreferenceHelper getDeviceFingerprintID]]]];
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

    [self genericHTTPRequest:request log:YES callback:callback];
}

@end
