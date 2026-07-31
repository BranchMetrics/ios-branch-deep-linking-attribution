/**
 @file          BNCKeyChain.m
 @package       Branch-SDK
 @brief         Simple access routines for secure keychain storage.

 @author        Edward Smith
 @date          January 8, 2018
 @copyright     Copyright © 2018 Branch. All rights reserved.
*/

#import "BNCKeyChain.h"
#import "BranchLogger.h"

// Apple Keychain Reference:
// https://developer.apple.com/library/content/documentation/Conceptual/
//      keychainServConcepts/02concepts/concepts.html#//apple_ref/doc/uid/TP30000897-CH204-SW1
//
// To translate security errors to text from the command line use: `security error -34018`
#pragma mark - BNCKeyChain

@implementation BNCKeyChain

// Wraps OSStatus in an NSError
// Security errors are defined in Security/SecBase.h
+ (NSError *) errorWithKey:(NSString *)key OSStatus:(OSStatus)status {
    if (status == errSecSuccess) return nil;
    NSString *reason = (__bridge_transfer NSString*) SecCopyErrorMessageString(status, NULL);
    NSString *description = [NSString stringWithFormat:@"Branch Keychain error for key '%@': OSStatus %ld.", key, (long) status];
    
    if (!reason) {
        reason = @"Sec OSStatus error.";
    }

    NSError *error = [NSError errorWithDomain:NSOSStatusErrorDomain code:status userInfo:@{
        NSLocalizedDescriptionKey: description,
        NSLocalizedFailureReasonErrorKey: reason
    }];
    return error;
}

+ (NSDate *)retrieveDateForService:(NSString *)service key:(NSString *)key error:(NSError **)error {
    if (error) *error = nil;
    if (service == nil || key == nil) {
        NSError *localError = [self errorWithKey:key OSStatus:errSecParam];
        if (error) *error = localError;
        return nil;
    }

    NSDictionary* dictionary = @{
        (__bridge id)kSecClass:                 (__bridge id)kSecClassGenericPassword,
        (__bridge id)kSecAttrService:           service,
        (__bridge id)kSecAttrAccount:           key,
        (__bridge id)kSecReturnData:            (__bridge id)kCFBooleanTrue,
        (__bridge id)kSecMatchLimit:            (__bridge id)kSecMatchLimitOne,
        (__bridge id)kSecAttrSynchronizable:    (__bridge id)kSecAttrSynchronizableAny
    };
    CFDataRef valueData = NULL;
    OSStatus status = SecItemCopyMatching((__bridge CFDictionaryRef)dictionary, (CFTypeRef *)&valueData);
    if (status != errSecSuccess) {
        NSError *localError = [self errorWithKey:key OSStatus:status];
        [[BranchLogger shared] logVerbose:@"Key not found" error:localError];
        
        if (error) *error = localError;
        if (valueData) CFRelease(valueData);
        return nil;
    }
    id value = nil;
    if (valueData) {
        @try {
            value = [NSKeyedUnarchiver unarchivedObjectOfClass:[NSDate class] fromData:(__bridge NSData*)valueData error:NULL];
        } @catch (NSException *exception) {
            value = nil;
            NSError *localError = [self errorWithKey:key OSStatus:errSecDecode];
            if (error) *error = localError;
        }
        CFRelease(valueData);
    }
    return value;
}

