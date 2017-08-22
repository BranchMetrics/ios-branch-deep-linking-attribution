//
//  BNCContentDiscoveryManager.m
//  Branch-TestBed
//
//  Created by Graham Mueller on 7/17/15.
//  Copyright © 2015 Branch Metrics. All rights reserved.
//

#import "BNCPreferenceHelper.h"
#import "BNCContentDiscoveryManager.h"
#import "BNCSystemObserver.h"
#import "BNCError.h"
#import "BranchConstants.h"
#import "BNCSpotlightService.h"
#import "BNCPreferenceHelper.h"

#if defined(__IPHONE_OS_VERSION_MAX_ALLOWED) && __IPHONE_OS_VERSION_MAX_ALLOWED >= 90000
#import <MobileCoreServices/MobileCoreServices.h>
#endif

#ifndef CSSearchableItemActionType
#define CSSearchableItemActionType @"com.apple.corespotlightitem"
#endif

#ifndef CSSearchableItemActivityIdentifier
#define CSSearchableItemActivityIdentifier @"kCSSearchableItemActivityIdentifier"
#endif
static NSString* const kUTTypeGeneric = @"public.content";

@interface BNCContentDiscoveryManager (){
    dispatch_queue_t    _workQueue;
}

@property (strong, readonly) dispatch_queue_t workQueue;
@property (strong, atomic) BNCSpotlightService* spotlight;

@end

@implementation BNCContentDiscoveryManager


- (id) init {
    self = [super init];
    
    if (self) {
        self.spotlight = [[BNCSpotlightService alloc] init];
    }
    return self;
}

#pragma mark - Launch handling

- (NSString *)spotlightIdentifierFromActivity:(NSUserActivity *)userActivity {
#if defined(__IPHONE_OS_VERSION_MAX_ALLOWED) && __IPHONE_OS_VERSION_MAX_ALLOWED >= 90000
    // If it has our prefix, then the link identifier is just the last piece of the identifier.
    NSString *activityIdentifier = userActivity.userInfo[CSSearchableItemActivityIdentifier];
    BOOL isBranchIdentifier = [activityIdentifier hasPrefix:BRANCH_SPOTLIGHT_PREFIX];
    if (isBranchIdentifier) {
        return activityIdentifier;
    }
#endif
    
    return nil;
}

- (NSString *)standardSpotlightIdentifierFromActivity:(NSUserActivity *)userActivity {
#if defined(__IPHONE_OS_VERSION_MAX_ALLOWED) && __IPHONE_OS_VERSION_MAX_ALLOWED >= 90000
    if (userActivity.userInfo[CSSearchableItemActivityIdentifier]) {
        return userActivity.userInfo[CSSearchableItemActivityIdentifier];
    }
#endif
    
    return nil;
}

#pragma mark - Content Indexing

- (void)indexContentWithTitle:(NSString *)title
                  description:(NSString *)description {
    [self indexContentWithTitle:title
                    description:description
              publiclyIndexable:NO
                           type:(NSString *)kUTTypeGeneric
                   thumbnailUrl:nil
                       keywords:nil
                       userInfo:nil
                 expirationDate:nil
                       callback:NULL];
}

- (void)indexContentWithTitle:(NSString *)title
                  description:(NSString *)description
                     callback:(callbackWithUrl)callback {
    [self indexContentWithTitle:title
                    description:description
              publiclyIndexable:NO
                           type:(NSString *)kUTTypeGeneric
                   thumbnailUrl:nil
                       keywords:nil
                       userInfo:nil
                 expirationDate:nil
                       callback:callback];
}

- (void)indexContentWithTitle:(NSString *)title
                  description:(NSString *)description
            publiclyIndexable:(BOOL)publiclyIndexable
                     callback:(callbackWithUrl)callback {
    [self indexContentWithTitle:title
                    description:description
              publiclyIndexable:publiclyIndexable
                           type:(NSString *)kUTTypeGeneric
                   thumbnailUrl:nil
                       keywords:nil userInfo:nil
                 expirationDate:nil
                       callback:callback];
}

- (void)indexContentWithTitle:(NSString *)title
                  description:(NSString *)description
            publiclyIndexable:(BOOL)publiclyIndexable
                         type:(NSString *)type
                     callback:(callbackWithUrl)callback {
    [self indexContentWithTitle:title
                    description:description
              publiclyIndexable:publiclyIndexable
                           type:type
                   thumbnailUrl:nil
                       keywords:nil
                       userInfo:nil
                 expirationDate:nil
                       callback: callback];
}

