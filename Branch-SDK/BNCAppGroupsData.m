//
//  BNCAppGroupsData.m
//  Branch
//
//  Created by Ernest Cho on 9/27/20.
//  Copyright © 2020 Branch, Inc. All rights reserved.
//

#import "BNCAppGroupsData.h"
#import "BNCDeviceInfo.h"

@interface BNCAppGroupsData()
@property (nonatomic, strong, readwrite) NSUserDefaults *groupDefaults;
@end

@implementation BNCAppGroupsData

- (instancetype)initWithAppGroup:(NSString *)appGroup {
    self = [super init];
    if (self) {
        if (appGroup) {
            self.groupDefaults = [[NSUserDefaults alloc] initWithSuiteName:appGroup];
        }
    }
    return self;
}

- (void)saveString:(NSString *)string forKey:(NSString *)key {
    if (self.groupDefaults) {
        [self.groupDefaults setObject:string forKey:key];
    }
}

- (NSString *)getStringForKey:(NSString *)key {
    if (self.groupDefaults) {
        return [self.groupDefaults stringForKey:key];
    }
    return nil;
}

@end
