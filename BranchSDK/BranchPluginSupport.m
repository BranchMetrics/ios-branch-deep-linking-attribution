//
//  BranchPluginSupport.m
//  BranchSDK
//
//  Created by Nipun Singh on 1/6/22.
//  Copyright © 2022 Branch, Inc. All rights reserved.
//

#import "BranchPluginSupport.h"
#import "NSMutableDictionary+Branch.h"
#import "BNCDeviceInfo.h"
#import "BNCPreferenceHelper.h"
#import "Branch.h"
#import "BranchJsonConfig.h"

// since most params are nullable, let's explicitly record the entry method
typedef NS_ENUM(NSUInteger, BNCEntryMethodType) {
    BNCEntryMethodTypeUnknown,
    BNCEntryMethodTypeInitSession,
    BNCEntryMethodTypeHandleDeepLink,
    BNCEntryMethodTypeContinueUserActivity
};

@interface BranchPluginSupport()

@property (nonatomic, assign, readwrite) BOOL deferInitForPlugin;

// cached entry params
@property (nonatomic, assign, readwrite) BNCEntryMethodType entry;
@property (nonatomic, strong, readwrite) NSDictionary *options;
@property (nonatomic, assign, readwrite) BOOL isReferrable;
@property (nonatomic, assign, readwrite) BOOL explicitlyRequestedReferrable;
@property (nonatomic, assign, readwrite) BOOL automaticallyDisplayController;
@property (nonatomic, copy, nullable) void (^callback)(BNCInitSessionResponse * _Nullable initResponse, NSError * _Nullable error);
@property (nonatomic, copy, readwrite) NSString *sceneIdentifier;
@property (nonatomic, strong, readwrite) NSURL *url;
@property (nonatomic, strong, readwrite) NSUserActivity *userActivity;

@end

@implementation BranchPluginSupport

+ (BranchPluginSupport *)instance {
    static BranchPluginSupport *pluginSupport;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        pluginSupport = [BranchPluginSupport new];
    });
    return pluginSupport;
}

- (instancetype)init {
    self = [super init];
    if (self) {
        // load initial value from branch.json
        self.deferInitForPlugin = [[BranchJsonConfig instance] deferInitForPlugin];
    }
    return self;
}

- (void)initSessionWithLaunchOptions:(nullable NSDictionary *)options registerDeepLinkHandler:(void (^)(NSDictionary * _Nullable params, NSError * _Nullable error))callback {
    [self initSessionWithLaunchOptions:options isReferrable:YES explicitlyRequestedReferrable:NO automaticallyDisplayController:NO registerDeepLinkHandler:callback];
}

- (void)initSessionWithLaunchOptions:(nullable NSDictionary *)options registerDeepLinkHandlerUsingBranchUniversalObject:(void (^)(BranchUniversalObject * _Nullable universalObject, BranchLinkProperties * _Nullable linkProperties, NSError * _Nullable error))callback {
    [self initSessionWithLaunchOptions:options isReferrable:YES explicitlyRequestedReferrable:NO automaticallyDisplayController:NO registerDeepLinkHandlerUsingBranchUniversalObject:callback];
}

// Maps BNCInitSessionResponse callback to dictionary callback
- (void)initSessionWithLaunchOptions:(NSDictionary *)options
                        isReferrable:(BOOL)isReferrable
       explicitlyRequestedReferrable:(BOOL)explicitlyRequestedReferrable
      automaticallyDisplayController:(BOOL)automaticallyDisplayController
registerDeepLinkHandlerUsingBranchUniversalObject:(callbackWithBranchUniversalObject)callback {
    [self initSceneSessionWithLaunchOptions:options
                               isReferrable:isReferrable
              explicitlyRequestedReferrable:explicitlyRequestedReferrable
             automaticallyDisplayController:automaticallyDisplayController
                    registerDeepLinkHandler:^(BNCInitSessionResponse * _Nullable initResponse, NSError * _Nullable error) {
        if (callback) {
            if (initResponse) {
                callback(initResponse.universalObject, initResponse.linkProperties, error);
            } else {
                callback([BranchUniversalObject new], [BranchLinkProperties new], error);
            }
        }
    }];
}

// Maps BNCInitSessionResponse callback to BUO callback
- (void)initSessionWithLaunchOptions:(NSDictionary *)options
                        isReferrable:(BOOL)isReferrable
       explicitlyRequestedReferrable:(BOOL)explicitlyRequestedReferrable
      automaticallyDisplayController:(BOOL)automaticallyDisplayController
             registerDeepLinkHandler:(callbackWithParams)callback {

    [self initSceneSessionWithLaunchOptions:options
                               isReferrable:isReferrable
              explicitlyRequestedReferrable:explicitlyRequestedReferrable
             automaticallyDisplayController:automaticallyDisplayController
                    registerDeepLinkHandler:^(BNCInitSessionResponse * _Nullable initResponse, NSError * _Nullable error) {
        if (callback) {
            if (initResponse) {
                callback(initResponse.params, error);
            } else {
                callback([NSDictionary new], error);
            }
        }
    }];
}

// initSession with optional caching. Requires the branch.json deferInitForPlugin option
- (void)initSceneSessionWithLaunchOptions:(NSDictionary *)options
                             isReferrable:(BOOL)isReferrable
            explicitlyRequestedReferrable:(BOOL)explicitlyRequestedReferrable
           automaticallyDisplayController:(BOOL)automaticallyDisplayController
                  registerDeepLinkHandler:(void (^)(BNCInitSessionResponse * _Nullable initResponse, NSError * _Nullable error))callback {
    BOOL didCache = NO;
    @synchronized (self) {
        if (self.deferInitForPlugin) {
            [self clearCachedParams];
            self.entry = BNCEntryMethodTypeInitSession;
            self.options = options;
            self.isReferrable = isReferrable;
            self.explicitlyRequestedReferrable = explicitlyRequestedReferrable;
            self.automaticallyDisplayController = automaticallyDisplayController;
            self.callback = callback;
        }
    }
    
    if (!didCache) {
        [[Branch getInstance] initSceneSessionWithLaunchOptions:options
                                                   isReferrable:isReferrable
                                  explicitlyRequestedReferrable:explicitlyRequestedReferrable
                                 automaticallyDisplayController:automaticallyDisplayController
                                        registerDeepLinkHandler:callback];
    }
}

