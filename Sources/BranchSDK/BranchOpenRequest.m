//
//  BranchOpenRequest.m
//  Branch-TestBed
//
//  Created by Graham Mueller on 5/26/15.
//  Copyright (c) 2015 Branch Metrics. All rights reserved.
//

#import "BranchOpenRequest.h"
#import "BranchConstants.h"
#import "BNCEncodingUtils.h"
#import "Branch.h"

// used to save one timestamp...
#import "BNCApplication.h"

// used to call SKAN based on response
#import "BNCSKAdNetwork.h"

// handle app clip data for installs. This shouldn't be here imho
#import "BNCAppGroupsData.h"

#import "BranchLogger.h"
#import "BNCRequestFactory.h"

#import "BNCServerAPI.h"
#import "BNCInAppBrowser.h"

@interface BranchOpenRequest ()
@property (assign, nonatomic) BOOL isInstall;
@end


@implementation BranchOpenRequest

- (id)initWithCallback:(callbackWithStatus)callback {
    return [self initWithCallback:callback isInstall:NO];
}

- (id)initWithCallback:(callbackWithStatus)callback isInstall:(BOOL)isInstall {
    if ((self = [super init])) {
        _callback = callback;
        _isInstall = isInstall;
        _isFromArchivedQueue = NO;
    }

    return self;
}

- (void)makeRequest:(BNCServerInterface *)serverInterface key:(NSString *)key callback:(BNCServerCallback)callback {
    BNCRequestFactory *factory = [[BNCRequestFactory alloc] initWithBranchKey:key UUID:self.requestUUID TimeStamp:self.requestCreationTimeStamp];
    NSDictionary *params = [factory dataForOpenWithURLString:self.urlString];

    [serverInterface postRequest:params
        url:[[BNCServerAPI sharedInstance] openServiceURL]
        key:key
        callback:callback];
}

