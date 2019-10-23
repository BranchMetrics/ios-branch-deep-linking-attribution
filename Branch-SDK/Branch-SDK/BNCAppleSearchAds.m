//
//  BNCAppleSearchAds.m
//  Branch
//
//  Created by Ernest Cho on 10/22/19.
//  Copyright © 2019 Branch, Inc. All rights reserved.
//

#import "BNCAppleSearchAds.h"
#import "NSError+Branch.h"

@interface BNCAppleSearchAds()
@property (nonatomic, strong, readwrite) Class adClientClass;
@property (nonatomic, assign, readwrite) SEL adClientSharedClient;
@property (nonatomic, assign, readwrite) SEL adClientRequestAttribution;
@end

@implementation BNCAppleSearchAds

+ (BNCAppleSearchAds *)sharedInstance {
    static BNCAppleSearchAds *singleton;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        singleton = [[BNCAppleSearchAds alloc] init];
    });
    return singleton;
}

- (instancetype)init {
    self = [super init];
    if (self) {
        self.adClientClass = NSClassFromString(@"ADClient");
        self.adClientSharedClient = NSSelectorFromString(@"sharedClient");
        self.adClientRequestAttribution = NSSelectorFromString(@"requestAttributionDetailsWithBlock:");
    }
    return self;
}

// business logic around checking and storing Apple Search Ads attribution
- (void)checkAppleSearchAdsSaveTo:(BNCPreferenceHelper *)preferenceHelper installDate:(NSDate *)installDate completion:(void (^_Nullable)(void))completion {
    if ([self isAppleSearchAdSavedToDictionary:preferenceHelper.appleSearchAdDetails]) {
        if (completion) {
            completion();
        }
        return;
    }
    
    if (![self isDateWithinWindow:installDate]) {
        if (completion) {
            completion();
        }
        return;
    }
    
    [self requestAttributionWithCompletion:^(NSDictionary * _Nullable attributionDetails, NSError * _Nullable error, NSTimeInterval elapsedSeconds) {
        // BNCPreferenceHelper should be responsible for correctly storing and resetting this
        @synchronized ([BNCPreferenceHelper preferenceHelper]) {
            BNCPreferenceHelper *preferenceHelper = [BNCPreferenceHelper preferenceHelper];
            if (attributionDetails.count > 0 && !error) {
                [preferenceHelper addInstrumentationDictionaryKey:@"apple_search_ad" value:[[NSNumber numberWithInteger:elapsedSeconds*1000] stringValue]];
            }
            if (!error) {
                if (attributionDetails == nil) {
                    attributionDetails = @{};
                }
                if (preferenceHelper.appleSearchAdDetails == nil) {
                    preferenceHelper.appleSearchAdDetails = @{};
                }
                if (![preferenceHelper.appleSearchAdDetails isEqualToDictionary:attributionDetails]) {
                    preferenceHelper.appleSearchAdDetails = attributionDetails;
                    preferenceHelper.appleSearchAdNeedsSend = YES;
                }
            }
        }
        
        if (completion) {
            completion();
        }
    }];
}

- (BOOL)isAppleSearchAdSavedToDictionary:(NSDictionary *)appleSearchAdDetails {
    if (appleSearchAdDetails) {
        NSNumber *hasAppleSearchAdAttribution = appleSearchAdDetails[@"iad-attribution"];
        return [hasAppleSearchAdAttribution boolValue];
    }
    return NO;
}

- (BOOL)isDateWithinWindow:(NSDate *)installDate {
    NSDate *installDatePlus30 = [installDate dateByAddingTimeInterval:(30.0*24.0*60.0*60.0)];
    if ([installDatePlus30 compare:[NSDate date]] == NSOrderedAscending) {
        return YES;
    }
    return NO;
}

- (BOOL)isAdClientAvailable {
    BOOL ADClientIsAvailable = self.adClientClass &&
        [self.adClientClass instancesRespondToSelector:self.adClientRequestAttribution] &&
        [self.adClientClass methodForSelector:self.adClientSharedClient];

    if (ADClientIsAvailable) {
        return YES;
    }
    return NO;
}

- (void)requestAttributionWithCompletion:(void (^_Nullable)(NSDictionary *__nullable attributionDetails, NSError *__nullable error, NSTimeInterval elapsedSeconds))completion {
    
    // if AdClient is not available, this is a noop.
    if (![self isAdClientAvailable]) {
        if (completion) {
            completion(nil, [NSError branchErrorWithCode:BNCGeneralError localizedMessage:@"ADClient is not available. Requires iAD.framework and iOS 10+"], 0);
        }
        return;
    }
    
    id adClient = ((id (*)(id, SEL))[self.adClientClass methodForSelector:self.adClientSharedClient])(self.adClientClass, self.adClientSharedClient);
    
    __block NSDate *startDate = [NSDate date];
    void (^__nullable completionBlock)(NSDictionary *attrDetails, NSError *error) = ^ void(NSDictionary *__nullable attributionDetails, NSError *__nullable error) {
        NSTimeInterval elapsedSeconds = - [startDate timeIntervalSinceNow];
        if (completion) {
            completion(attributionDetails, error, elapsedSeconds);
        }
    };

    ((void (*)(id, SEL, void (^ __nullable)(NSDictionary *__nullable attrDetails, NSError * __nullable error)))
    [adClient methodForSelector:self.adClientRequestAttribution])
    (adClient, self.adClientRequestAttribution, completionBlock);
}

@end
