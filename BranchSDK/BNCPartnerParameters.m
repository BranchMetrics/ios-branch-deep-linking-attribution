//
//  BNCPartnerParameters.m
//  Branch
//
//  Created by Ernest Cho on 12/9/20.
//  Copyright © 2020 Branch, Inc. All rights reserved.
//

#import "BNCPartnerParameters.h"

@interface BNCPartnerParameters()
@property (nonatomic, strong, readwrite) NSMutableDictionary<NSString *, NSMutableDictionary<NSString *, NSString *> *> *parameters;
@end

@implementation BNCPartnerParameters

+ (instancetype)shared {
    static BNCPartnerParameters *partnerParameters;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        partnerParameters = [BNCPartnerParameters new];
    });
    return partnerParameters;
}

- (instancetype)init {
    self = [super init];
    if (self) {
        self.parameters = [NSMutableDictionary<NSString *, NSMutableDictionary<NSString *, NSString *> *> new];
    }
    return self;
}

- (void)clearAllParameters {
    self.parameters = [NSMutableDictionary<NSString *, NSMutableDictionary<NSString *, NSString *> *> new];
}

- (NSMutableDictionary<NSString *, NSString *> *)parametersForPartner:(NSString *)partnerName {
    NSMutableDictionary<NSString *, NSString *> *parametersForPartner = [self.parameters objectForKey:partnerName];
    if (!parametersForPartner) {
        parametersForPartner = [NSMutableDictionary<NSString *, NSString *> new];
        [self.parameters setObject:parametersForPartner forKey:partnerName];
    }
    return parametersForPartner;
}

- (void)addParameterWithName:(NSString *)name value:(NSString *)value partnerName:(NSString *)partnerName {
    NSMutableDictionary<NSString *, NSString *> *parametersForPartner = [self parametersForPartner:partnerName];
    [parametersForPartner setObject:value forKey:name];
}

- (void)addFaceBookParameterWithName:(NSString *)name value:(NSString *)value {
    if ([self sha256HashSanityCheckValue:value]) {
        [self addParameterWithName:name value:value partnerName:@"fb"];
    } else {
        // TODO: log a warning that the parameter looks invalid and will be ignored. Do not log the value as it may be PII that was inadvertently passed in.
    }
}

- (BOOL)sha256HashSanityCheckValue:(NSString *)value {
    return ([value length] == 64 && [self isStringHex:value]);
}

- (BOOL)isStringHex:(NSString *)string {
    NSCharacterSet *chars = [[NSCharacterSet characterSetWithCharactersInString:@"0123456789ABCDEF"] invertedSet];
    return (NSNotFound == [[string uppercaseString] rangeOfCharacterFromSet:chars].location);
}

- (NSDictionary *)parameterJson {
    return self.parameters;
}

@end
