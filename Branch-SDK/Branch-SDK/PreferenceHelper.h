//
//  PreferenceHelper.h
//  KindredPrints-iOS-TestBed
//
//  Created by Alex Austin on 1/31/14.
//  Copyright (c) 2014 Kindred Prints. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface PreferenceHelper : NSObject

+ (void)writeIntegerToDefaults:(NSString *)key value:(NSInteger)value;
+ (void)writeBoolToDefaults:(NSString *)key value:(BOOL)value;
+ (void)writeObjectToDefaults:(NSString *)key value:(NSObject *)value;

+ (NSObject *)readObjectFromDefaults:(NSString *)key;
+ (BOOL)readBoolFromDefaults:(NSString *)key;
+ (NSInteger)readIntegerFromDefaults:(NSString *)key;

@end
