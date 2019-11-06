//
//  BNCAppleSearchAds.m
//  Branch
//
//  Created by Ernest Cho on 10/22/19.
//  Copyright © 2019 Branch, Inc. All rights reserved.
//

#import "BNCAppleSearchAds.h"
#import "NSError+Branch.h"
#import <UIKit/UIKit.h>

@interface BNCAppleSearchAds()

@property (nonatomic, strong, readwrite) Class adClientClass;
@property (nonatomic, assign, readwrite) SEL adClientSharedClient;
@property (nonatomic, assign, readwrite) SEL adClientRequestAttribution;

// Maximum number of tries
@property (nonatomic, assign, readwrite) NSInteger maxAttempts;

// Apple recommends waiting a bit before checking search ads and waiting between retries.
@property (nonatomic, assign, readwrite) NSTimeInterval delay;

// Apple recommends implementing our own timeout per request to Apple Search Ads
@property (nonatomic, assign, readwrite) NSTimeInterval timeOut;

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
        self.enableAppleSearchAdsCheck = NO;
        self.adClientClass = NSClassFromString(@"ADClient");
        self.adClientSharedClient = NSSelectorFromString(@"sharedClient");
        self.adClientRequestAttribution = NSSelectorFromString(@"requestAttributionDetailsWithBlock:");
        
        self.ignoreAppleTestData = NO;
        [self useBranchRecommendedDelay];
    }
    return self;
}

// Based on discussions with Apple, our default values are p95
- (void)useBranchRecommendedDelay {
    self.delay = 0.5;
    self.maxAttempts = 1;
    self.timeOut = 3.0;
}

// Apple suggests a longer delay, however this is detrimental to app launch times
- (void)useAppleRecommendedDelay {
    self.delay = 2.0;
    self.maxAttempts = 2;
    self.timeOut = 5.0;
}

// business logic around checking and storing Apple Search Ads attribution
- (void)checkAppleSearchAdsSaveTo:(BNCPreferenceHelper *)preferenceHelper installDate:(NSDate *)installDate completion:(void (^_Nullable)(void))completion {
    
    // several conditions where we do not check apple search ads
    if (!self.enableAppleSearchAdsCheck ||
        [self isAppleSearchAdSavedToDictionary:preferenceHelper.appleSearchAdDetails] ||
        ![self isDateWithinWindow:installDate]) {
        
        if (completion) {
            completion();
        }
        return;
    }
    
    // recursive retry using blocks.  maybe I should have tried to rework this into a loop.
    __block NSInteger attempts = 1;
    
    // define the retry block
    __block void (^retryBlock)(NSDictionary *attrDetails, NSError *error, NSTimeInterval elapsedSeconds);
    
    // define a weak version of the retry block
    __unsafe_unretained __block void (^weakRetryBlock)(NSDictionary *attrDetails, NSError *error, NSTimeInterval elapsedSeconds);
    
    // retry block will retry the call to Apple Search Ads using the weak retry block on retryable error
    retryBlock = ^ void(NSDictionary * _Nullable attributionDetails, NSError * _Nullable error, NSTimeInterval elapsedSeconds) {
        if ([self isSearchAdsErrorRetryable:error] && attempts < self.maxAttempts) {
            attempts++;
            [self requestAttributionWithCompletion:weakRetryBlock];
            
        } else {
            
            if (self.ignoreAppleTestData && [self isAppleTestData:attributionDetails]) {
                [self saveToPreferences:preferenceHelper attributionDetails:@{} error:error elapsedSeconds:elapsedSeconds];

            } else {
            
                // save search ads data for future use and callback
                [self saveToPreferences:preferenceHelper attributionDetails:attributionDetails error:error elapsedSeconds:elapsedSeconds];
            }
            
            if (completion) {
                completion();
            }
        }
    };
    
    // set the weak retryblock as the retryblock
    weakRetryBlock = retryBlock;
    
    [self requestAttributionWithCompletion:retryBlock];
}

/*
 Apple recommends retrying the following error codes

 ADClientErrorUnknown = 0
 ADClientErrorMissingData = 2
 ADClientErrorCorruptResponse = 3
 */