+ (NSError *) storeDate:(NSDate *)date
             forService:(NSString *)service
                    key:(NSString *)key
       cloudAccessGroup:(NSString *)accessGroup {

    if (date == nil || service == nil || key == nil) {
        return [self errorWithKey:key OSStatus:errSecParam];
    }
    
    NSData* valueData = nil;
    @try {
        valueData = [NSKeyedArchiver archivedDataWithRootObject:date requiringSecureCoding:YES error:NULL];
    } @catch (NSException *exception) {
        valueData = nil;
    }
    if (!valueData) {
        NSError *error = [NSError errorWithDomain:NSCocoaErrorDomain
            code:NSPropertyListWriteStreamError userInfo:nil];
        return error;
    }
    NSMutableDictionary* dictionary = [NSMutableDictionary dictionaryWithDictionary:@{
        (__bridge id)kSecClass:                 (__bridge id)kSecClassGenericPassword,
        (__bridge id)kSecAttrService:           service,
        (__bridge id)kSecAttrAccount:           key,
        (__bridge id)kSecAttrSynchronizable:    (__bridge id)kSecAttrSynchronizableAny
    }];
    OSStatus status = SecItemDelete((__bridge CFDictionaryRef)dictionary);
    if (status != errSecSuccess && status != errSecItemNotFound) {
        NSError *error = [self errorWithKey:key OSStatus:status];
        [[BranchLogger shared] logDebug:@"Failed to save key" error:error];
    }

    dictionary[(__bridge id)kSecValueData] = valueData;
    dictionary[(__bridge id)kSecAttrIsInvisible] = (__bridge id)kCFBooleanTrue;
    dictionary[(__bridge id)kSecAttrAccessible] = (__bridge id)kSecAttrAccessibleWhenUnlockedThisDeviceOnly;

    if (accessGroup.length) {
        dictionary[(__bridge id)kSecAttrAccessGroup] = accessGroup;
        dictionary[(__bridge id)kSecAttrSynchronizable] = (__bridge id) kCFBooleanTrue;
    } else {
        dictionary[(__bridge id)kSecAttrSynchronizable] = (__bridge id) kCFBooleanFalse;
    }
    status = SecItemAdd((__bridge CFDictionaryRef)dictionary, NULL);
    if (status) {
        NSError *error = [self errorWithKey:key OSStatus:status];
        [[BranchLogger shared] logDebug:@"Failed to save key" error:error];
        return error;
    }
    return nil;
}

+ (NSError*) removeValuesForService:(NSString *)service key:(NSString *)key {
    NSMutableDictionary *dictionary = [NSMutableDictionary dictionaryWithDictionary:@{
        (__bridge id)kSecClass:                 (__bridge id)kSecClassGenericPassword,
        (__bridge id)kSecAttrSynchronizable:    (__bridge id)kSecAttrSynchronizableAny
    }];
    if (service) dictionary[(__bridge id)kSecAttrService] = service;
    if (key) dictionary[(__bridge id)kSecAttrAccount] = key;

    OSStatus status = SecItemDelete((__bridge CFDictionaryRef)dictionary);
    if (status == errSecItemNotFound) status = errSecSuccess;
    if (status) {
        NSError *error = [self errorWithKey:key OSStatus:status];
        [[BranchLogger shared] logDebug:@"Failed to remove key" error:[self errorWithKey:key OSStatus:status]];
        return error;
    }
    return nil;
}

// The security access group string is prefixed with the Apple Developer Team ID
+ (NSString * _Nullable)securityAccessGroup {
    static NSString *_securityAccessGroup = nil;
    static dispatch_once_t onceToken = 0;
    dispatch_once(&onceToken, ^{
        
        // The keychain cannot be empty prior to requesting the security access group string. Add a tmp variable.
        NSError *error = [self storeDate:[NSDate date] forService:@"BranchKeychainService" key:@"Temp" cloudAccessGroup:nil];
        if (error) {
            [[BranchLogger shared] logWarning:@"Failed to store temp value" error:error];
        }
        
        NSDictionary* dictionary = @{
            (__bridge id)kSecClass:                 (__bridge id)kSecClassGenericPassword,
            (__bridge id)kSecAttrService:           @"BranchKeychainService",
            (__bridge id)kSecReturnAttributes:      (__bridge id)kCFBooleanTrue,
            (__bridge id)kSecAttrSynchronizable:    (__bridge id)kSecAttrSynchronizableAny,
            (__bridge id)kSecMatchLimit:            (__bridge id)kSecMatchLimitOne
        };
        CFDictionaryRef resultDictionary = NULL;
        OSStatus status = SecItemCopyMatching((__bridge CFDictionaryRef)dictionary, (CFTypeRef*)&resultDictionary);
        
        if (status == errSecItemNotFound) { 
            return;
        }
        if (status != errSecSuccess) {
            [[BranchLogger shared] logWarning:[NSString stringWithFormat:@"Failed to retrieve security access group"] error:[self errorWithKey:nil OSStatus:status]];
            return;
        }
        NSString *group = [(__bridge NSDictionary *)resultDictionary objectForKey:(__bridge NSString *)kSecAttrAccessGroup];
        if (group.length > 0) {
            _securityAccessGroup = [group copy];
        }
        CFRelease(resultDictionary);
    });
    
    return _securityAccessGroup;

}

@end