- (void)indexContentWithTitle:(NSString *)title
                  description:(NSString *)description
            publiclyIndexable:(BOOL)publiclyIndexable
                         type:(NSString *)type
                 thumbnailUrl:(NSURL *)thumbnailUrl
                     callback:(callbackWithUrl)callback {
    [self indexContentWithTitle:title
                    description:description
              publiclyIndexable:publiclyIndexable
                           type:type
                   thumbnailUrl:thumbnailUrl
                       keywords:nil
                       userInfo:nil
                 expirationDate:nil
                       callback:callback];
}

- (void)indexContentWithTitle:(NSString *)title
                  description:(NSString *)description
            publiclyIndexable:(BOOL)publiclyIndexable
                         type:(NSString *)type
                 thumbnailUrl:(NSURL *)thumbnailUrl
                     keywords:(NSSet *)keywords
                     callback:(callbackWithUrl)callback {
    [self indexContentWithTitle:title
                    description:description
              publiclyIndexable:publiclyIndexable
                           type:type
                   thumbnailUrl:thumbnailUrl
                       keywords:keywords
                       userInfo:nil
                 expirationDate:nil
                       callback:callback];
}

- (void)indexContentWithTitle:(NSString *)title
                  description:(NSString *)description
            publiclyIndexable:(BOOL)publiclyIndexable
                         type:(NSString *)type
                 thumbnailUrl:(NSURL *)thumbnailUrl
                     keywords:(NSSet *)keywords {
    [self indexContentWithTitle:title
                    description:description
              publiclyIndexable:publiclyIndexable
                           type:type
                   thumbnailUrl:thumbnailUrl
                       keywords:keywords
                       userInfo:nil
                 expirationDate:nil
                       callback:NULL];
}

- (void)indexContentWithTitle:(NSString *)title
                  description:(NSString *)description
            publiclyIndexable:(BOOL)publiclyIndexable
                         type:(NSString *)type
                 thumbnailUrl:(NSURL *)thumbnailUrl
                     keywords:(NSSet *)keywords
                     userInfo:(NSDictionary *)userInfo {
    [self indexContentWithTitle:title
                    description:description
              publiclyIndexable:publiclyIndexable
                           type:type
                   thumbnailUrl:thumbnailUrl
                       keywords:keywords
                       userInfo:userInfo
                 expirationDate:nil
                       callback:NULL];
}

- (void)indexContentWithTitle:(NSString *)title
                  description:(NSString *)description
            publiclyIndexable:(BOOL)publiclyIndexable
                 thumbnailUrl:(NSURL *)thumbnailUrl
                     userInfo:(NSDictionary *)userInfo {
    [self indexContentWithTitle:title
                    description:description
              publiclyIndexable:publiclyIndexable
                           type:kUTTypeGeneric
                   thumbnailUrl:thumbnailUrl
                       keywords:nil
                       userInfo:userInfo
                 expirationDate:nil
                       callback:NULL];
}

- (void)indexContentWithTitle:(NSString *)title
                  description:(NSString *)description
            publiclyIndexable:(BOOL)publiclyIndexable
                 thumbnailUrl:(NSURL *)thumbnailUrl
                     keywords:(NSSet *)keywords
                     userInfo:(NSDictionary *)userInfo {
    [self indexContentWithTitle:title
                    description:description
              publiclyIndexable:publiclyIndexable
                           type:kUTTypeGeneric
                   thumbnailUrl:thumbnailUrl
                       keywords:keywords
                       userInfo:userInfo
                 expirationDate:nil
                       callback:NULL];
}

- (void)indexContentWithTitle:(NSString *)title
                  description:(NSString *)description
            publiclyIndexable:(BOOL)publiclyIndexable
                         type:(NSString *)type
                 thumbnailUrl:(NSURL *)thumbnailUrl
                     keywords:(NSSet *)keywords
                     userInfo:(NSDictionary *)userInfo
               expirationDate:(NSDate*)expirationDate
                     callback:(callbackWithUrl)callback {
    [self indexContentWithTitle:title
                    description:description
                    canonicalId:nil
              publiclyIndexable:publiclyIndexable
                           type:type
                   thumbnailUrl:thumbnailUrl
                       keywords:keywords
                       userInfo:userInfo
                 expirationDate:nil
                       callback:callback
              spotlightCallback:nil];
}

