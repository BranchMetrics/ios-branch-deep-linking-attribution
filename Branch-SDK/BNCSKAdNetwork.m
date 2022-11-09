//
//  BNCSKAdNetwork.m
//  Branch
//
//  Created by Ernest Cho on 8/12/20.
//  Copyright © 2020 Branch, Inc. All rights reserved.
//

#import "BNCSKAdNetwork.h"
#import "BNCApplication.h"
#import "BNCPreferenceHelper.h"
#import "BranchConstants.h"

@interface BNCSKAdNetwork()

@property (nonatomic, strong, readwrite) NSDate *installDate;

@property (nonatomic, strong, readwrite) Class skAdNetworkClass;
@property (nonatomic, assign, readwrite) SEL skAdNetworkRegisterAppForAdNetworkAttribution;
@property (nonatomic, assign, readwrite) SEL skAdNetworkUpdateConversionValue;
@property (nonatomic, assign, readwrite) SEL skAdNetworkUpdatePostbackConversionValue;
@property (nonatomic, assign, readwrite) SEL skAdNetworkUpdatePostbackConversionValueCoarseValueLockWindow;

@end

@implementation BNCSKAdNetwork

+ (BNCSKAdNetwork *)sharedInstance {
    static BNCSKAdNetwork *singleton;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        singleton = [[BNCSKAdNetwork alloc] init];
    });
    return singleton;
}

- (instancetype)init {
    self = [super init];
    if (self) {
        if (@available(iOS 16.1, *)){
            // Can send postbacks upto 35 days
            self.maxTimeSinceInstall = 3600.0 * 24.0 * 35;
        } else {
            // by default, we send updates to SKAdNetwork for up a day after install
            self.maxTimeSinceInstall = 3600.0 * 24.0;
        }
        
        self.installDate = [BNCApplication currentApplication].currentInstallDate;
        
        self.skAdNetworkClass = NSClassFromString(@"SKAdNetwork");
        self.skAdNetworkRegisterAppForAdNetworkAttribution = NSSelectorFromString(@"registerAppForAdNetworkAttribution");
        self.skAdNetworkUpdateConversionValue = NSSelectorFromString(@"updateConversionValue:");
        self.skAdNetworkUpdatePostbackConversionValue = NSSelectorFromString(@"updatePostbackConversionValue:completionHandler:");
        self.skAdNetworkUpdatePostbackConversionValueCoarseValueLockWindow = NSSelectorFromString(@"updatePostbackConversionValue:coarseValue:lockWindow:completionHandler:");
    }
    return self;
}

- (BOOL)shouldAttemptSKAdNetworkCallout {
    if (self.installDate && self.skAdNetworkClass) {
        NSDate *now = [NSDate date];
        NSDate *maxDate = [self.installDate dateByAddingTimeInterval:self.maxTimeSinceInstall];
        if ([now compare:maxDate] == NSOrderedDescending) {
            return NO;
        } else {
            return YES;
        }
    }
    return NO;
}

- (void)registerAppForAdNetworkAttribution {
    if (@available(iOS 14.0, *)) {
        if ([self shouldAttemptSKAdNetworkCallout]) {

            // Equivalent call [SKAdNetwork registerAppForAdNetworkAttribution];
            ((id (*)(id, SEL))[self.skAdNetworkClass methodForSelector:self.skAdNetworkRegisterAppForAdNetworkAttribution])(self.skAdNetworkClass, self.skAdNetworkRegisterAppForAdNetworkAttribution);
        }
    }
}

- (void)updateConversionValue:(NSInteger)conversionValue {
    if (@available(iOS 14.0, *)) {
        if ([self shouldAttemptSKAdNetworkCallout]) {
            
            // Equivalent call [SKAdNetwork updateConversionValue:conversionValue];
            ((id (*)(id, SEL, NSInteger))[self.skAdNetworkClass methodForSelector:self.skAdNetworkUpdateConversionValue])(self.skAdNetworkClass, self.skAdNetworkUpdateConversionValue, conversionValue);
        }
    }
}

- (void)updatePostbackConversionValue:(NSInteger)conversionValue
                    completionHandler:(void (^)(NSError *error))completion {
    if (@available(iOS 15.4, *)) {
        if ([self shouldAttemptSKAdNetworkCallout]) {
            
            // Equivalent call [SKAdNetwork updatePostbackConversionValue:completionHandler:];
            ((id (*)(id, SEL, NSInteger,void (^)(NSError *error)))[self.skAdNetworkClass methodForSelector:self.skAdNetworkUpdatePostbackConversionValue])(self.skAdNetworkClass, self.skAdNetworkUpdatePostbackConversionValue, conversionValue, completion);
        }
    }
    
}

