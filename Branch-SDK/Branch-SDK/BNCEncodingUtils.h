//
//  BNCEncodingUtils.h
//  Branch
//
//  Created by Graham Mueller on 3/31/15.
//  Copyright (c) 2015 Branch Metrics. All rights reserved.
//

#if __has_feature(modules)
@import Foundation;
#else
#import <Foundation/Foundation.h>
#endif

#pragma mark BNCWireFormat

static inline NSDate* BNCDateFromWireFormat(id object) {
    NSDate *date = nil;
    NSNumber *number = object;
    if ([number isKindOfClass:[NSNumber class]] ||
        [number isKindOfClass:[NSString class]]) {
        NSTimeInterval t = [number doubleValue];
        date = [NSDate dateWithTimeIntervalSince1970:t/1000.0];
    }
    return date;
}

static inline NSNumber* BNCWireFormatFromDate(NSDate *date) {
    NSNumber *number = nil;
    NSTimeInterval t = [date timeIntervalSince1970];
    if (date && t != 0.0 ) {
        number = [NSNumber numberWithLongLong:(long long)(t*1000.0)];
    }
    return number;
}

#pragma mark - BNCKeyValue

@interface BNCKeyValue : NSObject

+ (BNCKeyValue*) key:(NSString*)key value:(NSString*)value;
- (NSString*) description;

@property (nonatomic, strong) NSString* key;
@property (nonatomic, strong) NSString* value;

@end

#pragma mark - BNCEncodingUtils

@interface BNCEncodingUtils : NSObject

+ (NSString *)base64EncodeStringToString:(NSString *)strData;
+ (NSString *)base64DecodeStringToString:(NSString *)strData;
+ (NSString *)base64EncodeData:(NSData *)objData;
+ (NSData *)base64DecodeString:(NSString *)strBase64;

+ (NSString *)md5Encode:(NSString *)input;

+ (NSString *)urlEncodedString:(NSString *)string;
+ (NSString *)encodeArrayToJsonString:(NSArray *)dictionary;
+ (NSString *)encodeDictionaryToJsonString:(NSDictionary *)dictionary;
+ (NSData *)encodeDictionaryToJsonData:(NSDictionary *)dictionary;

+ (NSString*) stringByPercentDecodingString:(NSString*)string;

+ (NSDictionary *)decodeJsonDataToDictionary:(NSData *)jsonData;
+ (NSDictionary *)decodeJsonStringToDictionary:(NSString *)jsonString;
+ (NSDictionary *)decodeQueryStringToDictionary:(NSString *)queryString;
+ (NSString *)encodeDictionaryToQueryString:(NSDictionary *)dictionary;

+ (NSString *) hexStringFromData:(NSData*)data;
+ (NSData *)   dataFromHexString:(NSString*)string;

+ (NSArray<BNCKeyValue*>*) queryItems:(NSURL*)URL;

@end