- (void)indexContentWithTitle:(NSString *)title
                  description:(NSString *)description
                  canonicalId:(NSString *)canonicalId
            publiclyIndexable:(BOOL)publiclyIndexable
                         type:(NSString *)type
                 thumbnailUrl:(NSURL *)thumbnailUrl
                     keywords:(NSSet *)keywords
                     userInfo:(NSDictionary *)userInfo
               expirationDate:(NSDate*)expirationDate
                     callback:(callbackWithUrl)callback {
    [self indexContentWithTitle:title
                    description:description
                    canonicalId:canonicalId
              publiclyIndexable:publiclyIndexable
                           type:type
                   thumbnailUrl:thumbnailUrl
                       keywords:keywords
                       userInfo:userInfo
                 expirationDate:nil
                       callback:callback
              spotlightCallback:nil];
}


- (void)indexContentWithTitle:(NSString *)title
                  description:(NSString *)description
            publiclyIndexable:(BOOL)publiclyIndexable
                         type:(NSString *)type
                 thumbnailUrl:(NSURL *)thumbnailUrl
                     keywords:(NSSet *)keywords
                     userInfo:(NSDictionary *)userInfo
                     callback:(callbackWithUrl)callback {
    [self indexContentWithTitle:title
                    description:description
                    canonicalId:nil
              publiclyIndexable:publiclyIndexable
                           type:type
                   thumbnailUrl:thumbnailUrl
                       keywords:keywords
                       userInfo:userInfo
                 expirationDate:nil
                       callback:callback
              spotlightCallback:nil];
}

- (void)indexContentWithTitle:(NSString *)title
                  description:(NSString *)description
            publiclyIndexable:(BOOL)publiclyIndexable
                         type:(NSString *)type
                 thumbnailUrl:(NSURL *)thumbnailUrl
                     keywords:(NSSet *)keywords
                     userInfo:(NSDictionary *)userInfo
            spotlightCallback:(callbackWithUrlAndSpotlightIdentifier)spotlightCallback {
    [self indexContentWithTitle:title
                    description:description
                    canonicalId:nil
              publiclyIndexable:publiclyIndexable
                           type:type
                   thumbnailUrl:thumbnailUrl
                       keywords:keywords
                       userInfo:userInfo
                 expirationDate:nil
                       callback:nil
              spotlightCallback:spotlightCallback];
}

-(void) indexObject:(BranchUniversalObject *)universalObject
       onCompletion:(void (^)(BranchUniversalObject *, NSString*, NSError *))completion {
    
    [self indexContentWithTitle:universalObject.title
                    description:universalObject.description
                    canonicalId:universalObject.canonicalUrl
              publiclyIndexable:universalObject.contentIndexMode
                           type:universalObject.type
                   thumbnailUrl:[NSURL URLWithString: universalObject.imageUrl]
                       keywords:[NSSet setWithArray:universalObject.keywords]
                       userInfo:universalObject.metadata expirationDate:nil
                       callback:nil
              spotlightCallback:^(NSString * _Nullable url, NSString * _Nullable spotlightIdentifier, NSError * _Nullable error) {
                  
                  if (error) {
                      completion(universalObject,url,error);
                  } else {
                      universalObject.spotlightIdentifier = spotlightIdentifier;
                      completion(universalObject,url,error);
                  }
              }];
}

//This is the final one, which figures out which callback to use, if any
// The simpler callbackWithURL overrides spotlightCallback, so don't send both
- (void)indexContentWithTitle:(NSString *)title
                  description:(NSString *)description
                  canonicalId:(NSString *)canonicalId
            publiclyIndexable:(BOOL)publiclyIndexable
                         type:(NSString *)type
                 thumbnailUrl:(NSURL *)thumbnailUrl
                     keywords:(NSSet *)keywords
                     userInfo:(NSDictionary *)userInfo
               expirationDate:(NSDate *)expirationDate
                     callback:(callbackWithUrl)callback
            spotlightCallback:(callbackWithUrlAndSpotlightIdentifier)spotlightCallback {

    
    if(publiclyIndexable) {
        [self.spotlight indexContentUsingUserActivityWithTitle:title
                                              description:description
                                              canonicalId:canonicalId
                                                     type:type
                                             thumbnailUrl:thumbnailUrl
                                                 keywords:keywords
                                                 userInfo:userInfo
                                           expirationDate:expirationDate
                                                 callback:callback
                                        spotlightCallback:spotlightCallback];
    } else {
        [self.spotlight indexContentUsingCSSearchableItemWithTitle:title
                                                  CanonicalId:canonicalId
                                                  description:description
                                                         type:type
                                                 thumbnailUrl:thumbnailUrl
                                                     userInfo:userInfo
                                                     keywords:keywords
                                                     callback:callback
                                            spotlightCallback:spotlightCallback];
    }
}

