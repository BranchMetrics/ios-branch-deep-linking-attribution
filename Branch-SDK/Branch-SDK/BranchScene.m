//
//  BranchScene.m
//  Branch
//
//  Created by Ernest Cho on 3/24/20.
//  Copyright © 2020 Branch, Inc. All rights reserved.
//

#import "BranchScene.h"
#import "Branch.h"

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

- (void)initSessionWithLaunchOptions:(NSDictionary *)options registerDeepLinkHandler:(void (^ _Nonnull)(NSDictionary * _Nullable params, NSError * _Nullable error, UIScene * _Nullable scene, UISceneSession * _Nullable sceneSession))callback {
    [[Branch getInstance] initSessionWithLaunchOptions:options andRegisterDeepLinkHandler:^(NSDictionary * _Nullable params, NSError * _Nullable error) {
        
    }];
}

- (void)scene:(UIScene *)scene continueUserActivity:(NSUserActivity *)userActivity {
    NSString *identifier = [self saveScene:scene];
    
}

- (void)scene:(UIScene *)scene openURLContexts:(NSSet<UIOpenURLContext *> *)URLContexts {
    NSString *identifier = [self saveScene:scene];
    
}

- (NSString *)saveScene:(UIScene *)scene {
    NSString *identifier = scene.session.persistentIdentifier;
    if (identifier) {
        [self.scenes setObject:scene forKey:identifier];
    }
    return identifier;
}

- (void)removeSceneWithIdentifier:(NSString *)identifier {
    if (identifier) {
        [self.scenes removeObjectForKey:identifier];
    }
}

@end
