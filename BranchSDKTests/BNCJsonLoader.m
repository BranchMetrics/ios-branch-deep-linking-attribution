//
//  BNCJsonLoader.m
//  Branch-TestBed
//
//  Created by Ernest Cho on 9/16/19.
//  Copyright © 2019 Branch, Inc. All rights reserved.
//

#import "BNCJsonLoader.h"

@implementation BNCJsonLoader

+ (NSDictionary *)dictionaryFromJSONFileNamed:(NSString *)fileName {
    
    // Since this class is part of the Test target, [self class] returns the Test Bundle
    NSString *path = [[NSBundle bundleForClass:[self class]] pathForResource:fileName ofType:@"json"];
    
    NSString *jsonString = [NSString stringWithContentsOfFile:path encoding:NSUTF8StringEncoding error:NULL];
    
    id dict = [NSJSONSerialization JSONObjectWithData:[jsonString dataUsingEncoding:NSUTF8StringEncoding] options:0 error:nil];
    if ([dict isKindOfClass:NSDictionary.class]) {
        return dict;
    }
    return nil;
}

@end