- (void)processResponse:(BNCServerResponse *)response error:(NSError *)error {
    BNCPreferenceHelper *preferenceHelper = [BNCPreferenceHelper sharedInstance];
    if (error && preferenceHelper.dropURLOpen) {
        // Ignore this response from the server. Dummy up a response:
        error = nil;
        response.data = @{
            BRANCH_RESPONSE_KEY_SESSION_DATA: @{
                BRANCH_RESPONSE_KEY_CLICKED_BRANCH_LINK: @0
            }
        };
    } else
    if (error) {
        [BranchOpenRequest releaseOpenResponseLock];
        if (self.callback) {
            self.callback(NO, error);
        }
        return;
    }
    NSDictionary *data = response.data;
    
    // Handle possibly mis-parsed identity.
    id userIdentity = data[BRANCH_RESPONSE_KEY_DEVELOPER_IDENTITY];
    if ([userIdentity isKindOfClass:[NSNumber class]]) {
        userIdentity = [userIdentity stringValue];
    }
    
    if ([data objectForKey:BRANCH_RESPONSE_KEY_RANDOMIZED_DEVICE_TOKEN]) {
        preferenceHelper.randomizedDeviceToken = data[BRANCH_RESPONSE_KEY_RANDOMIZED_DEVICE_TOKEN];
        if (!preferenceHelper.randomizedDeviceToken) {
            // fallback to deprecated name. Fingerprinting was removed long ago, hence the name change.
            preferenceHelper.randomizedDeviceToken = data[@"device_fingerprint_id"];
        }
    }
   
    if (data[BRANCH_RESPONSE_KEY_USER_URL]) {
        preferenceHelper.userUrl = data[BRANCH_RESPONSE_KEY_USER_URL];
    }
    preferenceHelper.userIdentity = userIdentity;
    if ([data objectForKey:BRANCH_RESPONSE_KEY_SESSION_ID])
        preferenceHelper.sessionID = data[BRANCH_RESPONSE_KEY_SESSION_ID];
    preferenceHelper.previousAppBuildDate = [BNCApplication currentApplication].currentBuildDate;

    NSString *sessionData = data[BRANCH_RESPONSE_KEY_SESSION_DATA];
    if (sessionData == nil || [sessionData isKindOfClass:[NSString class]]) {
    } else
    if ([sessionData isKindOfClass:[NSDictionary class]]) {
        [[BranchLogger shared] logWarning:[NSString stringWithFormat:@"Received session data of type '%@' data is '%@'.", NSStringFromClass(sessionData.class), sessionData] error:nil];
        sessionData = [BNCEncodingUtils encodeDictionaryToJsonString:(NSDictionary*)sessionData];
    } else
    if ([sessionData isKindOfClass:[NSArray class]]) {
        [[BranchLogger shared] logWarning:[NSString stringWithFormat:@"Received session data of type '%@' data is '%@'.", NSStringFromClass(sessionData.class), sessionData] error:nil];
        sessionData = [BNCEncodingUtils encodeArrayToJsonString:(NSArray*)sessionData];
    } else {
        [[BranchLogger shared] logError:[NSString stringWithFormat:@"Received session data of type '%@' data is '%@'.", NSStringFromClass(sessionData.class), sessionData] error:error];
        sessionData = nil;
    }

    // Update session params

    if (preferenceHelper.spotlightIdentifier) {
        NSMutableDictionary *sessionDataDict =
        [NSMutableDictionary dictionaryWithDictionary: [BNCEncodingUtils decodeJsonStringToDictionary:sessionData]];
        NSDictionary *spotlightDic = @{BRANCH_RESPONSE_KEY_SPOTLIGHT_IDENTIFIER:preferenceHelper.spotlightIdentifier};
        [sessionDataDict addEntriesFromDictionary:spotlightDic];
        sessionData = [BNCEncodingUtils encodeDictionaryToJsonString:sessionDataDict];
    }
    
    preferenceHelper.sessionParams = sessionData;

    // Scenarios:
    // If no data, data isn't from a link click, or isReferrable is false, don't set, period.
    // Otherwise,
    // * On Install: set.
    // * On Open and installParams set: don't set.
    if (sessionData.length) {
        NSDictionary *sessionDataDict = [BNCEncodingUtils decodeJsonStringToDictionary:sessionData];
        BOOL dataIsFromALinkClick = [sessionDataDict[BRANCH_RESPONSE_KEY_CLICKED_BRANCH_LINK] isEqual:@1];

        if (dataIsFromALinkClick && self.isInstall) {
            preferenceHelper.installParams = sessionData;
        }
    }

    NSString *referringURL = nil;
    if (self.urlString.length > 0) {
        referringURL = self.urlString;
    } else {
        NSDictionary *sessionDataDict = [BNCEncodingUtils decodeJsonStringToDictionary:sessionData];
        NSString *link = sessionDataDict[BRANCH_RESPONSE_KEY_BRANCH_REFERRING_LINK];
        if ([link isKindOfClass:[NSString class]]) {
            if (link.length) {
                referringURL = link;
            }
        }
    }

    // Clear link identifiers so they don't get reused on the next open
    preferenceHelper.linkClickIdentifier = nil;
    preferenceHelper.spotlightIdentifier = nil;
    preferenceHelper.universalLinkUrl = nil;
    preferenceHelper.externalIntentURI = nil;
    preferenceHelper.referringURL = referringURL;
    preferenceHelper.initialReferrer = nil;
    preferenceHelper.dropURLOpen = NO;
    preferenceHelper.uxType = nil;
    preferenceHelper.urlLoadMs = nil;
    
    NSString *string = BNCStringFromWireFormat(data[BRANCH_RESPONSE_KEY_RANDOMIZED_BUNDLE_TOKEN]);
    if (!string) {
        // fallback to deprecated name. The old name was easily confused with the setIdentity, hence the name change.
        string = BNCStringFromWireFormat(data[@"identity_id"]);
    }
    
    if (string) {
        preferenceHelper.randomizedBundleToken = string;
    }
    
    [BranchOpenRequest releaseOpenResponseLock];
    
    if (self.isInstall) {
        [[BNCAppGroupsData shared] saveAppClipData];
    }
    
#if !TARGET_OS_TV
    if ([data[BRANCH_RESPONSE_KEY_INVOKE_REGISTER_APP] isKindOfClass:NSNumber.class]) {
        NSNumber *invokeRegister = (NSNumber *)data[BRANCH_RESPONSE_KEY_INVOKE_REGISTER_APP];
        preferenceHelper.invokeRegisterApp = invokeRegister.boolValue;
        if (invokeRegister.boolValue && self.isInstall) {
            if (@available(iOS 16.1, macCatalyst 16.1, *)){
                NSString *defaultCoarseConValue = [[BNCSKAdNetwork sharedInstance] getCoarseConversionValueFromDataResponse:@{}];
                [[BNCSKAdNetwork sharedInstance] updatePostbackConversionValue:0 coarseValue:defaultCoarseConValue
                    lockWindow:NO completionHandler:^(NSError * _Nullable error) {
                    if (error) {
                        [[BranchLogger shared] logError:[NSString stringWithFormat:@"Update conversion value failed with error - %@", [error description]] error:error];
                    } else {
                        [[BranchLogger shared] logDebug:[NSString stringWithFormat:@"Update conversion value was successful for INSTALL Event"] error:nil];
                    }
                }];
            } else if (@available(iOS 15.4, macCatalyst 15.4, *)){
                [[BNCSKAdNetwork sharedInstance] updatePostbackConversionValue:0 completionHandler:^(NSError * _Nullable error) {
                    if (error) {
                        [[BranchLogger shared] logError:[NSString stringWithFormat:@"Update conversion value failed with error - %@", [error description]] error:error];
                    } else {
                        [[BranchLogger shared] logDebug:[NSString stringWithFormat:@"Update conversion value was successful for INSTALL Event"] error:nil];
                    }
                }];
            }
            else {
                [[BNCSKAdNetwork sharedInstance] registerAppForAdNetworkAttribution];
            }
        }
    } else {
        preferenceHelper.invokeRegisterApp = NO;
    }
    
 
    if (data && [data[BRANCH_RESPONSE_KEY_UPDATE_CONVERSION_VALUE] isKindOfClass:NSNumber.class] && !self.isInstall) {
        NSNumber *conversionValue = (NSNumber *)data[BRANCH_RESPONSE_KEY_UPDATE_CONVERSION_VALUE];
        // Regardless of SKAN opted-in in dashboard, we always get conversionValue, so adding check to find out if install/open response had "invoke_register_app" true
        if (conversionValue && preferenceHelper.invokeRegisterApp ) {
            if (@available(iOS 16.1, macCatalyst 16.1, *)){
                NSString* coarseConversionValue = [[BNCSKAdNetwork sharedInstance] getCoarseConversionValueFromDataResponse:data] ;
                BOOL lockWin = [[BNCSKAdNetwork sharedInstance] getLockedStatusFromDataResponse:data];
                BOOL shouldCallUpdatePostback = [[BNCSKAdNetwork sharedInstance] shouldCallPostbackForDataResponse:data];
                
                [[BranchLogger shared] logDebug: [NSString stringWithFormat:@"SKAN 4.0 params - conversionValue:%@ coarseValue:%@, locked:%d, shouldCallPostback:%d, currentWindow:%d, firstAppLaunchTime: %@", conversionValue, coarseConversionValue, lockWin, shouldCallUpdatePostback, (int)preferenceHelper.skanCurrentWindow, preferenceHelper.firstAppLaunchTime] error:nil];
                
                if(shouldCallUpdatePostback){
                    [[BNCSKAdNetwork sharedInstance] updatePostbackConversionValue: conversionValue.longValue coarseValue:coarseConversionValue lockWindow:lockWin completionHandler:^(NSError * _Nullable error) {
                        if (error) {
                            [[BranchLogger shared] logError:[NSString stringWithFormat:@"Update conversion value failed with error - %@", [error description]] error:error];
                        } else {
                            [[BranchLogger shared] logDebug:[NSString stringWithFormat:@"Update conversion value was successful. Conversion Value - %@", conversionValue] error:nil];
                        }
                    }];
                }
            } else if (@available(iOS 15.4, macCatalyst 15.4, *)) {
                [[BNCSKAdNetwork sharedInstance] updatePostbackConversionValue:conversionValue.intValue completionHandler: ^(NSError *error){
                    if (error) {
                        [[BranchLogger shared] logError:[NSString stringWithFormat:@"Update conversion value failed with error - %@", [error description]] error:error];
                    } else {
                        [[BranchLogger shared] logDebug:[NSString stringWithFormat:@"Update conversion value was successful. Conversion Value - %@", conversionValue] error:nil];
                    }
                }];
            } else {
                [[BNCSKAdNetwork sharedInstance] updateConversionValue:conversionValue.integerValue];
            }
        }
    }
#endif

    NSDictionary *invokeFeatures = data[BRANCH_RESPONSE_KEY_INVOKE_FEATURES];
    if (invokeFeatures) {
        if ([self invokeFeatures:invokeFeatures]) {
            return; // Return - Dont call callback since weblink in launched
        }
    }

    if (self.callback) {
        self.callback(YES, nil);
    }
}

