//
//  TestBedSpotlightSceneTestHook.m
//  Branch-TestBed
//

#import "TestBedSpotlightSceneTestHook.h"
@import BranchSDK;
@import CoreSpotlight;

#if DEBUG
// UISceneConnectionOptions has no public initializer (+new and -init are both NS_UNAVAILABLE in
// UISceneOptions.h). +alloc is not, so an instance can still be made by never sending it -init.
// Both accessors the SDK reads are overridden below, so nothing ever reads the superclass's
// (never-run-init) internal state.
@interface TestBedFakeSceneConnectionOptions : UISceneConnectionOptions
@property (nonatomic, strong, nullable) NSSet<NSUserActivity *> *stubbedUserActivities;
@end

@implementation TestBedFakeSceneConnectionOptions
- (NSSet<NSUserActivity *> *)userActivities {
    return self.stubbedUserActivities ?: [NSSet set];
}
- (NSSet<UIOpenURLContext *> *)URLContexts {
    return [NSSet set];
}
@end
#endif

@implementation TestBedSpotlightSceneTestHook

+ (void)installIfRequested:(UIApplication *)application {
#if DEBUG
    [self installWarmIfRequestedForApplication:application];
    [self installColdIfRequestedForApplication:application];
#endif
}

#if DEBUG

+ (NSUserActivity *)spotlightActivityWithIdentifier:(NSString *)identifierURL {
    NSUserActivity *activity = [[NSUserActivity alloc] initWithActivityType:CSSearchableItemActionType];
    activity.userInfo = @{ CSSearchableItemActivityIdentifier: identifierURL };
    return activity;
}

+ (nullable UIWindowScene *)connectedWindowScene {
    for (UIScene *scene in [UIApplication sharedApplication].connectedScenes) {
        if ([scene isKindOfClass:[UIWindowScene class]]) {
            return (UIWindowScene *)scene;
        }
    }
    return nil;
}

// Delivers `deliver` once `BranchDidStartSessionNotification` fires, or after a ten-second
// fallback if it never does -- matching TestBedDeepLinkTestHook's own delivery gate, so a
// synthetic activity always lands after the launch-time automatic open, never racing it.
+ (void)deliverAfterSessionStart:(dispatch_block_t)deliver {
    __block BOOL delivered = NO;
    __block id observer = nil;
    dispatch_block_t wrapped = ^{
        if (delivered) return;
        delivered = YES;
        if (observer) {
            [[NSNotificationCenter defaultCenter] removeObserver:observer];
            observer = nil;
        }
        deliver();
    };
    observer = [[NSNotificationCenter defaultCenter]
        addObserverForName:BranchDidStartSessionNotification
                    object:nil
                     queue:[NSOperationQueue mainQueue]
                usingBlock:^(NSNotification *note) {
                    wrapped();
                }];
    dispatch_after(
        dispatch_time(DISPATCH_TIME_NOW, (int64_t)(10.0 * NSEC_PER_SEC)),
        dispatch_get_main_queue(),
        ^{
            wrapped();
        });
}

+ (void)installWarmIfRequestedForApplication:(UIApplication *)application {
    NSString *urlString = [[NSUserDefaults standardUserDefaults] stringForKey:@"testSpotlightWarmURL"];
    if (urlString.length == 0) {
        return;
    }

    NSLog(@"[TestHook] -testSpotlightWarmURL received: %@", urlString);
    NSUserActivity *activity = [self spotlightActivityWithIdentifier:urlString];

    [self deliverAfterSessionStart:^{
        UIWindowScene *scene = [self connectedWindowScene];
        id<UISceneDelegate> sceneDelegate = (id<UISceneDelegate>)scene.delegate;
        if (scene == nil || ![sceneDelegate respondsToSelector:@selector(scene:continueUserActivity:)]) {
            NSLog(@"[TestHook] No connected scene delegate implementing scene:continueUserActivity:");
            return;
        }
        NSLog(@"[TestHook] Delivering synthetic scene:continueUserActivity: (warm): %@", urlString);
        [sceneDelegate scene:scene continueUserActivity:activity];
    }];
}

+ (void)installColdIfRequestedForApplication:(UIApplication *)application {
    NSString *urlString = [[NSUserDefaults standardUserDefaults] stringForKey:@"testSpotlightColdURL"];
    if (urlString.length == 0) {
        return;
    }

    NSLog(@"[TestHook] -testSpotlightColdURL received: %@", urlString);
    NSUserActivity *activity = [self spotlightActivityWithIdentifier:urlString];

    [self deliverAfterSessionStart:^{
        UIWindowScene *scene = [self connectedWindowScene];
        if (scene == nil) {
            NSLog(@"[TestHook] No connected scene to deliver the synthetic connection options to");
            return;
        }

        TestBedFakeSceneConnectionOptions *fakeOptions = [TestBedFakeSceneConnectionOptions alloc];
        fakeOptions.stubbedUserActivities = [NSSet setWithObject:activity];

        NSLog(@"[TestHook] Delivering synthetic requestDeepLinkDataWithSceneOptions:scene:callback: (cold): %@", urlString);
        [[Branch sharedInstance] requestDeepLinkDataWithSceneOptions:fakeOptions
                                                                scene:scene
                                                             callback:^(NSDictionary *params, NSError *error) {
            NSLog(@"[TestHook] Cold Spotlight callback params: %@ error: %@", params, error);
        }];
    }];
}

#endif

@end