- (void)updatePostbackConversionValue:(NSInteger)fineValue
                          coarseValue:(NSString *)coarseValue
                           lockWindow:(BOOL)lockWindow
                    completionHandler:(void (^)(NSError *error))completion {
    if (@available(iOS 16.1, *)) {
        if ([self shouldAttemptSKAdNetworkCallout]) {
            
            ((id (*)(id, SEL, NSInteger, NSString *, BOOL, void (^)(NSError *error)))[self.skAdNetworkClass methodForSelector:self.skAdNetworkUpdatePostbackConversionValueCoarseValueLockWindow])(self.skAdNetworkClass, self.skAdNetworkUpdatePostbackConversionValueCoarseValueLockWindow, fineValue, coarseValue, lockWindow, completion);
        }
    }
}

- (int) calculateSKANWindowForTime:(NSDate *) currentTime{
    
    int firstWindowDuration = 2 * 24 * 3600;
    int secondWindowDuration = 7 * 24 * 3600;
    int thirdWindowDuration = 35 * 24 * 3600;
    
    NSTimeInterval timeDiff = [currentTime timeIntervalSinceDate:self.installDate];
    
    if (timeDiff <= firstWindowDuration) {
        return 1;
    } else if (timeDiff <= secondWindowDuration) {
        return 2;
    }else if (timeDiff <= thirdWindowDuration) {
        return 3;
    }
    return 0;
}

- (SKAdNetworkCoarseConversionValue) getCoarseConversionValueFromDataResponse:(NSDictionary *) dataResponseDictionary{
    
    NSString *coarseConversionValue = dataResponseDictionary[BRANCH_RESPONSE_KEY_COARSE_KEY] ;
    
    if ([coarseConversionValue isEqualToString:@"high"]) {
        return SKAdNetworkCoarseConversionValueHigh;
    } else if ([coarseConversionValue isEqualToString:@"medium"]) {
        return SKAdNetworkCoarseConversionValueMedium;
    } else {
        return SKAdNetworkCoarseConversionValueLow;
    }
}

- (BOOL) getLockedStatusFromDataResponse:(NSDictionary *) dataResponseDictionary {
    
    BOOL lockWin = NO;
    if([dataResponseDictionary[BRANCH_RESPONSE_KEY_UPDATE_IS_LOCKED] isKindOfClass:NSNumber.class])
        lockWin = ((NSNumber *)dataResponseDictionary[BRANCH_RESPONSE_KEY_UPDATE_IS_LOCKED]).boolValue;
    return lockWin;
}

- (BOOL) getEnforceHighestConversionValueFromDataResponse:(NSDictionary *) dataResponseDictionary {

    BOOL ascendingOnly = YES;
    if(  [dataResponseDictionary[BRANCH_RESPONSE_KEY_ENFORCE_HIGHEST_CONVERSION_VALUE] isKindOfClass:NSNumber.class])
        ascendingOnly = ((NSNumber *)dataResponseDictionary[BRANCH_RESPONSE_KEY_ENFORCE_HIGHEST_CONVERSION_VALUE]).boolValue;
    return ascendingOnly;
}

- (BOOL) shouldCallPostbackForDataResponse:(NSDictionary *) dataResponseDictionary {
    
    BOOL shouldCallUpdatePostback = YES;
    NSNumber *conversionValue = (NSNumber *)dataResponseDictionary[BRANCH_RESPONSE_KEY_UPDATE_CONVERSION_VALUE];

    int currentWindow = [self calculateSKANWindowForTime:[NSDate date]];
    if ( [BNCPreferenceHelper sharedInstance].skanCurrentWindow < currentWindow) {
        [BNCPreferenceHelper sharedInstance].highestConversionValueSent = 0;
        [BNCPreferenceHelper sharedInstance].skanCurrentWindow = currentWindow;
    }
    
    int highestConversionValue = (int)[BNCPreferenceHelper sharedInstance].highestConversionValueSent;
    if( conversionValue.intValue <= highestConversionValue ){
        BOOL ascendingOnly = [self getEnforceHighestConversionValueFromDataResponse:dataResponseDictionary];
        if (ascendingOnly)
            shouldCallUpdatePostback = NO;
    } else {
        [BNCPreferenceHelper sharedInstance].highestConversionValueSent = conversionValue.intValue;
    }
    
    return shouldCallUpdatePostback;
}

@end
