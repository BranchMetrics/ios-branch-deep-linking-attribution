//
//  BNCODMInfoCollector.m
//  BranchSDK
//
//  Created by Nidhi Dixit on 4/13/25.
//


#if !TARGET_OS_TV

#import "BNCODMInfoCollector.h"
#import "BNCPreferenceHelper.h"
#import "BranchLogger.h"
#import "NSError+Branch.h"

@interface BNCODMInfoCollector()

@property (nonatomic, strong, readwrite) BNCPreferenceHelper *preferenceHelper;
@property (nonatomic, copy) void (^odmFetchCompletion)(NSString *info, NSError *error);

@end

@implementation BNCODMInfoCollector

@synthesize odmInfo = _odmInfo;

+ (BNCODMInfoCollector *)instance {
    static BNCODMInfoCollector *collector = nil;
    static dispatch_once_t onceToken = 0;
    dispatch_once(&onceToken, ^{
        collector = [BNCODMInfoCollector new];
    });
    return collector;
}

- (instancetype)init {
    self = [super init];
    if (self) {
        self.preferenceHelper = [BNCPreferenceHelper sharedInstance];
    }
    return self;
}

- (void) setOdmInfo:(NSString *)odmInfo {
    _odmInfo = odmInfo;
}

- (NSString *) odmInfo {
    @synchronized (self) {
        // Load ODM info with a time-out of 500 ms. Its must for next call to v1/open.
        if (!_odmInfo) {
            [self loadODMInfoWithTimeOut:dispatch_time(DISPATCH_TIME_NOW, (int64_t)(500 * NSEC_PER_MSEC)) andCompletionHandler:nil]; // Timeout after 500 ms
        }
        
        if (_odmInfo) {
            // Check if odmInfo is within validity window
            NSDate *initTime = self.preferenceHelper.odmInfoInitDate;
            NSTimeInterval validityWindow = self.preferenceHelper.odmInfoValidityWindow;
            if ([self isWithinValidityWindow:initTime timeInterval:validityWindow]) {
                // fetch ODM info from pref helper
                _odmInfo = self.preferenceHelper.odmInfo;
            } else {
                _odmInfo = nil;
            }
        }
        return _odmInfo;
    }
}

- (void)loadODMInfo {
    [self loadODMInfoWithTimeOut: DISPATCH_TIME_FOREVER andCompletionHandler:nil];
}

- (void)loadODMInfoWithTimeOut:(dispatch_time_t) timeOut andCompletionHandler:(void (^_Nullable)(NSString * _Nullable odmInfo,  NSError * _Nullable error))completion {
    
    if (self.preferenceHelper.odmInfo) {
        self.odmInfo = self.preferenceHelper.odmInfo;
        if (completion) {
            completion(_odmInfo, nil);
        }
    } else {
        // Fetch ODM Info from device
        NSDate * odmInfofetchingTime = [NSDate date];
        dispatch_semaphore_t semaphore = dispatch_semaphore_create(0);
        
        [self fetchODMInfoFromDeviceWithInitDate:odmInfofetchingTime andCompletion:^(NSString *odmInfo, NSError *error) {
            if (odmInfo) {
                self.odmInfo = odmInfo;
                // Cache ODM info in pref helper
                self.preferenceHelper.odmInfo = odmInfo;
                self.preferenceHelper.odmInfoInitDate = odmInfofetchingTime;
            }
            if (completion) {
                completion(odmInfo, error);
            }
            dispatch_semaphore_signal(semaphore);
        }];
        dispatch_semaphore_wait(semaphore, timeOut);
    }
}

- (BOOL)isWithinValidityWindow:(NSDate *)initTime timeInterval:(NSTimeInterval)timeInterval  {
    NSDate *expirationDate = [initTime dateByAddingTimeInterval:timeInterval];
    if ([[NSDate date] compare:expirationDate] == NSOrderedAscending) {
        return YES;
    } else {
        return NO;
    }
}

