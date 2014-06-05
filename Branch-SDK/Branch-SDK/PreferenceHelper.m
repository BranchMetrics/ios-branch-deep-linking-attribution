//
//  PreferenceHelper.m
//  KindredPrints-iOS-TestBed
//
//  Created by Alex Austin on 1/31/14.
//  Copyright (c) 2014 Kindred Prints. All rights reserved.
//

#import "PreferenceHelper.h"

@implementation PreferenceHelper

+ (void)writeIntegerToDefaults:(NSString *)key value:(NSInteger)value
{
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [defaults setInteger:value forKey:key];
    [defaults synchronize];
}

+ (void)writeBoolToDefaults:(NSString *)key value:(BOOL)value
{
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [defaults setBool:value forKey:key];
    [defaults synchronize];
}

+ (void)writeObjectToDefaults:(NSString *)key value:(NSObject *)value
{
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [defaults setObject:value forKey:key];
    [defaults synchronize];
}

+ (NSObject *)readObjectFromDefaults:(NSString *)key
{
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    NSObject *obj = [defaults objectForKey:key];
    return obj;
}

+ (BOOL)readBoolFromDefaults:(NSString *)key {
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    BOOL boo = [defaults boolForKey:key];
    return boo;
}

+ (NSInteger)readIntegerFromDefaults:(NSString *)key
{
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    NSInteger integ = [defaults integerForKey:key];
    return integ;
}


@end
