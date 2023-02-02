//
//  BNCEventUtils.h
//  BranchSDK
//
//  Created by Nipun Singh on 1/31/23.
//

#import <Foundation/Foundation.h>
#import "BranchEvent.h"

NS_ASSUME_NONNULL_BEGIN

@interface BNCEventUtils : NSObject

+ (instancetype)shared;

- (void)storeEvent:(BranchEvent *)event;

- (void)removeEvent:(BranchEvent *)event;

@end

NS_ASSUME_NONNULL_END
