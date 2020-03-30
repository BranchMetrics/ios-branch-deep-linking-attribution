//
//  BranchScene.m
//  Branch
//
//  Created by Ernest Cho on 3/24/20.
//  Copyright © 2020 Branch, Inc. All rights reserved.
//

#import "BranchScene.h"
#import "Branch.h"
#import "BNCLog.h"

@interface BranchScene()
@property (strong, nonatomic, readwrite) NSMutableDictionary<NSString *, UIScene *> *scenes;
@end

@implementation BranchScene

- (instancetype)init {
    self = [super init];
    if (self) {
        self.scenes = [NSMutableDictionary<NSString *, UIScene *> new];
    }
    return self;
}

- (void)initSessionWithLaunchOptions:(NSDictionary *)options registerDeepLinkHandler:(void (^ _Nonnull)(NSDictionary * _Nullable params, NSError * _Nullable error, UIScene * _Nullable scene))callback {
    [[Branch getInstance] initSceneSessionWithLaunchOptions:options isReferrable:YES explicitlyRequestedReferrable:NO automaticallyDisplayController:NO registerDeepLinkHandler:^(BNCInitSessionResponse * _Nullable initResponse, NSError * _Nullable error) {
        if (callback) {
            if (initResponse) {
                callback(initResponse.params, error, [self sceneForIdentifier:initResponse.sceneIdentifier]);
            } else {
                callback([NSDictionary new], error, nil);
            }
        }
    }];
}

- (void)scene:(UIScene *)scene continueUserActivity:(NSUserActivity *)userActivity {
    NSString *identifier = [self saveScene:scene];
    [[Branch getInstance] continueUserActivity:userActivity sceneIdentifier:identifier];
}

- (void)scene:(UIScene *)scene openURLContexts:(NSSet<UIOpenURLContext *> *)URLContexts {
    if (URLContexts.count != 1) {
        BNCLogWarning(@"Branch only supports a single URLContext");
    }
    
    UIOpenURLContext *context = [URLContexts allObjects].firstObject;
    if (context) {
        NSString *identifier = [self saveScene:scene];
        [[Branch getInstance] sceneIdentifier:identifier openURL:context.URL sourceApplication:context.options.sourceApplication annotation:context.options.annotation];
    }
}

- (NSString *)saveScene:(UIScene *)scene {
    NSString *identifier = scene.session.persistentIdentifier;
    if (identifier) {
        [self.scenes setObject:scene forKey:identifier];
    }
    return identifier;
}

- (nullable UIScene *)sceneForIdentifier:(NSString *)identifier {
    UIScene *scene = nil;
    if (identifier) {
        scene = [self.scenes objectForKey:identifier];
    }
    return scene;
}

- (void)removeSceneWithIdentifier:(NSString *)identifier {
    if (identifier) {
        [self.scenes removeObjectForKey:identifier];
    }
}

@end
