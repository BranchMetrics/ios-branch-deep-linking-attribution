//
//  BNCCallbackMap.m
//  Branch
//
//  Created by Ernest Cho on 2/25/20.
//  Copyright © 2020 Branch, Inc. All rights reserved.
//

#import "BNCCallbackMap.h"

@interface BNCCallbackMap()
@property (nonatomic, strong, readwrite) NSMapTable *callbacks;
@end

@implementation BNCCallbackMap

+ (instancetype)shared {
    static BNCCallbackMap *map;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        map = [BNCCallbackMap new];
    });
    return map;
}

- (instancetype)init {
    self = [super init];
    if (self) {
        
        // the key is a weak pointer to the request object
        // the value is a strong pointer to the request callback block
        // if the request object becomes nil, the callback block is lost
        self.callbacks = [NSMapTable mapTableWithKeyOptions:NSMapTableWeakMemory valueOptions:NSMapTableStrongMemory];
    }
    return self;
}

- (void)storeRequest:(BNCServerRequest *)request withCompletion:(void (^_Nullable)(BOOL success, NSString *statusMessage))completion {
    [self.callbacks setObject:completion forKey:request];
}

- (BOOL)containsRequest:(BNCServerRequest *)request {
    BOOL contains = NO;
    if ([self.callbacks objectForKey:request] != nil) {
        contains = YES;
    }
    return contains;
}

- (void)callCompletionForRequest:(BNCServerRequest *)request withSuccessStatus:(BOOL)status message:(NSString *)statusMessage {
    void (^completion)(BOOL, NSString *) = [self.callbacks objectForKey:request];
    if (completion) {
        completion(status, statusMessage);
    }
}

@end