- (BOOL)handleDeepLink:(nullable NSURL *)url {
    return [self handleDeepLink:url sceneIdentifier:nil];
}
 
- (BOOL)handleDeepLink:(nullable NSURL *)url sceneIdentifier:(nullable NSString *)sceneIdentifier {
    BOOL didCache = NO;
    @synchronized (self) {
        if (self.deferInitForPlugin) {
            [self clearCachedParams];
            self.entry = BNCEntryMethodTypeHandleDeepLink;
            self.url = url;
            self.sceneIdentifier = sceneIdentifier;
        }
    }
    
    if (didCache) {
        return NO;
    } else {
        return [[Branch getInstance] handleDeepLink:url sceneIdentifier:sceneIdentifier];
    }
}

- (BOOL)continueUserActivity:(nullable NSUserActivity *)userActivity {
    return [self continueUserActivity:userActivity sceneIdentifier:nil];
}

- (BOOL)continueUserActivity:(nullable NSUserActivity *)userActivity sceneIdentifier:(nullable  NSString *)sceneIdentifier {
    BOOL didCache = NO;
    @synchronized (self) {
        if (self.deferInitForPlugin) {
            [self clearCachedParams];
            self.entry = BNCEntryMethodTypeContinueUserActivity;
            self.userActivity = userActivity;
            self.sceneIdentifier = sceneIdentifier;
            didCache = YES;
        }
    }
    
    if (didCache) {
        return NO;
    } else {
        return [[Branch getInstance] continueUserActivity:userActivity sceneIdentifier:sceneIdentifier];
    }
}

- (void)clearCachedParams {
    @synchronized (self) {
        self.entry = BNCEntryMethodTypeUnknown;
        self.options = nil;
        self.isReferrable = NO;
        self.explicitlyRequestedReferrable = NO;
        self.automaticallyDisplayController = NO;
        self.callback = nil;
        self.sceneIdentifier = nil;
        self.url = nil;
        self.userActivity = nil;
    }
}

- (void)notifyNativeToInit {
    @synchronized (self) {
        // call cached entry method
        switch (self.entry) {
            case BNCEntryMethodTypeInitSession:
                [[Branch getInstance] initSceneSessionWithLaunchOptions:self.options
                                                           isReferrable:self.isReferrable
                                          explicitlyRequestedReferrable:self.explicitlyRequestedReferrable
                                         automaticallyDisplayController:self.automaticallyDisplayController
                                                registerDeepLinkHandler:self.callback];
                break;
                
            case BNCEntryMethodTypeHandleDeepLink:
                [[Branch getInstance] handleDeepLink:self.url sceneIdentifier:self.sceneIdentifier];
                break;
                
            case BNCEntryMethodTypeContinueUserActivity:
                [[Branch getInstance] continueUserActivity:self.userActivity sceneIdentifier:self.sceneIdentifier];
                break;
                
            case BNCEntryMethodTypeUnknown:
                break;
            default:
                break;
        }
        
        [self clearCachedParams];
        self.deferInitForPlugin = NO;
    }
}


- (NSDictionary<NSString *, NSString *> *)deviceDescription {
    NSMutableDictionary<NSString *, NSString *> *dictionary = [NSMutableDictionary new];
    BNCDeviceInfo *deviceInfo = [BNCDeviceInfo getInstance];
    @synchronized (deviceInfo) {
        [deviceInfo checkAdvertisingIdentifier];
        [dictionary bnc_safeSetObject:deviceInfo.osName forKey:@"os"];
        [dictionary bnc_safeSetObject:deviceInfo.osVersion forKey:@"os_version"];
        [dictionary bnc_safeSetObject:deviceInfo.environment forKey:@"environment"];
        [dictionary bnc_safeSetObject:deviceInfo.vendorId forKey:@"idfv"];
        [dictionary bnc_safeSetObject:deviceInfo.advertiserId forKey:@"idfa"];
        [dictionary bnc_safeSetObject:deviceInfo.optedInStatus forKey:@"opted_in_status"];
        [dictionary bnc_safeSetObject:[BNCPreferenceHelper sharedInstance].userIdentity forKey:@"developer_identity"];
        [dictionary bnc_safeSetObject:deviceInfo.country forKey:@"country"];
        [dictionary bnc_safeSetObject:deviceInfo.language forKey:@"language"];
        [dictionary bnc_safeSetObject:deviceInfo.localIPAddress forKey:@"local_ip"];
        [dictionary bnc_safeSetObject:deviceInfo.brandName forKey:@"brand"];
        [dictionary bnc_safeSetObject:deviceInfo.applicationVersion forKey:@"app_version"];
        [dictionary bnc_safeSetObject:deviceInfo.modelName forKey:@"model"];
        [dictionary bnc_safeSetObject:deviceInfo.screenScale.stringValue forKey:@"screen_dpi"];
        [dictionary bnc_safeSetObject:deviceInfo.screenHeight.stringValue forKey:@"screen_height"];
        [dictionary bnc_safeSetObject:deviceInfo.screenWidth.stringValue forKey:@"screen_width"];
    }
    
    return dictionary;
}

@end
