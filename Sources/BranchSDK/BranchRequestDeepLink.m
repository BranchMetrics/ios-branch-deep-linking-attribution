//
//  BranchRequestDeepLink.m
//  BranchSDK
//
//  Created by Brandon Boothe on 5/6/26.
//

#import "BranchRequestDeepLink.h"
#import "BranchConstants.h"
#import "BNCEncodingUtils.h"
#import "Branch.h"

#import "BranchLogger.h"
#import "BNCRequestFactory.h"

#import "BNCServerAPI.h"
#import "BNCInAppBrowser.h"

@implementation BranchRequestDeepLink

- (id)initWithCallback:(callbackWithStatus)callback {
    if ((self = [super init])) {
        _callback = callback;
        _isFromArchivedQueue = NO;
    }

    return self;
}

- (void)makeRequest:(BNCServerInterface *)serverInterface key:(NSString *)key callback:(BNCServerCallback)callback {
    BNCRequestFactory *factory = [[BNCRequestFactory alloc] initWithBranchKey:key UUID:self.requestUUID TimeStamp:self.requestCreationTimeStamp];
    NSDictionary *params = [factory dataForDeepLinkWithURLString:self.urlString];
    self.requestParams = [params copy];
    self.requestServiceURL = [[BNCServerAPI sharedInstance] deepLinkServiceURL];
    [[BranchLogger shared] logDebug:[NSString stringWithFormat:@"Post Request sent for BranchRequestDeepLink"] error:nil];
    [serverInterface postRequest:params
        url: self.requestServiceURL
        key:key
        callback:callback];
}

- (void)processResponse:(BNCServerResponse *)response error:(NSError *)error {
    
    if (self.traceCallback) {
        self.traceCallback(self.urlString, self.requestParams, response.data, error, self.requestServiceURL);
    }
    
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
        [BranchRequestDeepLink releaseDeepLinkResponseLock];
        if (self.callback) {
            self.callback(NO, error);
        }
        return;
    }
    NSDictionary *data = response.data;
    
    [BranchRequestDeepLink releaseDeepLinkResponseLock];
    
    NSDictionary *invokeFeatures = data[BRANCH_RESPONSE_KEY_INVOKE_FEATURES];
    if (invokeFeatures) {
        if ([self invokeFeatures:invokeFeatures]) {
            // Redirect is happening - send attribution but skip initialization callback
            [self attemptToSendOpen:preferenceHelper response:response skipCallback:YES];
            return; // Return - Dont call callback since weblink is launched
        }
    }

    if (self.callback) {
        self.callback(YES, nil);
    }

    // Normal flow - send attribution and allow initialization callback
    [self attemptToSendOpen:preferenceHelper response:response skipCallback:NO];
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
    return @"deepLink";
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

#pragma - Deep Link Data Response Lock Handling


//    Instead of semaphores, the lock is handled by scheduled dispatch_queues.
//    This is the 'new' way to lock and is handled better optimized for iOS.
//    Also, since implied lock is handled by a scheduler and not a hard semaphore it's less error
//    prone.


static dispatch_queue_t deepLinkRequestWaitQueue = NULL;
static BOOL deepLinkRequestWaitQueueIsSuspended = NO;


+ (void) initialize {
    if (self != [BranchRequestDeepLink self])
        return;
    deepLinkRequestWaitQueue =
        dispatch_queue_create("io.branch.sdk.openqueue", DISPATCH_QUEUE_CONCURRENT);
}

// Need to Update names for all of these to deepLinkRespone Lock
+ (void) setWaitNeededForDeepLinkResponseLock {
    @synchronized (self) {
        if (!deepLinkRequestWaitQueueIsSuspended) {
            [[BranchLogger shared] logVerbose:@"Suspended for deepLinkRequestWaitQueue." error:nil];
            deepLinkRequestWaitQueueIsSuspended = YES;
            dispatch_suspend(deepLinkRequestWaitQueue);
        }
    }
}

// Need to Update names for all of these to deepLinkRespone Lock
+ (void) waitForDeepLinkResponseLock {
    [[BranchLogger shared] logVerbose:@"Waiting for deepLinkRequestWaitQueue." error:nil];
    dispatch_sync(deepLinkRequestWaitQueue, ^ {
        [[BranchLogger shared] logVerbose:@"Finished waitForDeepLinkResponseLock." error:nil];
    });
}

// Need to Update names for all of these to deepLinkRespone Lock
+ (void) releaseDeepLinkResponseLock {
    @synchronized (self) {
        if (deepLinkRequestWaitQueueIsSuspended) {
            [[BranchLogger shared] logVerbose:@"Resuming deepLinkRequestWaitQueue." error:nil];
            deepLinkRequestWaitQueueIsSuspended = NO;
            dispatch_resume(deepLinkRequestWaitQueue);
        }
    }
}

- (void) attemptToSendOpen:(BNCPreferenceHelper *)preferenceHelper response:(BNCServerResponse *)response skipCallback:(BOOL)skipCallback {
    NSString *referringURL = nil;
    if (self.urlString.length > 0) {
        referringURL = self.urlString;
    } else {
        NSDictionary *sessionData = response.data[BRANCH_RESPONSE_KEY_SESSION_DATA];
        if ([sessionData isKindOfClass:[NSDictionary class]]) {
            NSString *link = sessionData[BRANCH_RESPONSE_KEY_BRANCH_REFERRING_LINK];
            if ([link isKindOfClass:[NSString class]] && link.length) {
                referringURL = link;
            }
        } else if ([sessionData isKindOfClass:[NSString class]]) {
            // Handle case where session data is a JSON string
            NSDictionary *sessionDataDict = [BNCEncodingUtils decodeJsonStringToDictionary:(NSString *)sessionData];
            NSString *link = sessionDataDict[BRANCH_RESPONSE_KEY_BRANCH_REFERRING_LINK];
            if ([link isKindOfClass:[NSString class]] && link.length) {
                referringURL = link;
            }
        }
    }

    if (referringURL != nil) {
        [[BranchLogger shared] logDebug:[NSString stringWithFormat:@"~referring_link found in response: %@, sending sendOpen network request." ,referringURL] error:nil];
        [[Branch getInstance] sendOpen:response.data skipCallback:skipCallback];
    } else {
        [[BranchLogger shared] logDebug:@"No ~referring_link on deeplink data. Not sending sendOpen network request." error:nil];
    }
}

@end
