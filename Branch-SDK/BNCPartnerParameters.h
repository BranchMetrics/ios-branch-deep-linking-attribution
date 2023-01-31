//
//  BNCPartnerParameters.h
//  Branch
//
//  Created by Ernest Cho on 12/9/20.
//  Copyright © 2020 Branch, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

/**
 Parameters that clients wish to share with partners
 */
@interface BNCPartnerParameters : NSObject

+ (instancetype)shared;

// FB partner parameters, see FB documentation for details
// Values that do not look like a valid SHA-256 hash are ignored
- (void)addFacebookParameterWithName:(NSString *)name value:(NSString *)value;

// Snap partner parameters, see Snap documentation for details
// Values that do not look like a valid SHA-256 hash are ignored
- (void)addSnapParameterWithName:(NSString *)name value:(NSString *)value;

- (void)clearAllParameters;

// reference to the internal json dictionary
- (NSDictionary *)parameterJson;

@end

NS_ASSUME_NONNULL_END
