//
//  BNCJsonLoader.h
//  Branch-TestBed
//
//  Created by Ernest Cho on 9/16/19.
//  Copyright © 2019 Branch, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface BNCJsonLoader : NSObject

// test utility that loads json files from the Test Bundle.  only works on hosted tests
+ (NSDictionary *)dictionaryFromJSONFileNamed:(NSString *)fileName;

@end

NS_ASSUME_NONNULL_END
