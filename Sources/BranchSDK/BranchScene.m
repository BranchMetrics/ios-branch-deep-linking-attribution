//
//  BranchScene.m
//  Branch
//
//  Created by Ernest Cho on 3/24/20.
//  Copyright © 2020 Branch, Inc. All rights reserved.
//

#import "BranchScene.h"
#import "Branch.h"
#import "BranchLogger.h"

@implementation BranchScene

+ (BranchScene *)shared NS_EXTENSION_UNAVAILABLE("BranchScene does not support Extensions") {
    static BranchScene *bscene = nil;
    static dispatch_once_t onceToken = 0;
    dispatch_once(&onceToken, ^{
        bscene = [BranchScene new];
    });
    return bscene;
}

- (void)initSessionWithLaunchOptions:(nullable NSDictionary *)options registerDeepLinkHandler:(void (^ _Nonnull)(NSDictionary * _Nullable params, NSError * _Nullable error, UIScene * _Nullable scene))callback NS_EXTENSION_UNAVAILABLE("BranchScene does not support Extensions") {
    [[BranchLogger shared] logVerbose:@"BranchScene initSession" error:nil];

    [[Branch getInstance] initSceneSessionWithLaunchOptions:options isReferrable:YES explicitlyRequestedReferrable:NO automaticallyDisplayController:NO registerDeepLinkHandler:^(BNCInitSessionResponse * _Nullable initResponse, NSError * _Nullable error) {
        if (callback) {
            if (initResponse) {
                callback(initResponse.params, error, [self sceneForIdentifier:initResponse.sceneIdentifier]);
            } else {
                callback([NSDictionary new], error, [self sceneForIdentifier:initResponse.sceneIdentifier]);
            }
        }
    }];
}

- (void)initSessionWithSceneOptions:(nullable UISceneConnectionOptions *)connectionOptions scene:(UIScene *)scene
             registerDeepLinkHandler:(void (^ _Nonnull)(NSDictionary * _Nullable params, NSError * _Nullable error, UIScene * _Nullable scene))callback {
    
    NSMutableDictionary *launchOptions = [[NSMutableDictionary alloc] init];
    
    if (connectionOptions.userActivities.count ) {
        launchOptions[UIApplicationLaunchOptionsUserActivityDictionaryKey] = connectionOptions.userActivities.allObjects ;
    }
    
    if (connectionOptions.URLContexts.count ) {
        launchOptions[UIApplicationLaunchOptionsURLKey] = connectionOptions.URLContexts.allObjects ;
    }

    [[Branch getInstance] initSceneSessionWithLaunchOptions:launchOptions sceneIdentifier:scene.session.persistentIdentifier isReferrable:YES explicitlyRequestedReferrable:NO automaticallyDisplayController:NO registerDeepLinkHandler:^(BNCInitSessionResponse * _Nullable initResponse, NSError * _Nullable error) {
        if (callback) {
            if (initResponse) {
                callback(initResponse.params, error, [self sceneForIdentifier:initResponse.sceneIdentifier]);
            } else {
                callback([NSDictionary new], error, [self sceneForIdentifier:initResponse.sceneIdentifier]);
            }
        }
    }];
    
    if (connectionOptions.userActivities.count) {
        [self scene:scene continueUserActivity:connectionOptions.userActivities.allObjects.firstObject];
    } else if (connectionOptions.URLContexts.count) {
        [self scene:scene openURLContexts:connectionOptions.URLContexts];
    }
}

- (void)scene:(UIScene *)scene continueUserActivity:(NSUserActivity *)userActivity NS_EXTENSION_UNAVAILABLE("BranchScene does not support Extensions") {
    [[BranchLogger shared] logVerbose:@"BranchScene continueUserActivity" error:nil];

    NSString *identifier = scene.session.persistentIdentifier;
    [[Branch getInstance] continueUserActivity:userActivity sceneIdentifier:identifier];
}

- (void)scene:(UIScene *)scene openURLContexts:(NSSet<UIOpenURLContext *> *)URLContexts NS_EXTENSION_UNAVAILABLE("BranchScene does not support Extensions") {
    [[BranchLogger shared] logVerbose:@"BranchScene openURLContexts" error:nil];
    
    if (URLContexts.count != 1) {
        [[BranchLogger shared] logWarning:@"Branch only supports a single URLContext" error:nil];
    }
    
    UIOpenURLContext *context = [URLContexts allObjects].firstObject;
    if (context) {
        NSString *identifier = scene.session.persistentIdentifier;
        [[Branch getInstance] sceneIdentifier:identifier openURL:context.URL sourceApplication:context.options.sourceApplication annotation:context.options.annotation];
    }
}

- (nullable UIScene *)sceneForIdentifier:(NSString *)identifier NS_EXTENSION_UNAVAILABLE("BranchScene does not support Extensions") {
    UIScene *scene = nil;
    if (identifier) {
        NSArray<UIScene *> *scenes = [[[UIApplication sharedApplication] connectedScenes] allObjects];
        for (UIScene *scene in scenes) {
            if ([identifier isEqualToString:scene.session.persistentIdentifier]) {
                return scene;
            }
        }
    }
    return scene;
}

@end