- (void) fetchODMInfoFromDeviceWithInitDate:(NSDate *) date  andCompletion:(void (^)(NSString *odmInfo, NSError *error))completion {
    
    NSError *error = nil ;
    
    Class ODMConversionManagerClass = NSClassFromString(@"ODCConversionManager");
    SEL sharedInstanceSelector = NSSelectorFromString(@"sharedInstance");
    
    if (ODMConversionManagerClass && [ODMConversionManagerClass respondsToSelector:sharedInstanceSelector]) {
        
        id sharedInstance =  ((id (*)(id, SEL))[ODMConversionManagerClass methodForSelector:sharedInstanceSelector])
        (ODMConversionManagerClass, sharedInstanceSelector);

        // Set the time when the app was first launched by calling setFirstLaunchTime: dynamically
        SEL setFirstLaunchTimeSelector = NSSelectorFromString(@"setFirstLaunchTime:");
        
        if ([sharedInstance respondsToSelector:setFirstLaunchTimeSelector]) {
            
            void (*setFirstLaunchTimeMethod)(id, SEL, NSDate *) = (void (*)(id, SEL, NSDate *))
                    [sharedInstance methodForSelector:setFirstLaunchTimeSelector];
            setFirstLaunchTimeMethod(sharedInstance, setFirstLaunchTimeSelector, date);
            [[BranchLogger shared] logDebug:[NSString stringWithFormat:@"setFirstLaunchTimeSelector: invoked successfully."] error:nil];
            
            // Fetch the conversion info. Call fetchAggregateConversionInfoForInteraction:completion dynamically
            SEL fetchAggregateConversionInfoSelector = NSSelectorFromString(@"fetchAggregateConversionInfoForInteraction:completion:");
            if ([sharedInstance respondsToSelector:fetchAggregateConversionInfoSelector]) {
                NSMethodSignature *signature = [sharedInstance methodSignatureForSelector:fetchAggregateConversionInfoSelector];
                NSInvocation *invocation = [NSInvocation invocationWithMethodSignature:signature];
                [invocation setTarget:sharedInstance];
                [invocation setSelector:fetchAggregateConversionInfoSelector];

                // Since ODCInteractionType is an enum defined in AppAdsOnDeviceConversion.framework and its not accessible via reflection. And since enums in Objective-C are just symbolic constants that get replaced by their underlying integer values at compile time, so defining similar enum here -
                typedef NS_ENUM(NSInteger, ODCInteractionType) {
                  ODCInteractionTypeInstallation,
                } ;
                
                ODCInteractionType arg1 = ODCInteractionTypeInstallation;
                [invocation setArgument:&arg1 atIndex:2];
                
                __weak typeof(self) weakSelf = self;
                self.odmFetchCompletion = ^(NSString *info, NSError *error) {
                    
                    
                    if (error) {
                        [[BranchLogger shared] logDebug:[NSString stringWithFormat:@"ODMConversionManager:fetchInfo Error : %@", error.localizedDescription ] error:error];
                    }
                    
                    __strong typeof(self) self = weakSelf;
                    if (info) {
                        self->_odmInfo = info; // Save new value even if its new.
                    }
                    
                    if (completion) {
                        completion( self->_odmInfo, error);
                    }
                    [[BranchLogger shared] logVerbose:[NSString stringWithFormat:@"Received Info: %@", info] error:nil];
                };

                [invocation setArgument:&_odmFetchCompletion atIndex:3];
                [invocation invoke];
                [[BranchLogger shared] logDebug:[NSString stringWithFormat:@"fetchInfo:completion: invoked successfully."] error:nil];
        
                
            } else {
                NSString *message = [NSString stringWithFormat:@"Method fetchInfo:completion: not found."] ;
                error = [NSError branchErrorWithCode:BNCMethodNotFoundError localizedMessage:message];
                [[BranchLogger shared] logDebug:message error:error ];
                if (completion) {
                    completion( nil, error);
                }
            }
        } else {
            NSString *message = [NSString stringWithFormat:@"Method setFirstLaunchTimeSelector: not found."] ;
            error = [NSError branchErrorWithCode:BNCMethodNotFoundError localizedMessage:message];
            [[BranchLogger shared] logDebug:message error:error];
            if (completion) {
                completion( nil, error);
            }
        }
    } else {
        NSString *message = [NSString stringWithFormat:@"ODCConversionManager class or sharedInstance method not found."] ;
        error = [NSError branchErrorWithCode:BNCClassNotFoundError localizedMessage:message];
        [[BranchLogger shared] logDebug:message error:error];
        if (completion) {
            completion( nil, error);
        }
    }
}

@end
#endif
