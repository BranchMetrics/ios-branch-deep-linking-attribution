//
//  BNCKeyChain.h
//  Branch-SDK
//
//  Created by Edward on 1/8/18.
//  Copyright © 2018 Branch. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface BNCKeyChain : NSObject
+ (NSError*) storeValue:(id)value forService:(NSString*)service key:(NSString*)key iCloud:(BOOL)iCloud;
+ (id) retrieveValueForService:(NSString*)service key:(NSString*)key error:(NSError**)error;
+ (NSError*) removeValuesForService:(NSString*)service key:(NSString*)key;
@end