- (BOOL) invokeFeatures:(NSDictionary *)invokeFeatures {
    
    NSString *uxType = invokeFeatures[BRANCH_RESPONSE_KEY_ENHANCED_WEB_LINK_UX];
    
    if (uxType) {
        NSURL *webLinkRedirectUrl = [NSURL URLWithString:invokeFeatures[BRANCH_RESPONSE_KEY_WEB_LINK_REDIRECT_URL]];
        if (webLinkRedirectUrl) {
            if ([uxType isEqualToString:WEB_UX_IN_APP_WEBVIEW]) {
                id inAppBrowser = nil;
#if !TARGET_OS_TV
                inAppBrowser = [BNCInAppBrowser sharedInstance];
# endif
                if (inAppBrowser) {
#if !TARGET_OS_TV
                    dispatch_async(dispatch_get_main_queue(), ^{
                        [(BNCInAppBrowser *)inAppBrowser openURLInSafariVC:webLinkRedirectUrl];
                    });
                    [BNCPreferenceHelper sharedInstance].uxType = uxType;
                    [BNCPreferenceHelper sharedInstance].urlLoadMs = [NSDate date];
                    return TRUE;
# endif
                } else {
                    uxType = WEB_UX_EXTERNAL_BROWSER;
                }
            }
            if ([uxType isEqualToString:WEB_UX_EXTERNAL_BROWSER]) {
                BOOL isAppExtension = [[[NSBundle mainBundle] bundlePath] hasSuffix:@".appex"];
                if (!isAppExtension) {
                    dispatch_async(dispatch_get_main_queue(), ^{
                        [self openURLInDefaultBrowser:webLinkRedirectUrl];
                    });
                    [BNCPreferenceHelper sharedInstance].uxType = uxType;
                    [BNCPreferenceHelper sharedInstance].urlLoadMs = [NSDate date];
                    return TRUE;
                } else {
                    [[BranchLogger shared] logDebug:@"Will not load URL for app extensions" error:nil];
                }
            }
        } else {
            [[BranchLogger shared] logDebug:[NSString stringWithFormat:@"Invalid  URL: %@", webLinkRedirectUrl] error:nil];
        }
    }
    return FALSE;
}

