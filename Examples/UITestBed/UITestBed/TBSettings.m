//
//  TBSettings.m
//  UITestBed
//
//  Created by Edward on 5/7/18.
//  Copyright © 2018 Branch. All rights reserved.
//

#import "TBSettings.h"

@implementation TBSettings

+ (TBSettings*) shared {
    static TBSettings *sharedSettings = nil;
    static dispatch_once_t onceToken = 0;
    dispatch_once(&onceToken, ^{
        sharedSettings = [[TBSettings alloc] init];
    });
    return sharedSettings;
}

- (BOOL) usePrettyDisplay {
    return [[NSUserDefaults standardUserDefaults] boolForKey:@"prettyDisplay"];
}

- (void) setUsePrettyDisplay:(BOOL)b {
    [[NSUserDefaults standardUserDefaults] setBool:b forKey:@"prettyDisplay"];
}

@end
