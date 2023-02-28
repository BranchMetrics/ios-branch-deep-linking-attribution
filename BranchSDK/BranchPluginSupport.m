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

@interface BranchPluginSupport()

@property (nonatomic, assign, readwrite) BOOL deferInitForPlugin;
@property (nonatomic, copy, nullable) void (^cachedBlock)(void);

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
        self.deferInitForPlugin = [BranchJsonConfig instance].deferInitForPlugin;
    }
    return self;
}

- (void)initSessionWithLaunchOptions:(nullable NSDictionary *)options registerDeepLinkHandler:(void (^)(NSDictionary * _Nullable params, NSError * _Nullable error))callback {
    [self deferBlock:^{
        [[Branch getInstance] initSessionWithLaunchOptions:options andRegisterDeepLinkHandler:callback];
    }];
}

- (void)initSessionWithLaunchOptions:(nullable NSDictionary *)options registerDeepLinkHandlerUsingBranchUniversalObject:(void (^)(BranchUniversalObject * _Nullable universalObject, BranchLinkProperties * _Nullable linkProperties, NSError * _Nullable error))callback {
    [self deferBlock:^{
        [[Branch getInstance] initSessionWithLaunchOptions:options andRegisterDeepLinkHandlerUsingBranchUniversalObject:callback];
    }];
}

- (BOOL)handleDeepLink:(nullable NSURL *)url {
    [self deferBlock:^{
        [[Branch getInstance] handleDeepLink:url sceneIdentifier:nil];
    }];
    return YES;
}

- (BOOL)continueUserActivity:(nullable NSUserActivity *)userActivity {
    [self deferBlock:^{
        [[Branch getInstance] continueUserActivity:userActivity sceneIdentifier:nil];
    }];
    return YES;
}

- (BOOL)deferBlock:(void (^)(void))block {
    BOOL deferred = NO;
    @synchronized (self) {
        if (self.deferInitForPlugin) {
            self.cachedBlock = block;
            deferred = YES;
        }
    }
    
    if (!deferred && block) {
        block();
    }
    return deferred;
}

- (void)notifyNativeToInit {
    @synchronized (self) {
        self.deferInitForPlugin = NO;
    }
    
    if (self.cachedBlock) {
        self.cachedBlock();
    }
    self.cachedBlock = nil;
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