- (void)openURLInDefaultBrowser:(NSURL *)url{
    
    if (!url) return;

    Class applicationClass = NSClassFromString(@"UIApplication");
    SEL sharedAppSel = NSSelectorFromString(@"sharedApplication");

    if ([applicationClass respondsToSelector:sharedAppSel]) {
        id sharedApp = ((id (*)(id, SEL))[applicationClass methodForSelector:sharedAppSel])
                (applicationClass, sharedAppSel);

        SEL openURLSel = NSSelectorFromString(@"openURL:options:completionHandler:");
        if ([sharedApp respondsToSelector:openURLSel]) {
            NSDictionary *options = @{};

            NSMethodSignature *signature = [sharedApp methodSignatureForSelector:openURLSel];
            NSInvocation *invocation = [NSInvocation invocationWithMethodSignature:signature];
            [invocation setSelector:openURLSel];
            [invocation setTarget:sharedApp];

            [invocation setArgument:&url atIndex:2];
            [invocation setArgument:&options atIndex:3];

            void (^nilHandler)(BOOL) = nil;
            [invocation setArgument:&nilHandler atIndex:4];

            [invocation invoke];
        }
    }
}

- (NSString *)getActionName {
    return @"open";
}

- (instancetype)initWithCoder:(NSCoder *)decoder {
    self = [super initWithCoder:decoder];
    if (!self) return self;
    self.urlString = [decoder decodeObjectOfClass:NSString.class forKey:@"urlString"];
    return self;
}

- (void)encodeWithCoder:(NSCoder *)coder {
    [super encodeWithCoder:coder];
    [coder encodeObject:self.urlString forKey:@"urlString"];
}

+ (BOOL)supportsSecureCoding {
    return YES;
}

#pragma - Open Response Lock Handling


//	Instead of semaphores, the lock is handled by scheduled dispatch_queues.
//	This is the 'new' way to lock and is handled better optimized for iOS.
//	Also, since implied lock is handled by a scheduler and not a hard semaphore it's less error
//	prone.


static dispatch_queue_t openRequestWaitQueue = NULL;
static BOOL openRequestWaitQueueIsSuspended = NO;


+ (void) initialize {
    if (self != [BranchOpenRequest self])
        return;
    openRequestWaitQueue =
        dispatch_queue_create("io.branch.sdk.openqueue", DISPATCH_QUEUE_CONCURRENT);
}

+ (void) setWaitNeededForOpenResponseLock {
    @synchronized (self) {
        if (!openRequestWaitQueueIsSuspended) {
            [[BranchLogger shared] logVerbose:@"Suspended for openRequestWaitQueue." error:nil];
            openRequestWaitQueueIsSuspended = YES;
            dispatch_suspend(openRequestWaitQueue);
        }
    }
}

+ (void) waitForOpenResponseLock {
    [[BranchLogger shared] logVerbose:@"Waiting for openRequestWaitQueue." error:nil];
    dispatch_sync(openRequestWaitQueue, ^ {
        [[BranchLogger shared] logVerbose:@"Finished waitForOpenResponseLock." error:nil];
    });
}

+ (void) releaseOpenResponseLock {
    @synchronized (self) {
        if (openRequestWaitQueueIsSuspended) {
            [[BranchLogger shared] logVerbose:@"Resuming openRequestWaitQueue." error:nil];
            openRequestWaitQueueIsSuspended = NO;
            dispatch_resume(openRequestWaitQueue);
        }
    }
}

@end