- (BOOL)isSearchAdsErrorRetryable:(nullable NSError *)error {
    if (error && (error.code == 0 || error.code == 2 || error.code == 3)) {
        return YES;
    }
    return NO;
}

// Eventually BNCPreferenceHelper should be responsible for correctly storing data
- (void)saveToPreferences:(BNCPreferenceHelper *)preferenceHelper attributionDetails:(nullable NSDictionary *)attributionDetails error:(nullable NSError *)error elapsedSeconds:(NSTimeInterval)elapsedSeconds {
    @synchronized (preferenceHelper) {
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
}

- (BOOL)isAppleSearchAdSavedToDictionary:(NSDictionary *)appleSearchAdDetails {
    NSDictionary *tmp = [appleSearchAdDetails objectForKey:@"Version3.1"];
    if (tmp && ([tmp isKindOfClass:NSDictionary.class])) {
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
    
    // install date + 30 days should be after current date
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
    NSDictionary *tmp = [appleSearchAdDetails objectForKey:@"Version3.1"];
    if ([@"1234567890" isEqualToString:[tmp objectForKey:@"iad-adgroup-id"]] &&
        [@"AdGroupName" isEqualToString:[tmp objectForKey:@"iad-adgroup-name"]] &&
        [@"1234567890" isEqualToString:[tmp objectForKey:@"iad-campaign-id"]] &&
        [@"CampaignName" isEqualToString:[tmp objectForKey:@"iad-campaign-name"]] &&
        [@"1234567890" isEqualToString:[tmp objectForKey:@"iad-org-id"]] &&
        [@"OrgName" isEqualToString:[tmp objectForKey:@"iad-org-name"]]) {
        return YES;
    }
    return NO;
}

// This method blocks the thread, it should only be called on a background thread.
- (void)requestAttributionWithCompletion:(void (^_Nullable)(NSDictionary *__nullable attributionDetails, NSError *__nullable error, NSTimeInterval elapsedSeconds))completion {
    
    // Apple recommends waiting for a short delay between requests for Search Ads, even the very first request to Apple Search Ads
    [NSThread sleepForTimeInterval:self.delay];
    
    // track timeout
    __block BOOL searchAdsResponded = NO;
    __block BOOL timedOut = NO;
    __block NSObject *timedOutLock = [NSObject new];
    
    // track apple search ads API performance
    __block NSDate *startDate = [NSDate date];
    
    // get ADClint using reflection
    id adClient = ((id (*)(id, SEL))[self.adClientClass methodForSelector:self.adClientSharedClient])(self.adClientClass, self.adClientSharedClient);
    
    // block to handle ADClient response
    void (^__nullable completionBlock)(NSDictionary *attrDetails, NSError *error) = ^ void(NSDictionary *__nullable attributionDetails, NSError *__nullable error) {

        // skip callback if request already timed out
        @synchronized (timedOutLock) {
            if (timedOut) {
                return;
            } else {
                searchAdsResponded = YES;
            }
        }
        
        // callback with Apple Search Ads data
        NSTimeInterval elapsedSeconds = -[startDate timeIntervalSinceNow];
        if (completion) {
            completion(attributionDetails, error, elapsedSeconds);
        }
    };

    // call Apple Search Ads via reflection
    ((void (*)(id, SEL, void (^ __nullable)(NSDictionary *__nullable attrDetails, NSError * __nullable error)))
    [adClient methodForSelector:self.adClientRequestAttribution])
    (adClient, self.adClientRequestAttribution, completionBlock);
    
    // timer for timeout, this is racing the call to Apple Search Ads
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(self.timeOut * NSEC_PER_SEC)), dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        @synchronized (timedOutLock) {
            if (searchAdsResponded) {
                return;
            } else {
                timedOut = YES;
            }
        }
        
        NSTimeInterval elapsedSeconds = -[startDate timeIntervalSinceNow];
        if (completion) {
            completion(nil, [NSError branchErrorWithCode:BNCGeneralError localizedMessage:@"AdClient timed out"], elapsedSeconds);
        }
    });
}

@end
