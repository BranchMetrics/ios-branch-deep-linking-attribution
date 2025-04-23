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

@interface BNCODMInfoCollector(){
    void (^completionBlock)(NSString *, NSError *);
}

@property (nonatomic, strong, readwrite) BNCPreferenceHelper *preferenceHelper;

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

- (void)loadODMInfoWithCompletion:(void (^__strong)(NSString * _Nullable __strong,  NSError * _Nullable))completion {
    
    if (self.preferenceHelper.odmInfo) {
        // Check if odmInfo is within validity window
        NSDate *initTime = self.preferenceHelper.odmInfoInitDate;
        NSTimeInterval validityWindow = self.preferenceHelper.odmInfoValidityWindow;
        if ([self isWithinValidityWindow:initTime timeInterval:validityWindow]) {
            // fetch ODM info from pref helper
            self.odmInfo = self.preferenceHelper.odmInfo;
        }
        if (completion) {
            completion(self.odmInfo, nil);
        }
    } else {
        // Fetch ODM Info from device
        NSDate * odmInfofetchingTime = [NSDate date];
        
        [self fetchODMInfoFromDeviceWithInitDate:odmInfofetchingTime andCompletion:^(NSString *odmInfo, NSError *error) {
            if (odmInfo) {
                self.odmInfo = odmInfo;
                 // Cache ODM info in pref helper
                 self.preferenceHelper.odmInfo = odmInfo;
                 self.preferenceHelper.odmInfoInitDate = odmInfofetchingTime;
             }
            
            if (completion) {
                completion(self.odmInfo, error);
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

                void (^completionBlock)(NSString *, NSError *) = ^(NSString *info, NSError *error) {
                    
                    if (error) {
                        [[BranchLogger shared] logDebug:[NSString stringWithFormat:@"ODMConversionManager:fetchInfo Error : %@", error.localizedDescription ] error:nil];
                    }
                    
                    if (info) {
                        self->_odmInfo = info;
                    }
                    
                    if (completion) {
                        completion( self->_odmInfo, error);
                    }
                    NSLog(@"Received Info: %@", info);
                };

                [invocation setArgument:&completionBlock atIndex:3];
                [invocation invoke];
                [[BranchLogger shared] logDebug:[NSString stringWithFormat:@"fetchInfo:completion: invoked successfully."] error:nil];
        
                
            } else {
                NSString *message = [NSString stringWithFormat:@"Method fetchInfo:completion: not found."] ;
                error = [NSError branchErrorWithCode:BNCMethodNotFoundError ];
                [[BranchLogger shared] logDebug:message error:nil];
                if (completion) {
                    completion( nil, error);
                }
            }
        } else {
            NSString *message = [NSString stringWithFormat:@"Method setFirstLaunchTimeSelector: not found."] ;
            error = [NSError branchErrorWithCode:BNCMethodNotFoundError ];
            [[BranchLogger shared] logDebug:message error:nil];
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