-(void) indexObjectUsingSearchableItem:(BranchUniversalObject *)universalObject
                          onCompletion:(void (^)(BranchUniversalObject *, NSError *))completion {
    BNCSpotlightService* spotlight = [[BNCSpotlightService alloc] init];
    [spotlight indexContentUsingCSSearchableItemWithTitle:universalObject.title
                                         CanonicalId:universalObject.canonicalIdentifier
                                         description:universalObject.canonicalIdentifier
                                                type:universalObject.type
                                        thumbnailUrl:[NSURL URLWithString:universalObject.imageUrl]
                                            userInfo:nil
                                            keywords:[NSSet setWithArray:universalObject.keywords]
                                            callback:nil
                                   spotlightCallback:^(NSString * _Nullable url, NSString * _Nullable spotlightIdentifier, NSError * _Nullable error) {
                                       if (!error) {
                                           universalObject.spotlightIdentifier = spotlightIdentifier;
                                       }
                                       completion(universalObject,error);
                                   }];
}

- (dispatch_queue_t) workQueue {
    @synchronized (self) {
        if (!_workQueue)
            _workQueue = dispatch_queue_create("io.branch.sdk.spotlight.indexing", DISPATCH_QUEUE_CONCURRENT);
        return _workQueue;
    }
}

-(void) indexObjectsUsingSearchableItem:(NSArray<BranchUniversalObject *> *)universalObjects
                           onCompletion:(void (^)(NSArray<BranchUniversalObject *> *))completion
                              onFailure:(void (^)(BranchUniversalObject *, NSError *))failure {
    
    dispatch_group_t workGroup = dispatch_group_create();
    NSMutableArray<BranchUniversalObject*> *completedBUO = [[NSMutableArray alloc] init];
    
    for (BranchUniversalObject* universalObject in universalObjects) {
        dispatch_group_async(workGroup, self.workQueue, ^{
            dispatch_semaphore_t indexingSema = dispatch_semaphore_create(0);
            [self indexObjectUsingSearchableItem:universalObject
                                    onCompletion:^(BranchUniversalObject *universalObject, NSError *error) {
                                        if (error)
                                            failure(universalObject,error);
                                        else
                                            [completedBUO addObject:universalObject];
                                        
                                        dispatch_semaphore_signal(indexingSema);
                                    }];
            dispatch_semaphore_wait(indexingSema, DISPATCH_TIME_FOREVER);
        });
    }
    
    dispatch_group_wait(workGroup, DISPATCH_TIME_FOREVER);
    completion(completedBUO);
}

-(void) removeSearchableItemWithBranchUniversalObject:(BranchUniversalObject *)universalObject
                                           completion:(completion)completion {
    
    if (universalObject.spotlightIdentifier == nil || [universalObject.spotlightIdentifier isEqualToString:@""]) {
        NSError* error = [NSError errorWithDomain:BNCErrorDomain code:BNCSpotlightTitleError userInfo:nil];
        completion(error);
        return;
    }
    
    [self.spotlight removeSearchableItemsWithIdentifier:universalObject.spotlightIdentifier
                                      completionHandler:completion];
}

-(void) removeSearchableItemsWithBranchUniversalObjects:(NSArray<BranchUniversalObject *> *)universalObjects
                                  completion:(completion)completion {
    
    NSMutableArray<NSString *> *spotlightIdentifiers = [[NSMutableArray alloc] init];
    
    for (BranchUniversalObject* universalObject in universalObjects) {
        [spotlightIdentifiers addObject:universalObject.spotlightIdentifier];
    }
    
    [self.spotlight removeSearchableItemsWithIdentifiers:spotlightIdentifiers
                                       completionHandler:completion];
}

-(void) removeSearchableItemsByBranchSpotlightDomainWithCompletionHandler:(completion)completion {
    [self.spotlight removeSearchableItemsByBranchSpotlightDomainWithCompletionHandler:completion];
}

@end
