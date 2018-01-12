//
//  BNCKeyChain.m
//  Branch-SDK
//
//  Created by Edward on 1/8/18.
//  Copyright © 2018 Branch. All rights reserved.
//

#import "BNCKeyChain.h"
#import "BNCLog.h"

@implementation BNCKeyChain

+ (NSError*) errorWithKey:(NSString*)key OSStatus:(OSStatus)status {
    // Security errors are defined in Security/SecBase.h
    if (status == errSecSuccess) return nil;
    NSString *s = [NSString stringWithFormat:@"Security error with key '%@': code %ld.", key, (long) status];
    NSError *error = [NSError errorWithDomain:NSOSStatusErrorDomain code:status userInfo:@{
        NSLocalizedDescriptionKey: s
    }];
    return error;
}

+ (id) retrieveValueForService:(NSString*)service key:(NSString*)key error:(NSError**)error {

//  NSString *accessGroup = [NSString stringWithFormat:@"3ZNSRC9M83.%@", [NSBundle mainBundle].bundleIdentifier];

    NSDictionary* dictionary = @{
        (__bridge id)kSecClass:                 (__bridge id)kSecClassGenericPassword,
        (__bridge id)kSecAttrService:           service,
        (__bridge id)kSecAttrAccount:           key,
//      (__bridge id)kSecAttrAccessible:        (__bridge id)kSecAttrAccessibleAfterFirstUnlock,
        (__bridge id)kSecReturnData:            (__bridge id)kCFBooleanTrue,
        (__bridge id)kSecMatchLimit:            (__bridge id)kSecMatchLimitOne,
        (__bridge id)kSecAttrSynchronizable:    (__bridge id)kSecAttrSynchronizableAny
//      (__bridge id)kSecAttrAccessGroup:       accessGroup
    };
    CFDataRef valueData = NULL;
    OSStatus status = SecItemCopyMatching((__bridge CFDictionaryRef)dictionary, (CFTypeRef *)&valueData);
    if (status) {
        NSError *localError = [self errorWithKey:key OSStatus:status];
        BNCLogError(@"Can't retrieve key: %@.", localError);
        if (error) *error = localError;
        return nil;
    }
    id value = [NSKeyedUnarchiver unarchiveObjectWithData:(__bridge NSData*)valueData];
    return value;
}

+ (NSError*) storeValue:(id)value forService:(NSString*)service key:(NSString*)key iCloud:(BOOL)iCloud {

    NSData* valueData = [NSKeyedArchiver archivedDataWithRootObject:value];
    if (!valueData) {
        NSError *error = [NSError errorWithDomain:NSCocoaErrorDomain code:NSPropertyListWriteStreamError userInfo:nil];
        return error;
    }
    NSMutableDictionary* dictionary = [NSMutableDictionary dictionaryWithDictionary:@{
        (__bridge id)kSecClass:                 (__bridge id)kSecClassGenericPassword,
        (__bridge id)kSecAttrService:           service,
        (__bridge id)kSecAttrAccount:           key,
        (__bridge id)kSecAttrSynchronizable:    (__bridge id)kSecAttrSynchronizableAny
    }];
    SecItemDelete((__bridge CFDictionaryRef)dictionary);

    dictionary[(__bridge id)kSecValueData] = valueData;
    dictionary[(__bridge id)kSecAttrIsInvisible] = (__bridge id)kCFBooleanTrue;
    dictionary[(__bridge id)kSecAttrAccessible] = (__bridge id)kSecAttrAccessibleAfterFirstUnlock;

    if (iCloud) {
        dictionary[(__bridge id)kSecAttrSynchronizable] = (__bridge id) kCFBooleanTrue;
        dictionary[(__bridge id)kSecAttrAccessGroup] =
            [NSString stringWithFormat:@"3ZNSRC9M83.%@", [NSBundle mainBundle].bundleIdentifier];
    } else {
        dictionary[(__bridge id)kSecAttrSynchronizable] = (__bridge id) kCFBooleanFalse;
    }
    OSStatus status = SecItemAdd((__bridge CFDictionaryRef)dictionary, NULL);
    if (status) {
        NSError *error = [self errorWithKey:key OSStatus:status];
        BNCLogError(@"Can't store key: %@.", error);
        return error;
    }
    return nil;
}

+ (NSError*) removeValuesForService:(NSString*)service key:(NSString*)key {
    NSMutableDictionary* dictionary = [NSMutableDictionary dictionaryWithDictionary:@{
        (__bridge id)kSecClass:                 (__bridge id)kSecClassGenericPassword,
        (__bridge id)kSecAttrAccessible:        (__bridge id)kSecAttrAccessibleAfterFirstUnlock,
        (__bridge id)kSecAttrSynchronizable:    (__bridge id)kSecAttrSynchronizableAny
    }];
    if (service) dictionary[(__bridge id)kSecAttrService] = service;
    if (key) dictionary[(__bridge id)kSecAttrAccount] = key;

    OSStatus status = SecItemDelete((__bridge CFDictionaryRef)dictionary);
    if (status == errSecItemNotFound) status = errSecSuccess;
    if (status) {
        NSError *error = [self errorWithKey:key OSStatus:status];
        BNCLogError(@"Can't remove key: %@.", error);
        return error;
    }
    return nil;
}

@end
