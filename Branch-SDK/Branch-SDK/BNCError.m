//
//  BNCError.m
//  Branch-SDK
//
//  Created by Qinwei Gong on 11/17/14.
//  Copyright (c) 2014 Branch Metrics. All rights reserved.
//

#import "BNCError.h"

NSString * const BNCErrorDomain = @"io.branch.sdk.error";

void BNCForceNSErrorCategoryToLoad(void) __attribute__((constructor));
void BNCForceNSErrorCategoryToLoad() {
    //  Nothing here, but forces linker to load the category.
}

@implementation NSError (Branch)

+ (NSString*) errorWithCode:(BNCErrorCode)code {

    if (code < BNCInitError || code > BNCContentIdentifierError)
        return @"Branch error.";

    static NSString* messages[] = {
        @"The Branch user session has not been initialized.",
        @"You're trying to redeem more credits than are available. Have you loaded rewards?",
        @"Public key is not an SecKeyRef type."
        @"A canonicalIdentifier or title are required to uniquely identify content, so could not register view.",
        @"The Core Spotlight indexing service is not available on this device.",
        @"Spotlight Indexing requires a title.",
        @"Cannot redeem zero credits.",
    };

    return messages[code - BNCInitError];
}

+ (NSError*) branchErrorWithCode:(BNCErrorCode)errorCode
                           error:(NSError*)error
                          reason:(NSString*_Nullable)reason {

    NSMutableDictionary *userInfo = [NSMutableDictionary new];

    NSString *localizedString = BNCLocalizedString([self errorWithCode:errorCode]);
    if (localizedString) userInfo[NSLocalizedDescriptionKey] = localizedString;

    NSString* localizedReason = BNCLocalizedString(reason);
    if (localizedReason) userInfo[NSLocalizedFailureReasonErrorKey] = localizedReason;

    if (error) userInfo[NSUnderlyingErrorKey] = error;

    return [NSError errorWithDomain:BNCErrorDomain code:errorCode userInfo:userInfo];
}

+ (NSError*_Nonnull) branchErrorWithCode:(BNCErrorCode)errorCode {
    return [NSError branchErrorWithCode:errorCode error:nil reason:nil];
}

+ (NSError*_Nonnull) branchErrorWithCode:(BNCErrorCode)errorCode error:(NSError*_Nullable)error {
    return [NSError branchErrorWithCode:errorCode error:error reason:nil];
}

+ (NSError*_Nonnull) branchErrorWithCode:(BNCErrorCode)errorCode reason:(NSString*_Nullable)reason {
    return [NSError branchErrorWithCode:errorCode error:nil reason:reason];
}

@end
