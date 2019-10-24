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
    NSDictionary *tmp = [appleSearchAdDetails objectForKey:@"Version3.1"];
    if (tmp && ([tmp isKindOfClass:NSDictionary.class] || [tmp isKindOfClass:NSMutableDictionary.class])) {
        NSNumber *hasAppleSearchAdAttribution = [tmp objectForKey:@"iad-attribution"];
        return [hasAppleSearchAdAttribution boolValue];
    }
    return NO;
}

- (BOOL)isDateWithinWindow:(NSDate *)installDate {
    // install date should NOT be after current date
    NSDate *now = [NSDate date];
    if ([installDate compare:now] == NSOrderedDescending) {
        return NO;
    }
    
    // install date + 30 should be after current date
    NSDate *installDatePlus30 = [installDate dateByAddingTimeInterval:(30.0*24.0*60.0*60.0)];
    if ([installDatePlus30 compare:now] == NSOrderedDescending) {
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

/*
Expected test payload from Apple.

Printing description of attributionDetails:
{
    "Version3.1" =     {
        "iad-adgroup-id" = 1234567890;
        "iad-adgroup-name" = AdGroupName;
        "iad-attribution" = true;
        "iad-campaign-id" = 1234567890;
        "iad-campaign-name" = CampaignName;
        "iad-click-date" = "2019-10-24T00:14:36Z";
        "iad-conversion-date" = "2019-10-24T00:14:36Z";
        "iad-conversion-type" = Download;
        "iad-country-or-region" = US;
        "iad-creativeset-id" = 1234567890;
        "iad-creativeset-name" = CreativeSetName;
        "iad-keyword" = Keyword;
        "iad-keyword-id" = KeywordID;
        "iad-keyword-matchtype" = Broad;
        "iad-lineitem-id" = 1234567890;
        "iad-lineitem-name" = LineName;
        "iad-org-id" = 1234567890;
        "iad-org-name" = OrgName;
        "iad-purchase-date" = "2019-10-24T00:14:36Z";
    };
}
*/
- (BOOL)isAppleTestData:(NSDictionary *)appleSearchAdDetails {
    BOOL isTestData = NO;
    
    NSDictionary *tmp = [appleSearchAdDetails objectForKey:@"Version3.1"];
    if ([@"1234567890" isEqualToString:[tmp objectForKey:@"iad-adgroup-id"]] &&
        [@"AdGroupName" isEqualToString:[tmp objectForKey:@"iad-adgroup-name"]] &&
        [@"1234567890" isEqualToString:[tmp objectForKey:@"iad-campaign-id"]] &&
        [@"CampaignName" isEqualToString:[tmp objectForKey:@"iad-campaign-name"]] &&
        [@"1234567890" isEqualToString:[tmp objectForKey:@"iad-org-id"]] &&
        [@"OrgName" isEqualToString:[tmp objectForKey:@"iad-org-name"]]) {
        isTestData = YES;
    }
    
    return isTestData;
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
