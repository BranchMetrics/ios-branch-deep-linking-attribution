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

- (void)loadODMInfoWithCompletionHandler:(void (^_Nullable)(NSString * _Nullable odmInfo,  NSError * _Nullable error))completion {
    
    NSString *odmInfoValidated = self.preferenceHelper.odmInfo;
    if (odmInfoValidated) {
        // Check if odmInfo is within validity window
        NSDate *initTime = self.preferenceHelper.odmInfoInitDate;
        NSTimeInterval validityWindow = self.preferenceHelper.odmInfoValidityWindow;
        if ([self isWithinValidityWindow:initTime timeInterval:validityWindow]) {
            // fetch ODM info from pref helper
            odmInfoValidated = self.preferenceHelper.odmInfo;
        } else {
            odmInfoValidated = nil;
        }
        if (completion) {
            completion(odmInfoValidated, nil);
        }
    } else {
        // Fetch ODM Info from device
        NSDate * odmInfofetchingTime = [NSDate date];
        
        [self fetchODMInfoFromDeviceWithInitDate:odmInfofetchingTime andCompletion:^(NSString *odmInfo, NSError *error) {
            if (odmInfo) {
                // Cache ODM info in pref helper
                self.preferenceHelper.odmInfo = odmInfo;
                self.preferenceHelper.odmInfoInitDate = odmInfofetchingTime;
            }
            if (completion) {
                completion(odmInfo, error);
            }
            
        }];
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
    @synchronized (self) {
        
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
                        
                        if (completion) {
                            completion( info, error);
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
            NSString *message = [NSString stringWithFormat:@"ODCConversionManager class or sharedInstance method not found. Ignore this error if not using ODM."] ;
            error = [NSError branchErrorWithCode:BNCClassNotFoundError localizedMessage:message];
            [[BranchLogger shared] logDebug:message error:error];
            if (completion) {
                completion( nil, error);
            }
        }
    }
}

@end
#endif
