//
//  BNCODMInfoCollector.m
//  BranchSDK
//
//  Created by Nidhi Dixit on 4/13/25.
//

#import <Foundation/Foundation.h>

#if !TARGET_OS_TV
#import "BNCODMInfoCollector.h"
#import "BNCPreferenceHelper.h"
#import "BranchLogger.h"
@interface BNCODMInfoCollector()
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
        
    }
    return self;
}
- (void)loadODMInfoWithCompletion:(void (^__strong)(NSString * _Nullable __strong))completion {
    
    NSString *savedODMInfo = [self fetchSavedODMInfo];
    if (savedODMInfo) {
        self.odmInfo = savedODMInfo;
        if (completion) {
            completion(savedODMInfo);
        }
    } else {
        [self fetchODMInfoFromDeviceWithInitDate:[NSDate date] andCompletion:  ^(NSString * _Nullable odmInfo) {
            self.odmInfo = odmInfo;
            [self saveODMInfo:odmInfo];
            if (completion) {
                completion(savedODMInfo);
            }
        }];
    }
    
}

- (NSString *) fetchSavedODMInfo {
    return nil;
}

- (void) saveODMInfo:(NSString *) odmInfo {
    
}


- (NSString *)fetchODMInfoFromDeviceWithInitDate:(NSDate *) date  andCompletion:(void (^)(NSString *odmInfo))completion {
    
    NSString *odmInfo = nil;
    
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
                        [[BranchLogger shared] logDebug:[NSString stringWithFormat:@""] error:nil];
                        NSLog(@"Error: %@", error.localizedDescription);
                        return;
                    }
                    [[BranchLogger shared] logDebug:[NSString stringWithFormat:@""] error:nil];
                    NSLog(@"Received Info: %@", info);
                };

                [invocation setArgument:&completionBlock atIndex:3];
                [invocation invoke];
                [[BranchLogger shared] logDebug:[NSString stringWithFormat:@""] error:nil];
                NSLog(@"fetchInfo:completion: invoked successfully.");
            } else {
                [[BranchLogger shared] logDebug:[NSString stringWithFormat:@""] error:nil];
                NSLog(@"Method fetchInfo:completion: not found.");
            }
        } else {
            [[BranchLogger shared] logDebug:[NSString stringWithFormat:@"Method setFirstLaunchTimeSelector: not found."] error:nil];
        }
    } else {
        [[BranchLogger shared] logDebug:[NSString stringWithFormat:@"ODCConversionManager class or sharedInstance method not found."] error:nil];
    }
    return  odmInfo;
}

@end
#endif
