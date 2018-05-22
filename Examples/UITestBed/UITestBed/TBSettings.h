//
//  TBSettings.h
//  UITestBed
//
//  Created by Edward on 5/7/18.
//  Copyright © 2018 Branch. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface TBSettings : NSObject
+ (TBSettings*) shared;
@property (nonatomic, assign) BOOL usePrettyDisplay;
@end
