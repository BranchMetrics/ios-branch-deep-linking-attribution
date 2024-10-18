//
//  BNCServerRequest.m
//  Branch-SDK
//
//  Created by Graham Mueller on 5/22/15.
//  Copyright (c) 2015 Branch Metrics. All rights reserved.
//

#import "BNCServerRequest.h"
#import "BranchLogger.h"
#import "BNCEncodingUtils.h"

@implementation BNCServerRequest

- (id) init {
    if ((self = [super init])) {
        NSDate *timeStamp = [NSDate date];
        _requestUUID = [BNCServerRequest generateRequestUUIDFromDate:timeStamp];
        _requestCreationTimeStamp = BNCWireFormatFromDate(timeStamp);
    }
    return self;
}

- (void)makeRequest:(BNCServerInterface *)serverInterface key:(NSString *)key callback:(BNCServerCallback)callback {
    [[BranchLogger shared] logError:@"BNCServerRequest subclasses must implement makeRequest:key:callback:." error:nil];
}

- (void)processResponse:(BNCServerResponse *)response error:(NSError *)error {
    [[BranchLogger shared] logError:@"BNCServerRequest subclasses must implement processResponse:error:." error:nil];
}


- (void)safeSetValue:(NSObject *)value forKey:(NSString *)key onDict:(NSMutableDictionary *)dict {
    if (value) {
        dict[key] = value;
    }
}

+ (NSString *) generateRequestUUIDFromDate:(NSDate *) localDate {
    NSString *uuid = [[NSUUID UUID ] UUIDString];
    
    NSTimeZone *gmt = [NSTimeZone timeZoneWithAbbreviation:@"GMT"];
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    dateFormatter.dateFormat = @"'-'yyyyMMddHH";
    [dateFormatter setTimeZone:gmt];
    
    return [uuid stringByAppendingString:[dateFormatter stringFromDate:localDate]];
}

@end
